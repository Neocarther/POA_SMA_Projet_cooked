extends CanvasLayer

@onready var timer_label = $TimerLabel
@onready var score_label = $ScoreLabel
@onready var progress_bar = $ActionProgressBar
@onready var end_screen = $EndScreen
@onready var end_message = $EndScreen/EndMessage
@onready var restart_button = $EndScreen/RestartButton

var game_time = 180.0  # en secondes (3 min)
var score = 0

func _ready():
	timer_label.text = format_time(game_time)
	score_label.text = "Score : 0"
	progress_bar.visible = false
	end_screen.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	set_process(true)

func _process(delta):
	game_time -= delta
	if game_time <= 0:
		game_time = 0
		_on_game_over()
		set_process(false)
	timer_label.text = format_time(game_time)

func format_time(seconds: float) -> String:
	var minimum = int(seconds) / 60
	var sec = int(seconds) % 60
	return "%02d:%02d" % [minimum, sec]

func update_score(new_score: int):
	score = new_score
	score_label.text = "Score : %d" % score

# -------- Progress bar (découpe, cuisson, etc.) --------
var progress_active = false
var progress_duration = 0.0
var progress_elapsed = 0.0

func show_progress_bar(duration: float):
	progress_duration = duration
	progress_elapsed = 0.0
	progress_bar.visible = true
	progress_bar.max_value = duration
	progress_bar.value = 0
	progress_active = true

func update_progress(delta: float):
	if progress_active:
		progress_elapsed += delta
		progress_bar.value = progress_elapsed
		if progress_elapsed >= progress_duration:
			hide_progress_bar()

func hide_progress_bar():
	progress_active = false
	progress_bar.visible = false

# Appelle ceci depuis _process de ton jeu si une action est en cours
func update_progress_bar_if_active(delta: float):
	if progress_active:
		update_progress(delta)

# -------- Fin de partie --------
func _on_game_over():
	end_screen.visible = true
	end_message.text = "Fin de la partie !\nScore final : %d" % score

func _on_restart_pressed():
	get_tree().reload_current_scene()
