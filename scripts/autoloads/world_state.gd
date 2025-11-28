extends Node
class_name WorldState

var _task_list: Dictionary[StringName, Timer]

var blackboards: Array[BlackBoard]
var blackboard_id_count: int = 0
var nb_free_counters: int = 0

## Get closest element in group_name from reference in the world space
## Search can be more specific by giving the content, an elements from group_name
## should contain.
## content can either be a String, StringName, an item with a name property or an
## int if the element searched for has an id
func get_closest_element(group_name: StringName, reference: Node, content = null) -> Vector2i:
	var elements = _get_elements(group_name)
	print(group_name)
	var closest_element = reference
	var closest_distance = INF
	for element in elements:
		if content != null and element is Station:
			var station_content = element.current_item
			if station_content == null:
				continue
			if content is String or content is StringName:
				if content != station_content.get_item_name():
					print(content + " " + station_content.get_item_name())
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
	print(closest_element.global_position)
	return closest_element.global_position

## Called by agent to get a recipe to work on
func get_recipe(agent_id: int):
	var selected_task
	var biggest_ingredient_per_second_ratio = 0
	if _task_list.size() == 0 and blackboards.size() == 0:
		return ""
	if _task_list.size() != 0:
		for recipe in _task_list.keys():
			if _RecipeManager.get_recipe_size(recipe) > nb_free_counters:
				continue
			var ingredient_per_second_ratio = _task_list[recipe].time_left / _RecipeManager.get_recipe_size(recipe)
			if ingredient_per_second_ratio > biggest_ingredient_per_second_ratio:
				biggest_ingredient_per_second_ratio = ingredient_per_second_ratio
				selected_task = recipe
	if blackboards.size() != 0:
		for blackboard in blackboards:
			var ingredient_per_second_ratio = blackboard.number_of_ingredients_left() / (blackboard.get_time_left() * blackboard.nb_of_agents_on_task)
			if ingredient_per_second_ratio > biggest_ingredient_per_second_ratio:
				biggest_ingredient_per_second_ratio = ingredient_per_second_ratio
				selected_task = blackboard
	if selected_task is StringName:
		var new_blackboard = BlackBoard.new(selected_task, _task_list[selected_task], agent_id, blackboard_id_count)
		_task_list.erase(selected_task)
		blackboard_id_count += 1
		blackboards.append(new_blackboard)
		return new_blackboard
	elif selected_task is BlackBoard:
		return selected_task
	else:
		return ""

## Called by main when new recipe is generated
func add_task(recipe: StringName, order_timer: Timer) -> void:
	_task_list[recipe] = order_timer

func item_added_on_counter() -> void:
	nb_free_counters -= 1

func item_taken_from_counter() -> void:
	nb_free_counters += 1

func _get_elements(group_name: StringName) -> Array[Node]:
	return self.get_tree().get_nodes_in_group(group_name)
