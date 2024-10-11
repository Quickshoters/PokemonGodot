extends TextureRect

var cry
var sprite : AnimatedSprite  # Especificar AnimatedSprite aquí

func _ready():
	# No liberamos el AnimatedSprite inmediatamente aquí, lo manejamos en `setup_by_pokemon`
	pass

func setup_by_pokemon(poke):
	cry = poke.get_cry()
	
	# Obtener el AnimatedSprite desde la función get_battle_foe_sprite()
	var new_sprite = poke.get_battle_foe_sprite()  # Siempre será AnimatedSprite
	new_sprite.name = "AnimatedSprite"
	
	# Verificar si ya existe un AnimatedSprite dentro de "Battler" y eliminarlo si es necesario
	if $Battler.has_node("AnimatedSprite"):
		var existing_sprite = $Battler.get_node("AnimatedSprite")
		if existing_sprite != null:
			existing_sprite.queue_free()

	# Añadir el nuevo AnimatedSprite a la escena
	$Battler.add_child(new_sprite)
	sprite = new_sprite  # Actualizamos la referencia al AnimatedSprite
	
	# Verificar que sprite.frames y sprite.animation no son null
	if sprite.frames != null and sprite.animation != "":
		# Configurar la sombra con el primer frame del AnimatedSprite
		$Battler/Shadow.texture = sprite.frames.get_frame(sprite.animation, 0)
	else:
		print("Error: 'sprite.frames' o 'sprite.animation' es nulo.")

func ball_flash():
	# Asegurarse de que el AnimatedSprite no es nulo antes de acceder a él
	if sprite != null:
		$Battler.visible = true
		sprite.visible = true

		var scene = load("res://Utilities/Battle/BallFlash.tscn")
		var ballflash = scene.instance()
		self.add_child(ballflash)
		ballflash.position = Vector2(272, -100)

		# Reproducir sonido de "Recall"
		$Ball/AudioStreamPlayer.stream = load("res://Audio/SE/recall.wav")
		$Ball/AudioStreamPlayer.play()
		yield($Ball/AudioStreamPlayer, "finished")

		# Reproducir sonido de "Cry"
		$Ball/AudioStreamPlayer.stream = load(cry)
		$Ball/AudioStreamPlayer.play()

		# Reproducir la animación correcta
		$Battler/AnimationPlayer.play("UnveilDrop")
	else:
		print("Error: El nodo 'sprite' es nulo.")

# Nueva función para establecer la bola
func set_ball(ball_type):
	# Assuming 'Ball' is some visual node that represents the ball
	match ball_type:
		"Pokeball":
			$Ball.texture = load("res://Graphics/Balls/pokeball.png")
		"GreatBall":
			$Ball.texture = load("res://Graphics/Balls/greatball.png")
		"UltraBall":
			$Ball.texture = load("res://Graphics/Balls/ultraball.png")
		_:
			print("Unknown ball type: ", ball_type)
