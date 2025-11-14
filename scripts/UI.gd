extends CanvasLayer

@onready var timer_label = $TimerLabel
@onready var score_label = $ScoreLabel
@onready var end_screen = $EndScreen
@onready var end_message = $EndScreen/EndMessage
@onready var restart_button = $EndScreen/RestartButton
@onready var order_container: VBoxContainer = $OrderContainer

var game_time = 180.0  # en secondes (3 min)
var score = 0
var order_labels = {}

func _ready():
	timer_label.text = format_time(game_time)
	score_label.text = "Score : 0000"
	end_screen.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	var main = get_tree().get_root().get_node("Main")
	if main:
		main.connect("score_updated",_on_score_updated)
		main.connect("order_added", _on_order_added)
		main.connect("order_completed", _on_order_completed)
	else:
		push_warning("Main node not found — signals not connected")

	set_process(true)

func _process(delta):
	game_time -= delta
	if game_time <= 0:
		game_time = 0
		_on_game_over()
		set_process(false)
	timer_label.text = format_time(game_time)
	for label in order_labels.keys():
		_update_order_timer(label, order_labels[label])

func format_time(seconds: float) -> String:
	@warning_ignore("integer_division")
	var minutes = int(seconds) / 60
	var sec = int(seconds) % 60
	return "%02d:%02d" % [minutes, sec]

func _on_score_updated(score_diff: int) -> void:
	score += score_diff
	score_label.text = ""
	print(score_label.text)
	if score < 0:
		score_label.text = "Score : %05d" % score
	else:
		score_label.text = "Score : %04d" % score

func _on_order_added(order: Order) -> void:
	var new_order_label: Label = Label.new()
	new_order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	order_container.add_child(new_order_label)
	order_labels[new_order_label] = order

func _update_order_timer(order_label: Label, order: Order) -> void:
	order_label.text = order.recipe_name + " %ds" % order.timer.time_left
	if order.timer.time_left == 0:
		order_labels.erase(order_label)
		order_label.queue_free()

func _on_order_completed(order: Order) -> void:
	for order_label in order_labels.keys():
		if order_labels[order_label].id == order.id:
			order_labels.erase(order_label)
			order_label.queue_free()
			return

# -------- Fin de partie --------
func _on_game_over():
	end_screen.visible = true
	end_message.text = "Fin de la partie !\nScore final : %d" % score

func _on_restart_pressed():
	get_tree().reload_current_scene()
