extends Control
class_name GameTitleScreen

onready var _continue_btn := $MarginContainer/VBoxContainer/VBoxContainer/Continue as Button
onready var _new_game_btn := $MarginContainer/VBoxContainer/VBoxContainer/NewGame as Button
onready var _quit_btn := $MarginContainer/VBoxContainer/VBoxContainer/Quit as Button

func _ready() -> void:
    _continue_btn.visible = GameData.last_level != 0
    _continue_btn.connect("pressed", self, "_start_game", [false])
    _new_game_btn.connect("pressed", self, "_start_game", [true])
    _quit_btn.connect("pressed", self, "_quit")

    if GameData.game_finished:
        GameGlobalMusicPlayer.play_stream(GameGlobalMusicPlayer.Track1)
        GameGlobalMusicPlayer.play(64.0)
        $MusicBG.audio_bus_output = "Music"
        $Clock.scale = Vector2(4, 4)
        $Clock._cycle_fx.volume_db = -80
        $Clock._tick_fx.volume_db = -80
        $Clock.start_animation()
        $AnimationPlayer.play("yay")

func _start_game(reset: bool) -> void:
    if reset:
        GameData.save_new_game()

    yield(GameGlobalMusicPlayer.fade_out(), "completed")
    GameGlobalMusicPlayer.stop()
    GameGlobalMusicPlayer.fade_in()
    GameSceneTransitioner.fade_to_cached_scene(GameLoadCache, "GameScreen")

func _quit() -> void:
    get_tree().quit()

func _clear_data():
    GameData.clear_all()
    GameSceneTransitioner.fade_to_cached_scene(GameLoadCache, "TitleScreen")
