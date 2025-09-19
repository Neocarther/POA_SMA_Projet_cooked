extends Node

@export var is_raw: bool = false #food that is raw can be cooked
@export var is_cut: bool = false #every food needs to be cut
@export var is_plated: bool = false

func is_cuttable() -> bool:
	return not is_cut

func is_cookable() -> bool:
	return is_cut and is_raw

func is_platable() -> bool:
	return is_cut and not is_raw and not is_plated
