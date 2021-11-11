class_name Socket_Set

# TODO: Convert keys to Vector3.directions instead of 'xP', 'xN', business

func _init():
	pass


# Rotate the socket set by shuffling around the socket IDs relative to the faces
static func rotate_right(sockets:Dictionary, rotation_amt:int):
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
	return rotate_right(sockets, rotation_amt -1)
# End func


# Get the socket key for the opposite direction
static func get_opposite_direction_key(dir_key:String):
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
# End func
