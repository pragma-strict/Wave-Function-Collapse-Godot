extends Spatial

var prototypes = Prototypes.new()
var rng = RandomNumberGenerator.new()

export var field_width = 4		# x and z dimensions
export var field_height = 5		# y dimension
export var cell_size = 2

var cell_nodes = []		# References to the scene nodes (for rendering meshes, etc.)
var cell_labels = []	# References to the debug labels for each cell
var cell_superpositions = []

var num_cells = field_width * field_width * field_height
var num_cells_collapsed = 0

var debug_mode = false

var stride_x	# Width dimension, increases by increments of width		(Vector3.RIGHT)
var stride_y	# Height dimension, increases by increments of width^2	(Vector3.UP)
var stride_z	# Width dimension, increases by increments of 1 		(Vector3.BACK)



# Generate 3D labels for the cells based on their index
func _ready():
	if debug_mode:
		dbg_generate_cell_labels()
		dbg_create_all_protos()
	pass



# Create stuff
func _init():
	rng.randomize()
	stride_x = field_width
	stride_y = field_width * field_width
	stride_z = 1
	reset_cells()



# Call debug functions on input
func _input(event):
	if (event is InputEventKey and event.pressed):
		if (event.scancode == KEY_SPACE):
			var collapsed_cell_index
			
			if (num_cells_collapsed == 0):
				collapsed_cell_index = 15
				collapse_specific(collapsed_cell_index, 0)
			else:
				collapsed_cell_index = collapse()
			
			if(collapsed_cell_index >= 0):
				propogate(collapsed_cell_index)
				num_cells_collapsed += 1
		elif (event.scancode == KEY_R):
			reset_cells()
			if debug_mode:
				dbg_generate_cell_labels()


# Load all the prototypes into the scene so that its easy to see which ones are which
func dbg_create_all_protos():
	for i in range(len(prototypes.proto_list)):
		var cell_coordinates = Vector3(8 * cell_size, 0, i * cell_size * 2 - 25)
		var new_mesh = prototypes.get_mesh_instance(i)
		
		new_mesh.translation.x = cell_coordinates.x
		new_mesh.translation.y = cell_coordinates.y
		new_mesh.translation.z = cell_coordinates.z
		
		add_child(new_mesh)	# Add new node to scene
		
		var label = get_node("Label3D")
		
		# Add the proto index above the mesh
		var new_label = label.duplicate()
		new_label.translation = cell_coordinates
		new_label.translation.y += 2 * cell_size * 0.9
		new_label.text = String(i)
		new_label.color = Color(0.2, 1.0, 0.7)
		add_child(new_label)
		
		# Add the socket labels on each face of the mesh
		var top_socket_label = label.duplicate()
		top_socket_label.translation = cell_coordinates
		top_socket_label.translation.y += cell_size * 0.9
		top_socket_label.text_size = 0.5
		top_socket_label.text = prototypes.proto_list[i]["sockets"]["up"]
		top_socket_label.color = Color("#bd2900")
		top_socket_label.extrude = 0.01
		add_child(top_socket_label)
		
		var bottom_socket_label = label.duplicate()
		bottom_socket_label.translation = cell_coordinates
		bottom_socket_label.translation.y -= cell_size * 0.9
		bottom_socket_label.text_size = 0.5
		bottom_socket_label.text = prototypes.proto_list[i]["sockets"]["down"]
		bottom_socket_label.color = Color("#bd2900")
		bottom_socket_label.extrude = 0.01
		add_child(bottom_socket_label)
		
		var left_socket_label = label.duplicate()
		left_socket_label.translation = cell_coordinates
		left_socket_label.translation.x -= cell_size * 0.9
		left_socket_label.text_size = 0.5
		left_socket_label.text = prototypes.proto_list[i]["sockets"]["left"]
		left_socket_label.color = Color("#bd2900")
		left_socket_label.extrude = 0.01
		add_child(left_socket_label)
		
		var right_socket_label = label.duplicate()
		right_socket_label.translation = cell_coordinates
		right_socket_label.translation.x += cell_size * 0.9
		right_socket_label.text_size = 0.5
		right_socket_label.text = prototypes.proto_list[i]["sockets"]["right"]
		right_socket_label.color = Color("#bd2900")
		right_socket_label.extrude = 0.01
		add_child(right_socket_label)
		
		var front_socket_label = label.duplicate()
		front_socket_label.translation = cell_coordinates
		front_socket_label.translation.z -= cell_size * 0.9
		front_socket_label.text_size = 0.5
		front_socket_label.text = prototypes.proto_list[i]["sockets"]["forward"]
		front_socket_label.color = Color("#bd2900")
		front_socket_label.extrude = 0.01
		add_child(front_socket_label)
		
		var back_socket_label = label.duplicate()
		back_socket_label.translation = cell_coordinates
		back_socket_label.translation.z += cell_size * 0.9
		back_socket_label.text_size = 0.5
		back_socket_label.text = prototypes.proto_list[i]["sockets"]["back"]
		back_socket_label.color = Color("#bd2900")
		back_socket_label.extrude = 0.01
		add_child(back_socket_label)


# Creates 3D labels for each cell to help with debugging
func dbg_generate_cell_labels():
	for i in range(num_cells):
		dbg_generate_cell_label_single(i)


# Creates a 3D label for the given cell to help with debugging
# Note this works by creating a copy of a label that was already placed in the scene (hacky)
func dbg_generate_cell_label_single(index):
	var label_text = str(index, ": ")	# Generate the label text
	var superpos = cell_superpositions[index]
	for i in range(len(superpos)):
		if (i % 5 == 0):
			label_text += str("\n")
		label_text += str(" ", superpos[i])
	
	var label
	if(index >= len(cell_labels)):	# Generate new label node if there aren't enough already (dubious condition)
		var original_label = get_node("Label3D")
		label = original_label.duplicate()
		label.translation = cell_index_to_coordinate(index) * cell_size
		label.text_size = 0.2
		var color = Color(rng.randf(), rng.randf(), rng.randf())
		label.color = color
		add_child(label)
		cell_labels.append(label)
	else:
		label = cell_labels[index]
	label.text = label_text


# Collapse one of the cells with lowest entropy
func collapse():
	var min_entropy = len(prototypes.proto_list)
	var candidate_cells = []
	for i in range(num_cells):
		var entropy = len(cell_superpositions[i])
		if entropy > 1:
			if entropy < min_entropy:
				min_entropy = entropy
				candidate_cells.clear()
				candidate_cells.append(i)
			elif entropy == min_entropy:
				candidate_cells.append(i)

	if len(candidate_cells) == 0:	# Return -1 if no candidates found
		print("<!> Unable to find a candidate cell to collapse")
		return -1
	else:
		# Choose a candidate to collapse by trying various methods, then collapse it
		var candidate = candidate_select_nonair_neighbor(candidate_cells)
		if candidate == -1:
			candidate = candidate_select_random(candidate_cells)
		collapse_specific(candidate)
		return candidate


# Return the a collapse candidate (by index) which has a collapsed, non-air neighbor, or -1 if none found
func candidate_select_nonair_neighbor(candidates):
	var candidates_checked = 0
	var current_index = rng.randi_range(0, len(candidates) -1)
	
	# Check each neighbor of each candidate to see if they have a collapsed, non-air neighbor
	while(candidates_checked < len(candidates)):
		var candidate = candidates[current_index]
		var neighbors = get_adjacent_cells(candidate)
		for neighbor in neighbors:
			if is_cell_collapsed(neighbor) and !is_cell_air(neighbor): # If we find a candidate 	
				return candidate
		
		# Increment counters
		candidates_checked += 1
		current_index += 1
		if current_index == len(candidates):
			current_index = 0
	print("<!> Unable to find candidate with a collapsed, non-air neighbor")
	return -1


# Return a random candidate from the list
func candidate_select_random(candidates):
	var index = rng.randi_range(0, len(candidates) -1)
	return candidates[index]


# Collapse the cell at the given index (remove all but one proto from its superposition)
# Optional superpos argument allows you to specify what to collapse to.
func collapse_specific(index:int, new_superpos = -1):
	if(new_superpos == -1):
		var rand_superpos_index = rng.randi_range(0, len(cell_superpositions[index]) -1)
		new_superpos = cell_superpositions[index][rand_superpos_index]
	cell_superpositions[index] = [new_superpos]
	regenerate_mesh_for_cell(index)
	if debug_mode:
		dbg_generate_cell_label_single(index)
		#print("Collapsing cell: ", index, " to superpos: ", new_superpos)
		pass


# Recursively propogates the state of a given cell throughout all other cells
func propogate(index:int, depth = 0, max_depth = 16):
	if depth > max_depth:
		return
	
	var neighbors = get_neighbor_kernel(index)
	for dir_key in neighbors.keys():
		var neighbor_index = neighbors[dir_key]
		var neighbor_superpos = cell_superpositions[neighbor_index]
		var neighbor_allowed_protos = prototypes.get_possible_neighbors(cell_superpositions[index], dir_key)
		var new_neighbor_superpos = prototypes.get_constrained_superpos(neighbor_superpos, neighbor_allowed_protos)
		
		# If neighbor's superpos is affected, update it and propogate from neighbor
		if neighbor_superpos != new_neighbor_superpos:
			cell_superpositions[neighbor_index] = new_neighbor_superpos
			if len(new_neighbor_superpos) == 0:
				print("Warning: assigning an empty superposition!")
			if len(new_neighbor_superpos) == 1:
				collapse_specific(neighbor_index)
			propogate(neighbor_index, depth + 1)
			if debug_mode:
				dbg_generate_cell_label_single(neighbor_index)


# Use cell superpos to load reload its mesh with the most up-to-date version
func regenerate_mesh_for_cell(index:int):
	var cell_superpos = cell_superpositions[index]
	if len(cell_superpos) > 0:
		var cell_coordinates = cell_index_to_coordinate(index)
		var new_mesh = prototypes.get_mesh_instance(cell_superpos[0])
		
		# Load a generic null mesh if the cell is uncollapsed
		if (len(cell_superpos) > 1):
			new_mesh.mesh = load("res://Meshes/chunk_0_uncollapsed.obj")
		
		new_mesh.translation.x = cell_coordinates.x * cell_size
		new_mesh.translation.y = cell_coordinates.y * cell_size
		new_mesh.translation.z = cell_coordinates.z * cell_size
		cell_nodes[index].free() 	# Delete old node
		cell_nodes[index] = new_mesh	# Log new node
		add_child(new_mesh)	# Add new node to scene
	else:
		print("Error - regenerate_mesh_for_cell(): cell superpos is empty")


# Returns true if cell at given index is collapsed
func is_cell_collapsed(index:int):
	if len(cell_superpositions[index]) == 1:
		return true
	return false


# Returns true if the cell at given index is collapsed to an air/empty tile
func is_cell_air(index:int):
	var superpos = cell_superpositions[index]
	if len(superpos) == 1:
		if prototypes.is_proto_air(superpos[0]):
			return true
	return false


# Resets all cells to their original (highest-entropy) states
func reset_cells():
	print("============= RESETTING CELLS =============")
	num_cells_collapsed = 0
	for i in range(len(cell_nodes)):
		cell_nodes[i].queue_free()
	cell_superpositions.clear()
	cell_nodes.clear()
	for i in range(num_cells):
		cell_superpositions.append(prototypes.get_max_entropy_index_list())
		var temp_node = Spatial.new()
		add_child(temp_node)
		cell_nodes.append(temp_node)
		regenerate_mesh_for_cell(i)


# Return the index adjacent to origin in the given direction or -1 if there is none.
func get_index_adjacent_to(origin:int, direction:Vector3):
	var coordinate = cell_index_to_coordinate(origin)
	
	if(direction == Vector3.UP):
		if(coordinate.y < field_height -1):
			return origin + stride_y
		else:
			return -1
	
	if(direction == Vector3.DOWN):
		if(coordinate.y > 0):
			return origin - stride_y
		else:
			return -1
	
	if(direction == Vector3.RIGHT):
		if(coordinate.x < field_width -1):
			return origin + stride_x
		else:
			return -1
	
	if(direction == Vector3.LEFT):
		if(coordinate.x > 0):
			return origin - stride_x
		else:
			return -1
	
	if(direction == Vector3.FORWARD):
		if(coordinate.z > 0):
			return origin - stride_z
		else:
			return -1
	
	if(direction == Vector3.BACK):
		if(coordinate.z < field_width -1):
			return origin + stride_z
		else:
			return -1


# Return all of the indexes adjacent to origin or -1 if there are none.
# TODO: Make the function do what the above comment says. Currently it will return -1s.
func get_adjacent_cells(origin:int):
	var adjacent_indexes = []
	
	# Get each neighbor index
	var cell_up = get_index_adjacent_to(origin, Vector3.UP)
	var cell_down = get_index_adjacent_to(origin, Vector3.DOWN)
	var cell_right = get_index_adjacent_to(origin, Vector3.RIGHT)
	var cell_left = get_index_adjacent_to(origin, Vector3.LEFT)
	var cell_forward = get_index_adjacent_to(origin, Vector3.FORWARD)
	var cell_back = get_index_adjacent_to(origin, Vector3.BACK)
	
	# Append whichever of the neighbors did not come back as -1 (not found)
	if (cell_up != -1):
		adjacent_indexes.append(cell_up)
	if (cell_down != -1):
		adjacent_indexes.append(cell_down)
	if (cell_left != -1):
		adjacent_indexes.append(cell_left)
	if (cell_right != -1):
		adjacent_indexes.append(cell_right)
	if (cell_forward != -1):
		adjacent_indexes.append(cell_forward)
	if (cell_back != -1):
		adjacent_indexes.append(cell_back)
	
	return adjacent_indexes


# Return the Vector3 coordinate of the cell at a given index
func cell_index_to_coordinate(index:int):
	var coordinate = Vector3()
	coordinate.x = int(floor(index / stride_x)) % field_width
	coordinate.y = int(floor(index / stride_y))
	coordinate.z = int(floor(index / stride_z)) % field_width
	return coordinate


# Return the index of the cell at a given coordinate
func cell_coordinate_to_index(coordinate:Vector3):
	var index = coordinate.x * stride_x
	index += coordinate.y * stride_y
	index += coordinate.z * stride_z
	return index


# Return a dictionary of neighbors where keys are the direction. No entry when no neighbor exists. 
func get_neighbor_kernel(origin):
	var neighbors = {}
	
	var cell_up = get_index_adjacent_to(origin, Vector3.UP)
	var cell_down = get_index_adjacent_to(origin, Vector3.DOWN)
	var cell_left = get_index_adjacent_to(origin, Vector3.LEFT)
	var cell_right = get_index_adjacent_to(origin, Vector3.RIGHT)
	var cell_forward = get_index_adjacent_to(origin, Vector3.FORWARD)
	var cell_back = get_index_adjacent_to(origin, Vector3.BACK)
	
	if (cell_up != -1):
		neighbors['up'] = cell_up
	if (cell_down != -1):
		neighbors['down'] = cell_down
	if (cell_left != -1):
		neighbors['left'] = cell_left
	if (cell_right != -1):
		neighbors['right'] = cell_right
	if (cell_forward != -1):
		neighbors['forward'] = cell_forward
	if (cell_back != -1):
		neighbors['back'] = cell_back
	return neighbors


# Returns the intersection of two arrays where order doesn't matter
# Possibly naive implementation, NOT TESTED
func util_set_intersect(arr_1:Array, arr_2:Array):
	var intersection = []
	for element in arr_1:
		if arr_2.has(element):
			intersection.append(element)
	return intersection




#=======================================#
# THE GRAVEYARD OF DEPRECATED FUNCTIONS #
#                  RIP                  #
#=======================================#
