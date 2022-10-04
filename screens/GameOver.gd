extends Control

onready var _label := $Label as RichTextLabel
onready var _chroma_fx := $ChromaticAberrationFX as SxFXChromaticAberration
onready var _clock := $Clock as GameClock
onready var _grayscale_fx := $BackBufferCopy/GrayscaleFX as SxFXGrayscale

var _tracer: SxNodeTracer

var _elapsed_time := 0.0
var _done := false
var _count := 0

func _ready() -> void:
    var vp_size := get_viewport_rect().size
    _tracer = SxNodeTracer.new()
    add_child(_tracer)

    _label.rect_position.y += vp_size.y

    GameGlobalMusicPlayer.fade_in()
    GameGlobalMusicPlayer.play_stream(GameGlobalMusicPlayer.Track1)

    _clock.start_animation()
    _clock._tick_fx.volume_db = -60
    _clock._cycle_fx.volume_db = -60
    _clock.connect("tick_cycle", self, "_tick_tack")

func _tick_tack() -> void:
    _count += 1
    if _count == 6:
        _this_is_the_end()

func _this_is_the_end() -> void:
    _done = true
    _grayscale_fx.ratio = 1
    _clock.stop_animation()

    var a_tween := get_tree().create_tween()
    a_tween.tween_property(GameGlobalMusicPlayer, "pitch_scale", 0.5, 0.25)
    a_tween.tween_property(GameGlobalMusicPlayer, "volume_db", -60, 0.5)
    yield(a_tween, "finished")

    # Reset
    GameGlobalMusicPlayer.stop()
    GameGlobalMusicPlayer.pitch_scale = 1.0
    GameGlobalMusicPlayer.volume_db = 0

    yield(get_tree().create_timer(4.0), "timeout")

    var bb_dissolve := $BBDissolve as BackBufferCopy
    bb_dissolve.visible = true
    var dissolve := $BBDissolve/DissolveFX as SxFXDissolve
    var tween := get_tree().create_tween()
    tween.tween_property(dissolve, "ratio", 1.0, 4.0)
    yield(tween, "finished")

    GameData.save_game_finished()
    GameSceneTransitioner.fade_to_cached_scene(GameLoadCache, "BootScreen")

func _process(delta: float):
    if _done:
        return

    _label.rect_position.y -= delta * 50
    _elapsed_time += delta

    if _elapsed_time > 25:
        _clock._tick_fx.volume_db = linear2db((_elapsed_time - 25) / 60)

    if _elapsed_time > 35:
        _chroma_fx.amount = clamp(_chroma_fx.amount + delta * 0.05, 0, 5)
        _clock.modulate.a = ((_elapsed_time - 35) / 30.0)

    _tracer.trace_parameter("Time", _elapsed_time)
    _tracer.trace_parameter("Chroma FX", _chroma_fx.amount)
    _tracer.trace_parameter("Clock A", _clock.modulate.a)
