extends Node2D

signal score_updated(score_diff)
signal order_added(order)
signal order_completed(order)

var orders: Array[Order]
var order_counter: int = 0
var time_elapsed: float = 0.0
var time_between_orders: float = 10.0

func _ready() -> void:
	for child in get_children():
		if child is CharacterBody2D:
			child.order_completed.connect(_on_order_completed)
	add_random_order()

func _process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= time_between_orders:
		add_random_order()
		time_elapsed = 0.0

func add_random_order() -> void:
	var order_id = ++order_counter
	var recipe = _RecipeManager.get_random_recipe()
	var deadline = _get_random_deadline()
	
	var new_order = Order.new(order_id, recipe, deadline, self)
	orders.append(new_order)
	order_added.emit(new_order)
	_WorldState.add_order(new_order)
	new_order.order_expired.connect(_on_order_expired)

## Return a random time between 30s and 90s needed to complete the order as an integer
func _get_random_deadline() -> int:
	return 30 + _RecipeManager.rng.randi() % 30

func _on_order_expired(order: Order):
	orders.erase(order)
	score_updated.emit(-5)

func _on_order_completed(blackboard: BlackBoard) -> void:
	var recipe = blackboard.recipe
	for order in orders:
		if order.id == blackboard.id:
			orders.erase(order)
			score_updated.emit(_RecipeManager.get_recipe_points(recipe))
			order_completed.emit(order)
			return
