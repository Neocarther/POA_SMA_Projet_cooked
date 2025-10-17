extends Node
class_name WorldState

var _task_list: Dictionary

## Does not work
## Implementation has changed but won't be updated for deadline 1 because of lack of time
func get_closest_element(group_name, reference: Node, content = null) -> Vector2i:
	var elements = _get_elements(group_name)
	var closest_element
	var closest_distance = INF
	if content != null:
		for element in elements:
			if element is Station:
				var e = element.get_item()
				if e is Ingredient and e.data.name == content[0] and e.state == content[1]:
					var distance = reference.global_position.distance_to(element.global_position)
					if distance < closest_distance:
						closest_distance = distance
						closest_element = element
				elif e is PlatedMeal:
					var nb_ingredients = e.ingredients.size()
					for i in range(nb_ingredients):
						if e.ingredients[i].data.name == content[i*2] and e.ingredients[i].state == content[(i*2)+1]:
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
