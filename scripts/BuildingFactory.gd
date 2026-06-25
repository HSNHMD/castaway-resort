class_name BuildingFactory
extends RefCounted

const _ACCOM := ["hut", "bung", "villa"]

static func build(key: String) -> Node3D:
	var path := "res://scenes/buildings/%s.tscn" % key
	if ResourceLoader.exists(path):
		return (load(path) as PackedScene).instantiate() as Node3D
	return _make_placeholder(key)

static func _make_placeholder(key: String) -> Node3D:
	var root := Node3D.new()
	root.name = key.capitalize()

	var h := _height_for(key)

	var body := MeshInstance3D.new()
	var box  := BoxMesh.new()
	box.size = Vector3(1.0, h, 1.0)
	var mat  := StandardMaterial3D.new()
	mat.albedo_color = _color_for(key)
	body.mesh = box
	body.set_surface_override_material(0, mat)
	body.position.y = h * 0.5
	root.add_child(body)

	if key in _ACCOM:
		var roof := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius    = 0.0
		cone.bottom_radius = 0.65
		cone.height        = 0.5
		cone.radial_segments = 6
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.5, 0.3, 0.1, 1)
		roof.mesh = cone
		roof.set_surface_override_material(0, rmat)
		roof.position.y = h + 0.25
		root.add_child(roof)

	return root

static func _height_for(key: String) -> float:
	match key:
		"hut":    return 1.5
		"bung":   return 2.0
		"villa":  return 2.5
		"rest":   return 2.0
		"gen":    return 1.5
		"desal":  return 1.5
		"jetty":  return 0.5
		"solar":  return 0.5
		"runway": return 0.3
		_:        return 1.0

static func _color_for(key: String) -> Color:
	match key:
		"hut":    return Color(0.93, 0.76, 0.42, 1)
		"bung":   return Color(0.95, 0.87, 0.67, 1)
		"villa":  return Color(0.55, 0.72, 0.85, 1)
		"rest":   return Color(0.95, 0.55, 0.45, 1)
		"gen":    return Color(0.55, 0.55, 0.55, 1)
		"desal":  return Color(0.35, 0.78, 0.85, 1)
		"jetty":  return Color(0.55, 0.38, 0.22, 1)
		"solar":  return Color(0.18, 0.29, 0.55, 1)
		"runway": return Color(0.65, 0.65, 0.62, 1)
		_:        return Color(0.8, 0.8, 0.8, 1)
