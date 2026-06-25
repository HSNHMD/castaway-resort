class_name TutorialOverlay
extends CanvasLayer

const STEPS := [
	"Welcome to Castaway Resort!\n\nYou washed ashore with nothing but a dream.\nTap [Forage] to gather leaves and wood.",
	"Build your first Hut!\n\nTap [Hut] in the dock, then tap the island\nto place it. Your first guest will arrive.",
	"Keep your guests happy!\n\nBuild a Generator for power, a Desalinator\nfor water, and hire Staff to stay ahead.",
]

@onready var _panel:      Control = $Root/Panel
@onready var _body_lbl:   Label   = $Root/Panel/Body
@onready var _next_btn:   Button  = $Root/Panel/NextBtn
@onready var _easy_btn:   Button  = $Root/Panel/DiffRow/EasyBtn
@onready var _norm_btn:   Button  = $Root/Panel/DiffRow/NormBtn
@onready var _hard_btn:   Button  = $Root/Panel/DiffRow/HardBtn
@onready var _diff_row:   HBoxContainer = $Root/Panel/DiffRow

var _game:        Game
var _step:        int = 0
var _chosen_diff: int = 1

func _ready() -> void:
	if FileAccess.file_exists(Game.SAVE_PATH) or FileAccess.file_exists("user://tutorial_done"):
		queue_free()
		return

	_game = get_parent() as Game

	_easy_btn.pressed.connect(func(): _set_diff(0))
	_norm_btn.pressed.connect(func(): _set_diff(1))
	_hard_btn.pressed.connect(func(): _set_diff(2))
	_next_btn.pressed.connect(_on_next)

	_show_step(0)

func _set_diff(d: int) -> void:
	_chosen_diff = d
	for btn in [_easy_btn, _norm_btn, _hard_btn]:
		(btn as Button).modulate = Color.WHITE
	match d:
		0: _easy_btn.modulate = Color.GREEN
		1: _norm_btn.modulate = Color.GREEN
		2: _hard_btn.modulate = Color.ORANGE_RED

func _show_step(s: int) -> void:
	_step = s
	_body_lbl.text = STEPS[s]
	_diff_row.visible = (s == 0)
	_next_btn.text = "Let's Go!" if s == STEPS.size() - 1 else "Next →"

func _on_next() -> void:
	if _step < STEPS.size() - 1:
		_show_step(_step + 1)
	else:
		var f := FileAccess.open("user://tutorial_done", FileAccess.WRITE)
		if f:
			f.store_string("1")
			f.close()
		_game.new_game(_chosen_diff)
		queue_free()
