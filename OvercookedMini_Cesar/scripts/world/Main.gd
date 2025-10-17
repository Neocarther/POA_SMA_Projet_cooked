extends Node2D

@onready var agent: Agent = $Agent
@onready var crate: CrateTomato = $CrateTomate
@onready var board: CuttingBoard = $CuttingBoard
@onready var dropc: DropCounter = $DropCounter
@onready var ui_state: Label = $UI/StateLabel
@onready var btn_restart: Button = $UI/RestartButton
@onready var navreg: NavigationRegion2D = $NavigationRegion2D

var objectives: int = 1 # nombre de tomates à déposer pour le test auto
var _since_change: float = 0.0

func _ready() -> void:
	# Positionne une petite "cuisine" ouverte
	#$CrateTomate.position = Vector2(-192, 0)
	#$CuttingBoard.position = Vector2(0, 0)
	#$DropCounter.position = Vector2(192, 0)
	#$Agent.position = Vector2(-256, -128)

	# Références
	agent.crate = crate
	agent.board = board
	agent.drop_counter = dropc

	# UI
	btn_restart.pressed.connect(_on_restart)
	_update_ui()

	# Écoute des changements d'état (évite la lambda qui ne peut pas réassigner)
	agent.fsm.state_changed.connect(_on_fsm_state_changed)

	# Tests auto
	call_deferred("_run_basic_tests")

func _process(_delta: float) -> void:
	ui_state.text = "Objectifs restants: %d | Score: %d | Agent: %s" % [objectives, dropc.score, agent.fsm.current()]
	_since_change += _delta

func _on_restart() -> void:
	get_tree().reload_current_scene()

func _update_ui() -> void:
	ui_state.text = "Objectifs restants: %d | Score: %d" % [objectives, dropc.score]

func _on_fsm_state_changed(_from: String, _to: String) -> void:
	_since_change = 0.0

# --- Tests automatiques minimalistes ---
func _run_basic_tests() -> void:
	var start_time := Time.get_ticks_msec()
	var ok := await _wait_until_score_at_least(1, 30.0)
	var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
	if ok:
		print("[TEST] 1 tomate déposée en ", elapsed, " s (<= 30s) : OK")
	else:
		push_error("[TEST] Échec: aucun dépôt en 30 s")

	# Test blocage (état ne reste pas > 5s)
	var t := 0.0
	while t < 6.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	if _since_change <= 5.0:
		print("[TEST] Pas de blocage d'état (>5s) : OK")
	else:
		push_error("[TEST] Blocage possible : état '%s' depuis %.2fs" % [agent.fsm.current(), _since_change])

func _wait_until_score_at_least(target_score: int, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if dropc.score >= target_score:
			return true
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	return false
