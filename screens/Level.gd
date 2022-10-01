extends Control
class_name GameLevel

signal win
signal game_over

export(String, MULTILINE) var help_text := ""

var TimeLockScene := preload("res://scenes/TimeLock.tscn") as PackedScene
var PlayerScene := preload("res://scenes/Player.tscn") as PackedScene
var CubeScene := preload("res://scenes/Cube.tscn") as PackedScene
var SphereScene := preload("res://scenes/Sphere.tscn") as PackedScene

onready var grayscale_fx := $FX/GrayscaleFX as GameGrayscaleFX
onready var bg_grayscale_fx := $Background/GrayscaleFX as GameGrayscaleFX
onready var clock := $Background/Clock as GameClock
onready var chromatic_fx := $FX/BackBufferCopy/BackBufferCopy/ChromaticAberrationFX as GameChromaticAberrationFX
onready var camera := $SxFXCamera as SxFXCamera
onready var motion_blur := $FX/BackBufferCopy/SxMotionBlur as SxMotionBlur
onready var tilemap := $TMForeground as TileMap
onready var time_particles := $Background/TimeParticles as CPUParticles2D
onready var _help_text := $UI/MarginContainer/SxFadingRichTextLabel as SxFadingRichTextLabel

var time_limit := 10.0 * 6
var _elapsed_time := 0.0
var _offset := 1.0 / time_limit
var _t := 0.0
var _last_effect := -1
var _player: GamePlayer = null
var _time_locks := {}
var _is_game_over := false
var _is_camera_rotating := false
var _wrapping_rect: Rect2
var _tracer: SxNodeTracer

func _ready() -> void:
    _help_text.update_text(help_text)
    _help_text.fade_in()

    _tracer = SxNodeTracer.new()
    add_child(_tracer)
    randomize()

    clock.connect("tick_cycle", self, "_on_clock_tick_cycle")
    _spawn_tiles()

    clock.start_animation()
    _update_objects_with_tick_cycle()

func _spawn_tiles() -> void:
    var vp_rect = get_viewport_rect()
    var used_rect = tilemap.get_used_rect()
    var target_rect = vp_rect.expand(used_rect.position * tilemap.cell_size).expand(used_rect.end * tilemap.cell_size)

    _tracer.trace_parameter("Original rect", target_rect)
    _wrapping_rect = target_rect.grow(500)
    _tracer.trace_parameter("Grown rect", _wrapping_rect)

    for pos in tilemap.get_used_cells():
        var tile_idx := tilemap.get_cellv(pos)
        var tile_name := tilemap.tile_set.tile_get_name(tile_idx)

        match tile_name:
            "time_lock":
                var time_lock := TimeLockScene.instance() as GameTimeLock
                time_lock.connect("broken", self, "_on_time_lock_broken", [time_lock])
                time_lock.position = tilemap.map_to_world(pos) + tilemap.cell_size
                add_child(time_lock)
                tilemap.set_cellv(pos, -1)
                _time_locks[time_lock.get_path()] = time_lock
            "player":
                var player := PlayerScene.instance() as GamePlayer
                player.position = tilemap.map_to_world(pos) + tilemap.cell_size / 2
                add_child(player)
                tilemap.set_cellv(pos, -1)
                _player = player
            "cube":
                var cube := CubeScene.instance() as RigidBody2D
                cube.position = tilemap.map_to_world(pos) + tilemap.cell_size / 2
                add_child(cube)
                tilemap.set_cellv(pos, -1)
            "sphere":
                var sphere := SphereScene.instance() as RigidBody2D
                sphere.position = tilemap.map_to_world(pos) + tilemap.cell_size / 2
                add_child(sphere)
                tilemap.set_cellv(pos, -1)

    assert(_player != null, "You need to have a player on your map.")

func _process(delta: float) -> void:
    camera.global_position = _player.global_position

    if _is_game_over:
        return

    chromatic_fx.amount = sin(_t * 4) * 2
    _t = wrapf(_t + delta, 0, PI * 2)

    if _is_camera_rotating:
        camera.rotation += delta * 0.25

    # Nearest time lock
    var nearest := _find_nearest_time_lock_from_player()
    if nearest:
        var dir = _player.global_position.direction_to(nearest.global_position)
        _player.get_radar().startup()
        _player.get_radar().point_to_direction(dir)
    else:
        _player.get_radar().shutdown()

    # Wrap player
    var player_pos = _player.global_position
    if player_pos.y > _wrapping_rect.end.y:
        player_pos.y = _wrapping_rect.position.y
    elif player_pos.y < _wrapping_rect.position.y:
        player_pos.y = _wrapping_rect.end.y
    if player_pos.x > _wrapping_rect.end.x:
        player_pos.x = _wrapping_rect.position.x
    elif player_pos.x < _wrapping_rect.position.x:
        player_pos.x = _wrapping_rect.end.x
    if _player.global_position != player_pos:
        _player.global_position = player_pos

func _on_clock_tick_cycle():
    _elapsed_time += 10.0
    _update_objects_with_tick_cycle()

    if _elapsed_time >= time_limit:
        _game_over()
    else:
        _apply_random_effect()

func _update_objects_with_tick_cycle() -> void:
    _player.set_time_scale(1 - _elapsed_time / time_limit)
    grayscale_fx.ratio = _elapsed_time / time_limit

    var target_scale = max(10.0 * (_elapsed_time / time_limit), 1)
    var tween := get_tree().create_tween()
    tween.tween_property(clock, "scale", Vector2(target_scale, target_scale), 0.25)

func _disable_effects():
    camera.shake_ratio = 0
    chromatic_fx.enabled = false
    motion_blur.strength = 0
    _is_camera_rotating = false
    camera.rotating = false
    camera.rotation = 0

func _apply_random_effect():
    _disable_effects()

    var max_effects = 6
    # var num = 1
    var num = SxRand.range_i(0, max_effects)
    while num == _last_effect:
        num = SxRand.range_i(0, max_effects)
    _last_effect = num

    match num:
        0:
            print("CHROMA")
            chromatic_fx.enabled = true
        1:
            print("SHAKE")
            camera.shake_ratio = 1
        2:
            print("MOTION")
            motion_blur.angle_degrees = 0
            motion_blur.strength = 0.005
        3:
            print("WOOOO")
            _is_camera_rotating = true
            camera.rotating = true
        4:
            print("COMBO 1")
            camera.shake_ratio = 1
            chromatic_fx.enabled = true
        5:
            print("COMBO 2")
            camera.shake_ratio = 1
            motion_blur.strength = 0.005
        var o:
            print("OOOPS %d" % o)

func _on_time_lock_broken(lock: GameTimeLock) -> void:
    _time_locks.erase(lock.get_path())
    if len(_time_locks) == 0:
        _win()
        return

    yield(clock.reclock_10_seconds(), "completed")
    _elapsed_time = max(_elapsed_time - 10, 0)
    _update_objects_with_tick_cycle()
    _disable_effects()

func _find_nearest_time_lock_from_player() -> GameTimeLock:
    var closest: GameTimeLock = null
    var closest_distance := INF

    for path in _time_locks:
        var time_lock := _time_locks[path] as GameTimeLock
        var dist_sq := _player.global_position.distance_squared_to(time_lock.global_position)
        if dist_sq < closest_distance:
            closest_distance = dist_sq
            closest = time_lock
    return closest

func _game_over() -> void:
    _is_game_over = true
    clock.stop_animation()
    _player.freeze_for_eternity()
    time_particles.emitting = false
    _disable_effects()

    for path in _time_locks:
        var time_lock := _time_locks[path] as GameTimeLock
        time_lock.freeze_for_eternity()

    # ...waiiiiiit
    yield(get_tree().create_timer(2), "timeout")

    # ...and animate dissolution
    var bb_dissolve := $FX/BBDissolve as BackBufferCopy
    bb_dissolve.visible = true
    var dissolve := $FX/BBDissolve/DissolveFX as GameDissolveFX
    var tween := get_tree().create_tween()
    tween.tween_property(dissolve, "ratio", 1.0, 4.0)
    yield(tween, "finished")
    emit_signal("game_over")

func _win() -> void:
    _is_game_over = true
    clock.stop_animation()
    _player.freeze()
    _disable_effects()
    bg_grayscale_fx.visible = true
    time_particles.emitting = false

    var tween := get_tree().create_tween()
    tween.tween_property(bg_grayscale_fx, "ratio", 1.0, 1.0)

    # ...waiiiiiit
    yield(get_tree().create_timer(2), "timeout")
    yield(GameSceneTransitioner.fade_out(), "completed")
    emit_signal("win")
