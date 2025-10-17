extends CharacterBody2D

@export var movement_speed: float = 4.0
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var plated_meal_scene = preload("res://scenes/PlatedMeal.tscn")
var step: String = ""
var node: Vector2

var held_item: Node = null
var nearby_interactables = []

var current_recipe: String = ""
var current_step_index: int = 0
var state: String = "idle"
var ingredient_collected = false 
var ingredient: String = ""

func _ready() -> void:
	var agent: RID = navigation_agent.get_rid()
	# Enable avoidance
	start_recipe("Steak")
	NavigationServer2D.agent_set_avoidance_enabled(agent, true)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	print("WorldState dispo ?", _WorldState)

func set_movement_target(target: Vector2):
	# Définir la cible de mouvement
	if target != null:
		print("Déplacement vers la cible :", target)
		navigation_agent.set_target_position(target)
		state = "moving_to_target"  # Passer à l'état de mouvement
	else:
		print("Cible invalide.")
		
func _physics_process(_delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		print("pas de carte de navigation valide")
		return
	if navigation_agent.is_navigation_finished():
		print("Agent est déjà arrivé à la cible.")
		return
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	print("Vitesse calculée : ", safe_velocity)
	velocity = safe_velocity
	move_and_slide()

func has_item() -> bool:
	return held_item != null

func add_item(item: Node) -> void:
	if has_item() and item_type() == "Plate":
		remove_item()
	elif has_item():
		return
	held_item = item
	add_child(item)
	item.position = Vector2.ZERO

func remove_item() -> Node:
	if not has_item():
		return null
	var removed_item = held_item
	if self.is_ancestor_of(held_item):
		remove_child(held_item)
		held_item = null
	return removed_item

func _try_interact():
	# Tenter d'interagir avec l'objet le plus proche
	var interactable = get_closest_interactable()
	if interactable:
		print("Interaction avec :", interactable.name)
		interactable.interact(self)
		_next_step()  # Passer à l'étape suivante
	else:
		print("Aucun objet à interagir.")

func get_closest_interactable():
	var closest = null
	var closest_dist := INF
	print("Vérification des objets interactifs proches...")
	for interactable in nearby_interactables:
		var dist = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest = interactable
			closest_dist = dist
	return closest

func item_type() -> String:
	if held_item is Ingredient and held_item.data.name == "Plate":
		return "Plate"
	else:
		return held_item.get_class()

func ingredient_to_meal() -> void:
	if held_item is Ingredient:
		var ingredient = remove_item()
		held_item = plated_meal_scene.instantiate() as PlatedMeal
		held_item.ingredients.append(ingredient)
		add_child(held_item)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactables"):
		nearby_interactables.append(area.get_parent())

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("interactables"):
		nearby_interactables.erase(parent)

func start_recipe(recipe_name: String):
	# Démarrer une recette
	current_recipe = recipe_name
	current_step_index = 0
	_next_step()

func _next_step():
	# Passer à l'étape suivante
	step = _RecipeManager.get_next_ingredient(current_recipe, "")
	print("Étape de recette actuelle : ", step)
	if step == "":
		print("Recette terminée.")
		state = "idle"
		return
	
	var parts = step.split("_")
	var ingredient_needed = parts[0]
	var state_needed = parts[1] if parts.size() > 1 else "base"

	print("Ingrédient nécessaire pour cette étape : ", ingredient_needed)
	print("État nécessaire : ", state_needed)

	# Mettre à jour l'ingrédient requis pour cette étape
	self.ingredient = ingredient_needed

	# Logique générique pour récupérer l'ingrédient avant de passer à l'étape suivante
	match state_needed:
		"base":
			if ingredient_collected:
				print("L'ingrédient est déjà récupéré.")
				return  # L'agent ne doit pas essayer de récupérer l'ingrédient deux fois.
			
			print("Recherche de l'ingrédient :", ingredient_needed)
			node = _WorldState.get_closest_element("ingredient_station", self)
			if node:
				set_movement_target(node)
			else:
				print("Aucun élément de base trouvé pour :", ingredient_needed)
				
		"cut":
			if not ingredient_collected:
				print("L'ingrédient n'a pas été récupéré. Impossible de couper.")
				return  # Ne pas essayer de couper si l'ingrédient n'a pas été récupéré
			print("Recherche de la station de découpe.")
			node = _WorldState.get_closest_element("cutting_station", self)
			if node:
				set_movement_target(node)
			else:
				print("Aucune station de découpe trouvée.")
				
		"cooked":
			if not ingredient_collected:
				print("L'ingrédient n'a pas été récupéré. Impossible de cuire.")
				node = _WorldState.get_closest_element("ingredient_station", self)
				if node == null:
					print("Aucun élément trouvé dans le groupe 'ingredient_station' au moment de l'appel.")
					return
				set_movement_target(node)
				return
				  # Ne pas essayer de cuire si l'ingrédient n'a pas été récupéré
			print("Recherche de la station de cuisson.")
			node = _WorldState.get_closest_element("cooking_station", self)
			if node:
				set_movement_target(node)
			else:
				print("Aucune station de cuisson trouvée.")

	current_step_index += 1
	print("Étape suivante : ", current_step_index)
