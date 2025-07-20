# main.gd
extends Node2D

@onready var world = $World
@onready var road1 = $World/Road1
@onready var road2 = $World/Road2
@onready var player = $World/Player
@onready var obstacle_scene = preload("res://obstacle.tscn")
@onready var obstacle_timer = $ObstacleTimer
@onready var sfx_beep = $SfxBeep
@onready var sfx_score = $SfxScore
@onready var sfx_crash = $SfxCrash
@onready var hud = $HUD

@onready var grass1 = $BackgroundLayer/Grass1
@onready var grass2 = $BackgroundLayer/Grass2

@onready var bgm_player = $BGMPlayer
var current_bgm_index = -1

@onready var engine_sound_player = $EngineSoundPlayer

var active_obstacles = []
var is_game_active = false
var score = 0
var beep_cooldown = 0.0
var road_speed = 400

const STAGGER_DISTANCE = 2500
const MAX_CONSECUTIVE_LANE = 3
var last_safe_lane = -1
var same_lane_count = 0


# Create an array of your music tracks
var bgm_tracks = [
	preload("res://assets/Music/going-up-chill-lofi-jazz-341261.mp3"),
	preload("res://assets/Music/we-jazz-lofi-soul-363084.mp3"),
	preload("res://assets/Music/sloth-tier-lofi-jazz-223593.mp3"),
	preload("res://assets/Music/warm-breeze-lofi-music-chill-lofi-344259.mp3"),
	preload("res://assets/Music/we-jazz-lofi-soul-363084.mp3")
]


func _ready():
	player.hit.connect(_on_player_hit)
	obstacle_timer.timeout.connect(_on_obstacle_timer_timeout)
	new_game()
	bgm_player.finished.connect(_on_bgm_finished)
	engine_sound_player.finished.connect(engine_sound_player.play)
	_play_next_song()

func new_game():
	get_tree().paused = false
	score = 0
	is_game_active = false
	
	for obs in active_obstacles:
		obs.queue_free()
	active_obstacles.clear()
	
	obstacle_timer.stop()

	hud.get_node("ScoreLabel").text = "Score: " + str(score)
	hud.get_node("MessageLabel").text = "Press to Start"
	hud.get_node("MessageLabel").show()
	engine_sound_player.stop()
	
func _unhandled_input(event):
	# Only check for input if the game is not active
	if not is_game_active:
		# Check for keyboard start OR a screen tap/mouse click
		var keyboard_start = event.is_action_pressed("start_game")
		var screen_tap_start = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()

		if keyboard_start or screen_tap_start:
			# Call new_game() to reset score, clear old obstacles, etc.
			new_game()

			# Now, immediately start the new game
			get_tree().paused = false
			is_game_active = true
			
			# Update UI for game start (this hides the "Tap to Start" message)
			hud.get_node("MessageLabel").hide()

			# Start the timers and sounds
			obstacle_timer.start()
			engine_sound_player.play()
			
func _on_player_hit():
	sfx_crash.play() # Add this line
	is_game_active = false
	obstacle_timer.stop()
	engine_sound_player.stop()
	hud.get_node("MessageLabel").text = "Game Over\nTap to Retry"
	hud.get_node("MessageLabel").show()
	
	get_tree().paused = true 

func _on_obstacle_timer_timeout():
	obstacle_timer.wait_time = 10.0
	var safe_lane = randi() % 3
	if safe_lane == last_safe_lane:
		same_lane_count += 1
	else:
		same_lane_count = 1
	if same_lane_count >= MAX_CONSECUTIVE_LANE:
		var new_safe_lane = safe_lane
		while new_safe_lane == last_safe_lane:
			new_safe_lane = randi() % 3
		safe_lane = new_safe_lane
		same_lane_count = 1
	last_safe_lane = safe_lane

	var screen_center_x = 360
	var lane_width = player.LANE_WIDTH
	var staggered = false
	for lane_index in range(3):
		if lane_index != safe_lane:
			var new_obstacle = obstacle_scene.instantiate()
			new_obstacle.player_node = player
			new_obstacle.position.x = screen_center_x + (lane_index - 1) * lane_width
			if not staggered:
				new_obstacle.position.y = -50
				staggered = true
			else:
				new_obstacle.position.y = -50 - STAGGER_DISTANCE
			world.add_child(new_obstacle) # Add obstacle to the world
			active_obstacles.append(new_obstacle)
			new_obstacle.tree_exiting.connect(func(): active_obstacles.erase(new_obstacle))

func _process(delta):
	# Keep the World node centered
	world.position.x = (get_viewport_rect().size.x - 720) / 2
	world.position.y = (get_viewport_rect().size.y - 1280) / 2

	# --- Road Scrolling ---
	road1.position.y += road_speed * delta
	road2.position.y += road_speed * delta
	var road_height = 1280
	if road1.position.y > 1280 + (road_height / 2):
		road1.position.y = road2.position.y - road_height
	if road2.position.y > 1280 + (road_height / 2):
		road2.position.y = road1.position.y - road_height
	
	# --- Grass Scrolling Logic ---
	# Move both grass textures down
	grass1.position.y += road_speed * delta
	grass2.position.y += road_speed * delta

	# Check if a grass texture has moved off the bottom of the screen
	var screen_height = 1280

	if grass1.position.y > screen_height:
		# Move it back to the top, above the other texture
		grass1.position.y = grass2.position.y - screen_height
		
	if grass2.position.y > screen_height:
		# Move it back to the top, above the other texture
		grass2.position.y = grass1.position.y - screen_height
	
	if not is_game_active:
		return

	# --- Radar Beep Logic ---
	beep_cooldown -= delta
	var closest_distance = 10000
	var obstacle_in_lane = false
	for obs in active_obstacles:
		if abs(obs.position.x - player.position.x) < 20:
			var distance = player.position.y - obs.position.y
			if distance > 0 and distance < closest_distance:
				closest_distance = distance
				obstacle_in_lane = true
	if obstacle_in_lane:
		if beep_cooldown <= 0:
			sfx_beep.play()
			Input.vibrate_handheld(150)
			var beep_interval = remap(closest_distance, 200, 800, 0.1, 1.0)
			beep_cooldown = clamp(beep_interval, 0.05, 1.2)

func _on_ScoreArea_area_entered(area):
	if area.is_in_group("obstacles") and not area.scored:
		area.scored = true
		score += 1
		hud.get_node("ScoreLabel").text = "Score: " + str(score)
		sfx_score.play()

func _on_bgm_finished():
	_play_next_song()

func _play_next_song():
	current_bgm_index += 1
	# If we've gone past the end of the list, loop back to the start
	if current_bgm_index >= bgm_tracks.size():
		current_bgm_index = 0
	
	bgm_player.stream = bgm_tracks[current_bgm_index]
	bgm_player.play()
