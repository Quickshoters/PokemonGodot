extends Node

const SAVE_SYSTEM = preload('res://Utilities/Save/SaveSystem.gd')

var grayBox = Rect2(16, 444, 384, 46)
var greenBox = Rect2(16, 490, 384, 46)

var grayLoad = Rect2(0, 0, 408, 222)
var greenLoad = Rect2(0, 222, 408, 222)

var pannel_layout
enum PANNEL {
	NEW,
	FULL
}
enum SELECTED {
	CONTINUE,
	NEW_GAME,
	OTHER_SAVES,
	DELETE_SAVE,
	UPDATE,
	OPTIONS,
	EXIT
}
var selected = 0
var save_id = 1

func _ready():
	$ErrorMessage.text = ""

	var num = SaveSystem.get_number_of_saves() # Accede a SaveSystem globalmente
	if num == 0:
		pannel_layout = PANNEL.NEW
		$Panels.visible = true
		$FullPanel.visible = false
		$Panels/NewGame.texture.region = greenBox
		$Panels/Exit.texture.region = grayBox
	else:
		pannel_layout = PANNEL.FULL
		$Panels.visible = false
		$FullPanel.visible = true
		$FullPanel/Load.region_rect = greenLoad

		var save = SaveSystem.load_file(save_id)
		var global_state = save.get_data("")
		var game_state = save.get_data("res://Game.tscn")

		var current_scene = load(game_state["current_scene"])
		var current_scene_instance = current_scene.instance()

		$FullPanel/Load/Location.text = current_scene_instance.place_name
		match global_state["TrainerGender"]:
			0:
				$FullPanel/Load/Player.texture = load("res://Graphics/Characters/HERO.png")
			1:
				$FullPanel/Load/Player.texture = load("res://Graphics/Characters/PU-Pluto.png")
			2:
				$FullPanel/Load/Player.texture = load("res://Graphics/Characters/HEROINE.png")

		$FullPanel/Load/Badges/Value.text = str(global_state["badges"])
		$FullPanel/Load/Pokedex/Value.text = str(global_state["pokedex_caught"].size())
		var minutes = global_state["time"]
		$FullPanel/Load/Time/Value.text = str("%02d" % (minutes / 60)) + ":" + str("%02d" % (minutes % 60))
		var poke_group = global_state["pokemon_group"]
		var index = 0
		for poke in poke_group:
			match index:
				0:
					$FullPanel/Load/P1.texture = poke.get_icon_texture()
					$FullPanel/Load/P1.show()
				1:
					$FullPanel/Load/P2.texture = poke.get_icon_texture()
					$FullPanel/Load/P2.show()
				2:
					$FullPanel/Load/P3.texture = poke.get_icon_texture()
					$FullPanel/Load/P3.show()
				3:
					$FullPanel/Load/P4.texture = poke.get_icon_texture()
					$FullPanel/Load/P4.show()
				4:
					$FullPanel/Load/P5.texture = poke.get_icon_texture()
					$FullPanel/Load/P5.show()
				5:
					$FullPanel/Load/P6.texture = poke.get_icon_texture()
					$FullPanel/Load/P6.show()
			index += 1

func _process(delta):
	$ErrorMessage.text = SaveSystem.error_messages

	if pannel_layout == PANNEL.NEW:
		if Input.is_action_just_pressed("ui_down") and selected == 0:
			selected = 1
			updateBoxes()
		if Input.is_action_just_pressed("ui_up") and selected == 1:
			selected = 0
			updateBoxes()
		if Input.is_action_just_pressed("ui_accept") and selected == 0:
			NewGame()
		if Input.is_action_just_pressed("ui_accept") and selected == 1:
			get_tree().quit()
	else:
		if Input.is_action_just_pressed("ui_down"):
			if selected == SELECTED.EXIT:
				selected = SELECTED.CONTINUE
			else:
				selected += 1
			updateBoxes()
		if Input.is_action_just_pressed("ui_up"):
			if selected == SELECTED.CONTINUE:
				selected = SELECTED.EXIT
			else:
				selected -= 1
			updateBoxes()
		if Input.is_action_just_pressed("ui_accept"):
			match selected:
				SELECTED.CONTINUE:
					continueGame(save_id)
				SELECTED.NEW_GAME:
					NewGame()
				SELECTED.EXIT:
					get_tree().quit()

func NewGame():
	changeScene("res://IntroScenes/PlayerCreation.tscn")

func updateBoxes():
	if pannel_layout == PANNEL.NEW:
		if selected == 0:
			$Panels/NewGame.texture.region = greenBox
			$Panels/Exit.texture.region = grayBox
		if selected == 1:
			$Panels/NewGame.texture.region = grayBox
			$Panels/Exit.texture.region = greenBox
		$AudioStreamPlayer.play()
	else:
		$FullPanel/Load.region_rect = grayLoad
		$FullPanel/NewGame.texture.region = grayBox
		$FullPanel/OtherSave.texture.region = grayBox
		$FullPanel/Delete.texture.region = grayBox
		$FullPanel/Update.texture.region = grayBox
		$FullPanel/Options.texture.region = grayBox
		$FullPanel/Exit.texture.region = grayBox
		var pannel_pos
		match selected:
			SELECTED.CONTINUE:
				$FullPanel/Load.region_rect = greenLoad
				pannel_pos = 0
			SELECTED.NEW_GAME:
				$FullPanel/NewGame.texture.region = greenBox
				pannel_pos = 0
			SELECTED.OTHER_SAVES:
				$FullPanel/OtherSave.texture.region = greenBox
				pannel_pos = 0
			SELECTED.DELETE_SAVE:
				$FullPanel/Delete.texture.region = greenBox
				pannel_pos = 1
			SELECTED.UPDATE:
				$FullPanel/Update.texture.region = greenBox
				pannel_pos = 1
			SELECTED.OPTIONS:
				$FullPanel/Options.texture.region = greenBox
				pannel_pos = 1
			SELECTED.EXIT:
				$FullPanel/Exit.texture.region = greenBox
				pannel_pos = 1
		if pannel_pos == 0:
			$FullPanel.position = Vector2(50, 32)
		else:
			$FullPanel.position = Vector2(50, -160)
		$AudioStreamPlayer.play()

func changeScene(scene):
	if Global.isMobile:
		get_parent().newScene(scene)
	else:
		get_tree().change_scene(scene)

func continueGame(id):
	Global.load_game_from_id = id
	changeScene("res://Game.tscn")
