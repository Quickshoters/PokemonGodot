extends Node2D
signal wait
signal unveil_finished

enum BattlePositions {INTRO_FADE, PLAYER_TOSS, CENTER, CENTER_IDLE, FOE_FOCUS, OPONENT_TALK, CAPTURE_ZOOM, CAPTURE_ZOOM_BACK}

var is_first_toss = true

func setPosistion(pos):
	var aniplayer = $AnimationPlayer
	match pos:
		BattlePositions.INTRO_FADE:
			aniplayer.play("FadeToIntroPos")
		BattlePositions.PLAYER_TOSS:
			aniplayer.play("player_toss")
			get_parent().get_parent().get_node("CanvasLayer/BattleInterfaceLayer/PlayerToss/AnimationPlayer").play("FadeIn")
		BattlePositions.CENTER:
			aniplayer.play("PlayerTossToCenter")
		BattlePositions.CAPTURE_ZOOM:
			aniplayer.play("CaptureZoom")
		BattlePositions.CAPTURE_ZOOM_BACK:
			aniplayer.play_backwards("CaptureZoom")
	yield(aniplayer, "animation_finished")
	emit_signal("wait")

func foe_unveil():
	var FoeBar = get_parent().get_parent().get_node("CanvasLayer/BattleInterfaceLayer/BattleBars/FoeBar")
	
	# Play sound for toss
	var audio_player = $FoeBase/Ball/AudioStreamPlayer
	if audio_player:
		audio_player.stream = load("res://Audio/SE/throw.wav")
		audio_player.play()
	else:
		print("Error: AudioStreamPlayer no encontrado en FoeBase/Ball")
	
	# Slide foe bar
	if FoeBar:
		FoeBar.get_parent().visible = true
		FoeBar.visible = true
		var bar_anim_player = FoeBar.get_node("AnimationPlayer")
		if bar_anim_player:
			bar_anim_player.play("Slide")
		else:
			print("Error: AnimationPlayer no encontrado en FoeBar")
	
	# Play toss animation
	$FoeBase/Ball.visible = true
	var ball_anim_player = $FoeBase/Ball/AnimationPlayer
	if ball_anim_player:
		ball_anim_player.play("Ball")
	else:
		print("Error: AnimationPlayer no encontrado en FoeBase/Ball")
	
	yield($FoeBase/Battler/AnimationPlayer, "animation_finished")
	emit_signal("unveil_finished")

func player_unveil():
	var PlayerBar = get_parent().get_parent().get_node("CanvasLayer/BattleInterfaceLayer/BattleBars/PlayerBar")
	
	# Slide Player bar
	if PlayerBar:
		PlayerBar.get_parent().visible = true
		PlayerBar.visible = true
		var bar_anim_player = PlayerBar.get_node("AnimationPlayer")
		if bar_anim_player:
			bar_anim_player.play("Slide")
		else:
			print("Error: AnimationPlayer no encontrado en PlayerBar")

	# Play toss animation
	if is_first_toss:
		var player_toss_anim_player = get_parent().get_parent().get_node("CanvasLayer/BattleInterfaceLayer/PlayerToss/AnimationPlayer")
		if player_toss_anim_player:
			player_toss_anim_player.play("Toss")
			# Add Delay
			var t = Timer.new()
			t.wait_time = 0.5
			t.one_shot = true
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
		else:
			print("Error: AnimationPlayer no encontrado en PlayerToss")

		is_first_toss = false
	
	# Play sound for toss
	var audio_player = $PlayerBase/Ball/AudioStreamPlayer
	if audio_player:
		audio_player.stream = load("res://Audio/SE/throw.wav")
		audio_player.play()
	else:
		print("Error: AudioStreamPlayer no encontrado en PlayerBase/Ball")
	
	var player_ball_anim_player = get_parent().get_parent().get_node("CanvasLayer/BattleGrounds/PlayerBase/Ball/AnimationPlayer")
	if player_ball_anim_player:
		player_ball_anim_player.play("PlayerBallToss")
	else:
		print("Error: AnimationPlayer no encontrado en PlayerBase/Ball")

	yield(get_parent().get_parent().get_node("CanvasLayer/BattleGrounds/PlayerBase/Battler/AnimationPlayer"), "animation_finished")
	emit_signal("unveil_finished")
