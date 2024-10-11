extends TextureRect

var cry
var sprite : AnimatedSprite

func _ready():
	# No liberamos el AnimatedSprite inmediatamente aquí, lo manejamos en `setup_by_pokemon`
	pass

func setup_by_pokemon(poke):
	cry = poke.get_cry()

	# Obtener el AnimatedSprite desde la función get_battle_player_sprite()
	var animated_sprite = poke.get_battle_player_sprite()
	animated_sprite.name = "AnimatedSprite"

	# Verificar si ya existe un AnimatedSprite dentro de "Battler" y eliminarlo si es necesario
	if $Battler.has_node("AnimatedSprite"):
		var existing_sprite = $Battler.get_node("AnimatedSprite")
		if existing_sprite != null:
			# Eliminar de forma segura el AnimatedSprite anterior
			existing_sprite.queue_free()  # Marcar para eliminarlo

	# Asegurarse de que el AnimatedSprite anterior ha sido completamente removido
	yield(get_tree(), "idle_frame")  # Esperar un frame para que el anterior sprite se elimine completamente

	# Añadir el nuevo AnimatedSprite a la escena
	$Battler.add_child(animated_sprite)
	sprite = animated_sprite  # Actualizamos la variable sprite para hacer referencia al nuevo AnimatedSprite

	# Reiniciar y cargar los nuevos SpriteFrames
	if animated_sprite is AnimatedSprite and animated_sprite.frames != null:
		# Reiniciar animación al primer frame
		animated_sprite.stop()  # Detener cualquier animación en curso
		animated_sprite.frame = 0  # Reiniciar al primer frame
		animated_sprite.play()  # Reproducir la animación por defecto (opcional)
		
		# Acceder al primer frame de la animación y asignarlo como textura de la sombra
		$Battler/Shadow.texture = animated_sprite.frames.get_frame(animated_sprite.animation, 0)
	else:
		print("Error: El nodo no es un AnimatedSprite o no tiene frames asignados.")

func ball_flash():
	# Aquí te aseguras de que el sprite no es nulo antes de acceder a él
	if sprite != null:
		$Battler.visible = true
		sprite.visible = true
		
		var scene = load("res://Utilities/Battle/BallFlash.tscn")
		var ballflash = scene.instance()
		self.add_child(ballflash)
		ballflash.position = Vector2(272, -100)
		
		# Play Recall sound
		$Ball/AudioStreamPlayer.stream = load("res://Audio/SE/recall.wav")
		$Ball/AudioStreamPlayer.play()
		yield($Ball/AudioStreamPlayer, "finished")
		
		# Play cry sound
		$Ball/AudioStreamPlayer.stream = load(cry)
		$Ball/AudioStreamPlayer.play()
		
		# Play animation
		$Battler/AnimationPlayer.play("UnveilDropPlayer")
	else:
		print("Error: El nodo 'sprite' es nulo.")
