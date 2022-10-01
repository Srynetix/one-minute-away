extends Area2D
class_name GameTimeLock

signal broken

onready var _animation_player := $AnimationPlayer as AnimationPlayer
onready var _crack_fx := $CrackFX as AudioStreamPlayer
onready var _shape := $CollisionShape2D as CollisionShape2D
onready var _particles := $CPUParticles2D as CPUParticles2D

var hits_needed := 3
var _current_hits := 0

func hit() -> void:
    _current_hits += 1
    if _current_hits >= hits_needed:
        _crack()
    else:
        _animation_player.play("hit")
        _shape.set_deferred("disabled", true)
        yield(_animation_player, "animation_finished")
        _shape.set_deferred("disabled", false)
        _animation_player.play("idle")

func _crack() -> void:
    _shape.set_deferred("disabled", true)
    _animation_player.play("crack")
    _crack_fx.play()
    emit_signal("broken")
    yield(_crack_fx, "finished")
    queue_free()

func freeze_for_eternity() -> void:
    _animation_player.stop(false)
    _particles.emitting = false