class_name Prototypes

var proto_list = []

# Socket ID cheat sheet:
#  -1:	Any
#	0:	Empty / Air
#	1:	Square
#	2:	Angle: top left -> bottom right
#	3:	Angle: top right -> bottom left (mirror of #2)

# Each chunk (3D tile) gets a mesh reference and a set of socket codes - one for each face
var chunk_data = [
	{
		'mesh_ref' : 'res://Meshes/chunk_1.obj',	# Full cube
		'sockets' : Socket_Set.new({
			'xP' : '-1',
			'xN' : '-1',
			'yP' : '-1',
			'yN' : '1',
			'zP' : '-1',
			'zN' : '-1'
		})
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_2.obj',
		'sockets' : Socket_Set.new({
			'xP' : '-1',
			'xN' : '1',
			'yP' : '0',
			'yN' : '1',
			'zP' : '3',
			'zN' : '2'
		})
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_3.obj',
		'sockets' : Socket_Set.new({
			'xP' : '2',
			'xN' : '1',
			'yP' : '0',
			'yN' : '1',
			'zP' : '3',
			'zN' : '1'
		})
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_4.obj',
		'sockets' : Socket_Set.new({
			'xP' : '-1',
			'xN' : '3',
			'yP' : '0',
			'yN' : '1',
			'zP' : '-1',
			'zN' : '2'
		})
	},
	{
		'mesh_ref' : 'res://Meshes/chunk_null.obj',		# Air / empty
		'sockets' : Socket_Set.new({
			'xP' : '-1',
			'xN' : '-1',
			'yP' : '-1',
			'yN' : '-1',
			'zP' : '-1',
			'zN' : '-1'
		})
	}
]


# Create 4 prototypes per chunk, one for each rotation state
func create_protos_from_chunk_data():
	for i in range(len(chunk_data)):
		for rot in range(4):
			var new_proto = chunk_data[i].duplicate()
			new_proto['sockets'].rotate_right(rot)
			new_proto['rotation'] = rot
			proto_list.append(new_proto)
	for i in range(4):	
		print(proto_list[i + 4]['sockets'].sockets)


func _init():
	create_protos_from_chunk_data()


# Get a list containing indexes to each prototype
func get_max_entropy_index_list():
	var index_list = []
	for i in range(len(proto_list)):
		index_list.append(i)
	return index_list


# Return true if two opposite-facing sockets are compatible
func check_sockets_compatible(socket_type_A, socket_type_B):
	if(socket_type_A == "-1" || socket_type_B == "-1" || socket_type_A == socket_type_B):
		return true
	return false


# Get a list of proto indexes that are incompatible with the given socket type and direction
# Note: Give the direction of the socket you have, not the sockets you want to find
func get_incompatible_protos_from_socket(socket_type:String, direction_key_this:String):
	var index_list = []
	var direction_key_other = Socket_Set.get_opposite_direction_key(direction_key_this)
	for i in range(len(proto_list)):
		if (proto_list[i]['sockets']["xP"] != socket_type):
			index_list.append(i)
	return index_list


# Get a list of proto indexes whose sockets match given socket type and direction
# Note: Give the direction of the socket you have, not the sockets you want to find
func get_compatible_protos_from_socket(socket_type:String, direction_key_this:String):
	var index_list = []
	var direction_key_other = Socket_Set.get_opposite_direction_key(direction_key_this)
	for i in range(len(proto_list)):
		if (proto_list[i]['sockets'][direction_key_other] == socket_type):
			index_list.append(i)
	return index_list


# Get a list of protos (by index) that could be adjacent to the given proto in the given direction
func get_compatible_protos(proto_index, direction_key:String):
	var protos = []
	var opposite_dir_key = Socket_Set.get_opposite_direction_key(direction_key)
	var socket_type = proto_list[proto_index]["sockets"].sockets[direction_key]
	for i in range(len(proto_list)):
		if (check_sockets_compatible(proto_list[i]['sockets'].sockets[opposite_dir_key], socket_type)):
			protos.append(i)
	return protos


func get_mesh_instance(proto_index):
	var mesh = MeshInstance.new()
	var proto_ref = proto_list[proto_index]
	mesh.mesh = load(proto_ref["mesh_ref"])
	mesh.rotate_y(deg2rad(90 * proto_ref["rotation"]))
	return mesh
