extends Node
## The main script that controls how the game window appears. Adapted from
## geegaz's tutorial on Godot multiple windows with some modifications.
## (https://github.com/geegaz/Multiple-Windows-tutorial)
## 
## This script sets the main game window (where your main mascot/pet will appear
## on) so it will appear in borderless mode, resize itself according to the
## mascot's sprite size, then follow the mascot's position accordingly.
## Since it is possible the mascot may appear offscreen, adjustment is also made
## so it will stick itself at the edge of the screen nearest to where the mascot is.
## This is done to prevent the white border appearing (at least in Windows) when
## the mascot goes offscreen.


@export_node_path("Camera2D") var camera : NodePath

#var world_offset := Vector2i.ZERO

@onready var _MainCamera : Camera2D = get_node(camera)
@onready var _MainWindow : Window = get_window()
@onready var _MainScreen : int = get_window().current_screen
@onready var main_screen_rect : Rect2i = DisplayServer.screen_get_usable_rect(_MainScreen)
@onready var pet : Character = $Character


# Called when the node enters the scene tree for the first time.
func _ready():
	# Sets up the window of the project by code.
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)
	_MainWindow.borderless = true
	_MainWindow.transient = true
	_MainWindow.transparent = true
	_MainWindow.transparent_bg = true
	_MainWindow.unresizable = true
	_MainWindow.gui_embed_subwindows = false
	_MainWindow.always_on_top = true
	_MainWindow.unfocusable = true
	
	_MainWindow.min_size = Vector2(pet.size) * pet.scale
	_MainWindow.size = _MainWindow.min_size
	_MainCamera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	_MainWindow.position = get_position_from_camera()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Ensure the main window always follows the assigned
	_MainWindow.position = get_position_from_camera()


# The function to be called to synchronize the game window's position with the assigned
# camera.
func get_position_from_camera() -> Vector2i:
	# Calculate the position of the window based on the main camera's global
	# position (which should follow the mascot since it's child of the mascot
	# sprite) and adjusted based on the camera's offset.
	# var pos = Vector2i(Vector2i(_MainCamera.global_position + _MainCamera.offset) - \
	# 		Vector2i(Vector2(pet.size)/2 * pet.scale)) * Vector2i(_MainCamera.zoom)
	var pos = Vector2i(_MainCamera.global_position + _MainCamera.offset)
	
#region Windows Borderless Fix
	# When the mascot goes offscreen, force the game window to stick on the edge
	# of the screen nearest to where the mascot/pet is to prevent white border
	# from appearing (at least in Windows OS).
	#if pos.x > main_screen_rect.size.x - pet.size.x * pet.scale.x:
		#pos.x = main_screen_rect.size.x - pet.size.x * pet.scale.x
	#elif pos.x < 0:
		#pos.x = 0
	#if pos.y > main_screen_rect.size.y - pet.size.y/2 * pet.scale.y:
		#pos.y = main_screen_rect.size.y - pet.size.y * pet.scale.y
	#elif pos.y < 0:
		#pos.y = 0
#endregion
	
	return pos
