extends CharacterBody2D

@export var speed: float = 150.0  # Character movement speed
@export var accel: float = 20.0    # Acceleration
@export var friction: float = 20.0 # Deceleration

@onready var anim = $AnimatedSprite2D 

# --- CAMERA ---
@onready var camera = $Camera2D 

var last_direction = Vector2.DOWN 

# Track loaded character visual ID
var current_visual_id: int = -1 

func _ready():
	# 1. Camera setup
	if camera:
		camera.make_current()
	
	# Automatically configure camera limits to fit map boundaries
	call_deferred("setup_camera_limits")
	
	# 2. Load character visual
	load_character_visuals()

	# Signal connection
	if Globals.has_signal("data_updated"):
		if not Globals.data_updated.is_connected(load_character_visuals):
			Globals.data_updated.connect(load_character_visuals)
			print("✅ Player listening for global data updates.")

# ============================================================
# CAMERA BOUNDS
# ============================================================
func setup_camera_limits():
	if camera == null: return

	# Look for parent scene's TileMap or Ground node
	var tilemap = get_parent().get_node_or_null("TileMap")
	
	if tilemap == null:
		tilemap = get_parent().get_node_or_null("Ground")
		
	if tilemap:
		# 1. Get populated rectangular map area
		var map_rect = tilemap.get_used_rect()
		
		# 2. Get tile size
		var tile_size = tilemap.tile_set.tile_size
		
		# 3. Left and top bounds
		camera.limit_left = map_rect.position.x * tile_size.x
		camera.limit_top = map_rect.position.y * tile_size.y
		
		# 4. Right and bottom bounds
		camera.limit_right = (map_rect.position.x + map_rect.size.x) * tile_size.x
		camera.limit_bottom = (map_rect.position.y + map_rect.size.y) * tile_size.y
		
		print("📷 Camera limits set to map bounds: ", map_rect)
	else:
		print("⚠️ Warning: Neither 'TileMap' nor 'Ground' found for camera limits.")

# --- LOAD CHARACTER VISUALS ---
func load_character_visuals():
	# 1. Get selected character ID from global cache
	var user_data = Globals.cache.get("user", {})
	var char_id = int(user_data.get("character_id", 1))
	
	if char_id == current_visual_id:
		return
	
	# 2. Construct resource path
	var path = "res://assets/characters/resources/char_%d.tres" % char_id
	
	# 3. If file exists, load and apply SpriteFrames
	if ResourceLoader.exists(path):
		var new_frames = load(path)
		if new_frames is SpriteFrames:
			anim.sprite_frames = new_frames
			play_animation("idle")
			
			current_visual_id = char_id
			print("🎭 [PLAYER] Appearance updated: ID ", char_id)
		else:
			print("⚠️ Error: Loaded resource is not SpriteFrames!")
	else:
		print("⚠️ Error: Character file not found -> ", path)

func _physics_process(delta):
	var direction = Vector2.ZERO

	# 1. Joystick input
	if UI.has_node("UIRoot/Joystick"):
		var joystick = UI.get_node("UIRoot/Joystick")
		if "direction" in joystick and joystick.direction.length() > 0:
			direction = (joystick.direction * 1.5).limit_length(1.0)

	# 2. Keyboard input
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 3. Movement and animation
	if direction != Vector2.ZERO:
		velocity = velocity.lerp(direction * speed, accel * delta)
		last_direction = direction
		play_animation("walk")
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		play_animation("idle")

	move_and_slide()

func play_animation(action_name: String):
	var dir_suffix = "_down"
	
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			dir_suffix = "_right"
		else:
			dir_suffix = "_left"
	else:
		if last_direction.y > 0:
			dir_suffix = "_down"
		else:
			dir_suffix = "_up"
	
	var final_anim_name = action_name + dir_suffix
	
	if anim.sprite_frames.has_animation(final_anim_name):
		anim.play(final_anim_name)
	else:
		pass
