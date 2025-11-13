extends Resource

class_name Order

signal order_expired(order)

var id: int
var recipe_name: StringName
var timer: Timer

@warning_ignore("shadowed_variable")
func _init(id: int, recipe_name: StringName, deadline: float, parent_node: Node):
	self.id = id
	self.recipe_name = recipe_name
	
	timer = Timer.new()
	timer.wait_time = deadline
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)
	parent_node.add_child(timer)
	timer.start()

func _on_timer_timeout():
	emit_signal("order_expired", self)
	
