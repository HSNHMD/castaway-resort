class_name HUD
extends CanvasLayer

const MAX_REVIEWS  := 20
const TOAST_SECS   := 4.0

@onready var _leaf_lbl:    Label        = $Root/TopBar/LeafLabel
@onready var _wood_lbl:    Label        = $Root/TopBar/WoodLabel
@onready var _money_lbl:   Label        = $Root/TopBar/MoneyLabel
@onready var _day_lbl:     Label        = $Root/TopBar/DayLabel
@onready var _rating_lbl:  Label        = $Root/TopBar/RatingLabel
@onready var _net_lbl:     Label        = $Root/TopBar/NetLabel
@onready var _staff_bar:   ProgressBar  = $Root/Gauges/StaffGauge
@onready var _power_bar:   ProgressBar  = $Root/Gauges/PowerGauge
@onready var _water_bar:   ProgressBar  = $Root/Gauges/WaterGauge
@onready var _review_list: VBoxContainer = $Root/ReviewFeed/ReviewList
@onready var _toast_lbl:   Label        = $Root/ToastLabel

var _game:      Game
var _placement: Placement
var _toast_t:   float = 0.0

func _ready() -> void:
	_game      = get_parent() as Game
	_placement = get_node("../Placement") as Placement

	_game.state_changed.connect(_on_state_changed)
	_game.reviews_posted.connect(_on_reviews_posted)
	_game.toast_shown.connect(_on_toast_shown)

	_connect_dock()
	_toast_lbl.visible = false
	_on_state_changed()

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast_lbl.visible = false

func _on_state_changed() -> void:
	var s := _game.sim
	_leaf_lbl.text   = "🌿 %d"    % s.leaf
	_wood_lbl.text   = "🪵 %d"    % s.wood
	_money_lbl.text  = "💰 %.0f"  % s.money
	_day_lbl.text    = "Day %d"   % s.day
	_rating_lbl.text = "⭐ %.1f"  % s.rating

	var net := s.last_net
	_net_lbl.text     = "%+.0f/day" % net
	_net_lbl.modulate = Color.GREEN if net >= 0.0 else Color.RED

	var c := s.caps()
	_update_gauge(_staff_bar, c["staff_load"],  c["staff_cap"])
	_update_gauge(_power_bar, c["power_load"],  c["power_cap"])
	_update_gauge(_water_bar, c["water_load"],  c["water_cap"])

func _update_gauge(bar: ProgressBar, load: int, cap: int) -> void:
	bar.max_value = max(cap, max(load, 1))
	bar.value     = load
	bar.modulate  = Color.RED if load > cap else Color.WHITE

func _on_reviews_posted(reviews: Array) -> void:
	for r in reviews:
		var kind: String = r.get("kind", "")
		var prefix := "👍" if kind == "good" else ("📢" if kind == "evt" else "👎")
		var lbl := Label.new()
		lbl.text          = "%s %s: %s" % [prefix, r.get("name", ""), r.get("msg", "")]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_review_list.add_child(lbl)

	while _review_list.get_child_count() > MAX_REVIEWS:
		_review_list.get_child(0).queue_free()

	await get_tree().process_frame
	var scroll := _review_list.get_parent() as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _on_toast_shown(text: String) -> void:
	_toast_lbl.text    = text
	_toast_lbl.visible = true
	_toast_t           = TOAST_SECS

func _connect_dock() -> void:
	$Root/BuildDock/ForageBtn.pressed.connect(func(): _game.forage())

	var keys := ["hut",  "bung",  "villa",  "jetty",  "rest",  "gen",  "solar",  "desal"]
	var btns := ["HutBtn","BungBtn","VillaBtn","JettyBtn","RestBtn","GenBtn","SolarBtn","DesalBtn"]
	for i in range(keys.size()):
		var k := keys[i]
		$Root/BuildDock.get_node(btns[i]).pressed.connect(func(): _placement.selected_key = k)
