class_name Interactable
extends Area3D

signal interacted(interactable: Interactable)

@export var interact_id: String = ""
@export var interact_type: String = "generic"
@export var prompt_text: String = "[E] INSPECT"
@export var anomaly_id: String = ""
@export var extra_data: Dictionary = {}


func _ready() -> void:
	# Dedicated interaction collision layer (Layer 2) so solid walls/door bodies (Layer 1)
	# never block targeting from either side, while wall-occlusion checks prevent interacting through walls.
	collision_layer = 2
	collision_mask = 0


func get_prompt() -> String:
	return prompt_text


func trigger_interact() -> void:
	emit_signal("interacted", self)
