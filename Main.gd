extends Node2D

var Room = preload("res://Room.tscn")
@onready var Map = $TileMap

var tile_size = 32
var num_rooms = 50
var min_size = 6
var max_size = 12
var horizontal_spread = 300
var cull = 0.6
var space_between_rooms = 1
var size_fix_vector = Vector2(space_between_rooms, space_between_rooms) * tile_size
var corridor_width = 2

var path


func _ready():
	randomize()
	make_rooms()


func make_rooms():
	for i in range(num_rooms):
		var intial_position = Vector2(randf_range(-horizontal_spread, horizontal_spread), 0)
		var room = Room.instantiate()
		var width = min_size + randi() % (max_size - min_size)
		var height = min_size + randi() % (max_size - min_size)
		room.make_room(intial_position, Vector2(width, height) * tile_size)
		$Rooms.add_child(room)

	await get_tree().create_timer(1.1).timeout

	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.freeze = true
			room.position = room.position - size_fix_vector
			room.size = room.size - size_fix_vector
			room_positions.append(Vector2(room.position.x, room.position.y))

	path = find_minimum_spanning_tree(room_positions)


func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2), Color(32, 228, 0), false)

	if path:
		var existing_paths := {}

		for position_id in path.get_point_ids():
			for connection_id in path.get_point_connections(position_id):
				var key_x = min(position_id, connection_id)
				var key_y = max(position_id, connection_id)
				var connection_key = "%s,%s" % [key_x, key_y]

				if connection_key in existing_paths:
					continue

				existing_paths[connection_key] = null

				var start_point = path.get_point_position(position_id)
				var end_point = path.get_point_position(connection_id)
				var intermediate_point = Vector2(start_point.x, end_point.y)

				draw_line(start_point, intermediate_point, Color(1, 1, 0), 15, true)
				draw_line(intermediate_point, end_point, Color(1, 1, 0), 15, true)


func _process(_delta):
	queue_redraw()


func _input(event):
	if event.is_action_pressed("ui_select"):
		for n in $Rooms.get_children():
			n.queue_free()

		path = null
		make_rooms()

	if event.is_action_pressed("ui_focus_next"):
		make_map()


func find_minimum_spanning_tree(nodes):
	var mst_path = AStar2D.new()
	mst_path.add_point(mst_path.get_available_point_id(), nodes.pop_front())

	while nodes:
		var min_distance = INF
		var min_position = null
		var current_position = null

		for position_id in mst_path.get_point_ids():
			position = mst_path.get_point_position(position_id)

			for node in nodes:
				var current_distance = position.distance_to(node)

				if current_distance < min_distance:
					min_distance = current_distance
					min_position = node
					current_position = position

		var point_id = mst_path.get_available_point_id()
		mst_path.add_point(point_id, min_position)
		mst_path.connect_points(mst_path.get_closest_point(current_position), point_id)
		nodes.erase(min_position)

	return mst_path


func make_map():
	Map.clear()
	var full_rect = Rect2()

	for room in $Rooms.get_children():
		var room_rect = Rect2(
			room.position - room.size, room.get_node("CollisionShape2D").shape.extents * 2
		)

		full_rect = full_rect.merge(room_rect)

	var top_left = Map.local_to_map(full_rect.position)
	var bottom_right = Map.local_to_map(full_rect.end)

	for x in range(top_left.x, bottom_right.x):
		for y in range(top_left.y, bottom_right.y):
			Map.set_cell(0, Vector2i(x, y), 1, Vector2i.ZERO, 0)

	var existing_paths := {}
	for room in $Rooms.get_children():
		var size = (room.size / tile_size).floor()
		var position = Map.local_to_map(room.position)
		var upper_left = (room.position / tile_size).floor() - size
		
		for x in range(size.x * 2):
			for y in range(size.y * 2):
				Map.set_cell(0, Vector2i(upper_left.x + x, upper_left.y + y), 0, Vector2i.ZERO, 0)
		
		var position_id = path.get_closest_point(room.position)
		for connection_id in path.get_point_connections(position_id):
			var key_x = min(position_id, connection_id)
			var key_y = max(position_id, connection_id)
			var connection_key = "%s,%s" % [key_x, key_y]

			if connection_key in existing_paths:
				continue

			existing_paths[connection_key] = null

			var start = Map.local_to_map(path.get_point_position(position_id))
			var end = Map.local_to_map(path.get_point_position(connection_id))
			carve_path(start, end)


func carve_path(pos1, pos2):
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)

	if x_diff == 0: 
		x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: 
		y_diff = pow(-1.0, randi() % 2)

	var start = pos1
	var end = pos2
	
	if (randi() % 2) > 0:
		start = pos2
		end = pos1

	for w in (corridor_width - 1):
		for x in range(pos1.x, pos2.x, x_diff):
			Map.set_cell(0, Vector2i(x, start.y + (y_diff * w)), 0, Vector2i(0, 0), 0)
		for y in range(pos1.y, pos2.y, y_diff):
			Map.set_cell(0, Vector2i(end.x + (x_diff * w), y), 0, Vector2i(0, 0), 0)

