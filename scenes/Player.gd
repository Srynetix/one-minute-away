extends KinematicBody2D
class_name GamePlayer

onready var _sprite := $Sprite as Sprite
onready var _animation_player := $AnimationPlayer as AnimationPlayer
onready var _hand := $Hand as Area2D
onready var _hand_shape := $Hand/CollisionShape2D as CollisionShape2D
onready var _radar := $Radar as GameRadar
onready var _punch_fx := $PunchFX as AudioStreamPlayer
onready var _initial_position := position

enum State {
    Idle,
    Jumping,
    Moving,
    Punching
}

var _time_scale := 1.0
var _speed := 40.0
var _acceleration := Vector2.ZERO
var _gravity := Vector2(0, 25.0)
var _jump_speed := 550.0
var _max_jumps := 2
var _max_velocity := 400.0
var _max_fall_velocity := 800.0
var _current_jumps := 0
var _velocity := Vector2.ZERO
var _friction_coef := 0.85
var _handle_input := true
var _state := State.Idle as int
var _zapped := false

var _tracer: SxNodeTracer

func _ready() -> void:
    _hand.connect("area_entered", self, "_on_area_hit")
    _hand.connect("body_entered", self, "_on_body_hit")
    _tracer = SxNodeTracer.new()
    add_child(_tracer)

func set_time_scale(value: float) -> void:
    _time_scale = value
    _animation_player.playback_speed = value

func get_radar() -> GameRadar:
    return _radar

func _physics_process(_delta: float) -> void:
    if _zapped:
        return

    _acceleration = Vector2.ZERO

    var direction := Vector2.ZERO

    if _handle_input:
        if Input.is_action_pressed("ui_left"):
            direction.x += -1
        if Input.is_action_pressed("ui_right"):
            direction.x += 1

    if is_on_floor() || is_on_wall():
        _current_jumps = 0

    if _handle_input && Input.is_action_just_pressed("jump"):
        # Jump mid-air
        if !is_on_floor() && !is_on_wall():
            if _current_jumps == 0:
                # Force one jump
                _current_jumps += 1

        if _current_jumps < _max_jumps:
            _acceleration += Vector2.UP * _jump_speed + (Vector2.UP * _velocity.y)
            _current_jumps += 1

    elif _handle_input && Input.is_action_just_released("jump"):
        if _velocity.y < 0:
            _acceleration += Vector2.UP * _velocity.y / 2

    if !is_on_floor() && _velocity.y < 0 && _state != State.Punching:
        _change_state(State.Jumping)
    elif _state == State.Jumping && is_on_floor() && _state != State.Punching:
        _change_state(State.Idle)

    if _handle_input && _state != State.Punching && Input.is_action_just_pressed("punch"):
        _change_state(State.Punching)

    if direction.length() > 0:
        # Movement
        _acceleration += direction * _speed * _time_scale;
        if direction.x < 0:
            _sprite.flip_h = true
            _hand.position.x = abs(_hand.position.x) * -1
        elif direction.x > 0:
            _sprite.flip_h = false
            _hand.position.x = abs(_hand.position.x)

        if _state != State.Punching:
            if is_on_floor():
                _change_state(State.Moving)
            else:
                _change_state(State.Jumping)
    else:
        # Friction
        _acceleration += Vector2(lerp(-_velocity.x, 0, 1 - _friction_coef), 0)
        if !_state in [State.Punching, State.Jumping]:
            _change_state(State.Idle)

    # Gravity
    _acceleration += _gravity * _time_scale

    # ...Integration!
    _velocity += _acceleration
    _velocity.x = clamp(_velocity.x, -_max_velocity * _time_scale, _max_velocity * _time_scale)
    _velocity.y = min(_velocity.y, _max_fall_velocity * _time_scale)

    _velocity = move_and_slide(_velocity, Vector2.UP, true, 4, 0.7853, false)

    _tracer.trace_parameter("position", position)

func _update_animation() -> void:
    match _state:
        State.Idle:
            _animation_player.play("idle")
        State.Jumping:
            _animation_player.play("jump")
        State.Moving:
            _animation_player.play("move")
        State.Punching:
            _animation_player.play("punch")

func _change_state(state: int) -> void:
    if _state != state:
        _state = state
        _update_animation()

        if _state == State.Punching:
            _hand_shape.disabled = false
            yield(_animation_player, "animation_finished")
            _hand_shape.disabled = true
            _change_state(State.Idle)

func freeze_for_eternity() -> void:
    _handle_input = false
    _velocity = Vector2.ZERO
    _gravity = Vector2.ZERO
    _friction_coef = 0
    _radar.shutdown()

func freeze() -> void:
    _handle_input = false
    _velocity = Vector2.ZERO
    _gravity = Vector2.ZERO
    _friction_coef = 0

func _on_area_hit(area: Area2D) -> void:
    if area is GameTimeLock:
        var time_lock := area as GameTimeLock
        time_lock.hit()
        _play_punch_fx()

func _on_body_hit(body: PhysicsBody2D) -> void:
    if body is RigidBody2D:
        var offset = global_position.direction_to(body.global_position)
        body.apply_impulse(offset, offset * 750.0)
        _play_punch_fx()

func _play_punch_fx() -> void:
    _punch_fx.pitch_scale = rand_range(0.9, 1.1)
    _punch_fx.play()

func zap() -> void:
    if _zapped:
        return

    _zapped = true
    _handle_input = false
    _velocity = Vector2()

    var tween := get_tree().create_tween()
    tween.tween_property(self, "modulate", Color.transparent, 0.15)
    yield(tween, "finished")

    yield(get_tree().create_timer(0.5), "timeout")

    var tween2 := get_tree().create_tween()
    position = _initial_position
    tween2.tween_property(self, "modulate", Color.white, 0.15)
    yield(tween2, "finished")
    _handle_input = true
    _zapped = false