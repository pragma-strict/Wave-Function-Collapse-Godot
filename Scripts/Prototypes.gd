class_name Prototypes

# Socket details:
# 'empty'		<- air chunk
# 'cube'		
# 'sq'			<- square face not belonging to a full cube
# 'tl-br'		<- when facing chunk
# 'tr-bl'		<- when facing chunk
# 'no-surf'		<- chunk is not empty, but there is no surface on that side
# 'sq-bottom'
# 'sq-top'

# Prototype templates contain the base data for each tile. They are used to create prototypes, which are
# the rotated versions of the templates. There are 4 protos for each proto_template. Each proto has a 
# socket set which determines which, along with the socket compatibility mappings, determine which protos
# can be neighbors.

var proto_templates = [
	{
		'label' : 'cube',
		'mesh_ref' : 'res://Meshes/chunk_1_cube.obj',
		'sockets' : {
			'right' : 'cube',
			'left' : 'cube',
			'up' : 'sq-top',
			'down' : 'sq-bottom',
			'forward' : 'cube',
			'back' : 'cube'
		},
		'rot_symmetry' : '4-way'	# 4-way rotational symmetry means only one proto needs to be made 
	},								# from this template
	{
		'label' : 'wedge',
		'mesh_ref' : 'res://Meshes/chunk_2_wedge.obj',
		'sockets' : {
			'right' : 'no-surf',
			'left' : 'sq',
			'up' : 'no-surf',
			'down' : 'sq-bottom',
			'forward' : 'tr-bl',
			'back' : 'tl-br'
		},
		'rot_symmetry' : 'none'
	},
	{
		'label' : 'full_corner',
		'mesh_ref' : 'res://Meshes/chunk_3_full_corner.obj',
		'sockets' : {
			'right' : 'tr-bl',
			'left' : 'sq',
			'up' : 'no-surf',
			'down' : 'sq-bottom',
			'forward' : 'sq',
			'back' : 'tl-br'
		},
		'rot_symmetry' : 'none'
	},
	{
		'label' : 'shard',
		'mesh_ref' : 'res://Meshes/chunk_4_shard.obj',
		'sockets' : {
			'right' : 'no-surf',
			'left' : 'tl-br',
			'up' : 'no-surf',
			'down' : 'sq-bottom',
			'forward' : 'tr-bl',
			'back' : 'no-surf'
		},
		'rot_symmetry' : 'none'
	},
	{
		'label' : 'peak',
		'mesh_ref' : 'res://Meshes/chunk_5_peak.obj',
		'sockets' : {
			'right' : 'no-surf',
			'left' : 'no-surf',
			'up' : 'no-surf',
			'down' : 'sq-bottom',
			'forward' : 'no-surf',
			'back' : 'no-surf'
		},
		'rot_symmetry' : '4-way'
	},
	{
		'label' : 'air',
		'mesh_ref' : 'res://Meshes/chunk_6_air.obj',
		'sockets' : {
			'right' : 'empty',
			'left' : 'empty',
			'up' : 'empty',
			'down' : 'empty',
			'forward' : 'empty',
			'back' : 'empty'
		},
		'rot_symmetry' : '4-way'
	},
	{
		'label' : 'missing_corner',
		'mesh_ref' : 'res://Meshes/chunk_7_missing_corner.obj',
		'sockets' : {
			'right' : 'tr-bl',
			'left' : 'sq',
			'up' : 'no-surf',
			'down' : 'sq-bottom',
			'forward' : 'sq',
			'back' : 'tl-br'
		},
		'rot_symmetry' : 'none'
	}
]


# There are 4 protos per template, each with a unique socket set according to its rotation.
var proto_list = []


# Two-way socket compatibility mappings for horizontal adjacencies
var socket_mappings_horizontal = [
	['sq', 'sq'],
	['cube', 'cube'],
	['no-surf', 'no-surf'],
	['empty', 'empty'],
	['cube', 'sq'],
	['cube', 'empty'],
	['tl-br', 'tr-bl'],
	['empty', 'no-surf']
]


# Two-way socket compatibility mappings for vertical adjacencies
var socket_mappings_vertical = [
	['sq-top', 'sq-bottom'],
	['sq-top', 'angle-away'],
	['sq-top', 'angle-towards'],
	['no-surf', 'empty'],
	['empty', 'empty']
]



# Create prototypes from template data
func _init():
	create_protos_from_proto_templates()


# Create 4 prototypes per template, one for each rotation state
func create_protos_from_proto_templates():
	for i in range(len(proto_templates)):
		
		# Start by determing how many different rotation states (permutations) are required
		var symmetry_type = proto_templates[i]['rot_symmetry']
		var permutations = 4	# 4 permutations corresponds to 'none' symmetry label
		if symmetry_type == '2-way':
			permutations = 2
		elif symmetry_type == '4-way':
			permutations = 1
		
		# Actually generate the proto permutations
		for rot in range(permutations):
			var new_proto = proto_templates[i].duplicate(true)
			new_proto['sockets'] = rotate_sockets_right(new_proto['sockets'], rot)
			new_proto['rotation'] = rot
			proto_list.append(new_proto)


# Returns true if the proto at the given index is labelled as 'air'
func is_proto_air(index:int):
	if proto_list[index]['label'] == 'air':
		return true
	return false


# Return a list containing indexes to each prototype (just consecutive numbers from 0-len(proto_list))
func get_max_entropy_index_list():
	var index_list = []
	for i in range(len(proto_list)):
		index_list.append(i)
	return index_list


# Return a list of proto indexes that can be adjacent to the given superpos in the given direction
# TODO: Replace Array.has() calls with the 'in' keyword
func get_possible_neighbors(superpos:Array, dir_key:String):
	var possible_neighbors = []
	
	for proto in superpos:
		# Get opposite-facing sockets that are compatibile with this socket
		var this_socket = proto_list[proto]["sockets"][dir_key]
		var compatible_sockets = get_compatible_sockets(this_socket, dir_key)
		
		# Get the opposite direction key
		var opp_dir_key = get_opposite_socket_direction_key(dir_key)
		
		# Find protos with a compatible opposite-facing socket
		for i in range(len(proto_list)):
			var opposite_socket = proto_list[i]["sockets"][opp_dir_key]
			if compatible_sockets.has(opposite_socket):	# If this proto's opposite socket is compatible...
				if !possible_neighbors.has(i):			# add it to our list if it isn't there already.
					possible_neighbors.append(i)
	
	return possible_neighbors


# Return an array of sockets that are compatible with the given socket in the given direction
func get_compatible_sockets(socket_code:String, dir_key:String):
	var compatible_sockets = []
	var horizonal_dir_keys = ['right', 'left', 'forward', 'back']
	var mapping_set
	
	# Figure out whether we're looking at horizontal or vertical mappings
	if(horizonal_dir_keys.has(dir_key)):
		mapping_set = socket_mappings_horizontal
	else:
		mapping_set = socket_mappings_vertical
	
	# Loop through the mapping set and append compatible partners to list
	for i in range(len(mapping_set)):
		var socket_A = mapping_set[i][0]
		var socket_B = mapping_set[i][1]
		if socket_A == socket_code:
			compatible_sockets.append(socket_B)
		elif socket_B == socket_code:
			compatible_sockets.append(socket_A)
	
	return compatible_sockets


# Return new superpos with only the compatible protos remaining (return intersection of arrays)
# TODO: Make static
func get_constrained_superpos(original_superpos:Array, allowed_protos:Array):
	var new_superpos = []
	for proto in original_superpos:
		if allowed_protos.has(proto):
			new_superpos.append(proto)
	return new_superpos


# Gets the mesh for a given proto. Basically just handles the rotation.
func get_mesh_instance(proto_index):
	var mesh = MeshInstance.new()
	var proto_ref = proto_list[proto_index]
	mesh.mesh = load(proto_ref["mesh_ref"])
	mesh.rotate_y(deg2rad(-90 * proto_ref["rotation"]))
	return mesh


# Get the socket key for the opposite direction
static func get_opposite_socket_direction_key(dir_key:String):
	if (dir_key == 'right'):
		return 'left'
	if (dir_key == 'left'):
		return 'right'
	if (dir_key == 'up'):
		return 'down'
	if (dir_key == 'down'):
		return 'up'
	if (dir_key == 'forward'):
		return 'back'
	if (dir_key == 'back'):
		return 'forward'


# Recursively rotate a socket set by shuffling around the socket IDs relative to the faces
static func rotate_sockets_right(sockets:Dictionary, rotation_amt:int):
	rotation_amt %= 4
	if(rotation_amt == 0):		# Base case
		return sockets
	sockets = {					# Rotate the socket set once
		'right' : String(sockets['forward']),
		'left' : String(sockets['back']),
		'up' : String(sockets['up']),		# Unchanged
		'down' : String(sockets['down']),	# Unchanged
		'back' : String(sockets['right']),
		'forward' : String(sockets['left'])
	}
	return rotate_sockets_right(sockets, rotation_amt -1)


# Returns the intersection of two arrays where order doesn't matter
# Possibly naive implementation, NOT TESTED
static func util_set_intersect(arr_1:Array, arr_2:Array):
	var intersection = []
	for element in arr_1:
		if arr_2.has(element):
			intersection.append(element)
	return intersection




#=====================================#
# THE GRAVEYARD OF DEPRECATED METHODS #
#                RIP                  #
#=====================================#
