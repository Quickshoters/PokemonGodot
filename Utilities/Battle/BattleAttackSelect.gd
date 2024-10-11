extends Node2D

signal command_received

var enabled = false
var selected = 1
var moves = 0  # Cambiado para contar los movimientos válidos
const MOVE1_POS = Vector2(110, 0)
const MOVE2_POS = Vector2(335, 0)
const MOVE3_POS = Vector2(560, 0)
const MOVE4_POS = Vector2(775, 0)

const MOVE_SLIDE_1 = Vector2(20, 0)
const MOVE_SLIDE_2 = Vector2(-200, 0)
const MOVE_SLIDE_3 = Vector2(-420, 0)
const MOVE_SLIDE_4 = Vector2(-640, 0)

var battler

onready var select_se_1 = load("res://Audio/SE/SE_Select1.wav")
onready var select_se_2 = load("res://Audio/SE/SE_Select2.wav")

func _ready():
	$MoveSlide/SelHand/AnimationPlayer.play("Squeez")

func reset(): # To be called when the player battler is switched
	selected = 1
	moves = 0  # Reiniciar el contador de movimientos
	$MoveSlide/SelHand.position = MOVE1_POS

func start(poke):
	battler = poke
	moves = 0  # Reiniciar el contador de movimientos
	$MoveSlide/Move1.visible = false
	$MoveSlide/Move2.visible = false
	$MoveSlide/Move3.visible = false
	$MoveSlide/Move4.visible = false

	if poke.move_1 != null:
		set_move_sprite($MoveSlide/Move1, poke.move_1)
		$MoveSlide/Move1.visible = true
		moves += 1  # Aumentar el contador de movimientos
	if poke.move_2 != null:
		set_move_sprite($MoveSlide/Move2, poke.move_2)
		$MoveSlide/Move2.visible = true
		moves += 1
	if poke.move_3 != null:
		set_move_sprite($MoveSlide/Move3, poke.move_3)
		$MoveSlide/Move3.visible = true
		moves += 1
	if poke.move_4 != null:
		set_move_sprite($MoveSlide/Move4, poke.move_4)
		$MoveSlide/Move4.visible = true
		moves += 1

	enabled = true
	change_Sel_Hand_Pos()  # Asegúrate de mover el cursor de selección al primer movimiento

func set_move_sprite(sprite, move):
	sprite.frame = int(move.type)
	sprite.get_node("Name").bbcode_text = "[center]" + move.name
	sprite.get_node("PP").text = "PP: " + str(move.remaining_pp) + "/" + str(move.total_pp)

func _input(event):
	if enabled:
		if event.is_action_pressed("ui_left") and selected > 1:
			selected -= 1
			change_Sel_Hand_Pos()
		if event.is_action_pressed("ui_right") and selected < moves:
			selected += 1
			change_Sel_Hand_Pos()
		if event.is_action_pressed("ui_accept"):
			$MoveSlide/SelHand/AudioStreamPlayer.stream = select_se_2
			$MoveSlide/SelHand/AudioStreamPlayer.play()
			
			var command = load("res://Utilities/Battle/Classes/BattleCommand.gd").new()
			command.command_type = command.ATTACK
			command.attack_target = command.B2 # Target Foe default
			
			var move = null  # Inicializar move como null
			
			match selected:
				1:
					move = battler.move_1
				2:
					move = battler.move_2
				3:
					move = battler.move_3
				4:
					move = battler.move_4
			
			# Asegúrate de que move no sea null antes de acceder a sus propiedades
			if move != null:
				command.attack_move = move.name
				
				# Set target of move
				if move.target_ability == MoveTarget.SELF:
					command.attack_target = command.B1

				if move.remaining_pp != 0:
					$AnimationPlayer.play_backwards("Slide")
					self.visible = false
					enabled = false
					emit_signal("command_received", command)
				else:
					print("Error: El movimiento no tiene PP disponible.")
			else:
				print("Error: El movimiento seleccionado es null.")

		if event.is_action_pressed("x"): # Go back to command select
			enabled = false
			self.visible = false
			self.get_parent().get_node("BattleComandSelect").enabled = true
			self.get_parent().get_node("BattleComandSelect").visible = true


func change_Sel_Hand_Pos():
	$MoveSlide/SelHand/AudioStreamPlayer.stream = select_se_1
	$MoveSlide/SelHand/AudioStreamPlayer.play()
	var tween = $MoveSlide/Tween

	match selected:
		1:
			$MoveSlide/SelHand.position = MOVE1_POS
			$MoveSlide/Move1/AnimationPlayer.play("Slide")
			$MoveSlide/Move2/AnimationPlayer.stop(true)
			$MoveSlide/Move3/AnimationPlayer.stop(true)
			$MoveSlide/Move4/AnimationPlayer.stop(true)
			tween.interpolate_property($MoveSlide, "position", $MoveSlide.position, MOVE_SLIDE_1, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
			tween.start()
		2:
			$MoveSlide/SelHand.position = MOVE2_POS
			$MoveSlide/Move2/AnimationPlayer.play("Slide")
			$MoveSlide/Move1/AnimationPlayer.stop(true)
			$MoveSlide/Move3/AnimationPlayer.stop(true)
			$MoveSlide/Move4/AnimationPlayer.stop(true)
			tween.interpolate_property($MoveSlide, "position", $MoveSlide.position, MOVE_SLIDE_2, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
			tween.start()
		3:
			$MoveSlide/SelHand.position = MOVE3_POS
			$MoveSlide/Move3/AnimationPlayer.play("Slide")
			$MoveSlide/Move1/AnimationPlayer.stop(true)
			$MoveSlide/Move2/AnimationPlayer.stop(true)
			$MoveSlide/Move4/AnimationPlayer.stop(true)
			tween.interpolate_property($MoveSlide, "position", $MoveSlide.position, MOVE_SLIDE_3, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
			tween.start()
		4:
			$MoveSlide/SelHand.position = MOVE4_POS
			$MoveSlide/Move4/AnimationPlayer.play("Slide")
			$MoveSlide/Move1/AnimationPlayer.stop(true)
			$MoveSlide/Move2/AnimationPlayer.stop(true)
			$MoveSlide/Move3/AnimationPlayer.stop(true)
			tween.interpolate_property($MoveSlide, "position", $MoveSlide.position, MOVE_SLIDE_4, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
			tween.start()
