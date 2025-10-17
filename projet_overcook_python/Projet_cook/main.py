# main.py
import tkinter as tk
from typing import List, Tuple, Optional, Iterable, Deque
from collections import deque
import time

from carte import Carte
from player import Player
from recette import (
    Aliment, EtatAliment, Recette,
    ALIMENTS_BAC, prendre_au_bac, nouvelle_recette, IngredientRequis
)

# ---------- Carte d'exemple ----------
grille: List[List[int]] = [
    [6,6,6,6,6,6,6,6,6,6],
    [6,0,0,3,2,2,0,0,8,6],
    [6,1,0,0,0,0,0,0,8,6],
    [6,1,0,0,0,0,0,0,4,6],
    [6,1,0,0,0,0,0,0,4,6],
    [6,1,0,0,0,0,0,0,4,6],

    [6,0,0,7,7,3,0,0,4,6],
    [6,6,6,6,6,6,6,6,6,6],
]

W, H = 600, 600
GAME_DURATION_S = 180
TICK_MS = 100
MOVE_EVERY = 1
BLOCK_TIMEOUT_S = 3.0
PAUSE_AFTER_RESET_S = 1.0

# ---------- Helpers recettes ----------
def recettes_possibles_pour_items(items: List[Aliment], recettes: List[Recette]) -> List[Recette]:
    possibles: List[Recette] = []
    for r in recettes:
        non_perimes = [a for a in items if not a.est_perime]
        requis = r.requis.copy()
        used = [False]*len(requis)
        ok = True
        for a in non_perimes:
            matched = False
            for i, req in enumerate(requis):
                if used[i]:
                    continue
                if a.nom == req.nom and a.etat == req.etat:
                    used[i] = True
                    matched = True
                    break
            if not matched:
                ok = False
                break
        if ok:
            possibles.append(r)
    return possibles

def items_completent_recette(items: List[Aliment], r: Recette) -> bool:
    non_perimes = [a for a in items if not a.est_perime]
    if len(non_perimes) < len(r.requis):
        return False
    used = [False]*len(r.requis)
    matched = 0
    for a in non_perimes:
        for i, req in enumerate(r.requis):
            if used[i]:
                continue
            if a.nom == req.nom and a.etat == req.etat:
                used[i] = True
                matched += 1
                break
    return matched == len(r.requis)

def matched_flags_for_recipe(items: List[Aliment], r: Recette) -> List[bool]:
    """Pour chaque requis, True si un item (non périmé) de même nom+état est présent."""
    flags = [False] * len(r.requis)
    for a in items:
        if a.est_perime:
            continue
        for i, req in enumerate(r.requis):
            if not flags[i] and a.nom == req.nom and a.etat == req.etat:
                flags[i] = True
                break
    return flags

def first_missing_index(flags: List[bool]) -> int:
    for i, ok in enumerate(flags):
        if not ok:
            return i
    return 0

# ---------- Pathfinding (BFS) ----------
Coord = Tuple[int, int]

def voisins_libres(carte: Carte, x: int, y: int) -> Iterable[Coord]:
    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
        nx, ny = x+dx, y+dy
        if 0 <= nx < carte.cols and 0 <= ny < carte.rows and not carte.est_bloquant(nx, ny):
            yield (nx, ny)

def bfs_path(carte: Carte, start: Coord, goals: Iterable[Coord]) -> Optional[List[Coord]]:
    goal_set = set(goals)
    q: Deque[Coord] = deque([start])
    parent: dict[Coord, Optional[Coord]] = {start: None}
    while q:
        cur = q.popleft()
        if cur in goal_set:
            path = [cur]
            while parent[cur] is not None:
                cur = parent[cur]
                path.append(cur)
            path.reverse()
            return path
        for nxt in voisins_libres(carte, *cur):
            if nxt not in parent:
                parent[nxt] = cur
                q.append(nxt)
    return None

def cases_adjacentes_a_stations(carte: Carte, stations: List[Coord]) -> List[Coord]:
    adj: set[Coord] = set()
    for (sx, sy) in stations:
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx, ny = sx+dx, sy+dy
            if 0 <= nx < carte.cols and 0 <= ny < carte.rows and not carte.est_bloquant(nx, ny):
                adj.add((nx, ny))
    return list(adj)

# ---------- Game + Bot ----------
class Game:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.canvas = tk.Canvas(root, width=W, height=H)
        self.canvas.pack()

        self.carte = Carte(grille, largeur=W, hauteur=H)
        self.carte.assigner_bacs(ALIMENTS_BAC)

        self.player = Player(2, 2)

        self.score = 0
        self.deadline = time.time() + GAME_DURATION_S
        self.last_tick = time.time()

        self.recettes: List[Recette] = [nouvelle_recette(), nouvelle_recette(), nouvelle_recette()]

        self.current_path: List[Coord] = []
        self.move_cooldown = 0
        self.bot_recette: Optional[Recette] = None
        self.bot_ingredient_en_cours: Optional[IngredientRequis] = None
        self.next_req_idx: int = 0

        # anti-blocage
        self.last_progress_time = time.time()
        self.last_pos: Coord = (self.player.x, self.player.y)
        self.pause_until = 0.0

        # assembleur “verrouillé” (si on exploite un partiel)
        self.current_assembly: Optional[Coord] = None

        self._refresh()
        self.root.after(TICK_MS, self._tick)

    # ---------- HUD ----------
    def _dessiner_hud(self):
        remaining = max(0, int(self.deadline - time.time()))
        mm = remaining // 60
        ss = remaining % 60
        info = f"⏱ {mm:02d}:{ss:02d}    ★ Score: {self.score}"

        self.canvas.create_rectangle(0, 0, W, 28, fill="#222", outline="")
        self.canvas.create_text(8, 14, text=info, fill="white", anchor="w", font=("Arial", 12, "bold"))

        y = 28
        self.canvas.create_rectangle(0, y, W, y + 22 * 3 + 6, fill="#333", outline="")
        for i, r in enumerate(self.recettes):
            need = " + ".join(f"{req.nom}({req.etat.name})" for req in r.requis)
            txt = f"{i+1}. {r.nom}  [{need}]"
            self.canvas.create_text(8, y + 4 + i * 22, text=txt, fill="white", anchor="nw", font=("Arial", 11))

    def _refresh(self):
        self.player.dessiner(self.canvas, self.carte)
        self._dessiner_hud()

    # ---------- anti-blocage ----------
    def _mark_progress(self):
        self.last_progress_time = time.time()
        self.last_pos = (self.player.x, self.player.y)

    def _enter_cooldown(self, seconds: float = PAUSE_AFTER_RESET_S) -> None:
        self.pause_until = time.time() + seconds
        self.current_path = []
        self.move_cooldown = 0

    def _restart_recipe_flow(self) -> None:
        self.player.item = None
        self.current_assembly = None
        if self.recettes:
            self.bot_recette = self.recettes[0]
            self.next_req_idx = 0
        self.current_path = []
        self._refresh()
        self._enter_cooldown(PAUSE_AFTER_RESET_S)
        self._mark_progress()

    def _check_blockage(self):
        now = time.time()
        pos_now = (self.player.x, self.player.y)
        stagnant = (pos_now == self.last_pos)
        if stagnant and (now - self.last_progress_time) > BLOCK_TIMEOUT_S:
            self._restart_recipe_flow()

    # ---------- Actions “joueur” ----------
    def try_action_e(self):
        p = self.player

        # --- BAC : ne prendre que l’ingrédient requis courant ---
        adj_bac = p.est_adjacent_a(self.carte.pos_bacs)
        if p.item is None and adj_bac and self.bot_recette:
            target_req = self.bot_recette.requis[self.next_req_idx % len(self.bot_recette.requis)]
            nom_bac, v = self.carte.bacs_config.get(adj_bac, ("?", 0.0005))
            if nom_bac != target_req.nom:
                return False
            p.item = prendre_au_bac(nom_bac, v)
            self._mark_progress()
            self._refresh()
            return True

        # --- DÉCOUPE : seulement si requis COUPE ---
        if p.item and p.est_adjacent_a(self.carte.pos_decoupes) and self.bot_recette:
            etat_requis = None
            for req in self.bot_recette.requis:
                if req.nom == p.item.nom:
                    etat_requis = req.etat
                    break
            if etat_requis == EtatAliment.COUPE and p.item.etat == EtatAliment.SORTI_DU_BAC and not p.item.est_perime:
                p.item.transformer(EtatAliment.COUPE)
                self._mark_progress()
                self._refresh()
                return True

        # --- CUISSON : seulement si requis CUIT ---
        if p.item and (p.est_adjacent_a(self.carte.pos_fours) or p.est_adjacent_a(self.carte.pos_poeles)) and self.bot_recette:
            etat_requis = None
            for req in self.bot_recette.requis:
                if req.nom == p.item.nom:
                    etat_requis = req.etat
                    break
            if etat_requis == EtatAliment.CUIT and not p.item.est_perime:
                if p.item.etat in (EtatAliment.SORTI_DU_BAC, EtatAliment.COUPE):
                    p.item.transformer(EtatAliment.CUIT)
                    self._mark_progress()
                    self._refresh()
                    return True

        # --- ASSEMBLAGE ---
        adj_ass = p.est_adjacent_a(self.carte.pos_assemblages)
        if adj_ass:
            stock = self.carte.assemblage_stock.setdefault(adj_ass, [])

            # Si la recette courante est déjà complète ici : finaliser sans déposer
            if self.bot_recette and p.item is None and items_completent_recette(stock, self.bot_recette):
                stock.clear()
                stock.append(Aliment(nom=self.bot_recette.nom, etat=EtatAliment.CUIT, vitesse_peremption=0.0005))
                self._mark_progress()
                self._refresh()
                return True

            # Déposer ?
            if p.item and not p.item.est_perime:
                tentative = stock + [p.item]
                possibles = recettes_possibles_pour_items(tentative, self.recettes)

                if not possibles:
                    # Mauvais ingrédient : si assembleur vide dispo -> y déposer, sinon jeter + pause + restart
                    assembleurs_vides = [pos for pos in self.carte.pos_assemblages
                                         if len(self.carte.assemblage_stock.get(pos, [])) == 0]
                    if assembleurs_vides:
                        # si celui-ci est vide, déposer directement
                        if len(stock) == 0:
                            self.carte.assemblage_stock[adj_ass].append(p.item)
                            p.item = None
                            self._mark_progress()
                            self._refresh()
                            return True
                        # sinon aller vers l'assembleur vide le plus proche
                        adj_targets = cases_adjacentes_a_stations(self.carte, assembleurs_vides)
                        path = bfs_path(self.carte, (p.x, p.y), adj_targets)
                        if path:
                            self.current_path = path
                            self.move_cooldown = 0
                            return True

                    # Tous pleins OU pas d'assembleur vide atteignable -> jeter + purge + pause + restart
                    all_full = all(len(self.carte.assemblage_stock.get(pos, [])) > 0 for pos in self.carte.pos_assemblages)
                    if all_full:
                        # jette l'item en main
                        p.item = None
                        # purge 1 item du plus proche assembleur non vide
                        non_vides = [pos for pos in self.carte.pos_assemblages
                                     if len(self.carte.assemblage_stock.get(pos, [])) > 0]
                        if non_vides:
                            nearest = min(non_vides, key=lambda t: abs(p.x - t[0]) + abs(p.y - t[1]))
                            st = self.carte.assemblage_stock.get(nearest, [])
                            if st:
                                st.pop()
                        self._restart_recipe_flow()
                        return True

                    # Sinon essayer un autre assembleur
                    autres = [pos for pos in self.carte.pos_assemblages if pos != adj_ass]
                    if autres:
                        adj_targets = cases_adjacentes_a_stations(self.carte, autres)
                        path = bfs_path(self.carte, (p.x, p.y), adj_targets)
                        if path:
                            self.current_path = path
                            self.move_cooldown = 0
                            return True
                    return False

                # Compatible -> déposer
                stock.append(p.item)
                p.item = None

                completed_now = False
                for r in possibles:
                    if items_completent_recette(stock, r):
                        stock.clear()
                        stock.append(Aliment(nom=r.nom, etat=EtatAliment.CUIT, vitesse_peremption=0.0005))
                        completed_now = True
                        break
                if not completed_now and self.bot_recette:
                    self.next_req_idx = (self.next_req_idx + 1) % len(self.bot_recette.requis)

                self._mark_progress()
                self._refresh()
                return True

            # Reprendre plat final prêt
            if p.item is None and stock:
                if len(stock) == 1 and stock[0].nom in [r.nom for r in self.recettes]:
                    p.item = stock.pop(0)
                    self._mark_progress()
                    self._refresh()
                    # aller au Service
                    self._aller_adjacent("SERVICE")
                    return True

        # --- SERVICE : livrer si adjacent (géométrique) ---
        if p.item:
            est_adj_service = any(abs(p.x - sx) + abs(p.y - sy) == 1 for (sx, sy) in self.carte.pos_services)
            if est_adj_service:
                for idx, r in enumerate(self.recettes):
                    if p.item.nom == r.nom:
                        self.score += 100
                        p.item = None
                        self.recettes[idx] = nouvelle_recette()
                        self._mark_progress()
                        self._refresh()
                        return True

        return False

    # ---------- Planification ----------
    def _planifier(self):
        # Plat final en main -> Service
        if self.player.item and any(r.nom == self.player.item.nom for r in self.recettes):
            self._aller_adjacent("SERVICE")
            return

        # Si un ingrédient est en main -> étape selon l'état requis
        if self.player.item and self.bot_recette:
            a = self.player.item
            etat_requis = None
            for req in self.bot_recette.requis:
                if req.nom == a.nom:
                    etat_requis = req.etat
                    break
            if etat_requis == EtatAliment.COUPE:
                if a.etat == EtatAliment.SORTI_DU_BAC:
                    self._aller_adjacent("DECOUPE"); return
                else:
                    self._aller_adjacent("ASSEMBLAGE"); return
            elif etat_requis == EtatAliment.CUIT:
                if a.etat != EtatAliment.CUIT:
                    self._aller_adjacent("FOUR_OU_POELE"); return
                else:
                    self._aller_adjacent("ASSEMBLAGE"); return
            else:
                self._aller_adjacent("ASSEMBLAGE"); return

        # Sinon : exploiter un assembleur partiellement prêt pour la 1re recette
        if not self.recettes:
            return
        if self.bot_recette is None:
            self.bot_recette = self.recettes[0]

        # scan des assembleurs
        best = None  # (pos, flags, matches, dist)
        for pos, stock in self.carte.assemblage_stock.items():
            flags = matched_flags_for_recipe(stock, self.bot_recette)
            matches = sum(flags)
            if matches > 0:
                dist = abs(self.player.x - pos[0]) + abs(self.player.y - pos[1])
                cand = (pos, flags, matches, dist)
                if best is None or cand[2] > best[2] or (cand[2] == best[2] and cand[3] < best[3]):
                    best = cand

        if best:
            pos, flags, _, _ = best
            self.current_assembly = pos
            # si déjà complet -> aller dessus, on finalisera sur place
            if all(flags):
                self._aller_adjacent("ASSEMBLAGE")
                return
            # sinon, viser le 1er requis manquant
            self.next_req_idx = first_missing_index(flags)
            target_req = self.bot_recette.requis[self.next_req_idx]
            self._aller_adjacent("BAC", cible_aliment=target_req.nom)
            return

        # rien d'utile sur les assembleurs -> prendre 1er ingrédient
        self.current_assembly = None
        self.bot_recette = self.recettes[0]
        self.next_req_idx = 0
        target_req = self.bot_recette.requis[self.next_req_idx]
        self._aller_adjacent("BAC", cible_aliment=target_req.nom)

    def _aller_adjacent(self, type_cible: str, cible_aliment: Optional[str] = None):
        px, py = self.player.x, self.player.y

        if type_cible == "BAC":
            stations = [pos for pos, (nom, _) in self.carte.bacs_config.items() if nom == (cible_aliment or "")]
        elif type_cible == "DECOUPE":
            stations = self.carte.pos_decoupes
        elif type_cible == "FOUR_OU_POELE":
            stations = self.carte.pos_fours + self.carte.pos_poeles or self.carte.pos_decoupes
        elif type_cible == "ASSEMBLAGE":
            stations = [self.current_assembly] if self.current_assembly else self.carte.pos_assemblages
        elif type_cible == "SERVICE":
            stations = self.carte.pos_services
        else:
            stations = []

        adj = cases_adjacentes_a_stations(self.carte, stations)
        path = bfs_path(self.carte, (px, py), adj)
        self.current_path = path or []

    def _suivre_chemin(self):
        if not self.current_path:
            return
        if self.current_path and self.current_path[0] == (self.player.x, self.player.y):
            self.current_path.pop(0)
        if not self.current_path:
            return
        nx, ny = self.current_path.pop(0)
        dx = nx - self.player.x
        dy = ny - self.player.y
        if abs(dx) + abs(dy) != 1:
            return
        if   dx == -1: self.player.gauche(self.carte)
        elif dx ==  1: self.player.droite(self.carte)
        elif dy == -1: self.player.haut(self.carte)
        elif dy ==  1: self.player.bas(self.carte)
        self._mark_progress()

    # ---------- Boucle ----------
    def _tick(self):
        now = time.time()
        dt = now - self.last_tick
        self.last_tick = now

        # pause active ?
        if time.time() < self.pause_until:
            self._refresh()
            self.root.after(TICK_MS, self._tick)
            return

        if self.player.item:
            self.player.item.tick(dt)
            if self.player.item and self.player.item.est_perime:
                self.player.item = None

        for pos, stock in self.carte.assemblage_stock.items():
            for a in list(stock):
                a.tick(dt)
                if a.est_perime:
                    stock.remove(a)

        if now >= self.deadline:
            self.player.dessiner(self.canvas, self.carte)
            self.canvas.create_rectangle(0, 0, W, H, fill="#00000088", outline="")
            self.canvas.create_text(W/2, H/2 - 10, text="FIN !", fill="white", font=("Arial", 26, "bold"))
            self.canvas.create_text(W/2, H/2 + 22, text=f"Score : {self.score}", fill="white", font=("Arial", 18))
            return

        # anti-blocage avant décision
        self._check_blockage()

        if not self.current_path:
            acted = self.try_action_e()
            if not acted:
                self._planifier()
        else:
            self.move_cooldown += 1
            if self.move_cooldown >= MOVE_EVERY:
                self._suivre_chemin()
                self.move_cooldown = 0
                if not self.current_path:
                    if self.try_action_e():
                        self._mark_progress()

        self._refresh()
        self.root.after(TICK_MS, self._tick)

def main():
    root = tk.Tk()
    root.title("Cuisine — Joueur autonome (anti-blocage, assembleurs intelligents)")
    root.resizable(False, False)
    Game(root)
    root.mainloop()

if __name__ == "__main__":
    main()
