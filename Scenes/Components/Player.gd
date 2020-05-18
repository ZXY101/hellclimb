#extends KinematicBody2D
#
#const UP=Vector2(0,-1)
#const GRAVITY=1400
#const ACCELERATION=100
#const MAXSPEED=250
#const JUMP_HEIGHT=-500
#
#var motion= Vector2()
#
#func _physics_process(delta):
#	motion.y+=GRAVITY * delta
#	var friction=false
#
#	if Input.is_action_pressed("ui_right"):
#		motion.x=min(motion.x+ACCELERATION,MAXSPEED)
#		$Sprite.flip_h =false
#		$Sprite.play("run")
#
#	elif Input.is_action_pressed("ui_left"):
#		motion.x=max(motion.x-ACCELERATION,-MAXSPEED)
#		$Sprite.flip_h =true
#		$Sprite.play("run")
#	else:
#		$Sprite.play("idle")
#		friction=true
#
#
#	if is_on_floor():
#		if Input.is_action_just_pressed("ui_up"):
#			motion.y=JUMP_HEIGHT
#		if friction==true:
#			motion.x=lerp(motion.x,0,0.2)
#
#	else:
#		if motion.y<0:
#			$Sprite.play("jump")
#		else:
#			$Sprite.play("fall")
#		if friction==true:
#			motion.x=lerp(motion.x,0,0.05)
#
#
#
#	motion=move_and_slide(motion,UP)
extends KinematicBody2D

signal grounded_updated(is_grounded)

onready var sprite = $Sprite
onready var drop_thru_raycasts = $DropThru

const UP = Vector2(0, -1)
const SLOPE_STOP = 64
const DROP_THRU_BIT = 1

var velocity = Vector2()
var move_speed = 5 * Globals.UNIT_SIZE
var gravity
var max_jump_velocity
var min_jump_velocity
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


func _handle_move_input():
	var move_direction = -int(Input.is_action_pressed("left")) + int(Input.is_action_pressed("right"))
	velocity.x = lerp(velocity.x, move_speed * move_direction, get_h_weight())
	if (move_direction != 0):
		sprite.scale.x = move_direction

func get_h_weight():
	return 0.2 if is_grounded else 0.1
	
func check_col(raycasts):
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
		return false

func _on_Area2D_body_exited(_body):
	set_collision_mask_bit(DROP_THRU_BIT, true)
