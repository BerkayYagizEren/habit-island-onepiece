extends Node

signal bananas_changed(amount: int)
signal xp_changed(xp: int, level: int)
signal habits_updated()
signal island_updated()
signal today_updated()

const SAVE_PATH := "user://save_data.json"
const TEMP_SAVE_PATH := "user://save_data.json.tmp"
const CORRUPT_SAVE_PATH := "user://save_data.json.corrupt"

const STARTING_BANANAS := 50
const HABIT_BANANA_REWARD := 5
const HABIT_XP_REWARD := 10
const XP_PER_LEVEL := 100
const SECONDS_PER_DAY := 86400
const CHECK_IN_REWARD := 15
const DAILY_QUEST_REWARD := 20
const DAILY_QUEST_XP := 20
const HABIT_PRIORITIES: Array[String] = ["high", "medium", "low"]
const DEFAULT_HABIT_PRIORITY := "low"
const DAILY_QUESTS: Array[String] = [
	"Bugün kendine bir iyilik yap: 15 dk odaklan veya bir alışkanlık tamamla.",
	"Telefonu bir kenara bırak ve 10 dakika yürüyüşe çık.",
	"Bir bardak su iç ve masanı toparla.",
	"Ertelediğin en küçük işi şimdi bitir.",
	"Beş dakika esne, omuzlarını gevşet.",
	"Bugün seni mutlu eden üç şeyi yaz.",
	"Sevdiğin birine güzel bir mesaj gönder.",
	"10 sayfa kitap oku.",
]

# Eşya koordinatları ada dünyasının (720x1000) içindeki merkez noktalarıdır.
# 1. seviyenin sınırları; büyüyen ada için get_island_bounds kullanılır.
const ISLAND_BOUNDS := Rect2(80, 150, 560, 700)
const MIN_ISLAND_LEVEL := 1
const MAX_ISLAND_LEVEL := 4
const ISLAND_GROWTH_PER_LEVEL := 1.19
# Anahtar: ulaşılacak seviye.
const ISLAND_EXPANSION_COSTS: Dictionary[int, int] = {2: 200, 3: 450, 4: 800}
const ISLAND_ITEMS := {
	"palm": {"icon": "🌴", "name": "Palmiye Ağacı", "price": 20},
	"flower": {"icon": "🌺", "name": "Tropik Çiçek", "price": 15},
	"monkey": {"icon": "👒", "name": "Monkey D. Luffy", "price": 80, "variant": "sonic", "bubble": "🍖!"},
	"zoro": {"icon": "⚔", "name": "Roronoa Zoro", "price": 100, "variant": "zoro", "bubble": "⚔!"},
	"sanji": {"icon": "🌀", "name": "Sanji", "price": 100, "variant": "sanji", "bubble": "🔥!"},
	"chopper": {"icon": "🦌", "name": "Tony Tony Chopper", "price": 90, "variant": "chopper", "bubble": "🦌!"},
	"nami": {"icon": "🍊", "name": "Nami", "price": 90, "variant": "nami", "bubble": "🍊!"},
	"usopp": {"icon": "🎯", "name": "Usopp", "price": 85, "variant": "usopp", "bubble": "🎯!"},
	"robin": {"icon": "🌸", "name": "Nico Robin", "price": 110, "variant": "robin", "bubble": "🌸!"},
	"franky": {"icon": "🦾", "name": "Franky", "price": 115, "variant": "franky", "bubble": "⭐!"},
	"brook": {"icon": "💀", "name": "Brook", "price": 95, "variant": "brook", "bubble": "🎵!"},
	"jinbe": {"icon": "🥋", "name": "Jinbe", "price": 120, "variant": "jinbe", "bubble": "🌊!"},
	"gear5": {"icon": "⚡", "name": "Gear 5 Nika Luffy", "price": 250, "variant": "gear5", "bubble": "⚡!"},
	"meat": {"icon": "🍖", "name": "Kemikli Korsan Eti", "price": 35},
	"jolly_roger": {"icon": "🏴‍☠", "name": "Hasır Şapka Bayrağı", "price": 50},
	"gomu_fruit": {"icon": "🍈", "name": "Gomu Gomu no Mi", "price": 75},
	"campfire": {"icon": "🔥", "name": "Kamp Ateşi", "price": 30},
	"tent": {"icon": "⛺", "name": "Macera Çadırı", "price": 40},
	"chest": {"icon": "📦", "name": "Hazine Sandığı", "price": 60},
	"ship": {"icon": "⛵", "name": "Korsan Gemisi", "price": 100},
	"monkey_knuckles": {"icon": "🐵", "name": "Kızıl Savaşçı", "price": 100, "variant": "knuckles"},
	"monkey_tails": {"icon": "🐵", "name": "İki Kuyruklu Mucid", "price": 90, "variant": "tails"},
	"monkey_shadow": {"icon": "🐵", "name": "Karanlık Gölge", "price": 140, "variant": "shadow"},
	"monkey_super": {"icon": "🐵", "name": "Altın Süper Maymun", "price": 250, "variant": "super"},
}
const FREE_SPOT_ATTEMPTS := 40
const FREE_SPOT_MIN_RADIUS := 60.0
const FREE_SPOT_MAX_RADIUS := 300.0
const FREE_SPOT_MIN_DISTANCE := 96.0

var data: Dictionary = _default_data()


func _ready() -> void:
	load_data()
	check_day_reset()


func _notification(what: int) -> void:
	# Uygulama gece boyunca arka planda kalmış olabilir.
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		check_day_reset()


func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary:
			data = _sanitized(parsed)
		else:
			# Bozuk dosyanın üzerine yazılmasın, elle kurtarılabilsin.
			push_error("Save file is corrupt, moving it to %s" % CORRUPT_SAVE_PATH)
			DirAccess.rename_absolute(SAVE_PATH, CORRUPT_SAVE_PATH)
			data = _default_data()
			save_data()
	else:
		data = _default_data()
		save_data()

	bananas_changed.emit(data.bananas)
	xp_changed.emit(data.xp, data.level)
	habits_updated.emit()
	island_updated.emit()
	today_updated.emit()


func save_data() -> void:
	# Önce geçici dosyaya yazılır; yazma yarıda kesilirse eski kayıt sağlam kalır.
	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	var error := DirAccess.rename_absolute(TEMP_SAVE_PATH, SAVE_PATH)
	if error != OK:
		push_error("Could not replace save file: %s" % error_string(error))


func add_bananas(amount: int) -> void:
	if amount <= 0:
		return
	check_day_reset()
	_earn_bananas(amount)
	save_data()
	today_updated.emit()


func spend_bananas(amount: int) -> bool:
	if amount < 0 or amount > data.bananas:
		return false
	_change_bananas(-amount)
	save_data()
	return true


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	_gain_xp(amount)
	save_data()


func check_day_reset() -> void:
	var today := _today()
	var changed := false
	for habit: Dictionary in data.habits:
		var last_date: String = habit.last_completed_date
		if last_date == today:
			continue
		if habit.completed_today:
			habit.completed_today = false
			changed = true
		if habit.streak > 0 and _days_between(last_date, today) > 1:
			habit.streak = 0
			changed = true

	var today_changed := _refresh_today(today)
	if changed or today_changed:
		save_data()
	if changed:
		habits_updated.emit()
	if today_changed:
		today_updated.emit()


func add_habit(title: String) -> String:
	var clean_title := title.strip_edges()
	if clean_title.is_empty():
		return ""
	var habit_id := _generate_id("habit")
	data.habits.append({
		"id": habit_id,
		"title": clean_title,
		"completed_today": false,
		"streak": 0,
		"last_completed_date": "",
		"set_best_streak": false,
		"priority": DEFAULT_HABIT_PRIORITY,
	})
	save_data()
	habits_updated.emit()
	return habit_id


func toggle_habit(habit_id: String) -> void:
	check_day_reset()
	var habit := _find_by_id(data.habits, habit_id)
	if habit.is_empty():
		return

	if habit.completed_today:
		# Ödül harcandıysa geri alma reddedilir; yoksa tamamla-harca-geri al
		# döngüsüyle sınırsız muz kazanılabilir.
		if data.bananas < HABIT_BANANA_REWARD or data.xp < HABIT_XP_REWARD:
			return
		_change_bananas(-HABIT_BANANA_REWARD)
		data.xp -= HABIT_XP_REWARD
		xp_changed.emit(data.xp, data.level)
		habit.completed_today = false
		data.today_stats.habits_completed = maxi(data.today_stats.habits_completed - 1, 0)
		data.today_stats.bananas_earned = maxi(data.today_stats.bananas_earned - HABIT_BANANA_REWARD, 0)
		# Yanlışlıkla işaretleme kalıcı rekor bırakmasın.
		if habit.set_best_streak and habit.streak == data.stats.best_streak:
			data.stats.best_streak = _highest_other_streak(habit, habit.streak - 1)
		habit.set_best_streak = false
		habit.streak -= 1
		# check_day_reset kırık serileri sıfırladığı için kalan seri dünde biter.
		habit.last_completed_date = _date_string_days_before(_today(), 1) if habit.streak > 0 else ""
		data.stats.habits_completed_total = maxi(data.stats.habits_completed_total - 1, 0)
	else:
		_earn_bananas(HABIT_BANANA_REWARD)
		_gain_xp(HABIT_XP_REWARD)
		habit.completed_today = true
		data.today_stats.habits_completed += 1
		habit.streak += 1
		habit.set_best_streak = habit.streak > data.stats.best_streak
		data.stats.best_streak = maxi(data.stats.best_streak, habit.streak)
		habit.last_completed_date = _today()
		data.stats.habits_completed_total += 1

	save_data()
	habits_updated.emit()
	today_updated.emit()


func cycle_habit_priority(habit_id: String) -> void:
	var habit := _find_by_id(data.habits, habit_id)
	if habit.is_empty():
		return
	var next_index := (HABIT_PRIORITIES.find(habit.priority) + 1) % HABIT_PRIORITIES.size()
	habit.priority = HABIT_PRIORITIES[next_index]
	save_data()
	habits_updated.emit()


func delete_habit(habit_id: String) -> void:
	check_day_reset()
	var habit := _find_by_id(data.habits, habit_id)
	if habit.is_empty():
		return
	# Silinen alışkanlık sayılmaya devam ederse şeritte 2/1 gibi bir oran görünürdü.
	if habit.completed_today:
		data.today_stats.habits_completed = maxi(data.today_stats.habits_completed - 1, 0)
	data.habits.erase(habit)
	save_data()
	habits_updated.emit()
	today_updated.emit()


func place_island_item(type: String, pos: Vector2) -> String:
	var item_id := _generate_id("item")
	data.island_items.append({
		"id": item_id,
		"type": type,
		"x": pos.x,
		"y": pos.y,
	})
	save_data()
	island_updated.emit()
	return item_id


func update_item_position(item_id: String, pos: Vector2) -> void:
	var item := _find_by_id(data.island_items, item_id)
	if item.is_empty():
		return
	item.x = pos.x
	item.y = pos.y
	save_data()
	island_updated.emit()


func record_focus_session(minutes: int) -> void:
	if minutes <= 0:
		return
	check_day_reset()
	# Sinyalleri dinleyen istatistik ekranı güncel süreyi görsün diye önce yazılır.
	data.stats.total_focus_minutes += minutes
	data.today_stats.focus_minutes += minutes
	_earn_bananas(minutes)
	_gain_xp(minutes)
	save_data()
	today_updated.emit()


func complete_daily_quest() -> bool:
	check_day_reset()
	if data.daily_quest.completed:
		return false
	data.daily_quest.completed = true
	_earn_bananas(data.daily_quest.reward)
	_gain_xp(DAILY_QUEST_XP)
	save_data()
	today_updated.emit()
	return true


func reroll_daily_quest() -> bool:
	check_day_reset()
	if data.daily_quest.completed:
		return false
	var options := DAILY_QUESTS.filter(func(text: String) -> bool: return text != data.daily_quest.text)
	data.daily_quest.text = options.pick_random()
	save_data()
	today_updated.emit()
	return true


func check_in_daily() -> bool:
	check_day_reset()
	if has_checked_in_today():
		return false
	data.last_check_in_date = _today()
	_earn_bananas(CHECK_IN_REWARD)
	save_data()
	today_updated.emit()
	return true


func has_checked_in_today() -> bool:
	return data.last_check_in_date == _today()


func get_daily_quest_seconds_left() -> int:
	return maxi(data.daily_quest.expires_at - int(Time.get_unix_time_from_system()), 0)


# Bir sonraki seviyenin fiyatı; ada en büyük halindeyse -1.
func get_next_expansion_cost() -> int:
	return ISLAND_EXPANSION_COSTS.get(data.island_level + 1, -1)


func expand_island() -> bool:
	var cost := get_next_expansion_cost()
	if cost < 0 or cost > data.bananas:
		return false
	# Muz sinyalini dinleyen mağaza bir sonraki seviyenin fiyatını görsün diye önce yazılır.
	data.island_level += 1
	_change_bananas(-cost)
	save_data()
	island_updated.emit()
	return true


func get_island_scale() -> float:
	return pow(ISLAND_GROWTH_PER_LEVEL, data.island_level - MIN_ISLAND_LEVEL)


func get_island_bounds() -> Rect2:
	var grown := ISLAND_BOUNDS.size * get_island_scale()
	return Rect2(ISLAND_BOUNDS.get_center() - grown / 2.0, grown)


func find_free_island_spot() -> Vector2:
	var center := get_island_bounds().get_center()
	var max_radius := FREE_SPOT_MAX_RADIUS * get_island_scale()
	var best_spot := center
	var best_distance := -1.0
	for attempt: int in FREE_SPOT_ATTEMPTS:
		# Önce merkeze yakın aranır; ada kalabalıksa arama alanı genişler.
		var radius := lerpf(FREE_SPOT_MIN_RADIUS, max_radius, float(attempt) / FREE_SPOT_ATTEMPTS)
		var offset := Vector2.from_angle(randf() * TAU) * randf() * radius
		var spot := clamp_to_island(center + offset)
		var distance := _distance_to_nearest_item(spot)
		if distance >= FREE_SPOT_MIN_DISTANCE:
			return spot
		if distance > best_distance:
			best_distance = distance
			best_spot = spot
	return best_spot


func clamp_to_island(pos: Vector2) -> Vector2:
	var bounds := get_island_bounds()
	return pos.clamp(bounds.position, bounds.end)


# Seviye atlayınca data.xp sıfırlandığı için önceki seviyelerin XP'si eklenir.
func get_total_xp() -> int:
	return data.level * (data.level - 1) / 2 * XP_PER_LEVEL + data.xp


func _distance_to_nearest_item(pos: Vector2) -> float:
	var nearest := INF
	for item: Dictionary in data.island_items:
		nearest = minf(nearest, pos.distance_to(Vector2(item.x, item.y)))
	return nearest


func _highest_other_streak(excluded_habit: Dictionary, floor_streak: int) -> int:
	var highest := floor_streak
	for habit: Dictionary in data.habits:
		if habit != excluded_habit:
			highest = maxi(highest, habit.streak)
	return highest


# Harcama ve geri alma kazanç sayılmaz; bugünkü kazanç yalnızca buradan artar.
func _earn_bananas(amount: int) -> void:
	data.today_stats.bananas_earned += amount
	_change_bananas(amount)


func _change_bananas(delta: int) -> void:
	data.bananas += delta
	bananas_changed.emit(data.bananas)


func _gain_xp(amount: int) -> void:
	data.xp += amount
	while data.xp >= data.level * XP_PER_LEVEL:
		data.xp -= data.level * XP_PER_LEVEL
		data.level += 1
	xp_changed.emit(data.xp, data.level)


func _find_by_id(entries: Array, id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if entry.id == id:
			return entry
	return {}


func _generate_id(prefix: String) -> String:
	return "%s_%d_%d" % [prefix, int(Time.get_unix_time_from_system()), randi()]


func _today() -> String:
	return Time.get_date_string_from_system()


func _refresh_today(today: String) -> bool:
	if data.today_stats.date != today:
		data.today_stats = _new_today_stats()
		data.daily_quest = _new_daily_quest()
		return true
	# Saat geri alındıysa veya saat dilimi değiştiyse gün bitmeden süre dolabilir.
	if data.daily_quest.expires_at <= int(Time.get_unix_time_from_system()):
		data.daily_quest.expires_at = _next_midnight_unix()
		return true
	return false


func _new_today_stats() -> Dictionary:
	return {
		"date": _today(),
		"habits_completed": 0,
		"focus_minutes": 0,
		"bananas_earned": 0,
	}


func _new_daily_quest() -> Dictionary:
	return {
		"text": DAILY_QUESTS.pick_random(),
		"reward": DAILY_QUEST_REWARD,
		"completed": false,
		"expires_at": _next_midnight_unix(),
	}


func _next_midnight_unix() -> int:
	var now := Time.get_time_dict_from_system()
	var seconds_today: int = now.hour * 3600 + now.minute * 60 + now.second
	return int(Time.get_unix_time_from_system()) + SECONDS_PER_DAY - seconds_today


# Tarihler aynı saat dilimi varsayımıyla çevrildiği için yaz saati farkı etkilemez.
func _days_between(from_date: String, to_date: String) -> int:
	if not _is_valid_date(from_date):
		return 2 # Tarih yoksa seri kırılmış sayılır.
	var from_unix := Time.get_unix_time_from_datetime_string(from_date)
	var to_unix := Time.get_unix_time_from_datetime_string(to_date)
	return (to_unix - from_unix) / SECONDS_PER_DAY


func _date_string_days_before(date: String, days: int) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date)
	return Time.get_date_string_from_unix_time(unix - days * SECONDS_PER_DAY)


func _is_valid_date(date: String) -> bool:
	var parts := date.split("-")
	return parts.size() == 3 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()


func _default_data() -> Dictionary:
	return {
		"bananas": STARTING_BANANAS,
		"xp": 0,
		"level": 1,
		"habits": [],
		"island_items": [],
		"island_level": MIN_ISLAND_LEVEL,
		"stats": {
			"total_focus_minutes": 0,
			"habits_completed_total": 0,
			"best_streak": 0,
		},
		"settings": {
			"muted": false,
		},
		"today_stats": _new_today_stats(),
		"daily_quest": _new_daily_quest(),
		"last_check_in_date": "",
	}


# JSON tüm sayıları float döndürür ve dosya elle değiştirilmiş olabilir.
func _sanitized(raw: Dictionary) -> Dictionary:
	var result := _default_data()
	result.bananas = maxi(_to_int(raw.get("bananas"), STARTING_BANANAS), 0)
	result.xp = maxi(_to_int(raw.get("xp"), 0), 0)
	result.level = maxi(_to_int(raw.get("level"), 1), 1)

	result.island_level = clampi(_to_int(raw.get("island_level"), MIN_ISLAND_LEVEL), MIN_ISLAND_LEVEL, MAX_ISLAND_LEVEL)

	for habit: Variant in _to_array(raw.get("habits")):
		if habit is Dictionary and habit.get("id") is String:
			result.habits.append({
				"id": habit.id,
				"title": str(habit.get("title", "")),
				"completed_today": habit.get("completed_today") == true,
				"streak": maxi(_to_int(habit.get("streak"), 0), 0),
				"last_completed_date": str(habit.get("last_completed_date", "")),
				"set_best_streak": habit.get("set_best_streak") == true,
				"priority": _to_priority(habit.get("priority")),
			})

	for item: Variant in _to_array(raw.get("island_items")):
		if item is Dictionary and item.get("id") is String:
			result.island_items.append({
				"id": item.id,
				"type": str(item.get("type", "")),
				"x": _to_float(item.get("x")),
				"y": _to_float(item.get("y")),
			})

	var stats: Variant = raw.get("stats")
	if stats is Dictionary:
		result.stats.total_focus_minutes = maxi(_to_int(stats.get("total_focus_minutes"), 0), 0)
		result.stats.habits_completed_total = maxi(_to_int(stats.get("habits_completed_total"), 0), 0)
		result.stats.best_streak = maxi(_to_int(stats.get("best_streak"), 0), 0)

	var settings: Variant = raw.get("settings")
	if settings is Dictionary:
		result.settings.muted = settings.get("muted") == true

	var today_stats: Variant = raw.get("today_stats")
	if today_stats is Dictionary:
		result.today_stats.date = str(today_stats.get("date", ""))
		result.today_stats.habits_completed = maxi(_to_int(today_stats.get("habits_completed"), 0), 0)
		result.today_stats.focus_minutes = maxi(_to_int(today_stats.get("focus_minutes"), 0), 0)
		result.today_stats.bananas_earned = maxi(_to_int(today_stats.get("bananas_earned"), 0), 0)
	else:
		# Eski kayıtta bugün tamamlananlar şeritte eksik görünmesin.
		result.today_stats.habits_completed = result.habits.filter(func(habit: Dictionary) -> bool: return habit.completed_today).size()

	var quest: Variant = raw.get("daily_quest")
	if quest is Dictionary and quest.get("text") is String and not quest.text.is_empty():
		result.daily_quest.text = quest.text
		result.daily_quest.reward = maxi(_to_int(quest.get("reward"), DAILY_QUEST_REWARD), 0)
		result.daily_quest.completed = quest.get("completed") == true
		result.daily_quest.expires_at = maxi(_to_int(quest.get("expires_at"), 0), 0)

	result.last_check_in_date = str(raw.get("last_check_in_date", ""))

	# Faz 3 öncesi kayıtlarda rekor alanı yok; en azından mevcut seriler sayılır.
	for habit: Dictionary in result.habits:
		result.stats.best_streak = maxi(result.stats.best_streak, habit.streak)

	return result


func _to_priority(value: Variant) -> String:
	return value if value is String and HABIT_PRIORITIES.has(value) else DEFAULT_HABIT_PRIORITY


func _to_int(value: Variant, fallback: int) -> int:
	return int(value) if value is float or value is int else fallback


func _to_float(value: Variant) -> float:
	return float(value) if value is float or value is int else 0.0


func _to_array(value: Variant) -> Array:
	return value if value is Array else []
