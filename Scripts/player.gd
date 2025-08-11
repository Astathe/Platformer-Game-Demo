extends CharacterBody2D

@export var walk_speed = 200.0
@export var run_speed = 300
@export_range(0, 1) var acceleration = 0.1
@export_range(0, 1) var deceleration = 0.1

@export var jump_force = -650.0
@export_range(0, 1) var decelerate_on_jump_release = 0.5

@export var dash_speed = 1000.0
@export var dash_max_range = 350.0
@export var dash_curve : Curve
@export var dash_cooldown = 1.0
@onready var animation_sprite = $AnimatedSprite2D

@export var wall_slide_speed = 40.0

var is_dashing = false
var dash_start_point = 0
var dash_direction = 0
var dash_timer = 0
var double_jump_available = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if is_on_wall() and velocity.y > 0:  # Only slide when falling down a wall
			# Cap the falling speed to wall_slide_speed
			velocity.y = min(velocity.y + get_gravity().y * delta, wall_slide_speed)
		else:
			# Normal gravity when not wall sliding
			velocity += get_gravity() * delta
		
	if (is_on_floor() or is_on_wall()) and not double_jump_available:
		double_jump_available = true
 		  
	# Handle jump.
	var jumping = false
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jumping = true
		velocity.y = jump_force

	#Double Jump
	if Input.is_action_just_pressed("jump") and not is_on_floor() and not is_on_wall() and double_jump_available:
		double_jump_available = false
		velocity.y = jump_force
		
	if Input.is_action_just_released("jump") and velocity.y < 0:    
		velocity.y *= decelerate_on_jump_release   
	
	var speed
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		animation_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)

	#Dash activation
	if Input.is_action_just_pressed("dash") and direction and not is_dashing and dash_timer <= 0:
		is_dashing = true
		dash_start_point = position.x
		dash_direction = direction
		dash_timer = dash_cooldown
		
	#Dash action
	if is_dashing:
		var current_distance = abs(position.x - dash_start_point)
		if current_distance >= dash_max_range or is_on_wall():
			is_dashing = false
		else:
			velocity.x = dash_direction * dash_speed * dash_curve.sample(current_distance / dash_max_range)
			velocity.y = 0
	
	# Reduce dash timer
	if dash_timer > 0:
		dash_timer -= delta
	
	move_and_slide()
	
	# ANIMATION LOGIC - Handle animations with proper priority
	# Priority order: wall grab > jump/fall > movement > idle
	if is_on_wall() and not is_on_floor() and velocity.y > 0:
		# Wall sliding/grabbing
		animation_sprite.play("grab")
	elif not is_on_floor():
		# In air (jumping or falling)
		if velocity.y < 0:
			animation_sprite.play("jump")  # Going up
		else:
			animation_sprite.play("fall")  # Going down (if you have a fall animation)
	elif direction != 0:
		# Moving on ground
		animation_sprite.play("walk")
	else:
		# Standing still on ground
		animation_sprite.play("idle")
