extends CharacterBody2D

var id = 0
var speed = 250


func get_input(delta):
	velocity = Vector2()
	
	if Input.is_action_pressed('ui_right'):
		velocity.x += 1 * delta
	if Input.is_action_pressed('ui_left'):
		velocity.x -= 1 * delta
	if Input.is_action_pressed('ui_up'):
		velocity.y -= 1 * delta
	if Input.is_action_pressed('ui_down'):
		velocity.y += 1 * delta
		
	velocity = velocity.normalized() * speed

func _physics_process(delta):
	get_input(delta)
	move_and_slide()
