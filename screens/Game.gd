extends Control
class_name GameScreen

export var initial_level_idx := -1

var _logger := SxLog.get_logger("Game")
var _level_scenes := {}
var _current_level: GameLevel
var _current_level_idx := 0

func _ready() -> void:
    var n := 1
    while true:
        var name = "Level%02d" % n
        if GameLoadCache.has_scene(name):
            _level_scenes[n - 1] = GameLoadCache.load_scene(name)
        else:
            break
        n = n + 1

    _logger.info("%d levels loaded." % (n - 1))
    if initial_level_idx == -1:
        _current_level_idx = GameData.last_level
    else:
        _current_level_idx = initial_level_idx

    _load_level(_current_level_idx)

func _restart_current_level() -> void:
    _load_level(_current_level_idx)

func _load_next_level() -> void:
    _current_level_idx += 1
    _load_level(_current_level_idx)

func _load_level(idx: int) -> void:
    if !_level_scenes.has(idx):
        GameGlobalMusicPlayer.fade_out_on_voice(0)
        GameSceneTransitioner.fade_to_cached_scene(GameLoadCache, "GameOverScreen")
    else:
        GameData.save_progression(_current_level_idx)
        if _current_level != null:
            yield(GameSceneTransitioner.fade_out(), "completed")
            _current_level.queue_free()

        var level := _level_scenes[idx].instance() as GameLevel
        level.connect("game_over", self, "_restart_current_level")
        level.connect("win", self, "_load_next_level")
        GameSceneTransitioner.fade_in()
        add_child(level)
        level.set_level_number(idx + 1)
        _current_level = level
