class_name Placement
extends Node3D

const ISLAND_RADIUS := 8.0
const BEACH_OUTER   := 11.5
const TAP_THRESHOLD := 8.0

@export var selected_key: String = ""

@onready var _game:      Game         = get_parent() as Game
@onready var _buildings: Node3D       = $"../Buildings"
@onready var _audio:     Node         = get_node_or_null("../AudioManager")

var _touch_start:  Vector2 = Vector2.ZERO
var _touch_moved:  float   = 0.0

var _mouse_held:   bool    = false
var _mouse_start:  Vector2 = Vector2.ZERO
var _mouse_moved:  float   = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start  = event.position
			_touch_moved  = 0.0
		else:
			if _touch_moved < TAP_THRESHOLD:
				_on_tap(_touch_start)
		return

	if event is InputEventScreenDrag:
		_touch_moved += event.relative.length()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_held  = true
			_mouse_start = event.position
			_mouse_moved = 0.0
		else:
			if _mouse_held and _mouse_moved < TAP_THRESHOLD:
				_on_tap(_mouse_start)
			_mouse_held = false
		return

	if event is InputEventMouseMotion and _mouse_held:
		_mouse_moved += event.relative.length()

func _on_tap(screen_pos: Vector2) -> void:
	if selected_key.is_empty():
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var origin := cam.project_ray_origin(screen_pos)
	var dir    := cam.project_ray_normal(screen_pos)

	var plane  := Plane(Vector3.UP, 0.0)
	var hit: Variant = plane.intersects_ray(origin, dir)
	if hit == null:
		return

	var hit_pos: Vector3 = hit
	var dist := Vector2(hit_pos.x, hit_pos.z).length()

	var island_r := ISLAND_RADIUS + _game.sim.reclaimed * 0.8
	var beach_r  := BEACH_OUTER   + _game.sim.reclaimed * 0.8
	var meta := {
		"on_beach":   dist > island_r,
		"over_water": dist > beach_r,
	}

	var result: Dictionary = _game.try_place(selected_key, hit_pos.x, hit_pos.z, meta)
	if not result.get("ok", false):
		return

	var node: Node3D = BuildingFactory.build(selected_key)
	node.position = Vector3(hit_pos.x, 0.0, hit_pos.z)
	node.scale    = Vector3.ZERO
	_buildings.add_child(node)

	if _audio != null:
		_audio.call(&"play_place")

	var tween := create_tween()
	tween.tween_property(node, "scale", Vector3.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
