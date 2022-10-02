extends SxGameData

var last_level: int = 0

func _ready() -> void:
    load_from_disk()
    last_level = load_value("last_level", 0)

func save_progression(level: int) -> void:
    last_level = level
    store_value("last_level", level)
    persist_to_disk()