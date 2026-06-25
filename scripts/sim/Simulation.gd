# Simulation.gd
# Castaway Resort — engine-agnostic game brain for Godot 4.
# Pure logic: NO nodes, NO scene tree, NO rendering. Lives as a RefCounted object.
# Scenes/UI only READ this state and CALL these methods. Keep it that way.
# Ported 1:1 from the validated TypeScript prototype — same constants, same formulas.

class_name Simulation
extends RefCounted

# ----------------------------- constants (validated balance) -----------------------------
const TICK_SECONDS := 1.5

const DEF := {
	"hut":    {"rate": 8,  "upkeep": 1, "max": 10, "req_star": 0.0, "cost": {"leaf": 12, "wood": 8}, "scale": 1.28},
	"bung":   {"rate": 26, "upkeep": 2, "max": 8,  "req_star": 1.5, "cost": {"money": 150, "wood": 6}, "scale": 1.32},
	"villa":  {"rate": 85, "upkeep": 3, "max": 8,  "req_star": 3.0, "cost": {"money": 600}, "scale": 1.36},
	"jetty":  {"rate": 0,  "upkeep": 1, "max": 1,  "req_star": 0.0, "cost": {"money": 60}, "scale": 1.0},
	"rest":   {"rate": 0,  "upkeep": 4, "max": 1,  "req_star": 0.0, "cost": {"money": 120, "leaf": 10}, "scale": 1.0},
	"gen":    {"rate": 0,  "upkeep": 2, "max": 5,  "req_star": 0.0, "cost": {"money": 90}, "scale": 1.22, "fuel": 6, "power": 6},
	"solar":  {"rate": 0,  "upkeep": 1, "max": 6,  "req_star": 0.0, "cost": {"money": 300}, "scale": 1.26, "power": 10},
	"desal":  {"rate": 0,  "upkeep": 2, "max": 5,  "req_star": 0.0, "cost": {"money": 110}, "scale": 1.22, "water": 8},
	"runway": {"rate": 0,  "upkeep": 6, "max": 1,  "req_star": 3.5, "cost": {"money": 2500}, "scale": 1.0},
}

const WAGE := 12
const HIRE_COST := 20
const STAFF_PER := 4
const CHECKOUT_P := 0.07
const WALKOUT_P := 0.12
const RATING_DRIFT := 0.08
const STORM_AFTER_DAY := 18
const STORM_P := 1.0 / 110.0
const BLOGGER_P := 1.0 / 150.0

const GEN_RADIUS := 4.5
const REST_RADIUS := 5.0
const CROWD_RADIUS := 3.2

const ROOMS := ["hut", "bung", "villa"]

const NAMES := ["Aishath","Ibrahim","Mariyam","Hassan","Fathimath","Liam","Sofia","Yuki","Anaya","Mohamed","Lena","Omar","Priya","Tom","Hana","Niko","Aria","Daniel","Mei","Zayan"]
const COMPLAINTS := {
	"staff": ["Room wasn't cleaned all day.","Waited 40 minutes at the desk, no one came.","Asked for service three times, gave up.","Housekeeping clearly stretched too thin."],
	"power": ["AC died at 2am — couldn't sleep.","Lights flickered, then went dark.","Power kept cutting, phone never charged.","Fan stopped and the room cooked."],
	"water": ["No water pressure — shower was a trickle.","Tap ran dry before dinner.","Couldn't flush or wash. Grim.","Brown water from the shower."],
	"place": ["Generator droning right outside our villa all night.","Diesel fumes drifting over the rooms.","Packed in like sardines — zero privacy.","No view, no space. Felt cramped."],
}
const PRAISE := ["Sunset from the deck was unreal.","Staff remembered our names — felt like home.","Cleanest, calmest island we've stayed on.","Snorkelling right off the beach. Magic.","Best value in the Maldives, hands down.","Woke up to dolphins. No notes."]

# ----------------------------- state -----------------------------
var leaf := 0
var wood := 0
var money := 150.0
var rating := 0.0
var sat := 100
var day := 1
var staff := 1
var reclaimed := 0
var built := {"hut":0,"bung":0,"villa":0,"jetty":0,"rest":0,"gen":0,"solar":0,"desal":0,"runway":0}
var occ := {"hut":0,"bung":0,"villa":0}
var structures: Array = []        # each: {id,key,x,z,on_beach,over_water,index}
var storm_repair := 0
var blogger_days := 0
var last_net := 0.0

var _idx := {"hut":0,"bung":0,"villa":0}
var _next_id := 0
var _seen_first_guest := false

# ----------------------------- pricing & affordability -----------------------------
func price_of(key: String) -> Dictionary:
	var d: Dictionary = DEF[key]
	var n: int = built[key]
	var out := {}
	for k in d["cost"]:
		out[k] = int(roundi(float(d["cost"][k]) * pow(d["scale"], n)))
	return out

func _can_afford(p: Dictionary) -> bool:
	return (not p.has("leaf") or leaf >= p["leaf"]) \
		and (not p.has("wood") or wood >= p["wood"]) \
		and (not p.has("money") or money >= p["money"])

func reclaim_cost() -> int:
	return int(roundi(80.0 * pow(1.3, reclaimed)))

# ----------------------------- capacities (the three challenge systems) -----------------------------
func caps() -> Dictionary:
	var rooms: int = built["hut"] + built["bung"] + built["villa"]
	var guests: int = occ["hut"] + occ["bung"] + occ["villa"]
	return {
		"rooms": rooms, "guests": guests,
		"staff_cap": 2 + staff * STAFF_PER, "staff_load": rooms,
		"power_cap": 2 + built["gen"] * 6 + built["solar"] * 10, "power_load": built["bung"] + built["villa"],
		"water_cap": 4 + built["desal"] * 8, "water_load": guests,
	}

func _cover(cap: int, load: int) -> float:
	return 9.0 if load <= 0 else float(cap) / float(load)

# ----------------------------- placement appeal (distance-based adjacency) -----------------------------
func _appeal_of(s: Dictionary) -> float:
	var is_v: bool = s["key"] == "villa"
	var a := 0.0
	if s["on_beach"]: a += 8.0
	if is_v: a += 12.0
	var crowd := 0
	var near_rest := false
	for o in structures:
		if o["id"] == s["id"]: continue
		var dist := Vector2(o["x"] - s["x"], o["z"] - s["z"]).length()
		if o["key"] == "gen" and dist < GEN_RADIUS: a -= (22.0 if is_v else 14.0)
		if o["key"] == "rest" and dist < REST_RADIUS: near_rest = true
		if o["key"] in ROOMS and dist < CROWD_RADIUS: crowd += 1
	if near_rest: a += 6.0
	if crowd >= 3: a -= (12.0 if is_v else 6.0)
	return a

func placement_mod() -> float:
	var rooms := []
	for s in structures:
		if s["key"] in ROOMS: rooms.append(s)
	if rooms.is_empty(): return 0.0
	var total := 0.0
	for s in rooms: total += _appeal_of(s)
	return clampf(total / rooms.size(), -25.0, 15.0)

# ----------------------------- actions -----------------------------
func forage() -> Dictionary:
	var l := 3 + (randi() % 3)
	var w := 2 + (randi() % 2)
	leaf += l
	wood += w
	return {"leaf": l, "wood": w}

func hire() -> bool:
	if money >= HIRE_COST:
		money -= HIRE_COST
		staff += 1
		return true
	return false

func fire() -> bool:
	if staff > 0:
		staff -= 1
		return true
	return false

func reclaim() -> bool:
	var c := reclaim_cost()
	if money < c: return false
	money -= c
	reclaimed += 1
	return true

# Renderer has already checked the tile zone and passes on_beach / over_water flags.
func place(key: String, x: float, z: float, meta := {}) -> Dictionary:
	var d: Dictionary = DEF[key]
	if built[key] >= d["max"]: return {"ok": false, "reason": "max"}
	if d["req_star"] > 0.0 and rating < d["req_star"]: return {"ok": false, "reason": "locked"}
	var p := price_of(key)
	if not _can_afford(p): return {"ok": false, "reason": "cost"}
	if p.has("leaf"): leaf -= p["leaf"]
	if p.has("wood"): wood -= p["wood"]
	if p.has("money"): money -= p["money"]
	var index := 0
	if key in ROOMS:
		index = _idx[key]
		_idx[key] += 1
	var placed := {
		"id": _next_id, "key": key, "x": x, "z": z,
		"on_beach": meta.get("on_beach", false), "over_water": meta.get("over_water", false),
		"index": index,
	}
	_next_id += 1
	structures.append(placed)
	built[key] += 1
	_recompute_rating()
	return {"ok": true, "placed": placed}

func repair_storm() -> bool:
	if money >= storm_repair:
		money -= storm_repair
		storm_repair = 0
		return true
	return false

func _recompute_rating() -> void:
	var struct_r := clampf(
		(0.6 if built["jetty"] > 0 else 0.0) + (1.2 if built["rest"] > 0 else 0.0) \
		+ built["bung"] * 0.2 + built["villa"] * 0.45 \
		+ (0.7 if built["runway"] > 0 else 0.0) + min(built["hut"] * 0.05, 0.4), 0.0, 5.0)
	rating = maxf(rating, struct_r)

# ----------------------------- the daily tick -----------------------------
func tick() -> Dictionary:
	day += 1
	var reviews: Array = []
	var toasts: Array = []
	var c := caps()

	# events
	if day > STORM_AFTER_DAY and storm_repair == 0 and randf() < STORM_P:
		for t in ROOMS: occ[t] = floori(occ[t] * 0.4)
		storm_repair = 40 + c["rooms"] * 6
		rating = clampf(rating - 0.3, 0.0, 5.0)
		toasts.append("🌀 Monsoon storm! Guests fled and buildings took damage.")
		reviews.append({"kind": "evt", "name": "Storm", "msg": "A monsoon swell battered the island overnight."})
	if blogger_days > 0: blogger_days -= 1
	if rating >= 2.0 and randf() < BLOGGER_P:
		rating = clampf(rating + 0.35, 0.0, 5.0)
		blogger_days = 6
		toasts.append("✨ A travel blogger featured your island — bookings are surging.")
		reviews.append({"kind": "evt", "name": "Featured", "msg": "'A hidden gem in the northern atolls.'"})

	# satisfaction from coverage + placement
	var cs := _cover(c["staff_cap"], c["staff_load"])
	var cp := _cover(c["power_cap"], c["power_load"])
	var cw := _cover(c["water_cap"], c["water_load"])
	var pm := placement_mod()
	var s := 100.0
	if cs < 1.0: s -= (1.0 - cs) * 38.0
	if cp < 1.0: s -= (1.0 - cp) * 32.0
	if cw < 1.0: s -= (1.0 - cw) * 32.0
	if storm_repair > 0: s -= 18.0
	s += pm
	if built["rest"] > 0: s += 4.0
	s = clampf(s, 0.0, 100.0)
	sat = int(round(s))

	# rating drifts toward satisfaction (neglect lowers it)
	rating = clampf(rating + (s / 100.0 * 5.0 - rating) * RATING_DRIFT, 0.0, 5.0)

	# demand & arrivals
	var demand := 0.10 + (0.22 if built["jetty"] > 0 else 0.0) + (0.40 if built["runway"] > 0 else 0.0) \
		+ rating * 0.05 + (0.2 if blogger_days > 0 else 0.0)
	demand = clampf(demand * (0.4 + s / 100.0 * 0.8), 0.0, 0.92)
	_seat("hut", demand)
	if rating >= 1.5: _seat("bung", demand)
	if rating >= 3.0: _seat("villa", demand * 0.85)
	for t in ROOMS: _checkout(t)
	if s < 35.0:
		for t in ROOMS:
			for i in range(occ[t]):
				if randf() < WALKOUT_P: occ[t] -= 1

	# income
	var income: int = occ["hut"] * DEF["hut"]["rate"] + occ["bung"] * DEF["bung"]["rate"] + occ["villa"] * DEF["villa"]["rate"]
	var full: int = occ["hut"] + occ["bung"] + occ["villa"]
	if built["rest"] > 0: income += full * 5

	# costs (the money sinks)
	var salaries := staff * WAGE
	var upkeep := 0
	for k in built: upkeep += built[k] * DEF[k]["upkeep"]
	var fuel: int = built["gen"] * int(DEF["gen"]["fuel"])
	var net: float = income - salaries - upkeep - fuel
	last_net = net
	money += net

	# payroll crunch
	if money < 0:
		money = 0
		if staff > 0:
			staff -= 1
			reviews.append({"kind": "bad", "name": "Payroll", "msg": "Couldn't make payroll — a staff member quit."})
		else:
			reviews.append({"kind": "bad", "name": "Cash", "msg": "Flat broke. The place is visibly slipping."})

	if not _seen_first_guest and full > 0:
		_seen_first_guest = true
		toasts.append("🛶 Your first guest steps onto the sand.")

	# one weighted review per tick
	var issues: Array = []
	if cs < 1.0: issues.append(["staff", 1.0 - cs])
	if cp < 1.0: issues.append(["power", 1.0 - cp])
	if cw < 1.0: issues.append(["water", 1.0 - cw])
	if pm < -8.0: issues.append(["place", (-pm - 8.0) / 20.0])
	issues.sort_custom(func(a, b): return a[1] > b[1])
	if full > 0:
		if issues.size() > 0 and randf() < clampf(issues[0][1] * 0.9, 0.1, 0.85):
			reviews.append({"kind": "bad", "name": _pick(NAMES), "msg": _pick(COMPLAINTS[issues[0][0]])})
		elif s > 78.0 and randf() < 0.3:
			reviews.append({"kind": "good", "name": _pick(NAMES), "msg": _pick(PRAISE)})

	return {"income": income, "net": net, "reviews": reviews, "toasts": toasts}

func _seat(t: String, chance: float) -> void:
	var empty: int = built[t] - occ[t]
	for i in range(empty):
		if randf() < chance: occ[t] += 1

func _checkout(t: String) -> void:
	var n: int = occ[t]
	for i in range(n):
		if randf() < CHECKOUT_P: occ[t] -= 1
	if occ[t] < 0: occ[t] = 0

func _pick(arr: Array):
	return arr[randi() % arr.size()]

# ----------------------------- save / load -----------------------------
func serialize() -> String:
	return JSON.stringify({
		"leaf": leaf, "wood": wood, "money": money, "rating": rating, "day": day,
		"staff": staff, "reclaimed": reclaimed, "built": built, "occ": occ, "idx": _idx,
		"structures": structures, "storm_repair": storm_repair, "blogger_days": blogger_days,
		"next_id": _next_id, "seen_first_guest": _seen_first_guest,
	})

static func load_from(json: String) -> Simulation:
	var s := Simulation.new()
	var d = JSON.parse_string(json)
	if d == null: return s
	s.leaf = d.get("leaf", 0)
	s.wood = d.get("wood", 0)
	s.money = d.get("money", 150.0)
	s.rating = d.get("rating", 0.0)
	s.day = d.get("day", 1)
	s.staff = d.get("staff", 1)
	s.reclaimed = d.get("reclaimed", 0)
	s.built = d.get("built", s.built)
	s.occ = d.get("occ", s.occ)
	s._idx = d.get("idx", s._idx)
	s.structures = d.get("structures", [])
	s.storm_repair = d.get("storm_repair", 0)
	s.blogger_days = d.get("blogger_days", 0)
	s._next_id = d.get("next_id", 0)
	s._seen_first_guest = d.get("seen_first_guest", false)
	return s
