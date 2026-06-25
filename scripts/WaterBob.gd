extends MeshInstance3D

@export var amplitude: float = 0.06
@export var period: float = 2.2

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	position.y = sin(_t * TAU / period) * amplitude
