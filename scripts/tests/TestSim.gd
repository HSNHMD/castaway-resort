# TestSim.gd
# Headless test for the game brain — proves the economy behaves before any 3D exists.
# Run from the project root:
#     godot --headless --script scripts/tests/TestSim.gd
# Exits 0 if all checks pass, 1 if any fail.

extends SceneTree

var _pass := 0
var _fail := 0

func _initialize() -> void:
	seed(12345)  # reproducible runs
	print("\n=== Castaway Resort — simulation tests ===\n")

	_test_forage()
	_test_income_rises()
	_test_undercoverage_tanks_rating()
	_test_placement_adjacency()
	_test_save_roundtrip()

	print("\n----------------------------------------")
	print("  %d passed, %d failed" % [_pass, _fail])
	print("----------------------------------------\n")
	quit(1 if _fail > 0 else 0)

func _check(name: String, cond: bool) -> void:
	if cond:
		_pass += 1
		print("  \u2713 ", name)
	else:
		_fail += 1
		print("  \u2717 FAIL: ", name)

# 1) Foraging accumulates materials.
func _test_forage() -> void:
	print("forage")
	var s := Simulation.new()
	for i in range(20): s.forage()
	_check("leaves gathered", s.leaf > 0)
	_check("branches gathered", s.wood > 0)

# 2) With covered systems, money rises as guests fill rooms.
func _test_income_rises() -> void:
	print("income rises with occupancy")
	var s := Simulation.new()
	s.money = 500.0
	for i in range(60): s.forage()           # stock materials for huts
	var built_ok := 0
	for i in range(4):
		var r := s.place("hut", i * 5.0, 0.0, {"on_beach": false})
		if r["ok"]: built_ok += 1
	_check("placed 4 huts", built_ok == 4)
	var start_money := s.money
	var max_occ := 0
	for t in range(200):
		s.tick()
		max_occ = max(max_occ, s.occ["hut"])
	_check("guests checked in over time", max_occ > 0)
	_check("money grew with a covered resort", s.money > start_money)

# 3) Under-covered power drags satisfaction and rating down.
func _test_undercoverage_tanks_rating() -> void:
	print("under-coverage tanks rating")
	var s := Simulation.new()
	s.money = 5000.0
	s.wood = 300
	s.rating = 2.0                            # allow bungalows (req 1.5), skip the climb
	for i in range(4):
		s.place("bung", i * 5.0, 0.0, {"on_beach": false})  # power load 4, cap only 2
	for t in range(30): s.tick()
	_check("satisfaction fell (power shortfall)", s.sat < 90)   # ~16pt penalty → sat≈84
	_check("rating stayed above bungalow gate", s.rating > 1.5) # shortfall didn't crater rep

# 4) A generator next to a villa hurts placement appeal.
func _test_placement_adjacency() -> void:
	print("placement adjacency")
	var s := Simulation.new()
	s.money = 5000.0
	s.rating = 3.0                            # allow villa (req 3)
	s.place("villa", 0.0, 0.0, {"over_water": true})
	var before := s.placement_mod()
	s.place("gen", 2.0, 0.0, {})              # within 4.5u of the villa
	var after := s.placement_mod()
	_check("lone water villa scores well", before > 0.0)
	_check("nearby generator lowers the score", after < before)

# 5) Save → load round-trips state.
func _test_save_roundtrip() -> void:
	print("save / load round-trip")
	var s := Simulation.new()
	s.money = 1234.0
	s.day = 42
	for i in range(40): s.forage()
	s.place("hut", 0.0, 0.0, {})
	var json := s.serialize()
	var s2 := Simulation.load_from(json)
	_check("money restored", s2.money == 1234.0)
	_check("day restored", s2.day == 42)
	_check("buildings restored", s2.built["hut"] == s.built["hut"])
	_check("structures restored", s2.structures.size() == s.structures.size())
