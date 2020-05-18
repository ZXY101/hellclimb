extends "res://Scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	call_deferred("set_state", states.idle)

func _input(event):
	if [states.idle, states.run].has(state):
		# JUMP
		if (event.is_action_pressed("jump")):
			# If holding down and grounded, drop through
			if Input.is_action_pressed("down"):
				# Check on-way raycasts to prevent getting stuck on solid ground
				if (parent.check_col(parent.drop_thru_raycasts)):
					# Unset drop theu bit so player stops colding with drop through layer
					parent.set_collision_mask_bit(parent.DROP_THRU_BIT, false)
			# otherwise jump
			else:
				parent.velocity.y = parent.max_jump_velocity
				parent.is_jumping = true

	if state == states.jump:
		# Variable jump
		if event.is_action_released("jump") && parent.velocity.y < parent.min_jump_velocity:
			parent.velocity.y = parent.min_jump_velocity

func _state_logic(_delta):
	parent._handle_move_input()
	parent._apply_gravity(_delta)
	parent._apply_movement()

func _get_transition(_delta):
	match (state):
		states.idle:
			if (!parent.is_on_floor()):
				if (parent.velocity.y < 0):
					return states.jump
				elif (parent.velocity.y >= 0):
					return states.fall
			elif (abs(parent.velocity.x) >= 25):
				return states.run
		states.run:
			if (!parent.is_on_floor()):
				if (parent.velocity.y < 0):
					return states.jump
				elif (parent.velocity.y >= 0):
					return states.fall
			elif (abs(parent.velocity.x) < 25):
				return states.idle
		states.jump:
			if (parent.is_on_floor()):
				return states.idle
			elif (parent.velocity.y >= 0):
				return states.fall
		states.fall:
			if (parent.is_on_floor()):
				return states.idle
			elif (parent.velocity.y < 0):
				return states.jump
	
	return null

func _enter_state(new_state, _old_state):
	match new_state:
		states.idle:
			parent.sprite.animation = "idle"
		states.run:
			parent.sprite.animation = "run"
		states.jump:
			parent.sprite.animation = "jump"
		states.fall:
			parent.sprite.animation = "fall"

func _exit_state(_old_state, _new_state):
	pass
