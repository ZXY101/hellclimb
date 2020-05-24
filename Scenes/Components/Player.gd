extends KinematicBody2D

signal grounded_updated(is_grounded)

onready var sprite = $Sprite
onready var drop_thru_raycasts = $DropThru

onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
onready var right_wall_raycasts = $WallRaycasts/RightWallRaycasts
onready var wall_slide_cooldown = $WallSlideCooldown
onready var wall_slide_sticky_timer = $WallSlideStickyTimer

const UP = Vector2(0, -1)
const SLOPE_STOP = 64
const DROP_THRU_BIT = 1
const WALL_JUMP_VELOCITY = Vector2(300, -300)

var velocity = Vector2()
var move_speed = 5 * Globals.UNIT_SIZE
var gravity
var max_jump_velocity
var min_jump_velocity
var wall_direction = 1
var move_direction = 1

var is_grounded
var is_jumping = false

var max_jump_height = 2.5 * Globals.UNIT_SIZE
var min_jump_height = 0.8 * Globals.UNIT_SIZE
var jump_duration = 0.5

func _ready():
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)

func _apply_gravity(delta):
	# Apply gravity
	velocity.y += gravity * delta
	

func _cap_gravity_wall_slide():
	var max_velocity = Globals.UNIT_SIZE if !Input.is_action_pressed("down") else 6 * Globals.UNIT_SIZE
	velocity.y = min(velocity.y, max_velocity)

func _apply_movement():
	# Set is_jumping to false if falling
	if (is_jumping && velocity.y >= 0):
		is_jumping = false
	
	#Snap to the floor if not jumping
	var snap = Vector2.DOWN * 16 if !is_jumping else Vector2.ZERO
	
	# Move player
	velocity = move_and_slide_with_snap(velocity, snap, UP)
	
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	# If gounded changed, emit signal
	if (was_grounded == null || is_grounded != was_grounded):
		emit_signal("grounded_updated", is_grounded)


func _update_move_direction():
	move_direction = -int(Input.is_action_pressed("left")) + int(Input.is_action_pressed("right"))

func _handle_move_input():
	velocity.x = lerp(velocity.x, move_speed * move_direction, get_h_weight())
	if (move_direction != 0):
		sprite.scale.x = move_direction

func _handle_wall_slide_sticky():
	if (move_direction != 0 && move_direction != wall_direction):
		if (wall_slide_sticky_timer.is_stopped()):
			print('nani')
			wall_slide_sticky_timer.start()
	else:
		wall_slide_sticky_timer.stop()

func get_h_weight():
	if (is_on_floor()):
		return 0.2
	else:
		if (move_direction == 0):
			return 0.02
		elif (move_direction == sign(velocity.x) && abs(velocity.x) > move_speed):
			return 0.0
		else:
			return 0.1

func _wall_jump():
	var wall_jump_velocity = WALL_JUMP_VELOCITY
	wall_jump_velocity.x *= -wall_direction
	velocity = wall_jump_velocity

func check_col(raycasts):
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
		return false

func _update_wall_direction():
	var is_near_wall_left = _check_is_valid_wall(left_wall_raycasts)
	var is_near_wall_right = _check_is_valid_wall(right_wall_raycasts)
	
	if (is_near_wall_left && is_near_wall_right):
		wall_direction = move_direction
	else:
		wall_direction = -int(is_near_wall_left) + int (is_near_wall_right)

func _check_is_valid_wall(wall_raycasts):
	for raycast in wall_raycasts.get_children():
		if raycast.is_colliding():
			var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
			if (dot > PI * 0.35 && dot < PI * 0.55):
				return true
	return false

func _on_Area2D_body_exited(_body):
	set_collision_mask_bit(DROP_THRU_BIT, true)
