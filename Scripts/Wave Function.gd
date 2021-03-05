
#TODO: Rename all row, col and depth to x, y and z so we know how the relate to the world

extends Spatial

var prototypes = Prototypes.new()
var rng = RandomNumberGenerator.new()

export var field_width = 16
export var field_height = 4
export var cell_size = 2
var cell_nodes = []		# Node refs
var cell_superpositions = [] # For each cell, a list of indexes into prototypes.list array
var num_cells = field_width * field_width * field_height

var stride_x
var stride_y
var stride_z


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
			var index = rng.randi_range(0, len(cell_nodes) -1)
			superpos_collapse_to_random(index)
			regenerate_mesh_for_cell(index)
			print(cell_superpositions[index])

		if (event.scancode == KEY_G): # Test function key
			pass


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
	var rand_proto_decision = rng.randi_range(0, len(cell_superpositions[index]) -1)
	cell_superpositions[index] = [rand_proto_decision]


# I don't remember what this was originally supposed to do. Now it does nothing.
func superpos_restrict_recursive(index:int, new_superpos:Array):
	cell_superpositions[index] = new_superpos # Update superpos for this cell
	for proto_index in new_superpos:
		var xP_compatibility_dict = {}
		#var xP_compatible_protos = prototypes.get_compatible_protos(proto_index, 'xP')
		#print("xP compatible: ", prototypes.get_compatible_protos(proto_index, 'xP'))
		#print("xN compatible: ", prototypes.get_compatible_protos(proto_index, 'xN'))
		#print("yP compatible: ", prototypes.get_compatible_protos(proto_index, 'yP'))
		#print("yN compatible: ", prototypes.get_compatible_protos(proto_index, 'yN'))
	# To begin, I know all the possible states of this node (my superpos)
	# For each adjacent node I want to find the set of restrictions on that node
	# I can do that by tallying all the possible sockets that that node would have to have on its border with this node
	# From that I can extract any sockets that don't appear
	# Any nodes with those sockets will be a restriction on next node
	# If there is a restriction I'll make a list of the possible states of the next node and recursively call
	# If there are no restrictions I'll simply return	
	pass


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
