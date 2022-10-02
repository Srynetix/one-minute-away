extends ColorRect
class_name GameMusicBG

export var audio_bus_output := "Master" setget _set_bus_output
export var vu_count := 16
export var min_freq := 200.0
export var max_freq := 8000.0
export var min_db := 60.0

var factor := 0.5
var spectrum: AudioEffectSpectrumAnalyzerInstance
var tracer: SxNodeTracer
var _vu_values := []
var _frozen := false

func freeze():
    _frozen = true

func _ready() -> void:
    _set_bus_output(audio_bus_output)

    for _i in range(vu_count):
        _vu_values.append(0.0)

func _set_bus_output(value: String) -> void:
    audio_bus_output = value
    var bus := AudioServer.get_bus_index(audio_bus_output)
    spectrum = AudioServer.get_bus_effect_instance(bus, 0)

func _process(_delta: float) -> void:
    if !_frozen:
        update()

func _draw() -> void:
    var rect := get_viewport_rect().size
    var width := rect.x
    var height := rect.y

    var w := width / float(vu_count)
    var prev_hz := min_freq
    for i in range(0, vu_count):
        var hz := i * max_freq / vu_count
        var magnitude := spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
        var energy := clamp((min_db + linear2db(magnitude)) / min_db, 0, 1)
        var prev_energy := _vu_values[i] as float
        var new_energy := lerp(prev_energy, energy, 0.1) as float
        var bar_height := new_energy * height
        var color = lerp(Color.white, Color.yellow, clamp(new_energy, 0, 0.5) * 2)
        draw_rect(Rect2(w * i, height - bar_height, w, bar_height), SxColor.with_alpha_f(color, 0.5))
        prev_hz = hz
        _vu_values[i] = new_energy
