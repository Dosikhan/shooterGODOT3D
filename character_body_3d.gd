extends CharacterBody3D

# --- Константы настроек ---
const SPEED = 8.0          # Скорость обычной ходьбы
const SPRINT_SPEED = 14.0   # Скорость бега (Shift)
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.002   # Чувствительность мыши
const BULLET_HOLE = preload("res://BulletHole.tscn") # Сцена дырки от пули

# --- Переменные состояния ---
var max_ammo = 120
var current_ammo = 30
var is_reloading = false    # Флаг блокировки стрельбы

# --- Ссылки на узлы ---
@onready var head = $head
@onready var camera = $head/Camera3D
@onready var raycast = $head/RayCast3D

# Эффекты и звуки (убедись, что пути совпадают с твоим деревом сцены)
@onready var muzzle_light = $head/Armature/OmniLight3D
@onready var muzzle_particles = $head/Armature/GPUParticles3D
@onready var shoot_sound = $head/Armature/ShootSound
@onready var reload_sound = $head/Armature/Reload
@onready var no_ammo_sound = $head/Armature/NoAmmo
@onready var ammo_label = $CanvasLayer/HUD/AmmoLabel

func _ready():
	# Захват курсора мыши
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_ammo_ui()

func _input(event):
	
	if event is InputEventMouseButton:
		if event.device < 0: 
			return
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_x(-event.relative.y * SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# Если идет перезарядка, игнорируем ввод для стрельбы и новой перезарядки
	if is_reloading:
		return

	# Логика нажатия кнопок
	if event.is_action_pressed("shoot"):
		if current_ammo > 0:
			shoot()
		else:
			play_no_ammo_sound()
			
	if event.is_action_pressed("reload") and current_ammo < 30 and max_ammo > 0:
		reload()

	# Вращение камеры мышью

func shoot():
	current_ammo -= 1
	update_ammo_ui()
	
	# Звук и визуальные эффекты
	play_shoot_sound()
	trigger_muzzle_flash()
	apply_recoil()
	
	# Проверка попадания
	if raycast.is_colliding():
		var target = raycast.get_collider()
		spawn_bullet_hole(raycast.get_collision_point(), raycast.get_collision_normal())

		if target.has_method("take_damage"):
			target.take_damage(5)
			print("Попал в: ", target.name)

func reload():
	is_reloading = true
	print("Перезарядка...")
	
	if reload_sound:
		reload_sound.play()
	
	# Таймер перезарядки (1.7 сек)
	await get_tree().create_timer(1.7).timeout
	
	# Математика патронов
	var need = 30 - current_ammo
	var amount = min(max_ammo, need)
	
	current_ammo += amount
	max_ammo -= amount
	
	update_ammo_ui()
	is_reloading = false
	print("Готов к стрельбе")

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Определяем скорость (спринт на Shift)
	var current_speed = SPEED
	if Input.is_action_pressed("shift") and is_on_floor():
		current_speed = SPRINT_SPEED

	# Обработка движения
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Плавный разгон (lerp)
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * 10.0)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * 10.0)
	else:
		# Плавное торможение
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)

	move_and_slide()

# --- Вспомогательные функции ---

func spawn_bullet_hole(pos, normal):
	var hole = BULLET_HOLE.instantiate()
	get_tree().root.add_child(hole)
	hole.global_position = pos
	# Поворот дырки по нормали поверхности
	if normal.is_equal_approx(Vector3.UP):
		hole.look_at(pos + normal, Vector3.RIGHT)
	else:
		hole.look_at(pos + normal, Vector3.UP)

func trigger_muzzle_flash():
	if muzzle_particles:
		muzzle_particles.emitting = true
		muzzle_particles.rotation.z = randf_range(0, 360)
	
	if muzzle_light:
		muzzle_light.visible = true
		muzzle_light.light_energy = randf_range(5.0, 10.0) # Энергию подбери под свой свет
		await get_tree().create_timer(0.05).timeout
		muzzle_light.visible = false

func apply_recoil():
	var tween = create_tween()
	# Рывок камеры вверх и плавный возврат
	tween.tween_property(camera, "rotation:x", deg_to_rad(2.0), 0.05).as_relative()
	tween.tween_property(camera, "rotation:x", deg_to_rad(-2.0), 0.15).as_relative()

func update_ammo_ui():
	if ammo_label:
		ammo_label.text = "Ammo: " + str(current_ammo) + " / " + str(max_ammo)

func play_shoot_sound():
	if shoot_sound:
		shoot_sound.pitch_scale = randf_range(0.9, 1.1)
		shoot_sound.play()

func play_no_ammo_sound():
	if no_ammo_sound:
		no_ammo_sound.pitch_scale = randf_range(0.9, 1.1)
		no_ammo_sound.play()
