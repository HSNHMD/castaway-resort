# Main.gd
# Game loop + coordinator. Attach to the root Node3D of Main.tscn.
# Owns the Simulation, ticks it on a Timer, and exposes the only API the rest of the
# game touches. Scenes (HUD, Placement, etc.) connect to these signals and call these
# methods — they never touch Simulation directly, and never hold game logic themselves.

class_name Game
extends Node3D

signal state_changed                       # fire after anything changes; HUD repaints
signal reviews_posted(reviews: Array)      # new guest reviews this tick
signal toast_shown(text: String)           # milestone / event banners

const SAVE_PATH := "user://save.json"
@export var autosave_every_ticks := 10

enum Difficulty { EASY = 0, NORMAL = 1, HARD = 2 }

var sim: Simulation = Simulation.new()
var _ticks_since_save := 0
var difficulty: int = Difficulty.NORMAL

func _ready() -> void:
	sim = _load_or_new()
	var timer := Timer.new()
	timer.wait_time = Simulation.TICK_SECONDS
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)
	state_changed.emit()

func _on_tick() -> void:
	var res := sim.tick()
	if (res["reviews"] as Array).size() > 0:
		reviews_posted.emit(res["reviews"])
	for m in res["toasts"]:
		toast_shown.emit(m)
	_ticks_since_save += 1
	if _ticks_since_save >= autosave_every_ticks:
		save()
		_ticks_since_save = 0
	state_changed.emit()

# ----------------------------- player actions (called by UI / placement) -----------------------------
func forage() -> Dictionary:
	var r := sim.forage()
	state_changed.emit()
	return r

func try_place(key: String, x: float, z: float, meta := {}) -> Dictionary:
	var res := sim.place(key, x, z, meta)
	if res["ok"]:
		state_changed.emit()
	return res   # caller inspects res.ok / res.reason / res.placed to spawn the model

func hire() -> bool:
	var ok := sim.hire()
	state_changed.emit()
	return ok

func fire() -> bool:
	var ok := sim.fire()
	state_changed.emit()
	return ok

func reclaim() -> bool:
	var ok := sim.reclaim()
	if ok:
		state_changed.emit()
	return ok

func repair_storm() -> bool:
	var ok := sim.repair_storm()
	if ok:
		state_changed.emit()
	return ok

# ----------------------------- persistence -----------------------------
func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(sim.serialize())
		f.close()

func _load_or_new() -> Simulation:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			return Simulation.load_from(txt)
	return Simulation.new()

func restart_to_tutorial() -> void:
	var d := DirAccess.open("user://")
	if d:
		if d.file_exists("save.json"):
			d.remove("save.json")
		if d.file_exists("tutorial_done"):
			d.remove("tutorial_done")
	get_tree().reload_current_scene()

func _delete_save() -> void:
	var d := DirAccess.open("user://")
	if d and d.file_exists("save.json"):
		d.remove("save.json")

func reset_game() -> void:
	sim = Simulation.new()
	_delete_save()
	state_changed.emit()

func set_difficulty(d: int) -> void:
	difficulty = clampi(d, 0, 2)

func new_game(diff: int) -> void:
	set_difficulty(diff)
	sim = Simulation.new()
	sim.money = ([300.0, 150.0, 80.0] as Array)[difficulty]
	_delete_save()
	state_changed.emit()
