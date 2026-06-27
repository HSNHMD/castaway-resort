class_name CameraRig
extends Node3D

const ORBIT_SPEED  := 0.3
const ZOOM_STEP    := 2.0
const PINCH_SPEED  := 0.05
const PAN_SPEED    := 0.0015
const PAN_LIMIT    := 14.0
const PITCH_MIN    := -80.0
const PITCH_MAX    := -10.0
const ZOOM_MIN     := 6.0
const ZOOM_MAX     := 35.0

var _yaw            := 0.0
var _pitch          := -50.0
var _zoom_distance  := 14.0
var _dragging       := false   # desktop left-mouse held

# two-finger state
var _touches: Dictionary = {}  # finger index -> Vector2
var _num_touches      := 0     # authoritative press count (avoids ScreenDrag race condition)
var _prev_pinch_dist  := 0.0
var _prev_pan_center  := Vector2.ZERO

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _camera: Camera3D   = $PitchPivot/Camera3D
@onready var _btn_in:  Button    = $ZoomButtons/VBox/ZoomIn
@onready var _btn_out: Button    = $ZoomButtons/VBox/ZoomOut

func _ready() -> void:
	_btn_in.pressed.connect(_on_zoom_in)
	_btn_out.pressed.connect(_on_zoom_out)
	_apply_camera()

func _unhandled_input(event: InputEvent) -> void:
	# ── touch ─────────────────────────────────────────────
	if event is InputEventScreenTouch:
		if event.pressed:
			_num_touches += 1
			_touches[event.index] = event.position
			if _num_touches == 2:
				_prev_pinch_dist = 0.0   # fresh start for each new pinch gesture
		else:
			_num_touches = max(0, _num_touches - 1)
			_touches.erase(event.index)
			_prev_pinch_dist = 0.0
		return

	if event is InputEventScreenDrag:
		_touches[event.index] = event.position

		if _num_touches <= 1 and not _dragging:
			_orbit(event.relative)

		elif _num_touches >= 2:
			var vals: Array = _touches.values()
			var pa: Vector2 = vals[0]
			var pb: Vector2 = vals[1]
			var dist  := pa.distance_to(pb)
			var center := (pa + pb) * 0.5

			if _prev_pinch_dist > 0.0:
				_zoom_by((dist - _prev_pinch_dist) * PINCH_SPEED)
				_pan_screen(center - _prev_pan_center)

			_prev_pinch_dist = dist
			_prev_pan_center = center
		return

	# ── mouse ─────────────────────────────────────────────
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: _zoom_by(ZOOM_STEP)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: _zoom_by(-ZOOM_STEP)
		return

	if event is InputEventMouseMotion and _dragging:
		_orbit(event.relative)

# ── helpers ───────────────────────────────────────────────

func _orbit(delta: Vector2) -> void:
	_yaw   -= delta.x * ORBIT_SPEED
	_pitch  = clampf(_pitch - delta.y * ORBIT_SPEED, PITCH_MIN, PITCH_MAX)
	_apply_camera()

func _zoom_by(amount: float) -> void:
	_zoom_distance = clampf(_zoom_distance - amount, ZOOM_MIN, ZOOM_MAX)
	_apply_camera()

func _pan_screen(screen_delta: Vector2) -> void:
	var scale := _zoom_distance * PAN_SPEED
	var right := transform.basis.x
	var fwd   := Vector3(transform.basis.z.x, 0.0, transform.basis.z.z).normalized()
	position -= right * screen_delta.x * scale
	position += fwd   * screen_delta.y * scale
	position.y = 0.0
	position.x = clampf(position.x, -PAN_LIMIT, PAN_LIMIT)
	position.z = clampf(position.z, -PAN_LIMIT, PAN_LIMIT)

func _apply_camera() -> void:
	rotation_degrees.y          = _yaw
	_pitch_pivot.rotation_degrees.x = _pitch
	_camera.position.z          = _zoom_distance

func _on_zoom_in()  -> void: _zoom_by(ZOOM_STEP)
func _on_zoom_out() -> void: _zoom_by(-ZOOM_STEP)
