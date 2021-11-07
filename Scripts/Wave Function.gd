
#TODO: Rename all row, col and depth to x, y and z so we know how the relate to the world

extends Spatial

var prototypes = Prototypes.new()
var rng = RandomNumberGenerator.new()

export var field_width = 3
export var field_height = 3
export var cell_size = 2
var cell_nodes = []		# References to the scene nodes (for rendering meshes, etc.)

# Cell superpositions represent the state of each cell. 
# They are lists of indexes into the prototypes array in the Prototypes class.
# When a superposition list contains just one element, the cell has totally collapsed to a single state.
# The entropy of a call is the length of its superposition array.
var cell_superpositions = []
var num_cells = field_width * field_width * field_height

var stride_x
var stride_y
var stride_z

func _ready():
	for i in range(num_cells):
		var label = get_node("Label3D")
		var new_label = label.duplicate()
		new_label.translation = cell_index_to_coordinate(i) * cell_size
		add_child(new_label)
		new_label.text = String(i)



# Create stuff
func _init():
	rng.randomize()
	stride_x = field_width * field_height
	stride_y = field_height
	stride_z = 1
	
	for i in range(num_cells):
		cell_superpositions.append(prototypes.get_max_entropy_index_list())
		var temp_node = Spatial.new()
		add_child(temp_node)
		cell_nodes.append(temp_node)
		regenerate_mesh_for_cell(i)

# Call debug functions on input
func _input(event):
	if (event is InputEventKey and event.pressed):
		if (event.scancode == KEY_SPACE):
			
			# Collapse a test cell
			#var index = rng.randi_range(0, len(cell_nodes) -1)
			#superpos_collapse_to_random(index)
			var collapsed_cell_index = collapse()
			if(collapsed_cell_index >= 0):
				propogate_entropy_adjacent(collapsed_cell_index)
				regenerate_mesh_for_cell(collapsed_cell_index)
				print("collapsed to: ", cell_superpositions[collapsed_cell_index])
				

		if (event.scancode == KEY_G): # Test function key
			pass


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
		print("Min entropty: ", min_entropy)
		print("Cells with min entropies: ", candidate_cells)
		var rand_candidate = rng.randi_range(0, len(candidate_cells) -1)
		var cell_to_collapse = candidate_cells[rand_candidate]
		superpos_collapse_to_random(cell_to_collapse)
		print("Cell to collapse: ", cell_to_collapse)
		return cell_to_collapse


# Updates the list of possible positions for each cell adjacent to the one at the given index
func propogate_entropy_adjacent(index:int):
	var origin_proto = cell_superpositions[index][0]
	var cell_up = get_index_adjacent_to(index, Vector3.UP)
	var cell_down = get_index_adjacent_to(index, Vector3.DOWN)
	var cell_left = get_index_adjacent_to(index, Vector3.LEFT)
	var cell_right = get_index_adjacent_to(index, Vector3.RIGHT)
	var cell_forward = get_index_adjacent_to(index, Vector3.FORWARD)
	var cell_back = get_index_adjacent_to(index, Vector3.BACK)
	cell_superpositions[cell_up] = prototypes.get_compatible_protos(origin_proto, 'yP')
	cell_superpositions[cell_down] = prototypes.get_compatible_protos(origin_proto, 'yN')
	cell_superpositions[cell_left] = prototypes.get_compatible_protos(origin_proto, 'xN')
	cell_superpositions[cell_right] = prototypes.get_compatible_protos(origin_proto, 'xP')
	cell_superpositions[cell_forward] = prototypes.get_compatible_protos(origin_proto, 'zN')
	cell_superpositions[cell_back] = prototypes.get_compatible_protos(origin_proto, 'zP')
	#print("up superpos: ", cell_superpositions[cell_up])
	#print("down superpos: ", cell_superpositions[cell_down])
	#print("left superpos: ", cell_superpositions[cell_left])
	#print("right superpos: ", cell_superpositions[cell_right])
	#print("forward superpos: ", cell_superpositions[cell_forward])
	#print("back superpos: ", cell_superpositions[cell_back])
	


# Use cell superpos to load reload its mesh with the most up-to-date version
func regenerate_mesh_for_cell(index:int):
	var cell_coordinates = cell_index_to_coordinate(index)
	var cell_superpos = cell_superpositions[index]
	var new_mesh = MeshInstance.new()
	
	if (len(cell_superpos) == 1):
		new_mesh.mesh = load(prototypes.proto_list[cell_superpos[0]]["mesh_ref"])
	else:
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


# Removes all but one proto index from superposition, collapsing the cell to given state 
func superpos_collapse_to_value(index:int, value):
	cell_superpositions[index] = value


# Removes all but one proto index from superposition, collapsing the cell to random possible state 
func superpos_collapse_to_random(index:int):
	var rand_superpos_index = rng.randi_range(0, len(cell_superpositions[index]) -1)
	var new_superpos = cell_superpositions[index][rand_superpos_index]
	cell_superpositions[index] = [new_superpos]


# Return the index adjacent to origin in the given direction
func get_index_adjacent_to(origin:int, direction:Vector3):
	var coordinate = cell_index_to_coordinate(origin)
	
	if(direction == Vector3.UP):
		if(coordinate.y < field_height -1):
			return origin + stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, 0, coordinate.z))
	
	if(direction == Vector3.DOWN):
		if(coordinate.y > 0):
			return origin - stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, field_height -1, coordinate.z))
	
	if(direction == Vector3.RIGHT):
		if(coordinate.x < field_width -1):
			return origin + stride_x
		else:
			return cell_coordinate_to_index(Vector3(0, coordinate.y, coordinate.z))
	
	if(direction == Vector3.LEFT):
		if(coordinate.x > 0):
			return origin - stride_x
		else:
			return cell_coordinate_to_index(Vector3(field_width -1, coordinate.y, coordinate.z))
	
	if(direction == Vector3.FORWARD):
		if(coordinate.z > 0):
			return origin - stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, coordinate.y, field_width -1))
	
	if(direction == Vector3.BACK):
		if(coordinate.z < field_width -1):
			return origin + stride_z
		else:
			return cell_coordinate_to_index(Vector3(coordinate.x, coordinate.y, 0))


# Return all of the indexes adjacent to origin
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
	coordinate.x = floor(index / (field_width * field_height))
	coordinate.y = int(floor(index / field_width)) % field_height
	coordinate.z = index % field_width
	return coordinate


# Return the index of the cell at a given coordinate
func cell_coordinate_to_index(coordinate:Vector3):
	var index = coordinate.x * stride_x
	index += coordinate.y * stride_y
	index += coordinate.z * stride_z
	return index
