# obstacle.gd
extends Area2D

# How fast the obstacle moves down the screen.
# We will set this from the main script later.
var speed = 120 
var scored = false

func _process(delta):
	# Move the obstacle downwards every frame.
	position.y += speed * delta
	
	# Check if the obstacle is off the bottom of the screen.
	if position.y > get_viewport_rect().size.y + 300:
		# queue_free() deletes the node, which is good for performance.
		queue_free()
