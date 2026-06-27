class_name AudioManager
extends Node

@onready var _ambient: AudioStreamPlayer = $AmbientPlayer
@onready var _sfx:     AudioStreamPlayer = $SFXPlayer

var _forage_stream: AudioStreamWAV
var _place_stream:  AudioStreamWAV
var _ui_stream:     AudioStreamWAV

func _ready() -> void:
	var amb := load("res://assets/audio/ambient_ocean.wav") as AudioStreamWAV
	amb.loop_mode  = AudioStreamWAV.LOOP_FORWARD
	_ambient.stream    = amb
	_ambient.volume_db = -10.0
	_ambient.play()

	_forage_stream = load("res://assets/audio/sfx_forage.wav")
	_place_stream  = load("res://assets/audio/sfx_place.wav")
	_ui_stream     = load("res://assets/audio/sfx_ui.wav")

func play_forage() -> void:
	_sfx.stream    = _forage_stream
	_sfx.volume_db = -4.0
	_sfx.play()

func play_place() -> void:
	_sfx.stream    = _place_stream
	_sfx.volume_db = -2.0
	_sfx.play()

func play_ui() -> void:
	_sfx.stream    = _ui_stream
	_sfx.volume_db = -6.0
	_sfx.play()
