class_name Character
extends Node2D


@export var size := Vector2i(32, 32)
@export var minimum_interval : float = 5.0
@export var maximum_interval : float = 10.0
@export var move_speed : float = 10.0

var _hold_time = 0
var _hold_time_before_drag = 0.1
var _clicked = false
var _dragged = false
var _mouse_offset = Vector2.ZERO
var _moving := false
var _tween : Tween
var _timer : Timer

@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _camera : Camera2D = $Sprite/Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	size = _sprite.sprite_frames.get_frame_texture("default", _sprite.frame).get_size()
	$Button.custom_minimum_size = size
	
	_moving = true
	visible = false
	
	_timer = Timer.new()
	_timer.wait_time = 1.0
	add_child(_timer)
	_timer.start()
	await _timer.timeout
	
	_sprite.play()
	visible = true
	
	#_enter_screen()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _clicked:
		if _hold_time > _hold_time_before_drag:
			_dragged = true
		_hold_time += delta


func _physics_process(delta):
	if _dragged:
		global_position = Vector2(DisplayServer.mouse_get_position()) - _mouse_offset
		
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


func _timer_until_next_move():
	_timer.wait_time = randf_range(minimum_interval, maximum_interval)


func get_move_tween_duration(from : float, to : float):
	return move_speed * abs(to - from)


func _on_button_button_down():
	_clicked = true
	_mouse_offset = Vector2(DisplayServer.mouse_get_position()) - global_position
	if _tween:
		_tween.pause()


func _on_button_button_up():
	if _dragged:
		_dragged = false
	_clicked = false
	_hold_time = 0
	if _tween and _tween.is_valid():
		_tween.play()
