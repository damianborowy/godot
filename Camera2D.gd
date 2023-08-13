extends Camera2D


@export var player: CharacterBody2D


func _process(delta):
	if not player:
		return
	
	position.x = player.position.x
	position.y = player.position.y
