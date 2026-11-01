# Çalıştırma (gerçek kaydı ezmemesi için HOME geçici dizine yönlendirilir):
#   HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase5_test.gd
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const SONIC_MONKEY := preload("res://scripts/sonic_monkey.gd")
const CREW_MONKEY := preload("res://scripts/crew_monkey.gd")

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
	_reset_data()
	root.size = Vector2i(720, 1280)

	_test_today_stats()
	_test_daily_quest()
	_test_check_in()
	_test_day_reset()
	_test_priority()
	_test_save_migration()

	_reset_data()
	var main: Control = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	await _frames(3)
	await _test_home_screen(main)
	await _test_focus_screen(main)
	await _test_monkeys(main)
	root.remove_child(main)
	main.free()
	# Ses sunucusu çalan sesleri bir sonraki karışımda bırakır.
	_stop_all_sounds()
	await create_timer(0.2).timeout

	print("SONUÇ: %d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _reset_data() -> void:
	_dm.data = _dm._default_data()
	_dm.save_data()


func _test_today_stats() -> void:
	_reset_data()
	var stats: Dictionary = _dm.data.today_stats
	_check(stats.habits_completed == 0 and stats.focus_minutes == 0 and stats.bananas_earned == 0, "bugün sıfırdan başlar")

	var id: String = _dm.add_habit("A")
	_dm.toggle_habit(id)
	_check(_dm.data.today_stats.habits_completed == 1 and _dm.data.today_stats.bananas_earned == 5, "tamamlama sayılır")
	_dm.toggle_habit(id)
	_check(_dm.data.today_stats.habits_completed == 0 and _dm.data.today_stats.bananas_earned == 0, "geri alma sayımı geri alır")

	_dm.toggle_habit(id)
	_dm.delete_habit(id)
	_check(_dm.data.today_stats.habits_completed == 0, "silinen alışkanlık oranı bozmaz")
	_check(_dm.data.today_stats.bananas_earned == 5 and _dm.data.bananas == 55, "silinse de kazanılan muz kalır")

	_dm.record_focus_session(25)
	_check(_dm.data.today_stats.focus_minutes == 25 and _dm.data.today_stats.bananas_earned == 30, "odak dakikası ve muzu sayılır")
	_dm.record_focus_session(0)
	_check(_dm.data.today_stats.focus_minutes == 25, "sıfır dakika sayılmaz")

	_dm.add_bananas(3)
	_check(_dm.data.today_stats.bananas_earned == 33, "doğrudan kazanç sayılır")
	_dm.spend_bananas(10)
	_check(_dm.data.today_stats.bananas_earned == 33, "harcama kazancı azaltmaz")


func _test_daily_quest() -> void:
	_reset_data()
	var quest: Dictionary = _dm.data.daily_quest
	_check(quest.text in _dm.DAILY_QUESTS and quest.reward == 20 and not quest.completed, "görev alanları")
	var left: int = _dm.get_daily_quest_seconds_left()
	_check(left > 0 and left <= _dm.SECONDS_PER_DAY, "görev gün içinde dolar (%d)" % left)

	# Her değiştirme farklı görev getirir, ödül ve süre aynı kalır.
	for i: int in 20:
		var before: String = _dm.data.daily_quest.text
		_check(_dm.reroll_daily_quest() and _dm.data.daily_quest.text != before, "değiştirme yeni metin verir")
	_check(_dm.data.daily_quest.reward == 20 and _dm.data.daily_quest.expires_at == quest.expires_at, "değiştirme ödülü ve süreyi korur")
	_check(_dm.data.bananas == 50, "değiştirme ödül vermez")

	var xp_before: int = _dm.get_total_xp()
	_check(_dm.complete_daily_quest(), "görev tamamlanır")
	_check(_dm.data.bananas == 70 and _dm.data.today_stats.bananas_earned == 20, "+20 muz")
	_check(_dm.get_total_xp() == xp_before + _dm.DAILY_QUEST_XP, "görev XP verir")

	_check(not _dm.complete_daily_quest() and _dm.data.bananas == 70, "ikinci tamamlama ödül vermez")
	var finished: String = _dm.data.daily_quest.text
	_check(not _dm.reroll_daily_quest() and _dm.data.daily_quest.text == finished, "biten görev değiştirilemez")

	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_dm.SAVE_PATH))
	_check(saved.daily_quest.completed == true, "görev durumu dosyaya yazılır")


func _test_check_in() -> void:
	_reset_data()
	_check(not _dm.has_checked_in_today(), "başta giriş yapılmamış")
	var xp_before: int = _dm.get_total_xp()
	_check(_dm.check_in_daily() and _dm.data.bananas == 65, "giriş +15 muz")
	_check(_dm.data.today_stats.bananas_earned == 15 and _dm.get_total_xp() == xp_before, "kazanç sayılır, XP verilmez")
	_check(not _dm.check_in_daily() and _dm.data.bananas == 65, "aynı gün ikinci giriş reddedilir")

	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_dm.SAVE_PATH))
	_check(_dm._sanitized(saved).last_check_in_date == _dm._today(), "giriş kayıttan okunur")


func _test_day_reset() -> void:
	_reset_data()
	_dm.add_habit("A")
	_dm.toggle_habit(_dm.data.habits[0].id)
	_dm.record_focus_session(10)
	_dm.check_in_daily()
	_dm.complete_daily_quest()
	var bananas: int = _dm.data.bananas

	var events := {"today": 0}
	var on_today := func() -> void: events.today += 1
	_dm.today_updated.connect(on_today)
	_dm.check_day_reset()
	_check(events.today == 0 and _dm.data.today_stats.habits_completed == 1, "aynı gün sıfırlanmaz")

	# Gün değişimi: kayıt dünden kalmış gibi davranılır.
	var yesterday: String = _dm._date_string_days_before(_dm._today(), 1)
	_dm.data.today_stats.date = yesterday
	_dm.data.last_check_in_date = yesterday
	_dm.data.habits[0].last_completed_date = yesterday
	_dm.check_day_reset()
	_dm.today_updated.disconnect(on_today)
	_check(events.today == 1, "sıfırlama bildirilir")
	var stats: Dictionary = _dm.data.today_stats
	_check(stats.date == _dm._today() and stats.habits_completed == 0 and stats.focus_minutes == 0 and stats.bananas_earned == 0, "bugün sayaçları sıfırlanır")
	_check(not _dm.data.daily_quest.completed, "yeni gün yeni görev")
	_check(not _dm.has_checked_in_today(), "yeni gün yeniden giriş")
	_check(_dm.data.bananas == bananas, "bakiye sıfırlanmaz")
	_check(_dm.check_in_daily(), "yeni gün giriş kabul edilir")

	# Saat değişikliğiyle süre gün bitmeden dolarsa bitmiş görev yeniden açılmaz.
	_dm.complete_daily_quest()
	_dm.data.daily_quest.expires_at = 1
	_dm.check_day_reset()
	_check(_dm.data.daily_quest.completed and _dm.get_daily_quest_seconds_left() > 0, "süre yenilenir, durum korunur")

	# Gece yarısını geçen oturum yeni güne yazılır.
	_dm.data.today_stats.date = yesterday
	_dm.record_focus_session(5)
	_check(_dm.data.today_stats.date == _dm._today() and _dm.data.today_stats.focus_minutes == 5, "gece yarısını geçen odak yeni güne yazılır")


func _test_priority() -> void:
	_reset_data()
	var id: String = _dm.add_habit("A")
	_check(_dm.data.habits[0].priority == "low", "varsayılan öncelik")
	var seen: Array[String] = []
	for i: int in 3:
		_dm.cycle_habit_priority(id)
		seen.append(_dm.data.habits[0].priority)
	_check(seen == ["high", "medium", "low"], "öncelik döngüsü (%s)" % [seen])
	_dm.cycle_habit_priority("yok")
	_check(_dm.data.habits[0].priority == "low", "bilinmeyen alışkanlık yok sayılır")


func _test_save_migration() -> void:
	# Bu özelliklerden önceki kayıt.
	var old: Dictionary = _dm._sanitized({"bananas": 7.0, "habits": [{"id": "h", "completed_today": true, "last_completed_date": _dm._today()}]})
	_check(old.bananas == 7 and old.habits[0].priority == "low", "eski alışkanlığa öncelik atanır")
	_check(old.today_stats.habits_completed == 1 and old.today_stats.date == _dm._today(), "eski kayıttaki bugünkü tamamlama sayılır")
	_check(old.daily_quest.text in _dm.DAILY_QUESTS and old.last_check_in_date == "", "eski kayda görev verilir")

	# Elle bozulmuş kayıt.
	var bad: Dictionary = _dm._sanitized({
		"habits": [{"id": "h", "priority": "acil"}],
		"today_stats": {"habits_completed": "x", "focus_minutes": -5.0, "bananas_earned": 12.0},
		"daily_quest": {"text": 5, "reward": "çok"},
		"last_check_in_date": 42,
	})
	_check(bad.habits[0].priority == "low", "geçersiz öncelik")
	_check(bad.today_stats.habits_completed == 0 and bad.today_stats.focus_minutes == 0 and bad.today_stats.bananas_earned == 12, "bozuk sayaçlar")
	_check(bad.daily_quest.text in _dm.DAILY_QUESTS and bad.daily_quest.reward == 20, "bozuk görev yenilenir")

	var good: Dictionary = _dm._sanitized({"daily_quest": {"text": "Q", "reward": 20.0, "completed": true, "expires_at": 99.0}})
	_check(good.daily_quest == {"text": "Q", "reward": 20, "completed": true, "expires_at": 99}, "görev tam sayı olarak okunur")


func _test_home_screen(main: Control) -> void:
	var view: Control = main.get_node("%HabitsView")
	_check(view.visible, "ana ekran açık")
	var progress: Control = view.get_node("Margin/Column/TodayProgress")
	var card: Control = view.get_node("Margin/Column/DailyQuestCard")
	_check("Today's Progress" in _all_text(progress), "şerit başlığı")
	_check("Günün Korsan Görevi: Grand Line'da zafer kazan!" in _all_text(card), "görev başlığı")
	_check(card.get_node("%RewardLabel").text == "+20 🍌", "ödül etiketi")
	_check(card.get_node("%QuestLabel").text == _dm.data.daily_quest.text, "görev metni")
	var countdown: String = card.get_node("%CountdownLabel").text
	_check(countdown.begins_with("⏳ ") and countdown.ends_with("m") and "h " in countdown, "geri sayım (%s)" % countdown)

	# Alışkanlık kartı şeridi günceller.
	_dm.add_habit("A")
	_dm.add_habit("B")
	await _frames(2)
	_check(progress.get_node("%HabitsLabel").text == "0/2 habits", "toplam alışkanlık")
	await _click(view._list.get_child(0).get_child(0).get_child(1).get_global_rect().get_center())
	_check(progress.get_node("%HabitsLabel").text == "1/2 habits", "tıklamayla şerit güncellenir")
	_check(progress.get_node("%BananasLabel").text == "🍌 5 acquired", "kazanılan muz")
	_dm.record_focus_session(12)
	_check(progress.get_node("%FocusLabel").text == "⏱ 12m focused", "odak dakikası")

	# Değiştir.
	var before: String = _dm.data.daily_quest.text
	await _click(card.get_node("%ChangeButton").get_global_rect().get_center())
	_check(_dm.data.daily_quest.text != before and card.get_node("%QuestLabel").text == _dm.data.daily_quest.text, "Değiştir yeni görev getirir")

	# Tamamla.
	var bananas: int = _dm.data.bananas
	_stop_all_sounds()
	await _click(card.get_node("%CompleteButton").get_global_rect().get_center())
	_check(_dm.data.bananas == bananas + 20 and _dm.data.daily_quest.completed, "Tamamla +20 muz")
	_check(card.get_node("%CompleteButton").disabled and card.get_node("%ChangeButton").disabled, "biten görevin butonları kapanır")
	_check(_sm._players["complete"].playing, "tamamlama sesi")
	await _click(card.get_node("%CompleteButton").get_global_rect().get_center())
	_check(_dm.data.bananas == bananas + 20, "ikinci tıklama ödül vermez")

	# CHECK-IN.
	var check_in: BaseButton = view.get_node("%CheckInButton")
	_check(not check_in.disabled and "SET SAIL!" in check_in.caption and "+15" in check_in.caption, "CHECK-IN hazır")
	bananas = _dm.data.bananas
	_stop_all_sounds()
	await _click(check_in.get_global_rect().get_center())
	_check(_dm.data.bananas == bananas + 15, "CHECK-IN +15 muz")
	_check(_sm._players["celebrate"].playing, "kutlama sesi")
	_check(check_in.disabled and "+15" not in check_in.caption, "CHECK-IN kapanır")
	await create_timer(0.4).timeout
	_check(check_in.scale.is_equal_approx(Vector2.ONE), "zıplama animasyonu biter")
	_stop_all_sounds()
	await _click(check_in.get_global_rect().get_center())
	_check(_dm.data.bananas == bananas + 15 and not _sm._players["celebrate"].playing, "ikinci CHECK-IN ödül ve ses vermez")

	# Gece yarısı uygulama açıkken.
	_dm.data.today_stats.date = _dm._date_string_days_before(_dm._today(), 1)
	_dm.data.last_check_in_date = _dm.data.today_stats.date
	card._on_countdown_tick()
	_check(not check_in.disabled and not card.get_node("%CompleteButton").disabled, "yeni günde butonlar açılır")
	_check(progress.get_node("%FocusLabel").text == "⏱ 0m focused", "yeni günde şerit sıfırlanır")

	# Öncelik noktaları.
	var dot_button := _priority_button(view, 0)
	var completed_before: bool = _dm.data.habits[0].completed_today
	_check(_priority_color(view, 0) == view.PRIORITY_COLORS["low"], "varsayılan beyaz nokta")
	await _click(dot_button.get_global_rect().get_center())
	await _frames(2)
	_check(_dm.data.habits[0].priority == "high" and _priority_color(view, 0) == view.PRIORITY_COLORS["high"], "dokununca kırmızı nokta")
	_check(_dm.data.habits[0].completed_today == completed_before, "nokta tamamlamayı etkilemez")

	# Yerleşim taşmaz.
	var column: Control = view.get_node("Margin/Column")
	_check(column.get_combined_minimum_size().y <= view.size.y - 232.0, "ana ekran sığar (%s)" % column.get_combined_minimum_size())
	_check(view.get_node("%Scroll").size.y >= 150.0, "liste için yer kalır (%s)" % view.get_node("%Scroll").size)
	var nav_top: float = main.get_node("%BottomNav").get_global_rect().position.y
	_check(view.get_node("%AddButton").get_global_rect().end.y <= nav_top, "Ekle butonu menünün üstünde")
	var bar_bottom: float = main.find_child("TopBar", true, false).get_global_rect().end.y
	_check(progress.get_global_rect().position.y >= bar_bottom, "şerit üst barın altında")


func _test_focus_screen(main: Control) -> void:
	await _click(main.get_node("%BottomNav").get_node("%TimerButton").get_global_rect().get_center())
	await _frames(2)
	var timer: Control = main.get_node("%TimerView")
	var stop: BaseButton = timer.get_node("%StopButton")
	var start: Button = timer.get_node("%StartButton")
	_check("Focus With Luffy" in _all_text(timer), "başlık")
	_check(timer.get_node("%FocusScene").is_processing(), "ateş animasyonu açık")
	_check(start.visible and not stop.visible and timer.get_node("%Presets").visible, "boşta BAŞLAT görünür")

	await _click(start.get_global_rect().get_center())
	await _frames(2)
	_check(not timer._tick_timer.is_stopped(), "sayaç başlar")
	_check(stop.visible and not start.visible and not timer.get_node("%Presets").visible, "çalışırken STOP görünür")
	_check(timer.get_node("%StatusLabel").text == "Luffy is locked in. Training his Haki on Rusukaina!", "kilitlenme metni")
	_check(timer.get_node("%SonicMonkey").writing, "maymun yazar")

	# Sayaç başka süreye sarmış olsun; STOP sıfırlar ve ödül vermez.
	timer._remaining_seconds = 100
	timer._update_display()
	_check(timer._time_label.text == "01:40", "sayaç metni")
	var bananas: int = _dm.data.bananas
	var focus: int = _dm.data.today_stats.focus_minutes
	await _click(stop.get_global_rect().get_center())
	await _frames(2)
	_check(timer._tick_timer.is_stopped() and timer._time_label.text == "25:00", "STOP durdurup sıfırlar")
	_check(_dm.data.bananas == bananas and _dm.data.today_stats.focus_minutes == focus, "STOP ödül vermez")
	_check(start.visible and not stop.visible and not timer.get_node("%SonicMonkey").writing, "STOP sonrası boşta")

	# Sayaç bitişi bugünkü odak süresine eklenir.
	await _click(start.get_global_rect().get_center())
	timer._end_unix_time = Time.get_unix_time_from_system() - 1.0
	timer._on_tick()
	_check(_dm.data.today_stats.focus_minutes == focus + 25, "biten oturum bugüne eklenir")
	timer._completed_dialog.hide()

	# İki ses butonu birbiriyle uyumlu kalır.
	var sound: Button = timer.get_node("%FocusSoundButton")
	var top_sound: Button = main.find_child("TopBar", true, false).get_node("%SoundButton")
	_check(sound.text == "🔊", "ses simgesi açık")
	await _click(sound.get_global_rect().get_center())
	_check(_sm.is_muted() and sound.text == "🔇" and top_sound.text == "🔇", "odak ekranından kapatılır")
	await _click(top_sound.get_global_rect().get_center())
	_check(not _sm.is_muted() and sound.text == "🔊" and top_sound.text == "🔊", "üst bardan açılır")

	# Yerleşim taşmaz; karakter ve yazılar çakışmaz.
	var column: Control = timer.get_node("Margin/Column")
	_check(column.get_combined_minimum_size().y <= timer.size.y - 232.0, "odak ekranı sığar (%s)" % column.get_combined_minimum_size())
	var stage: Control = timer.get_node("%Stage")
	_check(stage.size.y >= 300.0, "sahne için yer kalır (%s)" % stage.size)
	_check(timer.get_node("%FocusScene").stage_rect.size == stage.size, "sahne alanı senkron")

	await _click(main.get_node("%BottomNav").get_node("%StatsButton").get_global_rect().get_center())
	_check(not timer.get_node("%FocusScene").is_processing(), "gizliyken ateş animasyonu durur")


func _test_monkeys(main: Control) -> void:
	await _click(main.get_node("%BottomNav").get_node("%IslandButton").get_global_rect().get_center())
	await _frames(2)
	var island: Control = main.get_node("%IslandView")
	var monkey_found := false
	for entry: Dictionary in _dm.data.island_items:
		var node: Node2D = island._item_nodes[entry.id]
		var has_sprite := _count_monkeys(node) > 0
		_check(has_sprite == (entry.type == "monkey"), "%s çizimi" % entry.type)
		if entry.type == "monkey":
			monkey_found = true
			_check(node.get_node("%Emoji").text.is_empty(), "maymunda emoji kalmaz")
	_check(monkey_found, "adada maymun var")

	# Çizilmiş maymun sürüklemeyi engellemez.
	var entry: Dictionary = _dm.data.island_items[0]
	var item: Node2D = island._item_nodes[entry.id]
	var target: Vector2 = island._world.get_global_rect().position + Vector2(300, 400)
	await _press(item.global_position)
	await _move(target)
	await _release(target)
	await create_timer(0.2).timeout
	_check(Vector2(entry.x, entry.y).distance_to(Vector2(300, 400)) < 1.0, "maymun sürüklenir")

	var modal: CanvasLayer = island.get_node("%ShopModal")
	_check(_count_monkeys(modal) == 11, "mağazada çizilmiş 11 korsan")


func _count_monkeys(node: Node) -> int:
	var count := 1 if node.get_script() == SONIC_MONKEY or node.get_script() == CREW_MONKEY else 0
	for child: Node in node.get_children():
		count += _count_monkeys(child)
	return count


func _priority_button(view: Control, index: int) -> Button:
	return view._list.get_child(index).get_child(0).get_child(0).get_child(0).get_child(0)


func _priority_color(view: Control, index: int) -> Color:
	return _priority_button(view, index).get_child(0).color


func _stop_all_sounds() -> void:
	for player: AudioStreamPlayer in _sm._players.values():
		player.stop()


func _all_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text = node.text + "\n"
	for child: Node in node.get_children():
		text += _all_text(child)
	return text


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
