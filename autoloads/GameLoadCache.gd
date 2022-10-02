extends SxLoadCache

func load_resources() -> void:
    # Screens
    store_scene("BootScreen", "res://screens/Boot.tscn")
    store_scene("TitleScreen", "res://screens/Title.tscn")
    store_scene("GameScreen", "res://screens/Game.tscn")
    store_scene("GameOverScreen", "res://screens/GameOver.tscn")

    # Elements
    store_scene("TimeLock", "res://scenes/TimeLock.tscn")
    store_scene("Player", "res://scenes/Player.tscn")
    store_scene("Cube", "res://scenes/Cube.tscn")
    store_scene("Laser", "res://scenes/Laser.tscn")
    store_scene("Sphere", "res://scenes/Sphere.tscn")

    # Levels
    var n := 1
    while true:
        var path := "res://levels/Level%02d.tscn" % n
        var f := File.new()
        if f.file_exists(path):
            store_scene("Level%02d" % n, path)
        else:
            break
        n = n + 1