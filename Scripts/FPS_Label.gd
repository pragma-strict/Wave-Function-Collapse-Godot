extends Label


func _process(delta):
	var FPS = Performance.get_monitor(Performance.TIME_FPS)
	text = "FPS:" + str(FPS)
