extends Camera

export(float, 0.1, 1.0) var mouse_sensitivity = 1.0
export(float, 1.0, 100.0) var movement_speed = 1.0

var is_mouse_captured = false

func _ready():
	pass
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta):
	if(Input.is_action_pressed("ui_up")):
		global_translate(Vector3(0, movement_speed * delta, 0))
	
	if(Input.is_action_pressed("ui_down")):
		global_translate(Vector3(0, -movement_speed * delta, 0))
	
	if(Input.is_action_pressed("ui_right")):
		translate(Vector3(movement_speed * delta, 0, 0))
	
	if(Input.is_action_pressed("ui_left")):
		translate(Vector3(-movement_speed * delta, 0, 0))
	
	if(Input.is_action_pressed("ui_forward")):
		translate(Vector3(0, 0, -movement_speed * delta))
	
	if(Input.is_action_pressed("ui_backward")):
		translate(Vector3(0, 0, movement_speed * delta))
	
func _input(event):
	if (event is InputEventMouseMotion):
		var mouse_motion = event.relative
		global_rotate(Vector3(0, 1, 0), -deg2rad(mouse_motion.x) * mouse_sensitivity)
		rotate_object_local(Vector3(1, 0, 0), -deg2rad(mouse_motion.y) * mouse_sensitivity)
	
	if (event is InputEventMouseButton):
		is_mouse_captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if (Input.is_action_pressed("ui_fullscreen")):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if (Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()

