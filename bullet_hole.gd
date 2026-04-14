extends Decal

func _ready():
	# Дырка исчезнет через 10 секунд
	await get_tree().create_timer(20.0).timeout
	queue_free()
