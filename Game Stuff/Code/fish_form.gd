extends Node2D

const TRIANGLE = preload("res://Game Stuff/Scenes/triangle.tscn")

var custom_target:bool = false
var fish = preload("res://Game Stuff/Scenes/fish.tscn")

var prev_pos = Vector2.ZERO
var fish_count = 0
var max = 20
var fish_chain = []


func _ready() -> void:
	for i in range(max):
		var new_fish = fish.instantiate()
		new_fish.position = prev_pos
		new_fish.name = "fish%d" % fish_count
		#new_fish.get_node("Label").text = new_fish.name
		if fish_count == 0: #>0
			#new_fish.target = fish_chain[fish_chain.size()-1]
			#new_fish.anchor = fish_chain[fish_count-1].anchor
		#else:
			get_target()
			new_fish.target = $"../target"
			new_fish.mode = "anchor"
			new_fish.anchor = new_fish
			#print(new_fish.anchor)
		else:
			new_fish.anchor = fish_chain[fish_count-1].anchor
			new_fish.approaching == true
		new_fish.z_index = -fish_count
		new_fish.scale = (max-(fish_count/2))*Vector2(.1,.1) #used to be fish.sprite.scale
		fish_count += 1
		add_child(new_fish)
		fish_chain.append(new_fish)
		prev_pos = new_fish.position
	await get_tree().process_frame
	await initialize_shape(fish_chain[0])
	await get_tree().process_frame
	await get_tree().process_frame

	for fishs in fish_chain:
		if fishs.mode == "fill":
			fishs.target = fishs.anchor.shape
func change_type(fishs, mode):
		var changing_fish = get_node(fishs)
		if changing_fish.mode != mode and changing_fish.name != "fish0":
			if mode == "anchor":
				get_target()
				changing_fish.target = $"../target"
				changing_fish.mode = "anchor"
				changing_fish.approaching = false
			else:
				var start = fish_chain.find(changing_fish)
				changing_fish.target = fish_chain[start-1]
				changing_fish.mode = "follow"
				changing_fish.approaching = true


func _physics_process(delta: float) -> void:
	for fishs in fish_chain:
		if fishs.target != null:
			var target_pos = fishs.target.global_position
			#wanders around
			if fishs.mode == "anchor":
				#if custom_target:
					#fishs.target = get_global_mouse_position()
				if await approach_target(fishs, target_pos, fishs.DISTANCE) == false:
					get_target()
				left_or_right(fishs, target_pos, true)
				if fishs.shape!= null:
					fishs.shape.global_position = fishs.global_position
					left_or_right(fishs.shape, fishs.target.global_position, false)
			#follows anchors
			elif fishs.mode == "fill":
				if !fishs.approaching:
					if fishs.global_position.distance_to(target_pos) > fishs.anchor.shape.area:
						fishs.approaching = true
					else:
						#fishs.position = fishs.target.position+(fishs.target.position.direction_to(fishs.global_position)*fishs.DISTANCE)
						fishs.direction = fishs.global_position.direction_to(target_pos + Vector2(randi_range(-100,100),randi_range(-100,100)))
						fishs.global_position += fishs.direction
						left_or_right(fishs, target_pos, true)
				#heads to following spot
				else:
					if await approach_target(fishs, target_pos, fishs.anchor.shape.area) == false:
						fishs.approaching = false
					left_or_right(fishs, fishs.target.position, true)
			else:
				if !fishs.approaching:
					#fishs.position = fishs.target.position+(fishs.target.position.direction_to(fishs.global_position)*fishs.DISTANCE)
					while fishs.global_position.distance_to(target_pos) > fishs.DISTANCE:
						fishs.direction = fishs.global_position.direction_to(target_pos)
						fishs.global_position += fishs.direction
					left_or_right(fishs, target_pos, true)
				#heads to following spot
				else:
					if await approach_target(fishs, target_pos, fishs.DISTANCE) == false:
						fishs.approaching = false
					left_or_right(fishs, fishs.target.position, true)

func get_target():
	$"../target".global_position = get_global_mouse_position()#Vector2(randi_range(-1200,1200),randi_range(-1200,1200))
	
func approach_target(fishs, target_pos, dist):
	var pos = fishs.global_position
	if pos.distance_to(target_pos) > dist:
		fishs.direction = pos.direction_to(target_pos)
		fishs.global_position += fishs.direction*fishs.speed
		return true
	else: return false

func left_or_right(fishs, target, flip:bool):
	fishs.look_at(to_global(target))
	if flip:
		if target.x < fishs.position.x:
			fishs.scale.y = -abs(fishs.scale.y)
		else:
			fishs.scale.y = abs(fishs.scale.y)
#Get points in triangle
#Assign an anchor
#Assign fish to follow points
#Assign other fish to go in middle, maybe distribute
func initialize_shape(anchor):
	var new_shape = TRIANGLE.instantiate()
	get_tree().current_scene.add_child(new_shape)
	anchor.shape = new_shape
	for children in anchor.shape.get_children():
		anchor.shape.points.append([null])
	var count = 3
	var OG_Shape = [anchor.shape.get_node("point0"),anchor.shape.get_node("point1"),anchor.shape.get_node("point2")]
	
	while anchor.shape.get_children().size()<fish_chain.size():
		var new_node2D = Node2D.new()
		new_node2D.name = "point"+str(count)
		new_node2D.position = anchor.shape.position + Vector2(randi_range(100,-100),randi_range(100,-100))
		var lowest_y = anchor.shape.get_node("point0")
		var lowest_x = anchor.shape.get_node("point0")
		for children in OG_Shape:
			if children.position.y < lowest_y.position.y:
				lowest_y = children
			elif children.position.y == lowest_y.position.y and children.position.x < lowest_x.position.x:
				lowest_x = children
				lowest_y = children
		var point = lowest_y.position
#Step 1: Find the point with the lowest y-coordinate. If there's two points with same y-coordinate, choose the one with the lowest x-coordinate. This is the pivot point.
#Step 2: Sort all other points based on the polar angle they make with the pivot point.
#Step 3: If two points have the same angle, discard the one that is closer to the pivot.
#Step 4: Push the pivot and the next two sorted points onto a stack.
#Step 5: For each remaining point in the sorted list, check the orientation formed by the top two points on the stack and the current point.
#Step 6: If the orientation is not a left turn, pop the top point from the stack.
#Step 7: Repeat the orientation check until a left turn is found, then push the current point onto the stack.
#Step 8: After processing all points, the stack contains the vertices of the convex hull in counter-clockwise order.
		
		anchor.shape.add_child(new_node2D)
		anchor.shape.points.append([null])
		count += 1
	assign_shape(anchor)
func assign_shape(anchor):
	var start = fish_chain.find(anchor)
	var count = 0
	for points in anchor.shape.points:
		
		#if points == null:
		if start + 1 < fish_chain.size():# and fish_chain[start+1].mode != "anchor"
			if fish_chain[start+1].mode != "anchor":
				var fishs = fish_chain[start+1]
				points = fish_chain[start+1]
				fishs.target = anchor.shape.get_node("point"+str(count))
				fishs.mode = "follow"
				fishs.approaching = true
				print(fishs)
				print(fishs.target.name)
				count += 1
			start += 1
#func _on_timer_1_timeout() -> void:
	#var rand = str(fish_chain[randi_range(1,fish_chain.size()-1)].name)
	#change_type(rand, "anchor")
	#await get_tree().create_timer(4.0).timeout
	#change_type(rand, "follow")
	#$Timer1.start()
#
#func _on_timer_2_timeout() -> void:
	#var rand = str(fish_chain[randi_range(1,fish_chain.size()-1)].name)
	#change_type(rand, "anchor")
	#await get_tree().create_timer(5.0).timeout
	#change_type(rand, "follow")
	#$Timer2.start()
#
#func _on_timer_3_timeout() -> void:
	#custom_target = true
	#await get_tree().create_timer(randi_range(1,3)).timeout
	#custom_target = false
	#$Timer3.start()
#
#func _on_timer_4_timeout() -> void:
	#for fishs in fish_chain:
		#change_type(str(fishs.name), "anchor")
	#await get_tree().create_timer(randi_range(6,8)).timeout
	#for fishs in fish_chain:
		#change_type(str(fishs.name), "follow")
	#$Timer4.start()
