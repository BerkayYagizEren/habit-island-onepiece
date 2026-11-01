# Çalıştırma (gerçek kaydı ezmemesi için HOME geçici dizine yönlendirilir):
#   HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase6_test.gd
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const SONIC_MONKEY := preload("res://scripts/sonic_monkey.gd")
const CAMPFIRE_FLAME := preload("res://scripts/campfire_flame.gd")
const EMPTY_SPOT := Vector2(360, 880)

var _failures := 0
var _checks := 0
var _dm: Node
var _sm: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_dm = root.get_node("DataManager")
	_sm = root.get_node("SoundManager")
	var home := OS.get_environment("HOME")
	if not OS.get_user_data_dir().begins_with(home) or not ("/tmp" in home or "/var/folders" in home):
		printerr("HOME geçici dizin olmalı; gerçek kayıt ezilmesin diye test durduruldu.")
		quit(2)
		return
	_dm.data = _dm._default_data()
	_dm.save_data()
	root.size = Vector2i(720, 1280)

	var main: Control = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	await _frames(3)
	await _click(main.get_node("%BottomNav").get_node("%IslandButton").get_global_rect().get_center())
	await _frames(2)

	var island: Control = main.get_node("%IslandView")
	await _test_monkey(island)
	await _test_items(island)
	await _test_ripples(island)
	await _test_crab(island)
	_test_decor(island)
	await _test_hidden(main, island)
	root.remove_child(main)
	main.free()
	await _frames(2)

	print("SONUÇ: %d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_monkey(island: Control) -> void:
	var item := _item_of_type(island, "monkey")
	var monkey: Node2D = _find_child_with_script(item, SONIC_MONKEY)
	var outer_scale := monkey.scale
	var before: Transform2D = monkey._body_transform()
	await _wait(0.3)
	_check(not monkey._body_transform().is_equal_approx(before), "maymun nefes alır")
	_check(monkey.scale == outer_scale, "nefes dış ölçeği bozmaz")

	var feet := Vector2(0, monkey.FEET_Y)
	_check((monkey._body_transform() * feet).is_equal_approx(feet), "nefeste ayaklar yerde kalır")

	monkey._next_blink = 0.01
	monkey._process(0.02)
	_check(monkey._next_blink >= monkey.BLINK_MIN_GAP, "göz kırpma süresi yenilenir")

	var saved_position := item.position
	_sm._players["pop"].stop()
	await _click(item.global_position)
	# Ses 0,12 saniye sürer; beklemeden bakılır ki yavaş karede bitmiş olmasın.
	_check(_sm._players["pop"].playing, "dokununca ses çalar")
	await _wait(0.1)
	_check(monkey._hop < 0.0, "dokununca maymun zıplar")
	_check(is_instance_valid(item._bubble) and item._bubble.is_inside_tree(), "dokununca balon çıkar")
	_check(item.position == saved_position, "dokunuş eşyayı taşımaz")
	await _wait(1.2)
	_check(is_equal_approx(monkey._hop, 0.0) and monkey._squash.is_equal_approx(Vector2.ONE), "zıplama biter")
	await _wait(0.6)
	_check(not is_instance_valid(item._bubble), "balon söner")

	# Sürükleme dokunuş sayılmaz.
	var origin: Vector2 = island._world.get_global_rect().position
	await _press(item.global_position)
	await _move(origin + Vector2(250, 420))
	await _release(origin + Vector2(250, 420))
	_check(not is_instance_valid(item._bubble), "sürüklemede balon çıkmaz")
	await _wait(0.2)

	# Uzun basış da dokunuş sayılmaz.
	await _press(item.global_position)
	await _wait(0.5)
	await _release(item.global_position)
	_check(not is_instance_valid(item._bubble), "uzun basışta balon çıkmaz")
	await _wait(0.2)


func _test_items(island: Control) -> void:
	var palm := _item_of_type(island, "palm")
	var emoji: Label = palm.get_node("%Emoji")
	var before := emoji.rotation
	await _wait(0.3)
	_check(not is_equal_approx(emoji.rotation, before), "palmiye salınır")
	_check(absf(emoji.rotation) <= palm.SWAY_ANGLE + 0.001, "salınım sınırlı")
	_check(is_zero_approx(palm.get_node("%HitArea").rotation), "dokunma alanı dönmez")

	_dm.place_island_item("campfire", Vector2(200, 640))
	_dm.place_island_item("tent", Vector2(500, 640))
	await _frames(2)
	await _wait(0.4)
	var campfire := _item_of_type(island, "campfire")
	var flame: Node2D = _find_child_with_script(campfire, CAMPFIRE_FLAME)
	_check(flame != null, "kamp ateşi canlı alev çizer")
	_check(campfire.get_node("%Emoji").text.is_empty(), "alevin altında statik emoji kalmaz")
	var flame_time: float = flame._time
	await _frames(2)
	_check(flame._time > flame_time, "alev oynar")

	await _click(campfire.global_position)
	await _wait(0.1)
	_check(not flame.scale.is_equal_approx(Vector2.ONE), "ateş dokununca esner")

	var tent := _item_of_type(island, "tent")
	var tent_emoji: Label = tent.get_node("%Emoji")
	await _click(tent.global_position)
	await _wait(0.1)
	_check(not tent_emoji.scale.is_equal_approx(Vector2.ONE), "çadır dokununca esner")
	await _wait(0.7)
	_check(tent_emoji.scale.is_equal_approx(Vector2.ONE), "çadır eski boyuna döner")
	_check(flame.scale.is_equal_approx(Vector2.ONE), "ateş eski boyuna döner")
	_check(tent.scale.is_equal_approx(Vector2.ONE), "eşyanın ölçeği döner")


func _test_ripples(island: Control) -> void:
	island._ripples.clear()
	await _click(EMPTY_SPOT)
	_check(island._ripples.size() == 1, "boş yere dokununca halka çıkar")
	await _click(_item_of_type(island, "tent").global_position)
	_check(island._ripples.size() == 1, "eşyaya dokununca halka çıkmaz")
	var button: Button = island.get_node("%ShopButton")
	button.disabled = true
	await _click(button.get_global_rect().get_center())
	button.disabled = false
	_check(island._ripples.size() == 1, "mağaza düğmesine dokununca halka çıkmaz")
	for i: int in island.RIPPLE_LIMIT + 3:
		await _click(EMPTY_SPOT)
	_check(island._ripples.size() <= island.RIPPLE_LIMIT, "halka sayısı sınırlı")
	await _wait(island.RIPPLE_SECONDS + 0.2)
	_check(island._ripples.is_empty(), "halkalar söner")


func _test_crab(island: Control) -> void:
	# Yol boyunca kumsalda kalmalı: çimene girmez, denize düşmez.
	for x: float in [-island.CRAB_RANGE, -80.0, 0.0, 80.0, island.CRAB_RANGE]:
		island._crab_x = x
		var spot: Vector2 = island._crab_offset()
		_check(island._is_inside(spot, island.SAND_RADII), "yengeç denizde değil (%s)" % x)
		_check(not island._is_inside(spot, island.GRASS_RADII), "yengeç çimende değil (%s)" % x)

	island._crab_x = 0.0
	island._crab_walking = true
	island._crab_timer = 10.0
	await _wait(0.2)
	_check(not is_zero_approx(island._crab_x), "yengeç yürür")
	island._crab_walking = false
	island._crab_timer = 10.0
	var rested: float = island._crab_x
	await _wait(0.1)
	_check(is_equal_approx(island._crab_x, rested), "yengeç dinlenir")

	island._crab_x = island.CRAB_RANGE
	island._crab_direction = 1.0
	island._crab_walking = true
	island._update_crab(0.5)
	_check(absf(island._crab_x) <= island.CRAB_RANGE and island._crab_direction < 0.0, "yengeç sınırda döner")


func _test_decor(island: Control) -> void:
	_check(island._pebbles.size() == island.PEBBLE_COUNT and island._tufts.size() == island.TUFT_COUNT, "süsler üretilir")
	for spot: Vector2 in island._pebbles + island._shells:
		_check(island._is_inside(spot, island.SAND_RADII) and not island._is_inside(spot, island.GRASS_RADII), "kum süsü kumsalda")
	for spot: Vector2 in island._tufts + island._flowers:
		_check(island._is_inside(spot, island.GRASS_RADII), "çimen süsü çimende")


func _test_hidden(main: Control, island: Control) -> void:
	await _click(main.get_node("%BottomNav").get_node("%StatsButton").get_global_rect().get_center())
	await _frames(2)
	_check(not island.is_processing(), "gizli adada animasyon durur")
	var monkey: Node2D = _find_child_with_script(_item_of_type(island, "monkey"), SONIC_MONKEY)
	var time: float = monkey._time
	await _frames(3)
	_check(is_equal_approx(monkey._time, time), "gizli maymun zaman saymaz")


func _item_of_type(island: Control, type: String) -> Node2D:
	for entry: Dictionary in _dm.data.island_items:
		if entry.type == type:
			return island._item_nodes[entry.id]
	return null


func _find_child_with_script(node: Node, script: Script) -> Node2D:
	for child: Node in node.get_children():
		if child.get_script() == script:
			return child
	return null


func _click(pos: Vector2) -> void:
	await _press(pos)
	await _release(pos)


func _press(pos: Vector2) -> void:
	_push_button(pos, true)
	await _frames(1)


func _release(pos: Vector2) -> void:
	_push_button(pos, false)
	await _frames(1)


func _move(pos: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)
	await _frames(1)


func _push_button(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = pos
	event.global_position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("HATA: %s" % label)
