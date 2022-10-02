extends Control
class_name GameBootScreen

func _go_to_title() -> void:
    GameSceneTransitioner.fade_to_cached_scene(GameLoadCache, "TitleScreen")