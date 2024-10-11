extends Node2D

var last_direction: String = ""
var move_speed: float = 200.0
var move_timer: float = 0.0
var move_duration: float = 0.5

var pokemon_slots: Array = [1, 2, 3]  # Lista de IDs de Pokémon en los slots

func get_pokemon_from_slot(slot_index: int) -> int:
	if slot_index >= 0 and slot_index < pokemon_slots.size():
		return pokemon_slots[slot_index]
	else:
		print("Error: Índice de slot fuera de rango.")
		return -1

func get_follower_sprite(pokemon_id: int, shiny: bool) -> AnimatedSprite:
	var animated_sprite = AnimatedSprite.new()
	var sprite_frames: SpriteFrames
	var sprite_frames_path: String

	if shiny:
		sprite_frames_path = "res://Graphics/FramesPK/" + str("%04d" % pokemon_id) + "_follower_shiny.tres"
	else:
		sprite_frames_path = "res://Graphics/FramesPK/" + str("%04d" % pokemon_id) + ".tres"

	var resource = ResourceLoader.load(sprite_frames_path)
	if resource and resource is SpriteFrames:
		sprite_frames = resource
	else:
		print("Error: No se encontró un SpriteFrames válido en la ruta ", sprite_frames_path)
		return null

	animated_sprite.frames = sprite_frames
	animated_sprite.name = "FollowerSprite"

	var animations = sprite_frames.get_animation_names()
	if animations.size() > 0:
		animated_sprite.animation = animations[0]
	else:
		print("Error: No hay animaciones disponibles en los SpriteFrames del seguidor.")

	animated_sprite.play()

	return animated_sprite

func update_follower_animation(follower_sprite: AnimatedSprite, direction: String) -> void:
	if direction == "":
		if follower_sprite.frames.has_animation("Walk"):
			follower_sprite.animation = "Walk"
			if not follower_sprite.is_playing():
				follower_sprite.play()
	else:
		if direction != last_direction:
			match direction:
				"Up", "Down", "Left", "Right":
					if follower_sprite.frames.has_animation(direction):
						follower_sprite.animation = direction
						follower_sprite.play()
						last_direction = direction
					else:
						print("Error: La animación '", direction, "' no existe en los SpriteFrames del seguidor.")
				_:
					print("Error: Dirección no reconocida para la animación del seguidor.")

func move_sprite(sprite: AnimatedSprite, delta: float) -> void:
	var direction = Vector2.ZERO
	
	match randi() % 4:
		0: direction = Vector2(1, 0)
		1: direction = Vector2(-1, 0)
		2: direction = Vector2(0, 1)
		3: direction = Vector2(0, -1)

	sprite.position += direction * move_speed * delta
	
	if direction.x > 0:
		update_follower_animation(sprite, "Right")
	elif direction.x < 0:
		update_follower_animation(sprite, "Left")
	elif direction.y > 0:
		update_follower_animation(sprite, "Down")
	elif direction.y < 0:
		update_follower_animation(sprite, "Up")

func _ready() -> void:
	var slot_index = 1
	var pokemon_id = get_pokemon_from_slot(slot_index)
	
	if pokemon_id != -1:
		var is_shiny = false
		var direction = ""
		
		var follower_sprite = get_follower_sprite(pokemon_id, is_shiny)
		
		if follower_sprite:
			add_child(follower_sprite)
			update_follower_animation(follower_sprite, direction)
		else:
			print("Error: No se pudo crear el AnimatedSprite del seguidor.")
	else:
		print("Error: No se pudo obtener el ID del Pokémon del slot.")

func _process(delta: float) -> void:
	var player_direction = get_player_direction()
	if $FollowerSprite:
		update_follower_animation($FollowerSprite, player_direction)

		if player_direction == "":
			move_timer += delta
			
			if move_timer >= move_duration:
				move_timer = 0
				move_sprite($FollowerSprite, delta)
		else:
			move_timer = 0

func get_player_direction() -> String:
	if Input.is_action_pressed("ui_up"):
		return "Up"
	elif Input.is_action_pressed("ui_down"):
		return "Down"
	elif Input.is_action_pressed("ui_left"):
		return "Left"
	elif Input.is_action_pressed("ui_right"):
		return "Right"

	return ""
