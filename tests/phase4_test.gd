# Çalıştırma (gerçek kaydı ezmemesi için HOME geçici dizine yönlendirilir):
#   HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase4_test.gd
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const MIN_TOUCH_SIZE := 48.0
const SOUND_NAMES: Array[String] = ["banana", "complete", "timer_finish", "pop", "click"]
# Arayüzde kullanılan emojilerin tamamı.
const UI_EMOJI := "⏱⏳⛵⛺✅✖❓➕⬜🌱🌴🌺🍌🎖🎯🏅🏆🏝🐵💎📊🔊🔇🔥🗑🛍🍖🍈📦🏴☠👒⚔🌀🦌⚡"

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

	_test_synthesis()
	_test_mute()
	await _test_mute_button(main)
	_test_emoji_font(main)
	await _test_wiring(main)
	await _test_touch_sizes(main)
	root.remove_child(main)
	main.free()
	# Ses sunucusu çalan döngüleri bir sonraki karışımda bırakır.
	_stop_sounds()
	await create_timer(0.2).timeout

	print("SONUÇ: %d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_synthesis() -> void:
	var started := Time.get_ticks_usec()
	var fresh: Node = _sm.get_script().new()
	root.add_child(fresh)
	print("Sentez süresi: %.1f ms" % ((Time.get_ticks_usec() - started) / 1000.0))

	var peak_total := 0.0
	for sound: String in SOUND_NAMES:
		var stream: AudioStreamWAV = fresh._players[sound].stream
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == fresh.MIX_RATE and not stream.stereo, "%s biçimi" % sound)
		var samples := stream.data
		var count := samples.size() / 2
		_check(count > 0, "%s boş değil" % sound)
		var peak := 0
		var crossings := 0
		var previous := 0
		for i: int in count:
			var value := samples.decode_s16(i * 2)
			peak = maxi(peak, absi(value))
			if (value < 0) != (previous < 0):
				crossings += 1
			previous = value
		_check(peak > 3000 and peak < 32000, "%s tepe değeri kırpılmasız (%d)" % [sound, peak])
		_check(absi(samples.decode_s16(samples.size() - 2)) < 200, "%s sonu sessiz, tık yok" % sound)
		_check(crossings > 5, "%s salınım içerir" % sound)
		print("  %s: %.0f ms, tepe %.2f, %d KB" % [sound, stream.get_length() * 1000.0, peak / 32767.0, samples.size() / 1024])
		if sound in ["banana", "complete"]:
			peak_total += peak / 32767.0
	_check(peak_total <= 1.0, "tamamlama + muz birlikte kırpılmaz (%.2f)" % peak_total)
	root.remove_child(fresh)
	fresh.free()


func _test_mute() -> void:
	_check(not _sm.is_muted(), "başta ses açık")
	_sm.mute()
	_check(_sm.is_muted() and AudioServer.is_bus_mute(0), "mute Master'ı kısar")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_dm.SAVE_PATH))
	_check(saved.settings.muted == true, "tercih dosyaya yazılır")
	_check(_dm._sanitized(saved).settings.muted == true, "tercih kayıttan okunur")
	_check(_dm._sanitized({}).settings.muted == false, "eski kayıtta ses açık")
	_sm.unmute()
	_check(not _sm.is_muted(), "unmute geri açar")


func _test_mute_button(main: Control) -> void:
	var button: Button = _top_bar(main).get_node("%SoundButton")
	_check(button.text == "🔊", "ses simgesi açık")
	await _click(button.get_global_rect().get_center())
	_check(_sm.is_muted() and button.text == "🔇", "buton sesi kapatır")
	await _click(button.get_global_rect().get_center())
	_check(not _sm.is_muted() and button.text == "🔊", "buton sesi açar")


func _test_emoji_font(main: Control) -> void:
	var font: Font = _top_bar(main).get_node("%BananasLabel").get_theme_font("font")
	_check(main.EMOJI_FONT in font.fallbacks, "varsayılan fontun yedeği gömülü emoji")
	_check(font.allow_system_fallback if font is FontFile else true, "sistem yedeği açık")
	for i: int in UI_EMOJI.length():
		var code := UI_EMOJI.unicode_at(i)
		_check(main.EMOJI_FONT.has_char(code), "U+%X gömülü fontta" % code)
	# Kaynaklarda listede olmayan emoji kalmasın.
	for path: String in _source_files():
		var text := FileAccess.get_file_as_string(path)
		for i: int in text.length():
			var code := text.unicode_at(i)
			if code >= 0x2300 and code != 0xFE0F:
				_check(main.EMOJI_FONT.has_char(code), "%s: U+%X gömülü fontta" % [path, code])
	_check(main.EMOJI_FONT.has_char(0x1F34C), "gömülü font renkli")
	var ascent: float = main.EMOJI_FONT.get_ascent(26)
	_check(ascent > 0.0, "emoji fontu istenen boyuta ölçeklenir (%.1f)" % ascent)


func _source_files() -> Array[String]:
	var files: Array[String] = []
	for dir: String in ["res://scripts/", "res://scenes/"]:
		for file: String in DirAccess.get_files_at(dir):
			if file.get_extension() in ["gd", "tscn"]:
				files.append(dir + file)
	return files


func _test_wiring(main: Control) -> void:
	# Kısa sesler kontrol anından önce bitmesin; _stop_sounds bir sonraki adımda keser.
	for sound: String in SOUND_NAMES:
		var stream: AudioStreamWAV = _sm._players[sound].stream
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2

	# Tamamlama.
	await _click_nav(main, "%HabitsButton")
	_dm.add_habit("Ses")
	await _frames(2)
	var view: Control = main.get_node("%HabitsView")
	_stop_sounds()
	await _click(_card_button(view, 0).get_global_rect().get_center())
	_check(_dm.data.habits[0].completed_today, "alışkanlık tıklamayla tamamlandı")
	_expect(["complete", "banana"], "tamamlama")

	# Geri alma ödül sesi çalmaz.
	_stop_sounds()
	await _click(_card_button(view, 0).get_global_rect().get_center())
	_check(not _dm.data.habits[0].completed_today, "geri alındı")
	_expect(["click"], "geri alma")

	# Reddedilen geri alma da ödül sesi çalmaz.
	await _click(_card_button(view, 0).get_global_rect().get_center())
	_dm.data.bananas = 0
	_stop_sounds()
	await _click(_card_button(view, 0).get_global_rect().get_center())
	_check(_dm.data.habits[0].completed_today, "geri alma reddedildi")
	_expect([], "reddedilen geri alma")
	view._notice_dialog.hide()
	_dm.data.bananas = 50

	# Bırakma.
	await _click_nav(main, "%IslandButton")
	var island: Control = main.get_node("%IslandView")
	var item: Node2D = island._item_nodes[_dm.data.island_items[0].id]
	var target: Vector2 = island._world.get_global_rect().position + Vector2(300, 400)
	_stop_sounds()
	await _press(item.global_position)
	_expect([], "tutma")
	await _move(target)
	await _release(target)
	_expect(["pop"], "bırakma")

	# Sürükleme odak kaybıyla biterse sonradan gelen bırakma ses çıkarmaz.
	_stop_sounds()
	await _press(item.global_position)
	item._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _release(item.global_position)
	_expect([], "odak kaybıyla biten sürükleme")

	# Satın alma.
	await _click(island.get_node("%ShopButton").get_global_rect().get_center())
	await _frames(2)
	var modal: CanvasLayer = island.get_node("%ShopModal")
	_stop_sounds()
	modal._buy("ship")
	_expect([], "yetersiz muzla satın alma")
	await _click(modal._buy_buttons["flower"].get_global_rect().get_center())
	_check(not modal.visible, "satın alındı")
	_expect(["banana"], "satın alma")

	# Sayaç bitişi.
	await _click_nav(main, "%TimerButton")
	var timer: Control = main.get_node("%TimerView")
	await _click(timer.get_node("%StartButton").get_global_rect().get_center())
	_stop_sounds()
	timer._end_unix_time = Time.get_unix_time_from_system() - 1.0
	timer._on_tick()
	_expect(["timer_finish"], "sayaç bitişi")
	timer._completed_dialog.hide()

	# Genel buton sesi.
	_stop_sounds()
	await _click_nav(main, "%StatsButton")
	_expect(["click"], "sekme tıklaması")


func _test_touch_sizes(main: Control) -> void:
	# Kartlar yalnızca kendi sekmesi açıkken yerleşir.
	await _click_nav(main, "%HabitsButton")
	await _frames(2)
	main.get_node("%IslandView").get_node("%ShopModal").open()
	await _frames(2)
	for button: BaseButton in _all_buttons(main):
		var minimum := button.get_combined_minimum_size()
		var path := str(button.get_path())
		_check(minimum.y >= MIN_TOUCH_SIZE or button.get_parent() is HBoxContainer and button.size.y >= MIN_TOUCH_SIZE, "%s yüksekliği (%s)" % [path, minimum])
		_check(minimum.x >= MIN_TOUCH_SIZE, "%s genişliği (%s)" % [path, minimum])
	main.get_node("%IslandView").get_node("%ShopModal").close()
	# AcceptDialog buton boyutunu açılışta temadan yeniden kurar; açıkken ölçülmeli.
	var view: Control = main.get_node("%HabitsView")
	for dialog: AcceptDialog in [view._add_dialog, view._delete_dialog, view._notice_dialog, main.get_node("%TimerView")._completed_dialog]:
		dialog.popup_centered(Vector2i(560, 0))
		await _frames(2)
		_check(dialog.get_ok_button().size.y >= MIN_TOUCH_SIZE and dialog.get_ok_button().size.x >= MIN_TOUCH_SIZE, "%s Tamam butonu (%s)" % [dialog.name, dialog.get_ok_button().size])
		if dialog is ConfirmationDialog:
			_check(dialog.get_cancel_button().size.y >= MIN_TOUCH_SIZE, "%s İptal butonu (%s)" % [dialog.name, dialog.get_cancel_button().size])
		dialog.hide()


func _all_buttons(node: Node) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	for child: Node in node.get_children():
		# Pencerelerin kendi iç butonları ayrıca denetlenir.
		if child is Window:
			continue
		if child is BaseButton:
			buttons.append(child)
		buttons.append_array(_all_buttons(child))
	return buttons


func _top_bar(main: Control) -> Control:
	return main.find_child("TopBar", true, false)


func _card_button(view: Control, index: int) -> Button:
	return view._list.get_child(index).get_child(0).get_child(1)


func _stop_sounds() -> void:
	for sound: String in SOUND_NAMES:
		_sm._players[sound].stop()


func _expect(expected: Array, label: String) -> void:
	for sound: String in SOUND_NAMES:
		_check(_sm._players[sound].playing == (sound in expected), "%s: %s %s" % [label, sound, "çalmalı" if sound in expected else "çalmamalı"])


func _click_nav(main: Control, button: String) -> void:
	await _click(main.get_node("%BottomNav").get_node(button).get_global_rect().get_center())


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


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("HATA: %s" % label)
