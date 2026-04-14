extends StaticBody3D

var health = 100
@onready var mesh = $MeshInstance3D

func take_damage(amount):
	health -= amount
	flash_red()
	print("У врага осталось здоровья: ", health)
	if health <= 0:
		queue_free()
func flash_red():
	var mesh_resource = mesh.mesh
	var original_material = mesh.get_surface_override_material(0)
	if original_material == null:
		original_material = mesh_resource.surface_get_material(0)
	
	if original_material:
		var temp_material = original_material.duplicate()
		temp_material.albedo_color = Color(1, 0, 0)
		mesh.set_surface_override_material(0, temp_material)
		await get_tree().create_timer(0.3).timeout
		mesh.set_surface_override_material(0, null)
