class_name HUD
extends CanvasLayer

const MAX_REVIEWS  := 20
const TOAST_SECS   := 4.0
const _STAR_REQS   := {"bung": 1.5, "villa": 3.0, "runway": 3.5}
const _DIFF_LABELS := ["😊 Easy", "⚖️ Normal", "💀 Hard"]
const _DOCK_KEY_BTN := {
	"hut": "HutBtn", "bung": "BungBtn", "villa": "VillaBtn",
	"jetty": "JettyBtn", "rest": "RestBtn", "gen": "GenBtn",
	"solar": "SolarBtn", "desal": "DesalBtn", "runway": "RunwayBtn"
}

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
@onready var _storm_btn:       Button       = $Root/DockWrapper/ActionRow/StormRepairBtn
@onready var _reclaim_btn:     Button       = $Root/DockWrapper/ActionRow/ReclaimBtn
@onready var _new_game_btn:    Button       = $Root/DockWrapper/ActionRow/NewGameBtn
@onready var _diff_lbl:        Label        = $Root/TopBar/DifficultyLabel

var _game:           Game
var _placement:      Placement
var _audio:          AudioManager
var _toast_t:        float = 0.0
var _prev_reclaimed: int   = 0
var _build_btns:     Dictionary = {}   # key String -> Button
var _floater_count:  int   = 0

func _ready() -> void:
	_game      = get_parent() as Game
	_placement = get_node("../Placement") as Placement
	_audio     = get_node_or_null("../AudioManager") as AudioManager

	var t := Theme.new()
	t.default_font_size = 28
	$Root.theme = t

	_game.state_changed.connect(_on_state_changed)
	_game.reviews_posted.connect(_on_reviews_posted)
	_game.toast_shown.connect(_on_toast_shown)
	_game.income_earned.connect(_on_income_earned)

	_connect_dock()
	_toast_lbl.visible   = false
	_blogger_lbl.visible = false

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast_lbl.visible = false

func _on_state_changed() -> void:
	_refresh_build_highlights()
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

	if s.storm_repair > 0:
		_storm_btn.visible = true
		_storm_btn.text    = "🔧 Repair (%d)" % s.storm_repair
	else:
		_storm_btn.visible = false

	_reclaim_btn.text = "🏝 Reclaim (%d)" % s.reclaim_cost()

	if s.blogger_days > 0:
		_blogger_lbl.visible = true
		_blogger_lbl.text    = "✨ Blogger: %d days" % s.blogger_days
	else:
		_blogger_lbl.visible = false

	var rating := s.rating
	for key in _STAR_REQS:
		var btn := _get_building_btn(key)
		if btn:
			btn.disabled = rating < _STAR_REQS[key]

	var r := s.reclaimed
	if r > _prev_reclaimed:
		_prev_reclaimed = r
		_grow_island(r)

func _refresh_build_highlights() -> void:
	var sel := _placement.selected_key
	for key in _build_btns:
		(_build_btns[key] as Button).modulate = \
			Color(0.6, 1.0, 0.6) if sel == key else Color.WHITE

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
		"bung":   return $Root/DockWrapper/BuildRow/BungBtn
		"villa":  return $Root/DockWrapper/BuildRow/VillaBtn
		"runway": return $Root/DockWrapper/BuildRow/RunwayBtn
	return null

func _on_reviews_posted(reviews: Array) -> void:
	for i in reviews.size():
		var r: Dictionary = reviews[i]
		var kind: String = r.get("kind", "")
		var prefix := "👍" if kind == "good" else ("📢" if kind == "evt" else "👎")
		var lbl := Label.new()
		lbl.text          = "%s %s: %s" % [prefix, r.get("name", ""), r.get("msg", "")]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.modulate      = Color(1, 1, 1, 0)
		lbl.position.y    = 12.0
		_review_list.add_child(lbl)
		var t := create_tween().set_parallel(true)
		t.tween_property(lbl, "modulate:a", 1.0, 0.25).set_delay(i * 0.06)
		t.tween_property(lbl, "position:y",  0.0, 0.25).set_delay(i * 0.06)\
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	while _review_list.get_child_count() > MAX_REVIEWS:
		_review_list.get_child(0).queue_free()

	await get_tree().process_frame
	var scroll := _review_list.get_parent() as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _on_income_earned(amount: float) -> void:
	if _floater_count >= 5:
		return
	_floater_count += 1
	var lbl := Label.new()
	lbl.text = "+$%d" % int(amount)
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	var anchor := _money_lbl.get_screen_position()
	lbl.position = anchor + Vector2(randf_range(-20.0, 20.0), -8.0)
	$Root.add_child(lbl)
	var t := create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", lbl.position.y - 64.0, 1.2)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 1.2).set_delay(0.3)
	t.tween_callback(func(): _floater_count -= 1; lbl.queue_free()).set_delay(1.2)

func _on_toast_shown(text: String) -> void:
	_toast_lbl.text    = text
	_toast_lbl.visible = true
	_toast_t           = TOAST_SECS

func _connect_dock() -> void:
	_storm_btn.pressed.connect(func(): _game.repair_storm())
	_reclaim_btn.pressed.connect(_on_reclaim_pressed)
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	$Root/DockWrapper/ActionRow/ForageBtn.pressed.connect(_on_forage_pressed)

	var dock := $Root/DockWrapper/BuildRow
	for key in _DOCK_KEY_BTN:
		var btn := dock.get_node(_DOCK_KEY_BTN[key]) as Button
		_build_btns[key] = btn
		btn.pressed.connect(_on_build_btn_pressed.bind(key))

func _on_build_btn_pressed(key: String) -> void:
	_placement.selected_key = key
	_refresh_build_highlights()

func _on_forage_pressed() -> void:
	if _audio:
		_audio.play_forage()
	_game.forage()

func _on_new_game_pressed() -> void:
	if _audio:
		_audio.play_ui()
	_game.restart_to_tutorial()

func _on_reclaim_pressed() -> void:
	if _audio:
		_audio.play_ui()
	var ok := _game.reclaim()
	if not ok:
		_on_toast_shown("Not enough money to reclaim land.")
