# player.gd
extends CharacterBody2D

# This signal will tell the main game when we hit something.
signal hit

# We'll use these to control movement
const LANE_WIDTH = 200.0 # The distance between lanes
const MOVE_SPEED = 12.0 # How fast the lane change is

# The player's current lane (0=Left, 1=Center, 2=Right)
var current_lane = 1
var target_position_x = 0

# Variables for swipe detection on mobile
var touch_start_position = Vector2.ZERO
var min_swipe_distance = 50

# Sounds for lane switching
@onready var sfx_left: AudioStreamPlayer = $SfxLeft
@onready var sfx_center: AudioStreamPlayer = $SfxCenter
@onready var sfx_right: AudioStreamPlayer = $SfxRight


func _ready():
	# This function runs once when the player is created.
	# We get the center of the screen and set the player's initial position.
	target_position_x = get_viewport_rect().size.x / 2
	position.x = target_position_x

func _unhandled_input(event):
	var previous_lane = current_lane

	# --- Handle Keyboard Input ---
	if event.is_action_pressed("move_left"):
		if current_lane > 0:
			current_lane -= 1
	elif event.is_action_pressed("move_right"):
		if current_lane < 2:
			current_lane += 1

	# --- Handle Mobile Swipe Input ---
	if event is InputEventScreenTouch:
		if event.is_pressed():
			# Record where the touch started
			touch_start_position = event.position
		else: # This is a touch release
			var swipe_vector = event.position - touch_start_position
			# Check if it was a significant horizontal swipe
			if swipe_vector.length() > min_swipe_distance and abs(swipe_vector.x) > abs(swipe_vector.y):
				if swipe_vector.x < 0 and current_lane > 0: # Swipe Left
					current_lane -= 1
				elif swipe_vector.x > 0 and current_lane < 2: # Swipe Right
					current_lane += 1

	# --- Play sound based on the NEW lane, only if a change occurred ---
	if current_lane != previous_lane:
		match current_lane:
			0: # Left Lane
				sfx_left.play()
			1: # Center Lane
				sfx_center.play()
			2: # Right Lane
				sfx_right.play()

func _physics_process(delta):
	# This function runs every frame, handling physics and movement.
	
	# Determine the target X position based on the current lane
	var screen_center_x = 360.0
	if current_lane == 0: # Left Lane
		target_position_x = screen_center_x - LANE_WIDTH
	elif current_lane == 1: # Center Lane
		target_position_x = screen_center_x
	elif current_lane == 2: # Right Lane
		target_position_x = screen_center_x + LANE_WIDTH
		
	# Smoothly move the player towards the target X position
	position.x = lerp(position.x, target_position_x, MOVE_SPEED * delta)

	# The move_and_slide() function is part of CharacterBody2D. 
	# We aren't using its velocity features, but it's good practice to call it.
	move_and_slide()


func _on_hitbox_area_entered(area: Area2D) -> void:
	# When any area (like an obstacle) enters our hitbox, we emit the "hit" signal.
	emit_signal("hit")


func reset():
	# Reset lane and position to the starting state
	current_lane = 1
	var screen_center_x = 360.0
	position.x = screen_center_x
