class_name PlayerEquipmentManager
extends Node

signal slot_changed(new_slot: String)
signal state_changed(new_state: String)
signal action_started(action_name: String)

const VALID_SLOTS := ["hands", "flashlight", "keys", "radio", "notebook", "watch", "taser"]
const HOTBAR_ORDER := ["hands", "flashlight", "keys", "radio", "notebook", "taser", "watch"]

var current_slot: String = "flashlight"
var equipment_state: String = "FLASHLIGHT_HELD_ON"
var busy_timer: float = 0.0
var scroll_cooldown: float = 0.0
var active_action: String = ""
var flashlight_powered_on: bool = true


func _process(delta: float) -> void:
	if busy_timer > 0.0:
		busy_timer = maxf(0.0, busy_timer - delta)
		if busy_timer <= 0.0:
			active_action = ""
	if scroll_cooldown > 0.0:
		scroll_cooldown = maxf(0.0, scroll_cooldown - delta)


func is_busy() -> bool:
	return busy_timer > 0.0


func can_start_action() -> bool:
	return busy_timer <= 0.0


func get_equipment_state() -> String:
	return equipment_state


func sync_flashlight_state(is_on: bool) -> void:
	flashlight_powered_on = is_on
	_refresh_state()


func _refresh_state() -> void:
	var prev: String = equipment_state
	match current_slot:
		"hands":
			equipment_state = "EMPTY_HANDS"
		"flashlight":
			equipment_state = "FLASHLIGHT_HELD_ON" if flashlight_powered_on else "FLASHLIGHT_HELD_OFF"
		"keys":
			equipment_state = "KEYS_HELD"
		"radio":
			equipment_state = "RADIO_HELD"
		"notebook":
			equipment_state = "NOTEBOOK_HELD"
		"watch":
			equipment_state = "WATCH_HELD"
		"taser":
			equipment_state = "TASER_HELD"
		_:
			equipment_state = "EMPTY_HANDS"
	if equipment_state != prev:
		emit_signal("state_changed", equipment_state)


func begin_action(action_name: String, duration: float) -> bool:
	active_action = action_name
	busy_timer = maxf(0.05, duration)
	emit_signal("action_started", action_name)
	return true


func equip_slot(slot: String) -> bool:
	if not (slot in VALID_SLOTS):
		return false
	if current_slot == slot:
		_refresh_state()
		return false
	current_slot = slot
	GameState.equipped_slot = slot
	_refresh_state()
	begin_action("equip_" + slot, 0.24)
	emit_signal("slot_changed", slot)
	return true


func cycle_slot(direction: int, ignore_cooldown: bool = false) -> String:
	if not ignore_cooldown and scroll_cooldown > 0.0:
		return current_slot
	var idx: int = HOTBAR_ORDER.find(current_slot)
	if idx < 0:
		idx = 0
	var step: int = 1 if direction >= 0 else -1
	var next_idx: int = (idx + step + HOTBAR_ORDER.size()) % HOTBAR_ORDER.size()
	var next_slot: String = str(HOTBAR_ORDER[next_idx])
	scroll_cooldown = 0.09
	equip_slot(next_slot)
	return next_slot
