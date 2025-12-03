extends Node
class_name WorldState

var _order_list: Array[Order]

var blackboards: Array[BlackBoard]
var nb_free_counters: int = 0

## Get closest element in group_name from reference in the world space
## Search can be more specific by giving the content, an elements from group_name
## should contain.
## content can either be a String, StringName, an item with a name property or an
## int if the element searched for has an id
func get_closest_element(group_name: StringName, reference: Node, content = null) -> Vector2i:
	var elements = _get_elements(group_name)
	var closest_element = reference
	var closest_distance = INF
	for element in elements:
		if content != null and element is Station:
			var station_content = element.current_item
			if station_content == null:
				continue
			if content is String or content is StringName:
				if content != station_content.get_item_name():
					continue
			elif content is Item and content.get_item_name() != station_content.get_item_name():
				continue
		elif content == null and element is Station and element.current_item != null:
			continue
		elif content != null and element is Agent:
			if element.get_agent_id() != content:
				continue

		var distance = reference.global_position.distance_to(element.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_element = element
	return closest_element.global_position

## Called by agent to get a recipe to work on
func get_recipe():
	var selected_order
	var biggest_ingredient_per_second_ratio = 0
	if _order_list.size() == 0 and blackboards.size() == 0:
		return ""
	if _order_list.size() != 0:
		for order in _order_list:
			if _RecipeManager.get_recipe_size(order.recipe_name) > nb_free_counters + 1:
				continue
			var ingredient_per_second_ratio = order.timer.time_left / _RecipeManager.get_recipe_size(order.recipe_name)
			if ingredient_per_second_ratio > biggest_ingredient_per_second_ratio:
				biggest_ingredient_per_second_ratio = ingredient_per_second_ratio
				selected_order = order
	if blackboards.size() != 0:
		for blackboard in blackboards:
			var ingredient_per_second_ratio = blackboard.number_of_ingredients_left() / (blackboard.get_time_left() * blackboard.nb_of_agents_on_task)
			if ingredient_per_second_ratio > biggest_ingredient_per_second_ratio:
				biggest_ingredient_per_second_ratio = ingredient_per_second_ratio
				selected_order = blackboard
	if selected_order is Order:
		var new_blackboard = BlackBoard.new(selected_order)
		_order_list.erase(selected_order)
		blackboards.append(new_blackboard)
		return new_blackboard
	elif selected_order is BlackBoard:
		selected_order.nb_of_agents_on_task += 1
		return selected_order
	else:
		return ""

## Called by main when new recipe is generated
func add_order(order: Order) -> void:
	_order_list.append(order)

func remove_blackboard(blackboard: BlackBoard) -> void:
	blackboards.erase(blackboard)

func item_added_on_counter() -> void:
	nb_free_counters -= 1

func item_taken_from_counter() -> void:
	nb_free_counters += 1

func _get_elements(group_name: StringName) -> Array[Node]:
	return self.get_tree().get_nodes_in_group(group_name)
