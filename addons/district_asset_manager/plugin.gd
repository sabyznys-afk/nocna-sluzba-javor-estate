@tool
extends EditorPlugin

const MANAGER_SCENE := preload("res://tools/asset_browser/AssetManager.tscn")

var _panel: Control = null


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_panel = MANAGER_SCENE.instantiate()
		add_control_to_bottom_panel(_panel, "District Assets")


func _exit_tree() -> void:
	if _panel and is_instance_valid(_panel):
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
