
#TODO: Rename all row, col and depth to x, y and z so we know how the relate to the world

extends Spatial

var prototypes = Prototypes.new()
var rng = RandomNumberGenerator.new()

export var function_width = 4
export var cell_size = 2
var cell_superpositions = []		# 3D matrix where each element is a list of indexes into prototypes.list array
var cell_nodes = []		# Init with empty spatial nodes
var num_cells = pow(function_width, 3)


func regenerate_mesh_for_cell(x_index, y_index, z_index):
	var superp_tmp = cell_superpositions[x_index][y_index][z_index]
	var new_mesh = MeshInstance.new()
	
	if (len(superp_tmp) == 1):
		new_mesh.mesh = load(prototypes.proto_list[superp_tmp[0]]["mesh_ref"])
	else:
		new_mesh.mesh = load("res://Meshes/chunk_null.obj")
		
	new_mesh.translation.x = x_index * cell_size
	new_mesh.translation.y = y_index * cell_size
	new_mesh.translation.z = z_index * cell_size
	cell_nodes[x_index][y_index][z_index].free() 	# Delete old node
	cell_nodes[x_index][y_index][z_index] = new_mesh	# Log new node
	add_child(new_mesh)	# Add new node to scene


func _init():
	for x in range(function_width):
		cell_superpositions.append([])
		cell_nodes.append([])
		for y in range(function_width):
			cell_superpositions[x].append([])
			cell_nodes[x].append([])
			for z in range(function_width):
				cell_superpositions[x][y].append(prototypes.get_max_entropy_index_list())
				var temp_node = Spatial.new()
				add_child(temp_node)
				cell_nodes[x][y].append(temp_node)
				regenerate_mesh_for_cell(x, y, z)


# Removes the illegal protos from cell superposition. Assumes valid index args.
func superpos_restrict_single(x_index, y_index, z_index, illegal_protos:Array):
	var superp_tmp = cell_superpositions[x_index][y_index][z_index]
	for restriction in illegal_protos:
		if superp_tmp.has(restriction):
			superp_tmp.remove(superp_tmp.find(restriction))
	cell_superpositions[x_index][y_index][z_index] = superp_tmp # This line might not be needed if superp_tmp is ref


# Removes all but one proto index from superposition, collapsing the cell to given state 
func superpos_collapse_to_value(x_index, y_index, z_index, value):
	cell_superpositions[x_index][y_index][z_index] = value


# Removes all but one proto index from superposition, collapsing the cell to random possible state 
func superpos_collapse_to_random(x_index, y_index, z_index):
	var collapsed_proto = rng.randi_range(0, len(cell_superpositions[x_index][y_index][z_index]) -1)
	superpos_restrict_recursive(x_index, y_index, z_index, [collapsed_proto])
	
	# Collapse a neighboring cell to see if we have compatibility errors
	if (x_index < 3):
		var possible_neighbors = prototypes.get_compatible_protos(collapsed_proto, 'xP')
		var random_selection = rng.randi_range(0, len(possible_neighbors) -1)
		var neighbor_proto_index = possible_neighbors[random_selection]
		superpos_restrict_recursive(x_index+1, y_index, z_index, [neighbor_proto_index])
		regenerate_mesh_for_cell(x_index+1, y_index, z_index)
	else:
		var possible_neighbors = prototypes.get_compatible_protos(collapsed_proto, 'xN')
		var random_selection = rng.randi_range(0, len(possible_neighbors) -1)
		var neighbor_proto_index = possible_neighbors[random_selection]
		superpos_restrict_recursive(x_index-1, y_index, z_index, [neighbor_proto_index])
		regenerate_mesh_for_cell(x_index-1, y_index, z_index)
	
	
func superpos_restrict_recursive(x_index, y_index, z_index, new_superpos:Array):
	cell_superpositions[x_index][y_index][z_index] = new_superpos # Update superpos for this cell
	for proto_index in new_superpos:
		var xP_compatibility_dict = {}
		#var xP_compatible_protos = prototypes.get_compatible_protos(proto_index, 'xP')
		print("xP compatible: ", prototypes.get_compatible_protos(proto_index, 'xP'))
		print("xN compatible: ", prototypes.get_compatible_protos(proto_index, 'xN'))
		print("yP compatible: ", prototypes.get_compatible_protos(proto_index, 'yP'))
		print("yN compatible: ", prototypes.get_compatible_protos(proto_index, 'yN'))
	# To begin, I know all the possible states of this node (my superpos)
	# For each adjacent node I want to find the set of restrictions on that node
	# I can do that by tallying all the possible sockets that that node would have to have on its border with this node
	# From that I can extract any sockets that don't appear
	# Any nodes with those sockets will be a restriction on next node
	# If there is a restriction I'll make a list of the possible states of the next node and recursively call
	# If there are no restrictions I'll simply return	


func _input(event):
	if (event is InputEventKey and event.pressed):
		if (event.scancode == KEY_SPACE):
			
			# Collapse a test cell
			rng.randomize()
			var row = rng.randi_range(0, function_width - 1)
			var col = rng.randi_range(0, function_width - 1)
			var depth = rng.randi_range(0, function_width - 1)
			superpos_collapse_to_random(row, col, depth)
			regenerate_mesh_for_cell(row, col, depth)
			print(cell_superpositions[row][col][depth])

		if (event.scancode == KEY_G): # Test function key
			pass
