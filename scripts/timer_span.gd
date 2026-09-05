extends Label


var elapsed_time := 0.0

func _process(delta):

	elapsed_time += delta

	var total_seconds = int(elapsed_time)
	
	@warning_ignore("integer_division")
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60

	text = "%02d:%02d" % [minutes, seconds]
