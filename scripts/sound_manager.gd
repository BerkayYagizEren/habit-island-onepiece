extends Node

signal mute_changed(muted: bool)

const MIX_RATE := 22050
const BYTES_PER_SAMPLE := 2
const MAX_SAMPLE_VALUE := 32767.0
const MAX_POLYPHONY := 4
const MASTER_BUS := 0
const NOISE_SEED := 7

# Sesler üst üste binebilir (tamamlama + muz); tepe değerlerin toplamı 1'i geçmemeli.
const BANANA_PEAK := 0.4
const COMPLETE_PEAK := 0.45
const FANFARE_PEAK := 0.6
const CELEBRATE_PEAK := 0.55
const POP_PEAK := 0.45
const CLICK_PEAK := 0.25

const ATTACK_SECONDS := 0.004
const BELL_OVERTONE := 0.25
const NOTE_C5 := 523.25
const NOTE_E5 := 659.25
const NOTE_G5 := 783.99
const NOTE_B5 := 987.77
const NOTE_C6 := 1046.5
const NOTE_E6 := 1318.51

var _players: Dictionary[String, AudioStreamPlayer] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = NOISE_SEED
	# Üretim baştan yapılır; ilk çalmada GDScript sentezi dokunuşu geciktirirdi.
	_add_player("banana", _synth_banana())
	_add_player("complete", _synth_complete())
	_add_player("timer_finish", _synth_timer_finish())
	_add_player("celebrate", _synth_celebrate())
	_add_player("pop", _synth_pop())
	_add_player("click", _synth_click())
	AudioServer.set_bus_mute(MASTER_BUS, DataManager.data.settings.muted)


func play_banana() -> void:
	_players["banana"].play()


func play_complete() -> void:
	_players["complete"].play()


func play_timer_finish() -> void:
	_players["timer_finish"].play()


func play_celebrate() -> void:
	_players["celebrate"].play()


func play_pop() -> void:
	_players["pop"].play()


func play_click() -> void:
	_players["click"].play()


func mute() -> void:
	_set_muted(true)


func unmute() -> void:
	_set_muted(false)


func toggle_mute() -> void:
	if is_muted():
		unmute()
		play_click()
	else:
		mute()


func is_muted() -> bool:
	return AudioServer.is_bus_mute(MASTER_BUS)


func _set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(MASTER_BUS, muted)
	DataManager.data.settings.muted = muted
	DataManager.save_data()
	mute_changed.emit(muted)


func _add_player(sound_name: String, stream: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.max_polyphony = MAX_POLYPHONY
	add_child(player)
	_players[sound_name] = player


func _synth_banana() -> AudioStreamWAV:
	var buffer := _create_buffer(0.42)
	_add_tone(buffer, 0.0, 0.09, NOTE_B5, NOTE_B5, 0.8, 18.0, BELL_OVERTONE)
	_add_tone(buffer, 0.07, 0.35, NOTE_E6, NOTE_E6, 1.0, 9.0, BELL_OVERTONE)
	return _to_stream(buffer, BANANA_PEAK)


func _synth_complete() -> AudioStreamWAV:
	var buffer := _create_buffer(0.75)
	_add_tone(buffer, 0.0, 0.7, NOTE_C5, NOTE_C5, 1.0, 5.0, BELL_OVERTONE)
	_add_tone(buffer, 0.04, 0.66, NOTE_E5, NOTE_E5, 0.9, 5.0, BELL_OVERTONE)
	_add_tone(buffer, 0.08, 0.62, NOTE_G5, NOTE_G5, 0.8, 5.0, BELL_OVERTONE)
	_add_tone(buffer, 0.12, 0.58, NOTE_C6, NOTE_C6, 0.7, 5.0, BELL_OVERTONE)
	return _to_stream(buffer, COMPLETE_PEAK)


func _synth_timer_finish() -> AudioStreamWAV:
	var buffer := _create_buffer(1.35)
	var note_gap := 0.13
	var melody: Array[float] = [NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6]
	for i: int in melody.size():
		_add_tone(buffer, i * note_gap, 0.25, melody[i], melody[i], 0.9, 7.0, BELL_OVERTONE)
	# Son akor, ezginin bitişinde birlikte çalar ve uzun söner.
	var chord_start := melody.size() * note_gap
	for note: float in [NOTE_G5, NOTE_C6, NOTE_E6]:
		_add_tone(buffer, chord_start, 0.8, note, note, 0.8, 3.5, BELL_OVERTONE)
	return _to_stream(buffer, FANFARE_PEAK)


func _synth_celebrate() -> AudioStreamWAV:
	var buffer := _create_buffer(0.95)
	var note_gap := 0.08
	var melody: Array[float] = [NOTE_G5, NOTE_C6, NOTE_E6, NOTE_C6, NOTE_E6]
	for i: int in melody.size():
		_add_tone(buffer, i * note_gap, 0.2, melody[i], melody[i], 0.9, 10.0, BELL_OVERTONE)
	var chord_start := melody.size() * note_gap
	for note: float in [NOTE_C5, NOTE_G5, NOTE_E6]:
		_add_tone(buffer, chord_start, 0.5, note, note, 0.8, 5.0, BELL_OVERTONE)
	return _to_stream(buffer, CELEBRATE_PEAK)


func _synth_pop() -> AudioStreamWAV:
	var buffer := _create_buffer(0.12)
	_add_tone(buffer, 0.0, 0.11, 620.0, 170.0, 1.0, 28.0, 0.0)
	_add_noise(buffer, 0.012, 0.35)
	return _to_stream(buffer, POP_PEAK)


func _synth_click() -> AudioStreamWAV:
	var buffer := _create_buffer(0.04)
	_add_tone(buffer, 0.0, 0.035, 1500.0, 950.0, 1.0, 90.0, 0.0)
	_add_noise(buffer, 0.004, 0.25)
	return _to_stream(buffer, CLICK_PEAK)


func _create_buffer(seconds: float) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(int(seconds * MIX_RATE))
	return buffer


# PackedFloat32Array değer gibi kopyalanmaz; değişiklik çağıranın dizisine yansır.
func _add_tone(buffer: PackedFloat32Array, start: float, seconds: float, from_hz: float, to_hz: float, amplitude: float, decay: float, overtone: float) -> void:
	var first := int(start * MIX_RATE)
	var count := mini(int(seconds * MIX_RATE), buffer.size() - first)
	var phase := 0.0
	for i: int in count:
		var t := float(i) / MIX_RATE
		var progress := float(i) / count
		phase += TAU * lerpf(from_hz, to_hz, progress) / MIX_RATE
		var sample := sin(phase) + overtone * sin(phase * 2.0)
		buffer[first + i] += sample * amplitude * _envelope(t, decay, progress)


func _add_noise(buffer: PackedFloat32Array, seconds: float, amplitude: float) -> void:
	var count := int(seconds * MIX_RATE)
	for i: int in count:
		buffer[i] += _rng.randf_range(-1.0, 1.0) * amplitude * (1.0 - float(i) / count)


# Başta ve sonda sıfıra inen zarf, hoparlördeki "tık" sesini önler.
func _envelope(t: float, decay: float, progress: float) -> float:
	return minf(t / ATTACK_SECONDS, 1.0) * exp(-decay * t) * minf((1.0 - progress) * 10.0, 1.0)


func _to_stream(buffer: PackedFloat32Array, peak: float) -> AudioStreamWAV:
	var loudest := 0.0
	for sample: float in buffer:
		loudest = maxf(loudest, absf(sample))

	var bytes := PackedByteArray()
	bytes.resize(buffer.size() * BYTES_PER_SAMPLE)
	for i: int in buffer.size():
		bytes.encode_s16(i * BYTES_PER_SAMPLE, int(buffer[i] / loudest * peak * MAX_SAMPLE_VALUE))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = bytes
	return stream
