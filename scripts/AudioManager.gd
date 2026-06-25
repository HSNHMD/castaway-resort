class_name AudioManager
extends Node

@onready var _ambient: AudioStreamPlayer = $AmbientPlayer
@onready var _sfx:     AudioStreamPlayer = $SFXPlayer

func _ready() -> void:
	if _ambient.stream != null:
		_ambient.play()

func _play_sfx() -> void:
	if _sfx.stream != null:
		_sfx.play()

func play_place()  -> void: _play_sfx()
func play_forage() -> void: _play_sfx()
func play_ui()     -> void: _play_sfx()
