extends Node2D
class_name GameClock

signal tick
signal tick_cycle

onready var _cadran := $Cadran as Sprite
onready var _tick := $Tick as Sprite
onready var _tick_tween := $TickTween as Tween
onready var _tick_fx := $TickFX as AudioStreamPlayer
onready var _cycle_fx := $CycleFX as AudioStreamPlayer

var _animation_running := false

func start_animation() -> void:
    _animation_running = true
    _tick_animation()

func _play_tick_sound() -> void:
    _tick_fx.play()

func reclock_10_seconds() -> void:
    _animation_running = false
    _tick_tween.stop_all()
    _cadran.rotation_degrees = 0
    _tick.rotation_degrees = 0

    _tick_tween.interpolate_property(_cadran, "rotation_degrees", _cadran.rotation_degrees, _cadran.rotation_degrees + 360, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
    _tick_tween.interpolate_property(_tick, "rotation_degrees", _tick.rotation_degrees, _tick.rotation_degrees - 360, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
    _tick_tween.start()

    yield(_tick_tween, "tween_all_completed")

    _cadran.rotation_degrees = fmod(_cadran.rotation_degrees, 360.0)
    _tick.rotation_degrees = fmod(_tick.rotation_degrees, -360.0)

    yield(get_tree().create_timer(0.5), "timeout")

    _animation_running = true
    _tick_animation()

func _tick_animation() -> void:
    _tick_tween.interpolate_property(_cadran, "rotation_degrees", _cadran.rotation_degrees, _cadran.rotation_degrees - 360 / 10, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
    _tick_tween.interpolate_property(_tick, "rotation_degrees", _tick.rotation_degrees, _tick.rotation_degrees + 360 / 10, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
    _tick_tween.interpolate_callback(self, 0.4, "_play_tick_sound")
    _tick_tween.start()

    yield(_tick_tween, "tween_all_completed")

    _cadran.rotation_degrees = fmod(_cadran.rotation_degrees, -360.0)
    _tick.rotation_degrees = fmod(_tick.rotation_degrees, 360.0)

    if _animation_running:
        if _tick.rotation_degrees == 0.0:
            _cycle_fx.play()
            emit_signal("tick_cycle")
        else:
            emit_signal("tick")

        yield(get_tree().create_timer(0.5), "timeout")
        if _animation_running:
            _tick_animation()

func stop_animation() -> void:
    _animation_running = false