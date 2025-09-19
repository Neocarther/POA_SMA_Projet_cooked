extends Node2D

enum station_state {
	IN_USE,
	IDLE,
	COOKING,
}

var current_ingredient = null
