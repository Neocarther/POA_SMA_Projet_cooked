extends Node
class_name WorldState

var _task_list: Dictionary
var _stations: Dictionary

func register_station(station: Node) -> void:
	_stations[station.get_instance_id()] = station

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

func get_recipe() -> StringName:
	if _task_list.size() != 0:
		var recipe = _task_list.keys()[0]
		_task_list.erase(recipe)
		return recipe
	else:
		return ""

func add_task(recipe: StringName, time: float) -> void:
	_task_list[recipe] = time

func _get_elements(group_name: StringName) -> Array[Node]:
	return self.get_tree().get_nodes_in_group(group_name)
