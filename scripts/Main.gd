extends Node2D

@onready var time_label = $UI/HUD/TimeLabel
@onready var score_label = $UI/HUD/ScoreLabel
@onready var orders_list = $UI/HUD/OrdersPanel/VBoxContainer/OrdersList

var game_time = 120.0  # 2 minutes
var score = 0
var orders = []

# Order types with ingredients needed
var order_recipes = {
	"Tomato Salad": ["tomato_cut", "lettuce_cut"],
	"Cooked Tomato": ["tomato_cooked"],
	"Simple Salad": ["lettuce_cut", "lettuce_cut"],
	"Mixed Salad": ["tomato_cut", "lettuce_cut", "lettuce_cut"]
}

func _ready():
	# Add to main group for easy finding
	add_to_group("main")
	
	# Start the game timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_timer)
	add_child(timer)
	timer.start()
	
	# Generate initial orders
	_generate_order()
	_generate_order()

func _update_timer():
	game_time -= 1.0
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	if game_time <= 0:
		_game_over()
	
	# Randomly generate new orders
	if randf() < 0.3:  # 30% chance each second
		_generate_order()

func _generate_order():
	if orders.size() < 5:  # Max 5 orders at once
		var recipe_names = order_recipes.keys()
		var order_name = recipe_names[randi() % recipe_names.size()]
		var order = {
			"name": order_name,
			"ingredients": order_recipes[order_name].duplicate(),
			"time_left": 30.0
		}
		orders.append(order)
		_update_orders_display()

func _update_orders_display():
	# Clear existing order labels
	for child in orders_list.get_children():
		child.queue_free()
	
	# Add new order labels
	for order in orders:
		var label = Label.new()
		label.text = "%s (%ds)" % [order.name, int(order.time_left)]
		orders_list.add_child(label)

func fulfill_order(ingredients: Array):
	for i in range(orders.size()):
		var order = orders[i]
		if _ingredients_match(ingredients, order.ingredients):
			orders.remove_at(i)
			score += 100
			score_label.text = "Score: %d" % score
			_update_orders_display()
			print("Order fulfilled: ", order.name)
			return true
	return false

func _ingredients_match(provided: Array, required: Array) -> bool:
	if provided.size() != required.size():
		return false
	
	var required_copy = required.duplicate()
	for ingredient in provided:
		var index = required_copy.find(ingredient)
		if index == -1:
			return false
		required_copy.remove_at(index)
	
	return required_copy.is_empty()

func _game_over():
	print("Game Over! Final Score: ", score)
	get_tree().paused = true
	# Here you could show a game over screen