class_name LoadingScreen
extends CanvasLayer

const BUILDINGS := [
	"res://scenes/buildings/hut.tscn",
	"res://scenes/buildings/bung.tscn",
	"res://scenes/buildings/villa.tscn",
	"res://scenes/buildings/jetty.tscn",
	"res://scenes/buildings/rest.tscn",
	"res://scenes/buildings/gen.tscn",
	"res://scenes/buildings/solar.tscn",
	"res://scenes/buildings/desal.tscn",
	"res://scenes/buildings/runway.tscn",
]

@onready var _label: Label       = $Root/Center/StatusLabel
@onready var _bar:   ProgressBar = $Root/Center/Bar

func _ready() -> void:
	_bar.max_value = BUILDINGS.size()
	_bar.value     = 0
	for i in range(BUILDINGS.size()):
		_label.text = "Loading %d / %d..." % [i + 1, BUILDINGS.size()]
		ResourceLoader.load(BUILDINGS[i])
		_bar.value = i + 1
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
