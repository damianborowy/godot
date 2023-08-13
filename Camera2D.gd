extends Camera2D


@export var player: CharacterBody2D


func _physics_process(_delta):
	if not player:
		return
	
	position = player.position
