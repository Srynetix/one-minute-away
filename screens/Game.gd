extends Control
class_name GameScreen

const LEVEL_COUNT = 3

var _level_scenes := {}
var _current_level: GameLevel
var _current_level_idx := 2

func _ready() -> void:
    for n in range(1, LEVEL_COUNT + 1):
        var level_scene := load("res://levels/Level%02d.tscn" % n) as PackedScene
        _level_scenes[n - 1] = level_scene

    # Let's start with the first level
    _load_level(_current_level_idx)

func _restart_current_level() -> void:
    _load_level(_current_level_idx)

func _load_next_level() -> void:
    _current_level_idx += 1
    _load_level(_current_level_idx)

func _load_level(idx: int) -> void:
    if !_level_scenes.has(idx):
        print("END OF THE GAME, BYE")
        GameSceneTransitioner.fade_out()
    else:
        if _current_level != null:
            _current_level.queue_free()

        var level := _level_scenes[idx].instance() as GameLevel
        level.connect("game_over", self, "_restart_current_level")
        level.connect("win", self, "_load_next_level")
        GameSceneTransitioner.fade_in()
        add_child(level)
        _current_level = level
