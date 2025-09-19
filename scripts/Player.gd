# player_2d.gd
extends CharacterBody2D

@export var max_speed := 180.0      # vitesse en px/s
@export var accel := 1200.0         # accélération
@export var friction := 1400.0      # freinage quand pas d'input

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	input.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	input.y = (Input.get_action_strength("move_down")  - Input.get_action_strength("move_up"))

	if input.length() > 0.0:
		input = input.normalized()
		var target := input * max_speed
		velocity = velocity.move_toward(target, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
