extends Node2D
class_name GameRadar

onready var _arrow := $Arrow as Sprite
onready var _animation_player := $AnimationPlayer as AnimationPlayer

func point_to_direction(dir: Vector2) -> void:
    _arrow.rotation = dir.angle()

func startup() -> void:
    _arrow.modulate = Color.white
    _animation_player.play("idle")

func shutdown() -> void:
    _arrow.modulate = Color.black
    _arrow.rotation = 0
    _animation_player.stop()