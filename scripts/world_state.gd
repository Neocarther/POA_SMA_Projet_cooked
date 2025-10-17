extends Node
class_name WorldState

var _task_list: Dictionary

func get_closest_element(group_name, reference: Node, content = null) -> Vector2i:
	var elements = _get_elements(group_name)
	var closest_element
	var closest_distance = INF
	if content != null:
		if content is Ingredient:
			for element in elements:
				if element is Station:
					var e = element.get_item()
					if e is Ingredient:
						if e.data.name == content.data.name && e.state == content.state:
							var distance = reference.global_position.distance_to(element.global_position)
							if distance < closest_distance:
								closest_distance = distance
								closest_element = element
								
		elif content is PlatedMeal:
			for element in elements:
				if element is PlatedMeal:
					var e = element.get_item()
					if e is PlatedMeal:
						if e.ingredients == content.ingredients:
							var distance = reference.global_position.distance_to(element.global_position)
							if distance < closest_distance:
								closest_distance = distance
								closest_element = element
	
	return closest_element.global_position

func get_recipe() -> StringName:
	var recipe = _task_list.keys()[0]
	_task_list.erase(recipe)
	return recipe

func add_task(recipe: StringName, time: float) -> void:
	_task_list[recipe] = time

func _get_elements(group_name):
	return self.get_tree().get_nodes_in_group(group_name)
