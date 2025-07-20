# obstacle.gd
extends Area2D

# How fast the obstacle moves down the screen.
# We will set this from the main script later.
var speed = 100 
var scored = false

var is_stopped = false

# Add this array at the top of obstacle.gd
var car_textures = [
	preload("res://assets//car1.png"),
	preload("res://assets//car2.png"),
	preload("res://assets//car3.png"),
	preload("res://assets//car4.png"),
	preload("res://assets//car5.png")
]

var player_node = null # To hold a reference to the player
var has_played_pass_sound = false
const PASS_SOUND_TRIGGER_DISTANCE = 400 # How close before the sound plays

@onready var sfx_pass_by = $SfxPassBy


@onready var sprite = $Sprite2D

func _ready():
	# Pick a random texture and assign it to the sprite
	sprite.texture = car_textures.pick_random()

func _process(delta):
	if is_stopped:
		return
	# Move the obstacle downwards every frame.
	position.y += speed * delta
	
	# Proximity check for pass-by sound
	if player_node != null and not has_played_pass_sound:
		var distance_y = player_node.position.y - self.position.y
		# Check if obstacle is approaching and within trigger distance
		if distance_y > 0 and distance_y < PASS_SOUND_TRIGGER_DISTANCE:
			sfx_pass_by.play()
			has_played_pass_sound = true
			
	# Check if the obstacle is off the bottom of the screen.
	if position.y > get_viewport_rect().size.y + 300:
		# queue_free() deletes the node, which is good for performance.
		queue_free()
