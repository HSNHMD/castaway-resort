class_name HUD
extends CanvasLayer

const MAX_REVIEWS  := 20
const TOAST_SECS   := 4.0
const _STAR_REQS   := {"bung": 1.5, "villa": 3.0, "runway": 3.5}
const _DIFF_LABELS := ["😊 Easy", "⚖️ Normal", "💀 Hard"]

@onready var _leaf_lbl:        Label        = $Root/TopBar/LeafLabel
@onready var _wood_lbl:        Label        = $Root/TopBar/WoodLabel
@onready var _money_lbl:       Label        = $Root/TopBar/MoneyLabel
@onready var _day_lbl:         Label        = $Root/TopBar/DayLabel
@onready var _rating_lbl:      Label        = $Root/TopBar/RatingLabel
@onready var _net_lbl:         Label        = $Root/TopBar/NetLabel
@onready var _staff_bar:       ProgressBar  = $Root/Gauges/StaffGauge
@onready var _power_bar:       ProgressBar  = $Root/Gauges/PowerGauge
@onready var _water_bar:       ProgressBar  = $Root/Gauges/WaterGauge
@onready var _review_list:     VBoxContainer = $Root/ReviewFeed/ReviewList
@onready var _toast_lbl:       Label        = $Root/ToastLabel
@onready var _blogger_lbl:     Label        = $Root/BloggerLabel
@onready var _storm_btn:       Button       = $Root/BuildDock/StormRepairBtn
@onready var _reclaim_btn:     Button       = $Root/BuildDock/ReclaimBtn
@onready var _diff_lbl:        Label        = $Root/TopBar/DifficultyLabel

var _game:              Game
var _placement:         Placement
var _toast_t:           float  = 0.0
var _prev_reclaimed:    int    = 0
var _active_build_btn:  Button = null

func _ready() -> void:
	_game      = get_parent() as Game
	_placement = get_node("../Placement") as Placement

	_game.state_changed.connect(_on_state_changed)
	_game.reviews_posted.connect(_on_reviews_posted)
	_game.toast_shown.connect(_on_toast_shown)

	_connect_dock()
	_toast_lbl.visible   = false
	_blogger_lbl.visible = false
	_prev_reclaimed      = _game.sim.reclaimed
	_on_state_changed()

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast_lbl.visible = false

func _on_state_changed() -> void:
	if _active_build_btn != null and _placement.selected_key.is_empty():
		_active_build_btn.modulate = Color.WHITE
		_active_build_btn = null
	var s := _game.sim
	_leaf_lbl.text   = "🌿 %d"    % s.leaf
	_wood_lbl.text   = "🪵 %d"    % s.wood
	_money_lbl.text  = "💰 %.0f"  % s.money
	_day_lbl.text    = "Day %d"   % s.day
	_rating_lbl.text = "⭐ %.1f"  % s.rating

	var net := s.last_net
	_net_lbl.text     = "%+.0f/day" % net
	_net_lbl.modulate = Color.GREEN if net >= 0.0 else Color.RED

	_diff_lbl.text = _DIFF_LABELS[clampi(_game.difficulty, 0, 2)]

	var c := s.caps()
	_update_gauge(_staff_bar, c["staff_load"],  c["staff_cap"])
	_update_gauge(_power_bar, c["power_load"],  c["power_cap"])
	_update_gauge(_water_bar, c["water_load"],  c["water_cap"])

	# storm repair
	_storm_btn.visible = s.storm_repair > 0
	if s.storm_repair > 0:
		_storm_btn.text = "🔧 Repair (%d)" % s.storm_repair

	# reclaim
	_reclaim_btn.text = "🏝 Reclaim (%d)" % s.reclaim_cost()

	# blogger surge
	_blogger_lbl.visible = s.blogger_days > 0
	if s.blogger_days > 0:
		_blogger_lbl.text = "✨ Blogger: %d days" % s.blogger_days

	# building lock indicators
	var rating := s.rating
	for key in _STAR_REQS:
		var btn := _get_building_btn(key)
		if btn:
			btn.disabled = rating < _STAR_REQS[key]

	# island growth
	var r := s.reclaimed
	if r > _prev_reclaimed:
		_prev_reclaimed = r
		_grow_island(r)

func _update_gauge(bar: ProgressBar, load: int, cap: int) -> void:
	bar.max_value = max(cap, max(load, 1))
	bar.value     = load
	bar.modulate  = Color.RED if load > cap else Color.WHITE

func _grow_island(n: int) -> void:
	var island_mesh := get_node_or_null("../Island/IslandMesh") as MeshInstance3D
	if island_mesh == null:
		return
	var ts := 1.0 + n * 0.1
	create_tween().tween_property(island_mesh, "scale",
		Vector3(ts, 1.0, ts), 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _get_building_btn(key: String) -> Button:
	match key:
		"bung":   return $Root/BuildDock/BungBtn
		"villa":  return $Root/BuildDock/VillaBtn
		"runway": return $Root/BuildDock/RunwayBtn
	return null

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
	_storm_btn.pressed.connect(func(): _game.repair_storm())
	_reclaim_btn.pressed.connect(_on_reclaim_pressed)
	$Root/BuildDock/ForageBtn.pressed.connect(func(): _game.forage())

	var keys: Array[String] = ["hut","bung","villa","jetty","rest","gen","solar","desal","runway"]
	var btns: Array[String] = ["HutBtn","BungBtn","VillaBtn","JettyBtn","RestBtn","GenBtn","SolarBtn","DesalBtn","RunwayBtn"]
	for i in range(keys.size()):
		var btn := $Root/BuildDock.get_node(btns[i]) as Button
		btn.pressed.connect(_on_build_btn_pressed.bind(btn, keys[i]))

func _on_build_btn_pressed(btn: Button, key: String) -> void:
	if _active_build_btn != null:
		_active_build_btn.modulate = Color.WHITE
	_active_build_btn = btn
	btn.modulate = Color(0.6, 1.0, 0.6)
	_placement.selected_key = key

func _on_reclaim_pressed() -> void:
	var ok := _game.reclaim()
	if not ok:
		_on_toast_shown("Not enough money to reclaim land.")
