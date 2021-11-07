class_name Socket_Set

#TODO: Don't actually store sockets here. Just provide some static functions to operate on sockets

var sockets = {
	'xP' : '0',
	'xN' : '0',
	'yP' : '0',
	'yN' : '0',
	'zP' : '0',
	'zN' : '0'
}

func _init(socket_data):
	sockets = socket_data

func get_rotated_copy(rotation_amt:int):
	"Returns a copy of the socket that has its values reassigned to represent a rotated version of the original."
	"This function rotates once to the right. The y values do not change."
	
	rotation_amt %= 4
	
	if(rotation_amt == 0):
		return sockets.duplicate()
	elif(rotation_amt == 1):
		return {
		'xP' : sockets['zN'],
		'xN' : sockets['zP'],
		'yP' : sockets['yP'],	# Unchanged
		'yN' : sockets['yN'],	# Unchanged
		'zP' : sockets['xP'],
		'zN' : sockets['xN']
	}
	elif(rotation_amt == 2):
		return {
		'xP' : sockets['xN'],
		'xN' : sockets['xP'],
		'yP' : sockets['yP'],	# Unchanged
		'yN' : sockets['yN'],	# Unchanged
		'zP' : sockets['zN'],
		'zN' : sockets['zP']
	}
	elif(rotation_amt == 3):
		return {
		'xP' : sockets['zP'],
		'xN' : sockets['zN'],
		'yP' : sockets['yP'],	# Unchanged
		'yN' : sockets['yN'],	# Unchanged
		'zP' : sockets['xN'],
		'zN' : sockets['xP']
	}
	else:
		printerr("Unable to rotate socket - rotation amount arg needs to be between [1-3]")
# End func


# Rotate the socket set by shuffling around the socket codes relative to the faces
func rotate_right(rotation_amt:int):
	"Rotate the socket set some number of steps to the right"
	rotation_amt %= 4
	var temp_sockets = {}
	if(rotation_amt == 0):
		return
	elif(rotation_amt == 1):
		temp_sockets = {
		'xP' : String(sockets['zN']),
		'xN' : String(sockets['zP']),
		'yP' : String(sockets['yP']),	# Unchanged
		'yN' : String(sockets['yN']),	# Unchanged
		'zP' : String(sockets['xP']),
		'zN' : String(sockets['xN'])
	}
	elif(rotation_amt == 2):
		temp_sockets = {
		'xP' : String(sockets['xN']),
		'xN' : String(sockets['xP']),
		'yP' : String(sockets['yP']),	# Unchanged
		'yN' : String(sockets['yN']),	# Unchanged
		'zP' : String(sockets['zN']),
		'zN' : String(sockets['zP'])
	}
	elif(rotation_amt == 3):
		temp_sockets = {
		'xP' : String(sockets['zP']),
		'xN' : String(sockets['zN']),
		'yP' : String(sockets['yP']),	# Unchanged
		'yN' : String(sockets['yN']),	# Unchanged
		'zP' : String(sockets['xN']),
		'zN' : String(sockets['xP'])
	}
	else:
		printerr("Unable to rotate socket - rotation amount arg needs to be between [1-3]")
	sockets = temp_sockets
# End func



static func get_opposite_direction_key(dir_key:String):
	if (dir_key == 'xP'):
		return 'xN'
	if (dir_key == 'xN'):
		return 'xP'
	if (dir_key == 'yP'):
		return 'yN'
	if (dir_key == 'yN'):
		return 'yP'
	if (dir_key == 'zP'):
		return 'zN'
	if (dir_key == 'zN'):
		return 'zP'
# End func
