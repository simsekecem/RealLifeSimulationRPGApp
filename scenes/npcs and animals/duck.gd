# Duck.gd
extends CharacterBody2D

# --- Configuration Variables ---

@export var speed: float = 20.0 
const MIN_WAIT_TIME: float = 0.1
const MAX_WAIT_TIME: float = 0.2

# --- LINE PATROL COORDINATES (Fixed Y axis) ---
# START and END points along the patrol line
# Keeping Y coordinate constant to maintain a straight line.
const START_POINT: Vector2 = Vector2(986, 230) # Left boundary (Xmin)
const END_POINT: Vector2 = Vector2(1268, 230)   # Right boundary (Xmax)

# --- Internal Variables ---
const TARGET_TOLERANCE: float = 5.0
var target_position: Vector2 = END_POINT # Initially moves toward END_POINT
var is_moving_to_end: bool = true        # Is moving towards end point?
var time_to_next_target: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Engine Callbacks ---

func _ready() -> void:
	randomize() 
	# Set starting position
	global_position = START_POINT 
	time_to_next_target = 1.0 # Begin moving immediately

func _physics_process(delta: float) -> void:
	if time_to_next_target > 0:
		var distance_to_target: float = global_position.distance_to(target_position)

		if distance_to_target < TARGET_TOLERANCE:
			# TARGET REACHED: Stop, start wait timer, switch target
			velocity = Vector2.ZERO
			
			# Set wait duration
			time_to_next_target = -randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)
			
			animated_sprite.play("swim_right") # Animation continues while idle
			animated_sprite.flip_h = false # Reset animation flip
			return

		# MOVEMENT
		var direction: Vector2 = global_position.direction_to(target_position)
		velocity = direction * speed
		move_and_slide()
		
		update_animation(direction)
		
	else:
		# WAIT FINISHED: Switch to next target
		time_to_next_target += delta # Add delta since time_to_next_target is negative
		if time_to_next_target >= 0:
			switch_target()

# --- Custom Methods ---

func switch_target() -> void:
	# Reverse target direction
	is_moving_to_end = !is_moving_to_end
	
	if is_moving_to_end:
		target_position = END_POINT
	else:
		target_position = START_POINT
		
	# Start swimming immediately
	time_to_next_target = 1.0 

func update_animation(direction: Vector2) -> void:
	animated_sprite.play("swim_right") 
	
	if direction.x > 0.1: # Swim right
		animated_sprite.flip_h = false 
	elif direction.x < -0.1: # Swim left
		animated_sprite.flip_h = true
