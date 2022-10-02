extends SxGameData

var last_level: int = 0
var game_finished := false

func _ready() -> void:
    default_file_path = "user://ld51_save.dat"

    load_from_disk()
    last_level = load_value("last_level", 0)
    game_finished = load_value("game_finished", false)

func clear_all() -> void:
    .clear_all()
    last_level = 0
    game_finished = false
    persist_to_disk()

func save_progression(level: int) -> void:
    last_level = level
    store_value("last_level", level)
    persist_to_disk()

func save_game_finished() -> void:
    game_finished = true
    store_value("game_finished", true)
    persist_to_disk()

func save_new_game() -> void:
    save_progression(0)