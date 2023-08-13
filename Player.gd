extends CharacterBody2D

var speed = 10000
@onready var _animated_sprite = $AnimatedSprite2D


func _ready():
	process_priority = 10


func get_input(delta):
	if Input.is_action_pressed("left"):
		_animated_sprite.play("walk_left")
	elif Input.is_action_pressed("right"):
		_animated_sprite.play("walk_right")
	elif Input.is_action_pressed("down"):
		_animated_sprite.play("walk_down")
	elif Input.is_action_pressed("up"):
		_animated_sprite.play("walk_up")
	else:
		_animated_sprite.stop()
	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction.normalized() * speed * delta


func _physics_process(delta):
	get_input(delta)
	move_and_slide()
