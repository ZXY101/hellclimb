extends "res://Scripts/StateMachine.gd"

func _ready():
	_init_states()
	call_deferred("set_state", states.idle)

func _init_states():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("wall_slide")

func _input(event):
	if [states.idle, states.run].has(state) || !parent.coyote_timer.is_stopped():
		# JUMP
		if (event.is_action_pressed("jump")):
			parent.coyote_timer.stop()
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
	elif state == states.wall_slide:
		if event.is_action_pressed("jump"):
			parent._wall_jump()
			set_state(states.jump)
	elif state == states.jump:
		# Variable jump
		if event.is_action_released("jump") && parent.velocity.y < parent.min_jump_velocity:
			parent.velocity.y = parent.min_jump_velocity

func _state_logic(_delta):
	parent._update_move_direction()
	parent._update_wall_direction()
	if (state != states.wall_slide):
		parent._handle_move_input()
	parent._apply_gravity(_delta)
	if (state == states.wall_slide):
		parent._cap_gravity_wall_slide()
		parent._handle_wall_slide_sticky()
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
			if (parent.wall_direction != 0 && parent.wall_slide_cooldown.is_stopped()):
				return states.wall_slide
			if (parent.is_on_floor()):
				return states.idle
			elif (parent.velocity.y >= 0):
				return states.fall
		states.fall:
			if (parent.wall_direction != 0 && parent.wall_slide_cooldown.is_stopped()):
				return states.wall_slide
			elif (parent.is_on_floor()):
				return states.idle
			elif (parent.velocity.y < 0):
				return states.jump
		states.wall_slide:
			if (parent.is_on_floor()):
				return states.idle
			elif (parent.wall_direction == 0):
				return states.fall
	
	return null

func _enter_state(new_state, _old_state):
	match new_state:
		states.idle:
			parent.sprite.animation = "idle"
			print('idle')
		states.run:
			print('run')
			parent.sprite.animation = "run"
			parent.play_sfx("walk")
		states.jump:
			print('jump')
			parent.sprite.animation = "jump"
			parent.play_sfx("jump")
		states.fall:
			print('fall')
			if (parent.coyote_timer.is_stopped()):
				parent.sprite.animation = "fall"
			if ([states.idle, states.run].has(_old_state)):
				parent.coyote_timer.start()
				parent.velocity.y = 0
		states.wall_slide:
			print('wall_slide')
			parent.sprite.animation = "wall_slide"
			parent.sprite.scale.x = -parent.wall_direction
			parent.play_sfx("land")

func _exit_state(_old_state, _new_state):
	match _old_state:
		states.wall_slide:
			parent.wall_slide_cooldown.start()
		states.fall:
			parent.play_sfx("land")
		states.run:
			parent.play_sfx()


func _on_WallSlideStickyTimer_timeout():
	if (state == states.wall_slide):
		set_state(states.fall)
