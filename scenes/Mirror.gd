tool
extends StaticBody2D
class_name GameMirror

export var inverted := false

onready var _laser := $Laser as GameLaser
var _activated := false

func _ready():
    _laser.get_node("Sprites").visible = false
    _laser._raycast.add_exception(self)
    _laser.continuous = true
    _laser.visible = true
    _laser.stop()
    _laser.get_node("FX").stream = null
    _laser.get_node("Load").stream = null

    if inverted:
        _laser.set_angle(PI/2)

func activate() -> void:
    if _activated:
        return

    _activated = true
    _laser.fire()

func stop() -> void:
    _laser.stop()
    _activated = false

func _process(_delta: float) -> void:
    if Engine.editor_hint:
        update()

func _draw() -> void:
    if Engine.editor_hint:
        var target = Vector2.RIGHT * 100
        if inverted:
            target = target.rotated(PI/2)

        draw_line(Vector2.ZERO, target, Color.green, 4.0)
        draw_circle(target, 4, Color.aqua)
