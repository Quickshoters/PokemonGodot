extends Node

var battle_instance : BattleInstanceData
var queue : BattleQueue
var registry
var battle_logic : BattleLogic

var battler1 : Pokemon # Player's pokemon
var battler2 : Pokemon # Foe's pokemon
var battler3 : Pokemon # Player's second pokemon in double battles
var battler4 : Pokemon # Foe's second pokemon double battles

export var effect_weight = 0.0 # Used for stat change animation
var effect_enable = false
var effect_shader

var battle_command : BattleCommand

var battle_is_over = false
var player_won = false

var battle_debug = true
var action_timer
var leveled_up_pokes = []

signal wait
signal EndOfBattleLoop
signal battle_complete
signal continue_pressed

func _ready():
	$CanvasLayer/BattleGrounds.visible = false
	$CanvasLayer/TransitionEffects.visible = false
	$CanvasLayer/BattleInterfaceLayer/BattleBars.visible = false
	$CanvasLayer/BattleInterfaceLayer/Message.visible = false
	$CanvasLayer/BattleInterfaceLayer/PlayerToss.visible = false
	$CanvasLayer/BattleInterfaceLayer/BattleComandSelect.visible = false
	$CanvasLayer/BattleGrounds/ColorRect.color = Color("000000")
	$CanvasLayer/BattleGrounds/ColorRect.visible = true
	$CanvasLayer/BattleInterfaceLayer/BattleAttackSelect.visible = false
	$CanvasLayer/ColorRect.visible = false
	$CanvasLayer/BattleInterfaceLayer/LevelUp.visible = false
	$CanvasLayer/BattleInterfaceLayer/BattleBag.visible = false
	$CanvasLayer/BattleGrounds/FoeBase/Ball.visible = false
	$CanvasLayer/BattleGrounds/PlayerBase/Ball.visible = false
	$CanvasLayer/BattleGrounds/PlayerBase/Battler.visible = false
	$CanvasLayer/BattleGrounds/PlayerBase/Battler.scale = Vector2(1.2, 1.2)
	$CanvasLayer/BattleGrounds/PlayerBase/Battler.modulate = Color(1.0,1.0,1.0,1.0)
	$CanvasLayer/BattleGrounds/PlayerBase/Battler.position = Vector2(270,-100)
	$CanvasLayer/BattleGrounds/FoeBase/Battler.hide()
	$CanvasLayer/BattleGrounds/FoeBase/Battler.position = Vector2(140, -80)
	$CanvasLayer/BattleGrounds/FoeBase/Battler.scale = Vector2(0.2, 0.2)
	$CanvasLayer/BattleInterfaceLayer/YesNo.hide()
	$CanvasLayer/BattleInterfaceLayer/Evolution.hide()
	action_timer = Timer.new()
	self.add_child(action_timer)
	action_timer.connect("timeout", self, "action_timeout")
	registry = load("res://Utilities/Battle/Database/Pokemon/registry.gd").new()
	
	# Check if we are testing
	if Global.past_events.size() == 0:
		test()
		battle_debug = true
	pass

func _ready2():
	# Aquí inicializamos effect_shader y otros parámetros
	var shader_path : String = "res://Graphics/Shaders/StatChange.shader"
	var shader : Shader = load(shader_path) as Shader
	if shader:
		effect_shader = ShaderMaterial.new()
		effect_shader.shader = shader
	else:
		print("Error: No se pudo cargar el shader desde la ruta ", shader_path)
		return  # Salir si el shader no se cargó correctamente

func _process(_delta):
	if effect_enable and effect_shader:
		effect_shader.set_shader_param("effect_weight", effect_weight)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		emit_signal("continue_pressed")

	if $CanvasLayer/BattleInterfaceLayer/YesNo.visible:
		if event.is_action_pressed("ui_left"):
			$CanvasLayer/BattleInterfaceLayer/YesNo/Select.position = Vector2(170, 260)
			$CanvasLayer/BattleInterfaceLayer/BattleComandSelect/SelHand/AudioStreamPlayer.play()
		if event.is_action_pressed("ui_right"):
			$CanvasLayer/BattleInterfaceLayer/YesNo/Select.position = Vector2(350, 260)
			$CanvasLayer/BattleInterfaceLayer/BattleComandSelect/SelHand/AudioStreamPlayer.play()
		pass



func test():
	var BID = load("res://Utilities/Battle/Classes/BattleInstanceData.gd")
	var OPP = load("res://Utilities/Battle/Classes/Opponent.gd")
	var bid = BID.new()
	bid.battle_type = BID.BattleType.SINGLE_WILD
	bid.battle_back = BID.BattleBack.FOREST
	bid.opponent = OPP.new()
	# bid.opponent.name = "Theo"
	bid.opponent.opponent_type = Opponent.OPPONENT_WILD
	bid.opponent.ai = load("res://Utilities/Battle/Classes/AI.gd").new()
	bid.opponent.ai.AI_Behavior = bid.opponent.ai.WILD
	# bid.opponent.after_battle_quote = "EVENT_MOKI_LAB_FIRST_POK_Battle_WIN"

	var poke = Pokemon.new()
	poke.set_basic_pokemon_by_level(1, 5)
	bid.opponent.pokemon_group.append(poke)
	
	bid.opponent.battle_texture = load("res://Graphics/Characters/trainer086.png")

	poke = Pokemon.new()
	poke.set_basic_pokemon_by_level(3, 5)
	poke.experience += 75
	Global.pokemon_group.append(poke)
	Global.TrainerGender = 0
	
	Start_Battle(bid)

func set_Vs_textures():
	match battle_instance.opponent.name:
		"Theo":
			$CanvasLayer/TransitionEffects/Vs/OpponentBanner.texture = load("res://Graphics/Transitions/vsTrainer86.png")
			$CanvasLayer/TransitionEffects/Vs/SpriteLeft.texture = load("res://Graphics/Transitions/vsBar86.png")
			$CanvasLayer/TransitionEffects/Vs/SpriteRight.texture = load("res://Graphics/Transitions/vsBar86.png")
			$CanvasLayer/TransitionEffects/Vs/OpponentBanner/Label.bbcode_text = "[center]" + battle_instance.opponent.name
		"LEADER Maria":
			$CanvasLayer/TransitionEffects/Vs/OpponentBanner.texture = load("res://Graphics/Transitions/vsTrainer71.png")
			$CanvasLayer/TransitionEffects/Vs/SpriteLeft.texture = load("res://Graphics/Transitions/vsBar71.png")
			$CanvasLayer/TransitionEffects/Vs/SpriteRight.texture = load("res://Graphics/Transitions/vsBar71.png")
			$CanvasLayer/TransitionEffects/Vs/OpponentBanner/Label.bbcode_text = "[center]" + "Maira"
		_:
			print("Battle Error: Invalid opponent texture on function set_Vs_textures")
	$CanvasLayer/TransitionEffects/Vs/SpriteLeft.texture.flags = Texture.FLAG_REPEAT
	$CanvasLayer/TransitionEffects/Vs/SpriteRight.texture.flags = Texture.FLAG_REPEAT
	$CanvasLayer/TransitionEffects/Vs/SpriteLeft.region_enabled = true
	$CanvasLayer/TransitionEffects/Vs/SpriteRight.region_enabled = true
	$CanvasLayer/TransitionEffects/Vs/SpriteLeft.region_rect = Rect2(Vector2(0,0), Vector2(256,128))
	$CanvasLayer/TransitionEffects/Vs/SpriteRight.region_rect = Rect2(Vector2(0,0), Vector2(256,128))

func set_gender_textures():
	match Global.TrainerGender:
		0:
			$CanvasLayer/TransitionEffects/Vs/PlayerBanner.texture = load("res://Graphics/Transitions/vsTrainer0.png")
			$CanvasLayer/BattleInterfaceLayer/PlayerToss.texture = load("res://Graphics/Characters/trback000.png")
		1:
			$CanvasLayer/TransitionEffects/Vs/PlayerBanner.texture = load("res://Graphics/Transitions/vsTrainer9.png")
			$CanvasLayer/BattleInterfaceLayer/PlayerToss.texture = load("res://Graphics/Characters/trback009.png")
		2:
			$CanvasLayer/TransitionEffects/Vs/PlayerBanner.texture = load("res://Graphics/Transitions/vsTrainer1.png")
			$CanvasLayer/BattleInterfaceLayer/PlayerToss.texture = load("res://Graphics/Characters/trback001.png")
	$CanvasLayer/TransitionEffects/Vs/PlayerBanner/Label.bbcode_text = "[center]" + Global.TrainerName

func set_battle_music():
	match battle_instance.battle_type:
		battle_instance.BattleType.RIVAL:
			$CanvasLayer/AudioStreamPlayer.stream = load("res://Audio/BGM/PU-TheoBattle.ogg")
		battle_instance.BattleType.SINGLE_WILD:
			$CanvasLayer/AudioStreamPlayer.stream = load("res://Audio/BGM/PU-WildPokeBattle.ogg")
		battle_instance.BattleType.SINGLE_TRAINER:
			$CanvasLayer/AudioStreamPlayer.stream = load("res://Audio/BGM/PU-TrainerPokeBattle.ogg")
		battle_instance.BattleType.SINGLE_GYML:
			$CanvasLayer/AudioStreamPlayer.stream = load("res://Audio/BGM/PU-GymBattle.ogg")
		_:
			print("Battle Warning: battle_type is not implemented or specified. Defaulting to PU-TrainerPokeBattle.ogg")
			$CanvasLayer/AudioStreamPlayer.stream = load("res://Audio/BGM/PU-TrainerPokeBattle.ogg")
	$CanvasLayer/AudioStreamPlayer.play()

func set_battle_back():
	var battle_back = $CanvasLayer/BattleGrounds/BattleBack
	var player_base = $CanvasLayer/BattleGrounds/PlayerBase
	var foe_base = $CanvasLayer/BattleGrounds/FoeBase
	match battle_instance.battle_back:
		battle_instance.BattleBack.INDOOR_1:
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgIndoorA.png")
			player_base.texture = load("res://Graphics/Battlebacks/playerbaseIndoorA.png")
			foe_base.texture = load("res://Graphics/Battlebacks/enemybaseIndoorA.png")
		battle_instance.BattleBack.FOREST:
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgForest.PNG")
			player_base.texture = load("res://Graphics/Battlebacks/playerbaseForest.png")
			foe_base.texture = load("res://Graphics/Battlebacks/enemybaseForest.png")
		battle_instance.BattleBack.FEILD_1:
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgField.PNG")
			player_base.texture = load("res://Graphics/Battlebacks/playerbaseField.png")
			foe_base.texture = load("res://Graphics/Battlebacks/enemybaseField.png")
		battle_instance.BattleBack.MOUNTAIN:
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgMountain.png")
			player_base.texture = load("res://Graphics/Battlebacks/playerbaseMountain.png")
			foe_base.texture = load("res://Graphics/Battlebacks/enemybaseMountain.png")
		battle_instance.BattleBack.CAVE:
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgCave.png")
			player_base.texture = load("res://Graphics/Battlebacks/playerbaseCave.png")
			foe_base.texture = load("res://Graphics/Battlebacks/enemybaseCave.png")
		battle_instance.BattleBack.CITY:
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgCity.png")
			player_base.texture = load("res://Graphics/Battlebacks/playerbaseCity.png")
			foe_base.texture = load("res://Graphics/Battlebacks/enemybaseCity.png")
		_:
			print("Battle Error: battle_back is not implemented or specified. Defaulting to battlebgIndoorA.png")
			battle_back.texture = load("res://Graphics/Battlebacks/battlebgIndoorA.png")

func run_transition():
	$CanvasLayer/TransitionEffects.visible = true
	$CanvasLayer/TransitionEffects/Vs.visible = false
	$CanvasLayer/TransitionEffects/AnimationPlayer.play("GreyFlashing")
	yield($CanvasLayer/TransitionEffects/AnimationPlayer, "animation_finished")
	$CanvasLayer/TransitionEffects/GreyFlash.visible = false
	if battle_instance.battle_type == battle_instance.BattleType.RIVAL or battle_instance.battle_type == battle_instance.BattleType.SINGLE_GYML:
		set_Vs_textures()
		$CanvasLayer/TransitionEffects/Vs.visible = true
		$CanvasLayer/TransitionEffects/Vs/AnimationPlayer.play("SlideBars")
		yield($CanvasLayer/TransitionEffects/Vs/AnimationPlayer, "animation_finished")
	$CanvasLayer/TransitionEffects.visible = false
	$CanvasLayer/BattleGrounds.visible = true
	emit_signal("wait")

func battle_loop():
	action_timer.wait_time = 6.0 # 6 second limit for actions
	action_timer.one_shot = true
	action_timer.start()
	var action = queue.pop()

	if battle_debug:
		print("Next action type: " + action.get_type_name())
	match action.type:
		action.BATTLE_GROUNDS_POS_CHANGE:
			if action.battle_grounds_pos_change == $CanvasLayer/BattleGrounds.BattlePositions.CAPTURE_ZOOM:
				$CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar.visible = false
				$CanvasLayer/BattleGrounds/PlayerBase.visible = false
			$CanvasLayer/BattleGrounds.setPosistion(action.battle_grounds_pos_change)
			yield($CanvasLayer/BattleGrounds, "wait")
			if action.battle_grounds_pos_change == $CanvasLayer/BattleGrounds.BattlePositions.CAPTURE_ZOOM_BACK:
				$CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar.visible = true
				$CanvasLayer/BattleGrounds/PlayerBase.visible = true
		action.BATTLE_TEXT:
			$CanvasLayer/BattleInterfaceLayer/Message/Label.text = action.battle_text
			$CanvasLayer/BattleInterfaceLayer/Message.visible = true
			if action.press_to_continue:
				$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
				yield(self, "continue_pressed")
			else:
				$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = false
				yield(get_tree().create_timer(2.0), "timeout")
			$CanvasLayer/BattleInterfaceLayer/Message.visible = false
		action.FOE_BALLTOSS:
			# if human opponent is visable play fadeing animation
			if $CanvasLayer/BattleGrounds/FoeBase/FoeHuman.visible == true:
				$CanvasLayer/BattleGrounds/FoeBase/FoeHuman/AnimationPlayer.play("FadeOut")
			$CanvasLayer/BattleGrounds/FoeBase/Ball.visible = true
			$CanvasLayer/BattleGrounds/FoeBase/Battler.show()
			$CanvasLayer/BattleGrounds.foe_unveil()
			$CanvasLayer/BattleGrounds/FoeBase/FoeHuman.visible = false
			yield($CanvasLayer/BattleGrounds, "unveil_finished")

		action.PLAYER_BALLTOSS:
			$CanvasLayer/BattleGrounds.player_unveil()
			yield($CanvasLayer/BattleGrounds, "unveil_finished")
		action.DAMAGE:
			# Play damage sound
			var audioplayer = $CanvasLayer/BattleInterfaceLayer/BattleBars/AudioStreamPlayer
			var sound
			var effect
			if action.damage_effectiveness > 1.0: # Super damage
				sound = load("res://Audio/SE/superdamage.wav")
				effect = "SuperDamage"
			elif action.damage_effectiveness < 1.0: # Low damage
				sound = load("res://Audio/SE/notverydamage.wav")
				effect = "LowDamage"
			else: # Normal damage
				sound = load("res://Audio/SE/normaldamage.wav")
				effect = "NormalDamage"
			audioplayer.stream = sound
			audioplayer.play()
			# Play damage animation
			match action.damage_target_index:
				1: # Player
					$CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer.play(effect)
					yield($CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer, "animation_finished")
				2: # Foe
					$CanvasLayer/BattleGrounds/FoeBase/Battler/AnimationPlayer.play(effect)
					yield($CanvasLayer/BattleGrounds/FoeBase/Battler/AnimationPlayer, "animation_finished")
			# Play hp bar slide
			var bars = $CanvasLayer/BattleInterfaceLayer/BattleBars
			match action.damage_target_index:
				1: # Player
					var percent = float(battler1.current_hp) / battler1.hp
					print("bar slide for player")
					bars.call_deferred("slide_player_bar", percent, battler1.current_hp)
				2: # Foe
					var percent = float(battler2.current_hp) / battler2.hp
					print("bar slide for foe")
					bars.call_deferred("slide_foe_bar", percent)
			yield(bars, "finished")
		action.FAINT:
			match action.damage_target_index:
				1:
					$CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer.stream = load(battler1.get_cry())
					$CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer.play()
					yield($CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer, "finished")
					$CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar/AnimationPlayer.play("Fade")
					$CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer.play("FaintPlayer")

					$CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer.stream = load("res://Audio/SE/faint.wav")
					$CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer.play()
					yield($CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer, "animation_finished")
					$CanvasLayer/BattleGrounds/PlayerBase/Battler.visible = false
				2:
					$CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer.stream = load(battler2.get_cry())
					$CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer.play()
					yield($CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer, "finished")
					$CanvasLayer/BattleGrounds/FoeBase/Battler/AnimationPlayer.play("FaintFoe")
					$CanvasLayer/BattleInterfaceLayer/BattleBars/FoeBar/AnimationPlayer.play("Fade")

					$CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer.stream = load("res://Audio/SE/faint.wav")
					$CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer.play()

					yield($CanvasLayer/BattleGrounds/FoeBase/Battler/AnimationPlayer, "animation_finished")
					$CanvasLayer/BattleGrounds/FoeBase/Battler.visible = false
		action.EXP_GAIN:
			var percent : float = action.exp_gain_percent
			$CanvasLayer/BattleInterfaceLayer/BattleBars.call_deferred("slide_player_exp_bar" , percent)
			yield($CanvasLayer/BattleInterfaceLayer/BattleBars, "finished")
		action.BATTLE_END:
			action_timer.stop()
			battle_is_over = true
			if action.winner == action.PLAYER_WIN:
				player_won = true
				print("Player wins.")
			if action.winner == action.FOE_WIN:
				print("Foe wins.")

			$CanvasLayer/BattleInterfaceLayer/BattleBars.visible = false
			
			if !action.run_away:
				if player_won:
					# Play victory music
					var victory_music
					match battle_instance.battle_type:
						BattleInstanceData.BattleType.SINGLE_TRAINER, BattleInstanceData.BattleType.RIVAL:
							victory_music = load("res://Audio/ME/PU-Victory Trainer Battle.ogg")
						BattleInstanceData.BattleType.SINGLE_WILD, BattleInstanceData.BattleType.DOUBLE_WILD:
							victory_music = load("res://Audio/BGM/PU-WildVictory.ogg") # There is another version in ME. Not sure which one to use.
						BattleInstanceData.BattleType.SINGLE_GYML, BattleInstanceData.BattleType.DOUBLE_GYML:
							victory_music = load("res://Audio/ME/PU-GymVictory.ogg")
						# TODO: Fill other battle types
					$CanvasLayer/AudioStreamPlayer.stop()
					$CanvasLayer/AudioStreamPlayer.stream = victory_music
					$CanvasLayer/AudioStreamPlayer.play()

					# Closing Battle quote
					var message
					# if battle_instance.battle_type == BattleInstanceData.BattleType.SINGLE_WILD || battle_instance.battle_type == BattleInstanceData.BattleType.DOUBLE_WILD:

					if action.captured:
						message = Global.TrainerName + " captured \n"

						# Add to pokedex caught list
						if !Global.pokedex_caught.has(battler2.ID):
							Global.pokedex_caught.append(battler2.ID)
					else:
						message = Global.TrainerName + " defeated \n"
					message += get_opponent_title()
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = message
					$CanvasLayer/BattleInterfaceLayer/Message.visible = true
					$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
					yield(self, "continue_pressed")
					$CanvasLayer/BattleInterfaceLayer/Message.visible = false

					# If applicable, show opponent win quote:
					if "after_battle_quote" in battle_instance.opponent && battle_instance.opponent.after_battle_quote != "":
						$CanvasLayer/BattleGrounds/AnimationPlayer.play("Opponent_Quote")
						yield($CanvasLayer/BattleGrounds/AnimationPlayer, "animation_finished")

						message = tr(battle_instance.opponent.after_battle_quote)
						$CanvasLayer/BattleInterfaceLayer/Message/Label.text = message
						$CanvasLayer/BattleInterfaceLayer/Message.visible = true
						yield(self, "continue_pressed")

						# Show money earned
						Global.money += battle_instance.victory_award
						$CanvasLayer/BattleInterfaceLayer/Message/Label.text = Global.TrainerName + " got $" + str(battle_instance.victory_award) + "\nfor winning!"
						yield(self, "continue_pressed")
				
					if action.captured:
						# Add Wild Pokemon to party
						# Make a copy of the pokemon
						var copy = registry.duplicate_pokemon(battle_instance.opponent.pokemon_group[0])
						Global.add_poke_to_party(copy)

					# Check for evolutions
					for poke in leveled_up_pokes:
						var poke_class = Global.registry.get_pokemon_class(poke.ID)
						var evolution_level = poke_class.evolution_level
						var evolution_ID = poke_class.evolution_ID
						if evolution_level != null && poke.level >= evolution_level:
							$CanvasLayer/AudioStreamPlayer.stop()
							$CanvasLayer/BattleInterfaceLayer/Evolution.setup(poke, evolution_ID)
							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeIn")
							yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")

							$CanvasLayer/BattleInterfaceLayer/Evolution.show()
							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeOut")
							yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")
							$CanvasLayer/BattleInterfaceLayer/Evolution.run()

							yield($CanvasLayer/BattleInterfaceLayer/Evolution, "close")

							# Logically change the poke
							var evolve_class = Global.registry.get_pokemon_class(evolution_ID)
							if poke.name == poke_class.name: # Not using nickname
								poke.name = evolve_class.name
							poke.ID = evolution_ID
							poke.update_stats()
							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeIn")
				else: # Player loses
					var message = Global.TrainerName + " has no more Pokémon that can fight!"
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = message
					$CanvasLayer/BattleInterfaceLayer/Message.visible = true
					$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
					yield(self, "continue_pressed")

					message = Global.TrainerName + " lost against\n" + get_opponent_title() + "."
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = message
					yield(self, "continue_pressed")
					message = Global.TrainerName + " gave $" + str(get_money_loss()) + " to the winner..."
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = message
					# Remove money
					Global.remove_money(get_money_loss())
					yield(self, "continue_pressed")
					message = Global.TrainerName + " blacked out!"
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = message
					yield(self, "continue_pressed")
		action.STAT_CHANGE_ANIMATION:
			var effect
			var animation
			var sound
			
			match action.damage_target_index:
				1:
					animation = $CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer
					sound = $CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer
					var animated_sprite = get_node_or_null('CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimatedSprite')
				2:
					animation = $CanvasLayer/BattleGrounds/FoeBase/Battler/AnimationPlayer
					var animated_sprite = get_node_or_null('CanvasLayer/BattleGrounds/FoeBase/Battler/AnimatedSprite')
					var animated_sprited = $CanvasLayer/BattleGrounds/FoeBase/Battler/AnimatedSprite
					#effect_shader = $CanvasLayer/BattleGrounds/FoeBase/Battler/Sprite.material
				_:
					print("Battle Error: Unimplemeted stat animation index")
			if action.stat_change_increase: # Note: Shader material is applied in Pokemon.gd script. Here we just edit the shader params.
				if effect_shader == null:
				#sound.stream = load("res://Audio/SE/increase.wav")
					effect_shader.shader = load("res://Graphics/Pictures/StatUp.png")
			else:
				var shader_path : String = "res://Graphics/Shaders/StatChange.shader"
				var shader : Shader = load(shader_path) as Shader
				var effect_shader : ShaderMaterial = ShaderMaterial.new()
				var effect1 : Texture = load("res://Graphics/Pictures/StatDown.png") as Texture
				var sound1 : AudioStreamPlayer = $CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer
				if shader:
					effect_shader.shader = shader
				else:
					print("Error: No se pudo cargar el shader desde la ruta ", shader_path)
					return  # Salir si el shader no se cargó correctamente
				if effect_shader and effect:
					effect.set_flags(Texture.FLAG_REPEAT)
					effect_shader.set_shader_param("effect", effect)
					effect_shader.set_shader_param("effect", effect)
					effect_shader.set_shader_param("effect_speed", -1.0)
					var sprite_node : AnimatedSprite = $CanvasLayer/BattleGrounds/FoeBase/Battler/AnimatedSprite
					if sprite_node:
						sprite_node.material = effect_shader
					else:
						print("Error: No se encontró el nodo de tipo Sprite en la ruta especificada.")
					if sound:
						sound.stream = load("res://Audio/SE/decrease.wav") as AudioStream
				else:
					if not effect_shader:
						print("Error: El ShaderMaterial es null.")
					if not effect:
						print("Error: La textura effect es null.")
			effect_enable = true
			animation.play("StatChange")
			yield(animation, "animation_finished")
			effect_enable = false
		action.WILD_INTRO:
			# Play cry:
			$CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer.stream = load(battler2.get_cry())
			$CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer.play()

			# Slide battle bar
			$CanvasLayer/BattleInterfaceLayer/BattleBars.visible = true
			$CanvasLayer/BattleInterfaceLayer/BattleBars/FoeBar.visible = true
			$CanvasLayer/BattleInterfaceLayer/BattleBars/FoeBar.get_node("AnimationPlayer").play("Slide")

			yield($CanvasLayer/BattleGrounds/FoeBase/Ball/AudioStreamPlayer, "finished")
		action.HEAL:
			#if action.heal_sound:
			#	var audioplayer = $CanvasLayer/BattleInterfaceLayer/BattleBars/AudioStreamPlayer
			#	var sound = load("I can not find the file!")
			var bars = $CanvasLayer/BattleInterfaceLayer/BattleBars
			match action.damage_target_index:
				1: # Player
					var percent = float(battler1.current_hp) / battler1.hp
					print(percent)
					bars.call_deferred("slide_player_bar", percent, battler1.current_hp)
				2: # Foe
					var percent = float(battler2.current_hp) / battler2.hp
					print(percent)
					bars.call_deferred("slide_foe_bar", percent)
			yield(bars, "finished")
		action.LEVEL_UP_SE:
			var audioplayer = $CanvasLayer/BattleInterfaceLayer/BattleBars/AudioStreamPlayer
			var sound = load("res://Audio/ME/BW_lvup.ogg")
			sound.loop = false
			$CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar/LevelLable.text = " " + str(action.level)
			audioplayer.stream = sound
			audioplayer.play()
			# Reset exp bar
			$CanvasLayer/BattleInterfaceLayer/BattleBars.call_deferred("reset_player_exp_bar")
		action.LEVEL_UP:
			action_timer.stop()

			if !leveled_up_pokes.has(battler1):
				leveled_up_pokes.append(battler1)

			# Update player bar
			$CanvasLayer/BattleInterfaceLayer/BattleBars.set_player_bar_by_pokemon(battler1)
			# Set exp bar to zero
			$CanvasLayer/BattleInterfaceLayer/BattleBars.player_exp_percent = 0.0
			$CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar/EXP.region_rect = $CanvasLayer/BattleInterfaceLayer/BattleBars.get_player_exp_rect2d_by_percentage(0.0)

			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/MaxHP/Value.text = "+" + str(action.level_stat_changes.hp_change)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/Attack/Value.text = "+" + str(action.level_stat_changes.attack_change)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/Defense/Value.text = "+" + str(action.level_stat_changes.defense_change)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/SpAtck/Value.text = "+" + str(action.level_stat_changes.spAtk_change)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/SpDef/Value.text = "+" + str(action.level_stat_changes.spDef_change)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/Speed/Value.text = "+" + str(action.level_stat_changes.speed_change)
			$CanvasLayer/BattleInterfaceLayer/LevelUp.visible = true
		
			yield(self, "continue_pressed")

			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/MaxHP/Value.text = str(battler1.hp)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/Attack/Value.text = str(battler1.attack)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/Defense/Value.text = str(battler1.defense)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/SpAtck/Value.text = str(battler1.sp_attack)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/SpDef/Value.text = str(battler1.sp_defense)
			$CanvasLayer/BattleInterfaceLayer/LevelUp/Box/Improve/Speed/Value.text = str(battler1.speed)
		
			yield(self, "continue_pressed")
			$CanvasLayer/BattleInterfaceLayer/LevelUp.visible = false

			# Learn new moves if applicable
			var data = registry.get_pokemon_class(battler1.ID)
			var moveset = [] # strings
			for move in data.moveset:
				if move.level == battler1.level:
					moveset.push_back(move.move)

			for new_moves in moveset:
				var num_moves_taken = battler1.get_moves().size()
				if num_moves_taken < 4:
					# Add the move
					match num_moves_taken:
						1:
							battler1.move_2 = MoveDataBase.get_move_by_name(new_moves)
						2:
							battler1.move_3 = MoveDataBase.get_move_by_name(new_moves)
						3:
							battler1.move_4 = MoveDataBase.get_move_by_name(new_moves)
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = battler1.name + " learned " + new_moves + "!"
					$CanvasLayer/BattleInterfaceLayer/Message.visible = true
					$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
					yield(self, "continue_pressed")
					$CanvasLayer/BattleInterfaceLayer/Message.visible = false
					$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = false
				else:	
					var done = false

					while !done:
						$CanvasLayer/BattleInterfaceLayer/Message/Label.text = battler1.name + " is trying to learn " + new_moves + "."
						$CanvasLayer/BattleInterfaceLayer/Message.visible = true
						$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
						yield(self, "continue_pressed")
						$CanvasLayer/BattleInterfaceLayer/Message/Label.text = "But " + battler1.name + " can't learn more than four moves."
						$CanvasLayer/BattleInterfaceLayer/Message.visible = true
						$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
						yield(self, "continue_pressed")

						$CanvasLayer/BattleInterfaceLayer/YesNo/Select.position = Vector2(170,260)
						$CanvasLayer/BattleInterfaceLayer/YesNo.show()

						$CanvasLayer/BattleInterfaceLayer/Message/Label.text = "Delete a move to make room for " + new_moves + "?"
						$CanvasLayer/BattleInterfaceLayer/Message.visible = true
						$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
						yield(self, "continue_pressed")

						if $CanvasLayer/BattleInterfaceLayer/YesNo/Select.position == Vector2(170,260): # Yes replace move
							$CanvasLayer/BattleInterfaceLayer/Message/Label.text = "Which move should be forgotten?"
							$CanvasLayer/BattleInterfaceLayer/Message.visible = true
							$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
							yield(self, "continue_pressed")

							# Fade to pokedex
							$CanvasLayer/BattleInterfaceLayer/YesNo.hide()
							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeIn")
							yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")
							
							$CanvasLayer/BattleInterfaceLayer/NewMove.setup(battler1, MoveDataBase.get_move_by_name(new_moves))
							$CanvasLayer/BattleInterfaceLayer/NewMove.mode = 1
							$CanvasLayer/BattleInterfaceLayer/NewMove.show()

							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeOut")
							yield($CanvasLayer/BattleInterfaceLayer/NewMove, "close")

							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeIn")
							yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")
							$CanvasLayer/BattleInterfaceLayer/NewMove.hide()

							$CanvasLayer/ColorRect/AnimationPlayer.play("FadeOut")
							yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")

							if $CanvasLayer/BattleInterfaceLayer/NewMove.selection != 0:
								$CanvasLayer/BattleInterfaceLayer/Message/Label.text = "1, 2, and... ... ..."
								$CanvasLayer/BattleInterfaceLayer/Message.visible = true
								$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
								yield(self, "continue_pressed")

								$CanvasLayer/BattleInterfaceLayer/Message/Label.text = "Poof!"
								$CanvasLayer/BattleInterfaceLayer/Message.visible = true
								$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
								yield(self, "continue_pressed")

								var old_move_name
								match $CanvasLayer/BattleInterfaceLayer/NewMove.selection:
									1:
										old_move_name = battler1.move_1.name
										battler1.move_1 = MoveDataBase.get_move_by_name(new_moves)
									2:
										old_move_name = battler1.move_2.name
										battler1.move_2 = MoveDataBase.get_move_by_name(new_moves)
									3:
										old_move_name = battler1.move_3.name
										battler1.move_3 = MoveDataBase.get_move_by_name(new_moves)
									4:
										old_move_name = battler1.move_4.name
										battler1.move_4 = MoveDataBase.get_move_by_name(new_moves)
								$CanvasLayer/BattleInterfaceLayer/Message/Label.text = battler1.name + " forgot " + old_move_name + "."
								$CanvasLayer/BattleInterfaceLayer/Message.visible = true
								$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
								yield(self, "continue_pressed")

								$CanvasLayer/BattleInterfaceLayer/Message/Label.text = "And..."
								$CanvasLayer/BattleInterfaceLayer/Message.visible = true
								$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
								yield(self, "continue_pressed")

								$CanvasLayer/BattleInterfaceLayer/Message/Label.text = battler1.name + " learned " + new_moves + "!"
								$CanvasLayer/BattleInterfaceLayer/Message.visible = true
								$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
								yield(self, "continue_pressed")
								done = true
							else:
								continue
							pass
						else: # No skip
							$CanvasLayer/BattleInterfaceLayer/Message/Label.text = battler1.name + " did not learn " + new_moves + "."
							$CanvasLayer/BattleInterfaceLayer/Message.visible = true
							$CanvasLayer/BattleInterfaceLayer/Message/Arrow.visible = true
							done = true
							yield(self, "continue_pressed")

					pass
		action.UPDATE_BARS: # Updates all bars
			$CanvasLayer/BattleInterfaceLayer/BattleBars.set_player_bar_by_pokemon(battler1)
			$CanvasLayer/BattleInterfaceLayer/BattleBars.set_foe_bar_by_pokemon(battler2)
		action.UPDATE_MAJOR_AILMENT: # To be remade as update bars
			var battler1_ailment = $CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar/MajorAilment
			var battler2_ailment = $CanvasLayer/BattleInterfaceLayer/BattleBars/FoeBar/MajorAilment
			match action.damage_target_index:
				1:
					match battler1.major_ailment:
						null:
							battler1_ailment.hide()
						_:
							battler1_ailment.frame = battler1.major_ailment
							battler1_ailment.show()
				2:
					match battler2.major_ailment:
						null:
							battler2_ailment.hide()
						_:
							battler2_ailment.frame = battler2.major_ailment
							battler2_ailment.show()
		action.ESCAPE_SE:
			var audioplayer = $CanvasLayer/BattleInterfaceLayer/BattleBars/AudioStreamPlayer
			var sound = load("res://Audio/BGS/Flee.ogg")
			sound.loop = false
			audioplayer.stream = sound
			audioplayer.play()
		action.BALL_CAPTURE_TOSS:
			$CanvasLayer/BattleGrounds/FoeBase/Ball/AnimationPlayer.play("Capture_Throw")
			yield($CanvasLayer/BattleGrounds/FoeBase/Ball/AnimationPlayer, "animation_finished")
		action.BALL_SHAKE:
			$CanvasLayer/BattleGrounds/FoeBase/Ball/AnimationPlayer.play("BallShake")
			yield($CanvasLayer/BattleGrounds/FoeBase/Ball/AnimationPlayer, "animation_finished")
		action.BALL_BROKE:
			$CanvasLayer/BattleGrounds/FoeBase/Ball/AnimationPlayer.play("BallBreak")
			yield($CanvasLayer/BattleGrounds/FoeBase/Ball/AnimationPlayer, "animation_finished")
		action.SET_BALL:
			$CanvasLayer/BattleGrounds/FoeBase.set_ball(action.ball_type)
		action.SWITCH_POKE: # For player switching by command
			action_timer.stop()
			var text = battler1.name + tr("BATTLE_SWITCH_1")
			$CanvasLayer/BattleInterfaceLayer/Message/Label.text = text
			$CanvasLayer/BattleInterfaceLayer/Message.visible = true
			yield(get_tree().create_timer(2.0), "timeout")

			# Set new shader
			var animated_sprite = $CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimatedSprite
			
			# Crear un nuevo ShaderMaterial
			var shader_material = ShaderMaterial.new()
			shader_material.shader = load("res://Utilities/Battle/WhiteFade.shader")
			shader_material.set_shader_param("effect_weight", 0.0)
			
			# Asignar el ShaderMaterial al AnimatedSprite
			#animated_sprite.material = shader_material
			
			# Configurar variables adicionales
			var effect_shader = shader_material
			var effect_weight = 0.0

			# Play return SE
			$CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer.stream = load("res://Audio/SE/recall.wav")
			$CanvasLayer/BattleGrounds/PlayerBase/Ball/AudioStreamPlayer.play()

			# Play return animation
			var animation = $CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer
			effect_enable = true
			animation.play("Return")
			
			# Fade away battle bar
			$CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar/AnimationPlayer.play("Fade")
			
			yield(animation, "animation_finished")
			effect_enable = false
			
			# Update battler1
			battler1 = Global.pokemon_group[action.switch_poke]
			$CanvasLayer/BattleInterfaceLayer/BattleBars.set_player_bar_by_pokemon(battler1)
			$CanvasLayer/BattleGrounds/PlayerBase.setup_by_pokemon(battler1)

			text = "Go! " + battler1.name + "!"
			$CanvasLayer/BattleInterfaceLayer/Message/Label.text = text
			$CanvasLayer/BattleInterfaceLayer/Message.visible = true
			yield(get_tree().create_timer(0.2), "timeout")

			# Move view
			$CanvasLayer/BattleGrounds/AnimationPlayer.play("player_switch")
			yield($CanvasLayer/BattleGrounds/AnimationPlayer, "animation_finished")

			$CanvasLayer/BattleGrounds.player_unveil()
			yield($CanvasLayer/BattleGrounds, "unveil_finished")

			# Change view back to center
			$CanvasLayer/BattleGrounds/AnimationPlayer.play_backwards("player_switch")
			yield($CanvasLayer/BattleGrounds/AnimationPlayer, "animation_finished")

			# Reset attack command menu
			$CanvasLayer/BattleInterfaceLayer/BattleAttackSelect.reset()
		action.NEXT_POKE:
			action_timer.stop()
			match action.damage_target_index:
				1, 3: # Player
					$CanvasLayer/ColorRect/AnimationPlayer.play("FadeIn")
					yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")

					$CanvasLayer/BattleInterfaceLayer/PokemonPartyMenu.setup(true, true)
					$CanvasLayer/BattleInterfaceLayer/PokemonPartyMenu.stage = 1
					$CanvasLayer/BattleInterfaceLayer/PokemonPartyMenu.show()
					$CanvasLayer/ColorRect/AnimationPlayer.play("FadeOut")
					yield($CanvasLayer/BattleInterfaceLayer/PokemonPartyMenu, "close_party")

					$CanvasLayer/ColorRect/AnimationPlayer.play("FadeIn")
					yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")
					$CanvasLayer/BattleInterfaceLayer/PokemonPartyMenu.hide()
					$CanvasLayer/ColorRect/AnimationPlayer.play("FadeOut")
					yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")

					var next_poke_index = $CanvasLayer/BattleInterfaceLayer/PokemonPartyMenu.selection
					var next_poke = Global.pokemon_group[next_poke_index]

					battler1 = next_poke
					$CanvasLayer/BattleInterfaceLayer/BattleBars.set_player_bar_by_pokemon(battler1)
					$CanvasLayer/BattleGrounds/PlayerBase.setup_by_pokemon(battler1)

					var text = "Go! " + battler1.name + "!"
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = text
					$CanvasLayer/BattleInterfaceLayer/Message.visible = true
					yield(get_tree().create_timer(0.2), "timeout")
					$CanvasLayer/BattleInterfaceLayer/Message.visible = false

					# Move view
					$CanvasLayer/BattleGrounds/AnimationPlayer.play("player_switch")
					yield($CanvasLayer/BattleGrounds/AnimationPlayer, "animation_finished")

					$CanvasLayer/BattleGrounds.player_unveil()
					yield($CanvasLayer/BattleGrounds, "unveil_finished")

					# Change view back to center
					$CanvasLayer/BattleGrounds/AnimationPlayer.play_backwards("player_switch")
					yield($CanvasLayer/BattleGrounds/AnimationPlayer, "animation_finished")

					# Reset attack command menu
					$CanvasLayer/BattleInterfaceLayer/BattleAttackSelect.reset()
				2, 4: # Foe
					var next_poke = battle_instance.opponent.ai.get_next_poke(get_battle_snapshot())
					if next_poke == null:
						next_poke = 0
						for poke in battle_instance.opponent.pokemon_group:
							if poke.current_hp != 0:
								next_poke = battle_instance.opponent.pokemon_group[next_poke]
								break
							else:
								next_poke += 1

					battler2 = next_poke
					$CanvasLayer/BattleInterfaceLayer/BattleBars.set_foe_bar_by_pokemon(battler2)
					$CanvasLayer/BattleGrounds/FoeBase.setup_by_pokemon(battler2)
					battle_logic.battler2 = battler2
					battle_logic.battler2_effects = []
					battle_logic.battler2_stat_stage = BattleStatStage.new()
					battle_logic.battler2_past_moves = []
									
					var text = battle_instance.opponent.name + " sent out \n" + battler2.name + "!"
					$CanvasLayer/BattleInterfaceLayer/Message/Label.text = text
					$CanvasLayer/BattleInterfaceLayer/Message.visible = true
					yield(get_tree().create_timer(2.0), "timeout")
					$CanvasLayer/BattleInterfaceLayer/Message.visible = false

					$CanvasLayer/BattleGrounds.foe_unveil()

					# Add to pokedex if new
					if !Global.pokedex_seen.has(next_poke.ID):
						Global.pokedex_seen.append(next_poke.ID)

					yield($CanvasLayer/BattleGrounds, "unveil_finished")

					# Mid battle opponent quotes
					match battle_instance.opponent.name:
						"LEADER Maria":
							if battler2.name == "Felunge":
								$CanvasLayer/BattleGrounds/AnimationPlayer.play("Opponent_Quote")
								$CanvasLayer/BattleInterfaceLayer/Message/Label.text = tr("GYM1_MARIA_8")
								$CanvasLayer/BattleInterfaceLayer/Message.visible = true
								$CanvasLayer/AudioStreamPlayer.stream = load("res://Audio/BGM/PU-DecisiveBattle.ogg")
								$CanvasLayer/AudioStreamPlayer.play()
								yield(self, "continue_pressed")
								$CanvasLayer/BattleInterfaceLayer/Message.visible = false
								$CanvasLayer/BattleGrounds/AnimationPlayer.play_backwards("Opponent_Quote")
								yield($CanvasLayer/BattleGrounds/AnimationPlayer, "animation_finished")
						
							pass
		_:
			print("Battle Error: Battle Action type did not match any correct value. action.type = " + str(action.type))
	action_timer.stop()
	emit_signal("EndOfBattleLoop")

func get_battle_command():
	var menu = $CanvasLayer/BattleInterfaceLayer/BattleComandSelect
	menu.get_node("AnimationPlayer").play("Slide")
	menu.visible = true
	menu.start(battler1.name)
	yield($CanvasLayer/BattleInterfaceLayer/BattleComandSelect, "command_received")

	if battle_command.command_type == battle_command.SWITCH_POKE:
		$CanvasLayer/ColorRect/AnimationPlayer.play("FadeOut")
		yield($CanvasLayer/ColorRect/AnimationPlayer, "animation_finished")

	emit_signal("wait")

func get_battle_snapshot():
	var snap = load("res://Utilities/Battle/Classes/BattleSnapshot.gd").new()
	snap.foe_poke_id = int(battler1.ID)
	snap.foe_hp_percentage = float(battler1.current_hp) / float(battler1.hp)
	snap.foe_poke_level = int(battler1.level)
	var index := 0
	for p in battle_instance.opponent.pokemon_group:
		if p == battler2:
			break
		else:
			index = index + 1
	snap.poke_index = int(index)
	snap.poke_remaining_hp = int(battler2.current_hp)
	snap.poke_max_hp = int(battler2.hp)
	snap.poke_level = int(battler2.level)
	for p in battle_instance.opponent.pokemon_group:
		snap.poke_list.push_back(int(p.ID))
	
	if battler2.move_1 != null:
		snap.poke_move_list.append(battler2.move_1.name)
	if battler2.move_2 != null:
		snap.poke_move_list.append(battler2.move_2.name)
	if battler2.move_3 != null:
		snap.poke_move_list.append(battler2.move_3.name)
	if battler2.move_4 != null:
		snap.poke_move_list.append(battler2.move_4.name)
	return snap

func get_opponent_title() :
	var title = ""
	match battle_instance.opponent.opponent_type:
		Opponent.OPPONENT_RIVAL:
			title += "RIVAL "
		Opponent.OPPONENT_TRAINER:
			title += ""
		Opponent.OPPONENT_WILD:
			title += "WILD "
	title += battle_instance.opponent.name
	return title

func get_money_loss() -> int:
	var amount : int = 0
	var level = 0
	var base_payout = 0
	for poke in Global.pokemon_group:
		if poke.level > level:
			level = poke.level
	match Global.badges:
		0:
			base_payout = 8
		1:
			base_payout = 16
		2:
			base_payout = 24
		3:
			base_payout = 36
		4:
			base_payout = 48
		5:
			base_payout = 60 # could be 64 depending on gen
		6:
			base_payout = 80
		7:
			base_payout = 100
		8:
			base_payout = 120
	amount = level * base_payout
	return amount

func check_if_battler_is_already_out(poke):
	if poke == battler1 || poke == battler3:
		return true
	return false
	
func action_timeout():
	print("BATTLE ERROR: Action took too long.")
	# Unfreeze the battle
	pass
