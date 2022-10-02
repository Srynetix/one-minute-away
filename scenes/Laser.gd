extends Node2D
class_name GameLaser

onready var _line := $Line2D as Line2D
onready var _raycast := $RayCast2D as RayCast2D
onready var _sprite_group := $Sprites as Node2D
onready var _core := $Sprites/Core as Sprite
onready var _anim_player := $AnimationPlayer as AnimationPlayer

export var active := false

var max_length := 1500.0
var continuous := false
var _angle := 0.0
var _last_mirror: Node

func _ready():
    _raycast.enabled = false
    set_angle(_angle)
    charge()

func _process(_delta: float):
    _line.visible = active
    _update_line()

func set_angle(angle: float):
    _angle = angle
    _sprite_group.rotation = angle
    _raycast.cast_to = (Vector2.RIGHT * max_length).rotated(angle)
    _line.points[0] = _sprite_group.position

func _update_line() -> void:
    var length := max_length
    var is_mirror := false
    if _raycast.is_colliding():
        var pt := _raycast.get_collision_point()
        var dist = global_position.distance_to(pt)
        length = min(max_length, dist)

        var collider := _raycast.get_collider()
        if collider.is_in_group("mirrors"):
            collider.activate()
            is_mirror = true
            _last_mirror = collider

        elif collider is GamePlayer:
            var player := collider as GamePlayer
            player.zap()

    if !is_mirror && _last_mirror != null:
        _stop_mirror()

    var target := (Vector2.RIGHT * length).rotated(_angle)
    _line.points[1] = target

func charge() -> void:
    _anim_player.play("charge")

func fire() -> void:
    _raycast.enabled = true
    if continuous:
        _anim_player.play("fire_nonstop")
    else:
        _anim_player.play("fire")

func wait() -> void:
    _raycast.enabled = false
    _anim_player.play("wait")

func stop() -> void:
    active = false
    _raycast.enabled = false
    _anim_player.play("RESET")
    if _last_mirror != null:
        _stop_mirror()

func _stop_mirror() -> void:
    _last_mirror.stop()
    _last_mirror = null