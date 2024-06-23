class_name Character
extends Node2D
## The class that controls how the mascot/pet behaves whether by itself, or in
## response to mouse inputs.
## 
## Upon initialization, the mascot will appear at the fixed point of the screen
## and play enter animation, after which a timer will automatically count down until
## the next action. The next action will be randomly chosen and played out, after
## which the timer will restart. The timer will be paused when user drags the mascot
## across the screen and resumes when the mascot is released, or it will be terminated
## and restarts when user manually interacts with the mascot using mouse clicks.
## 
## User can interact with the mascot using mouse clicks, which results in one of the
## following actions chosen at random:
## - play an alternate idle animation
## - move to a random point of the screen
## - jump
## - move to the center of the screen and give user (nonexistent) gift.
##
## Do note that due to issues regarding white border in borderless and fullscreen
## modes of Godot Engine when running in Windows, the position of the mascot is
## restricted to the on-screen only. If you want to create movements/actions involving
## the mascot/pet going offscreen, it is heavily advised to just use custom animation
## clips for it that depicts the offscreen action, rather than moving the mascot out.


signal move_completed

enum Actions {
	IDLE,
	IDLE_BOUNCE,
	MOVE,
	JUMP,
	GIVE_GIFTS,
}

enum MoveAxis {
	HORIZONTAL,
	VERTICAL
}

@export var size := Vector2i(32, 32)
@export var minimum_interval : float = 5.0
@export var maximum_interval : float = 10.0
@export var move_speed : float = 10.0

var _hold_time = 0
var _hold_time_before_drag = 0.1
var _held = false
var _dragged = false
var _mouse_offset = Vector2.ZERO

var _moving := false:
	set(value):
		_moving = value
		if value == false:
			print_debug("movement stopped")
		else:
			print_debug("movement started")
var _axis : int = 0
var _destination : float = 0
var _velocity := Vector2.ZERO
var _last_position := Vector2.ZERO

var _tween : Tween

@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _timer : Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	# Match the size with the animated sprite's size.
	size = _sprite.sprite_frames.get_frame_texture("default", _sprite.frame).get_size()
	$Button.custom_minimum_size = size
	
	visible = false
		
	_sprite.play()
	visible = true

	_timer.start()
	
	#_enter_screen()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Adapted from RachelfTech's code, give slight delay before allowing
	# the mascot to be dragged around.
	if _held:
		if _hold_time > _hold_time_before_drag:
			_dragged = true
		_hold_time += delta


func _physics_process(delta):
	if _dragged:
		# Using the mouse's global position doesn't play nice with the physics update,
		# so we use the display server's get mouse position instead.
		global_position = Vector2(DisplayServer.mouse_get_position()) - _mouse_offset

	if _moving:
		_last_position = global_position
		
		if _axis == MoveAxis.HORIZONTAL:
			global_position = global_position.move_toward(
					Vector2(get_parent().main_screen_rect.size.x * _destination,
							global_position.y), move_speed * delta
			)
		else:
			global_position = global_position.move_toward(Vector2(global_position.x,
					get_parent().main_screen_rect.size.y * _destination),
							move_speed * delta
			)
		
		_velocity = global_position -_last_position
		if _velocity == Vector2.ZERO:
			_moving = false

	#region Offscreen Control
	# When the mascot comes from offscreen and partially cropped, adjust its
	# position to make it truly look like it comes from offscreen.
	# This is done to mitigate the effect of the window being forced to stick
	# to the side of the screen to prevent white borders on Windows.
	if position.x > get_parent().main_screen_rect.size.x - size.x * scale.x:
		position.x -= size.x * scale.x + position.x - get_parent() \
				.main_screen_rect.size.x
	elif position.x < 0:
		position.x = 0
	if position.y > get_parent().main_screen_rect.size.y - size.y * scale.y:
		position.y -= size.y * scale.y + position.y - get_parent() \
				.main_screen_rect.size.y
	elif position.y < 0:
		position.y = 0
	#endregion


func _enter_screen():
	#if _sprite.animation != "walk_left":
		#_sprite.play("walk_left")
	_sprite.play()
	#_camera.offset = Vector2(-size.x, 0)
	
	global_position = Vector2i(DisplayServer.screen_get_usable_rect().size.x * 1.1, DisplayServer.screen_get_usable_rect().size.y * 0.8)
	visible = true
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:x", DisplayServer.screen_get_usable_rect().size.x * 1.0 - \
			size.x * scale.x, get_move_tween_duration(1.1, 1.0))
	#_tween.parallel().tween_property(_camera, "offset", Vector2(0.0, 0), abs(1.1 - 1.0) * move_speed).from(Vector2(-size.x/2, 0))
	_tween.tween_property(self, "position:x", DisplayServer.screen_get_usable_rect().size.x * 0.7,
			get_move_tween_duration((DisplayServer.screen_get_usable_rect().size.x - size.x * scale.x) / DisplayServer.screen_get_usable_rect().size.x, 0.7))
	await _tween.finished
	_timer_until_next_move()
	
	_sprite.play("default")
	_moving = false


# The main function to be called when the timer reaches timeout or manually
# interrupted when user interacts with the mascot using mouse click.
func _roll():
	var next = randi_range(1, Actions.size() - 1)

	if next == Actions.IDLE_BOUNCE:
		# _sprite.play("idle_bounce")
		pass
	elif next == Actions.MOVE:
		_move()
	elif next == Actions.JUMP:
		_jump()
	elif next == Actions.GIVE_GIFTS:
		_gift()

	_sprite.play("default")
	_timer_until_next_move()


# The function to be executed when the mascot is chosen to move.
# The movement works by first randomly choosing the axis the mascot will move
# at (horizontal/vertical), then to which point of the screen it will move to.
# The mascot will then be moved using Vector2.move_toward()
func _move():
	_axis = randi_range(0, 1)
	_destination = randf_range(0.0, 1.0)

	var val : float = 0

	if _axis == MoveAxis.HORIZONTAL:
		val = _destination - global_position / get_parent().main_screen_rect.size.x
		if val > 0:
			pass
			# _sprite.flip_h = true
			# _sprite.play("running")
		else:
			pass
			# _sprite.flip_h = false
			# _sprite.play("running")

	_moving = true


func _jump():
	#_sprite.play("jump")
	# TODO: resize the game window due to height change
	pass


func _gift():
	#_sprite.play("give_gift")
	pass


# The function to be called to determine wait time of the next action
func _timer_until_next_move():
	_timer.wait_time = randf_range(minimum_interval, maximum_interval)
	_timer.start()


func get_move_tween_duration(from : float, to : float):
	return move_speed * abs(to - from)


func _on_button_button_down():
	_held = true
	_mouse_offset = Vector2(DisplayServer.mouse_get_position()) - global_position
	_timer.paused = true

	# If mascot is in the middle of moving, terminate the action
	if _moving:
		_moving = false
		_velocity = Vector2.ZERO
		_last_position = Vector2.ZERO

	if _tween:
		_tween.pause()


func _on_button_button_up():
	if _dragged:
		_dragged = false
	_held = false
	_hold_time = 0
	_timer.paused = false
	if _tween and _tween.is_valid():
		_tween.play()


func _on_timer_timeout():
	_roll()
