
#TODO: 
# Use Vector3.directions instead of socket direction keys so that directions can be
# always consistent with the world directions

extends Spatial

var prototypes = Prototypes.new()
var rng = RandomNumberGenerator.new()

export var field_width = 3		# x and z dimensions
export var field_height = 3		# y dimension
export var cell_size = 2
var cell_nodes = []		# References to the scene nodes (for rendering meshes, etc.)

# Cell superpositions represent the state of each cell. 
# They are lists of indexes into the prototypes array in the Prototypes class.
# When a superposition list contains just one element, the cell has totally collapsed to a single state.
# The entropy of a call is the length of its superposition array.
var cell_superpositions = []
var num_cells = field_width * field_width * field_height
var num_cells_collapsed = 0

var stride_x	# Width dimension, increases by increments of width		(Vector3.RIGHT)
var stride_y	# Height dimension, increases by increments of width^2	(Vector3.UP)
var stride_z	# Width dimension, increases by increments of 1 		(Vector3.BACK)



# Generate 3D labels for the cells based on their index
func _ready():
	for i in range(num_cells):
		var label = get_node("Label3D")
		var new_label = label.duplicate()
		new_label.translation = cell_index_to_coordinate(i) * cell_size
		add_child(new_label)
		new_label.text = String(i)
		new_label.color = Color(0.2, 1.0, 0.7)
		
	dbg_create_all_protos()



# Create stuff
func _init():
	rng.randomize()
	stride_x = field_width
	stride_y = field_width * field_width
	stride_z = 1
	
	for i in range(num_cells):
		cell_superpositions.append(prototypes.get_max_entropy_index_list())
		var temp_node = Spatial.new()
		add_child(temp_node)
		cell_nodes.append(temp_node)
		regenerate_mesh_for_cell(i)
	
	var compatible_sockets = prototypes.get_compatible_sockets('tl-br', 'xP')
	print("compatible sockets: ", compatible_sockets)
	var proto_index = 12
	var dir_key = 'zN'
	var compatible_protos = prototypes.get_compatible_protos(proto_index, dir_key)
	print("protos compatible with ", proto_index, " in the direction: ", dir_key, ": ", compatible_protos)
	#prototypes.get_compatible_superpos(cell_superpositions[cell_up], compatible_protos_up)



# Call debug functions on input
func _input(event):
	if (event is InputEventKey and event.pressed):
		if (event.scancode == KEY_SPACE):
			
			var collapsed_cell_index
			
			if (num_cells_collapsed == 0):
				collapsed_cell_index = 13
				collapse_specific(collapsed_cell_index, 12)
			
			elif (num_cells_collapsed == 1):
				collapsed_cell_index = 12
				collapse_specific(collapsed_cell_index)
				
			elif (num_cells_collapsed == 2):
				collapsed_cell_index = 10
				collapse_specific(collapsed_cell_index)
			
			elif (num_cells_collapsed == 3):
				collapsed_cell_index = 16
				collapse_specific(collapsed_cell_index)
			
			elif (num_cells_collapsed == 4):
				collapsed_cell_index = 14
				collapse_specific(collapsed_cell_index)
			
			else:	# Else select the cell with min entropy and collapse to a random possible value
				collapsed_cell_index = collapse()
			
			if(collapsed_cell_index >= 0):
				propogate_entropy_adjacent(collapsed_cell_index)
				regenerate_mesh_for_cell(collapsed_cell_index)
				num_cells_collapsed += 1
		
		if (event.scancode == KEY_G): # Test function key
			pass



# Load all the prototypes into the scene so that its easy to see which ones are which
func dbg_create_all_protos():
	for i in range(len(prototypes.proto_list)):
		var cell_coordinates = Vector3(4 * cell_size, 0, i * cell_size * 2 - 25)
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
		top_socket_label.text = prototypes.proto_list[i]["sockets"]["yP"]
		top_socket_label.color = Color("#bd2900")
		top_socket_label.extrude = 0.01
		add_child(top_socket_label)
		
		var bottom_socket_label = label.duplicate()
		bottom_socket_label.translation = cell_coordinates
		bottom_socket_label.translation.y -= cell_size * 0.9
		bottom_socket_label.text_size = 0.5
		bottom_socket_label.text = prototypes.proto_list[i]["sockets"]["yN"]
		bottom_socket_label.color = Color("#bd2900")
		bottom_socket_label.extrude = 0.01
		add_child(bottom_socket_label)
		
		var left_socket_label = label.duplicate()
		left_socket_label.translation = cell_coordinates
		left_socket_label.translation.x -= cell_size * 0.9
		left_socket_label.text_size = 0.5
		left_socket_label.text = prototypes.proto_list[i]["sockets"]["xN"]
		left_socket_label.color = Color("#bd2900")
		left_socket_label.extrude = 0.01
		add_child(left_socket_label)
		
		var right_socket_label = label.duplicate()
		right_socket_label.translation = cell_coordinates
		right_socket_label.translation.x += cell_size * 0.9
		right_socket_label.text_size = 0.5
		right_socket_label.text = prototypes.proto_list[i]["sockets"]["xP"]
		right_socket_label.color = Color("#bd2900")
		right_socket_label.extrude = 0.01
		add_child(right_socket_label)
		
		var front_socket_label = label.duplicate()
		front_socket_label.translation = cell_coordinates
		front_socket_label.translation.z -= cell_size * 0.9
		front_socket_label.text_size = 0.5
		front_socket_label.text = prototypes.proto_list[i]["sockets"]["zN"]
		front_socket_label.color = Color("#bd2900")
		front_socket_label.extrude = 0.01
		add_child(front_socket_label)
		
		var back_socket_label = label.duplicate()
		back_socket_label.translation = cell_coordinates
		back_socket_label.translation.z += cell_size * 0.9
		back_socket_label.text_size = 0.5
		back_socket_label.text = prototypes.proto_list[i]["sockets"]["zP"]
		back_socket_label.color = Color("#bd2900")
		back_socket_label.extrude = 0.01
		add_child(back_socket_label)



# Collapse the cell with the lowest entropy. If there are multiple, choose a random one to collapse.
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
	if len(candidate_cells) == 0:
		print("<!> Unable to find a candidate cell to collapse")
		return -1
	else:
		print("Min entropty is ", min_entropy, " among candidates: ", candidate_cells)
		var rand_candidate = rng.randi_range(0, len(candidate_cells) -1)
		var cell_to_collapse = candidate_cells[rand_candidate]
		collapse_specific(cell_to_collapse)
		return cell_to_collapse



# Collapse the cell at the given index (remove all but one proto from its superposition)
func collapse_specific(index:int, new_superpos = -1):
	if(new_superpos == -1):
		var rand_superpos_index = rng.randi_range(0, len(cell_superpositions[index]) -1)
		new_superpos = cell_superpositions[index][rand_superpos_index]
	cell_superpositions[index] = [new_superpos]
	print("Collapsing cell: ", index, " to superpos: ", new_superpos)



# Updates the list of possible positions for each cell adjacent to the one at the given index
func propogate_entropy_adjacent(index:int):
	var origin_proto = cell_superpositions[index][0]
	var cell_up = get_index_adjacent_to(index, Vector3.UP)
	var cell_down = get_index_adjacent_to(index, Vector3.DOWN)
	var cell_left = get_index_adjacent_to(index, Vector3.LEFT)
	var cell_right = get_index_adjacent_to(index, Vector3.RIGHT)
	var cell_forward = get_index_adjacent_to(index, Vector3.FORWARD)
	var cell_back = get_index_adjacent_to(index, Vector3.BACK)
	
	if cell_up >= 0:
		var compatible_protos_up = prototypes.get_compatible_protos(origin_proto, 'yP')
		cell_superpositions[cell_up] = prototypes.get_compatible_superpos(cell_superpositions[cell_up], compatible_protos_up)
		print("cell_up: ", cell_up, ", new superpos: ", cell_superpositions[cell_up])
			
	if cell_down >= 0:
		var compatible_protos_down = prototypes.get_compatible_protos(origin_proto, 'yN')
		cell_superpositions[cell_down] = prototypes.get_compatible_superpos(cell_superpositions[cell_down], compatible_protos_down)
		print("cell_down: ", cell_down, ", new superpos: ", cell_superpositions[cell_down])
		
	if cell_left >= 0:
		var compatible_protos_left = prototypes.get_compatible_protos(origin_proto, 'xN')
		cell_superpositions[cell_left] = prototypes.get_compatible_superpos(cell_superpositions[cell_left], compatible_protos_left)
		print("cell_left: ", cell_left, ", new superpos: ", cell_superpositions[cell_left])
		
	if cell_right >= 0:
		var compatible_protos_right = prototypes.get_compatible_protos(origin_proto, 'xP')
		cell_superpositions[cell_right] = prototypes.get_compatible_superpos(cell_superpositions[cell_right], compatible_protos_right)
		print("cell_right: ", cell_right, ", new superpos: ", cell_superpositions[cell_right])
		
	if cell_forward >= 0:
		var compatible_protos_forward = prototypes.get_compatible_protos(origin_proto, 'zN')
		cell_superpositions[cell_forward] = prototypes.get_compatible_superpos(cell_superpositions[cell_forward], compatible_protos_forward)
		print("cell_forward: ", cell_forward, ", new superpos: ", cell_superpositions[cell_forward])
		
	if cell_back >= 0:
		var compatible_protos_back = prototypes.get_compatible_protos(origin_proto, 'zP')
		cell_superpositions[cell_back] = prototypes.get_compatible_superpos(cell_superpositions[cell_back], compatible_protos_back)
		print("cell_back: ", cell_back, ", new superpos: ", cell_superpositions[cell_back])



# Use cell superpos to load reload its mesh with the most up-to-date version
func regenerate_mesh_for_cell(index:int):
	var cell_coordinates = cell_index_to_coordinate(index)
	var cell_superpos = cell_superpositions[index]
	var new_mesh = prototypes.get_mesh_instance(cell_superpos[0])
	
	# Load a generic null mesh if the cell is uncollapsed
	if (len(cell_superpos) > 1):
		new_mesh.mesh = load("res://Meshes/chunk_null.obj")
	
	new_mesh.translation.x = cell_coordinates.x * cell_size
	new_mesh.translation.y = cell_coordinates.y * cell_size
	new_mesh.translation.z = cell_coordinates.z * cell_size
	cell_nodes[index].free() 	# Delete old node
	cell_nodes[index] = new_mesh	# Log new node
	add_child(new_mesh)	# Add new node to scene



# Removes the illegal protos from cell superposition. Assumes valid index args.
func superpos_restrict_single(index:int, illegal_protos:Array):
	var superp_tmp = cell_superpositions[index]
	for restriction in illegal_protos:
		if superp_tmp.has(restriction):
			superp_tmp.remove(superp_tmp.find(restriction))
	cell_superpositions[index] = superp_tmp # This line might not be needed if superp_tmp is ref



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
	adjacent_indexes.append(get_index_adjacent_to(origin, Vector3.UP))
	adjacent_indexes.append(get_index_adjacent_to(origin, Vector3.DOWN))
	adjacent_indexes.append(get_index_adjacent_to(origin, Vector3.RIGHT))
	adjacent_indexes.append(get_index_adjacent_to(origin, Vector3.LEFT))
	adjacent_indexes.append(get_index_adjacent_to(origin, Vector3.FORWARD))
	adjacent_indexes.append(get_index_adjacent_to(origin, Vector3.BACK))
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
