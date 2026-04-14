extends CanvasLayer


var touch_finger_index = -1
var last_touch_pos = Vector2()

func _input(event):
	if event is InputEventScreenTouch:
		# НОВАЯ ПРОВЕРКА: Если нажатие уже "съела" кнопка или джойстик — выходим
		if event.is_pressed() and get_viewport().gui_get_focus_owner():
			return
		
		# Также можно проверять через проверку "поглощения" события
		# Но самый надежный способ для тача — проверка координат
		var screen_size = get_viewport().get_visible_rect().size
		
		# Если джойстик слева, мы просто игнорируем левую половину экрана
		if event.position.x > screen_size.x / 2:
			if event.pressed:
				touch_finger_index = event.index
				last_touch_pos = event.position
			elif event.index == touch_finger_index:
				touch_finger_index = -1
