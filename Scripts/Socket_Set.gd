class_name Socket_Set

# TODO: Convert keys to Vector3.directions instead of 'xP', 'xN', business

func _init():
	pass


# Rotate the socket set by shuffling around the socket IDs relative to the faces
static func rotate_right(sockets:Dictionary, rotation_amt:int):
	rotation_amt %= 4
	if(rotation_amt == 0):
		return sockets
	elif(rotation_amt == 1):
		sockets = {
		'xP' : String(sockets['zN']),
		'xN' : String(sockets['zP']),
		'yP' : String(sockets['yP']),	# Unchanged
		'yN' : String(sockets['yN']),	# Unchanged
		'zP' : String(sockets['xP']),
		'zN' : String(sockets['xN'])
	}
	elif(rotation_amt == 2):
		sockets = {
		'xP' : String(sockets['xN']),
		'xN' : String(sockets['xP']),
		'yP' : String(sockets['yP']),	# Unchanged
		'yN' : String(sockets['yN']),	# Unchanged
		'zP' : String(sockets['zN']),
		'zN' : String(sockets['zP'])
	}
	elif(rotation_amt == 3):
		sockets = {
		'xP' : String(sockets['zP']),
		'xN' : String(sockets['zN']),
		'yP' : String(sockets['yP']),	# Unchanged
		'yN' : String(sockets['yN']),	# Unchanged
		'zP' : String(sockets['xN']),
		'zN' : String(sockets['xP'])
	}
	else:
		printerr("Unable to rotate socket - rotation amount arg needs to be between [1-3]")
	return sockets
# End func


# Get the socket key for the opposite direction
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
