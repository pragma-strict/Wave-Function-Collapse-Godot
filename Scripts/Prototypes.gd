class_name Prototypes

# TODO:
# Compatible sockets are not being found properly. You can run the program and look at the new superpos
# of adjacent cells after you spawn the first cell and you will see that their superpos contains many
# cells which they are not compatible with

# Socket ID details:
# 'empty'		<- air chunk
# 'cube'		
# 'sq'			<- square face not belonging to a full cube
# 'tl-br'		<- when facing chunk
# 'tr-bl'		<- when facing chunk
# 'no-surf'		<- chunk is not empty, but there is no surface on that side
# 'sq-bottom'
# 'sq-top'

# Each chunk (3D tile) gets a mesh reference and a set of socket codes - one for each face
# Note: The socket identifiers are those that a given face IS, not those that its compat. with
# TODO: rename to 'chunk_templates' or something. 
var chunk_data = [
	{
		'mesh_ref' : 'res://Meshes/chunk_1.obj',	# Cube
		'sockets' : {
			'xP' : 'cube',
			'xN' : 'cube',
			'yP' : 'sq-top',
			'yN' : 'sq-bottom',
			'zP' : 'cube',
			'zN' : 'cube'
		}
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_2.obj',	# Wedge
		'sockets' : {
			'xP' : 'no-surf',
			'xN' : 'sq',
			'yP' : 'no-surf',
			'yN' : 'sq-bottom',
			'zP' : 'tl-br',
			'zN' : 'tr-bl'
		}
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_3.obj',	# Full Corner
		'sockets' : {
			'xP' : 'tr-bl',
			'xN' : 'sq',
			'yP' : 'no-surf',
			'yN' : 'sq-bottom',
			'zP' : 'tl-br',
			'zN' : 'sq'
		}
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_4.obj',	# Shard
		'sockets' : {
			'xP' : 'no-surf',
			'xN' : 'tl-br',
			'yP' : 'no-surf',
			'yN' : 'sq-bottom',
			'zP' : 'no-surf',
			'zN' : 'tr-bl'
		}
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_null.obj',		# Air / empty cube
		'sockets' : {
			'xP' : 'empty',
			'xN' : 'empty',
			'yP' : 'empty',
			'yN' : 'empty',
			'zP' : 'empty',
			'zN' : 'empty'
		}
	}
]


# There are 4 protos for each chunk - each with a unique socket set according to its rotation. 
# Protos contain everything chunks contain PLUS a 'rotation' value as an int from [0-3].
var proto_list = []


# Two-way socket compatibility mappings for horizontal joints
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


# Two-way socket compatibility mappings for vertical joints
var socket_mappings_vertical = [
	['sq-top', 'sq-bottom'],
	['sq-top', 'angle-away'],
	['sq-top', 'angle-towards'],
	['sq-top', 'empty'],
	['no-surf', 'empty']
]


func _init():
	create_protos_from_chunk_data()


# Create 4 prototypes per chunk, one for each rotation state
func create_protos_from_chunk_data():
	for i in range(len(chunk_data)):
		for rot in range(4):
			var new_proto = chunk_data[i].duplicate(true)
			new_proto['sockets'] = Socket_Set.rotate_right(new_proto['sockets'], rot)
			new_proto['rotation'] = rot
			proto_list.append(new_proto)


# Get a list containing indexes to each prototype (just numbers from 0-len(proto_list))
func get_max_entropy_index_list():
	var index_list = []
	for i in range(len(proto_list)):
		index_list.append(i)
	return index_list


# Return true if two opposite-facing sockets are compatible
func are_horizontal_sockets_compatible(socket_code_A, socket_code_B):
	print("socket code A: ", socket_code_A, ", socket code B: ", socket_code_B)
	for i in range(len(socket_mappings_horizontal)):
		var map_A = socket_mappings_horizontal[i][0]
		var map_B = socket_mappings_horizontal[i][1]
		var forward_compat = (socket_code_A == map_A) && (socket_code_B == map_B)
		var backward_compat = (socket_code_A == map_B) && (socket_code_B == map_A)
		if (forward_compat || backward_compat):
			print("compatible")
			return true
	print("NOT compatible")
	return false


# Get a list of protos (by index) that can be adjacent to the given proto in the given direction
func get_compatible_protos(proto_index, this_dir_key:String):
	var compatible_protos = []		
	
	# Get sockets that are compatibile with THIS socket
	var this_socket = proto_list[proto_index]["sockets"][this_dir_key]
	var compatible_sockets = get_compatible_sockets(this_socket, this_dir_key)
	
	# Get the opposite direction key
	var other_dir_key = Socket_Set.get_opposite_direction_key(this_dir_key)
	
	# Look through protos and store those with an opposite socket on our compatible socket list
	#print("====== starting real deal ======")
	#print("this dir key: ", this_dir_key)
	#print("other dir key: ", other_dir_key)
	#print("this socket: ", this_socket)
	#print("compatible sockets: ", compatible_sockets)
	for i in range(len(proto_list)):
		var other_socket = proto_list[i]["sockets"][other_dir_key]
		#print("other socket (test) at index ", i, ": ", other_socket)
		if compatible_sockets.has(other_socket):
			#print("compatible proto list contains other socket (test). Appenging.")
			compatible_protos.append(i)
	
	return compatible_protos


# Return an array of sockets that are compatible with the given socket in the given direction
func get_compatible_sockets(socket_code:String, dir_key:String):
	var compatible_sockets = []
	var horizonal_dir_keys = ['xP', 'xN', 'zP', 'zN']
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


# Return new superpos with only the compatible protos remaining
func get_compatible_superpos(superpos:Array, compatible_protos:Array):
	var new_superpos = []
	for i in range(len(superpos)):
		if compatible_protos.has(superpos[i]):
			new_superpos.append(superpos[i])
	return new_superpos


func get_mesh_instance(proto_index):
	var mesh = MeshInstance.new()
	var proto_ref = proto_list[proto_index]
	mesh.mesh = load(proto_ref["mesh_ref"])
	mesh.rotate_y(deg2rad(-90 * proto_ref["rotation"]))
	return mesh
