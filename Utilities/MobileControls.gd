extends Node

var game = null
var gameInstance = null
var deviceResolution = OS.get_real_window_size()

func _ready():
	Global.isMobile = true
	deviceResolution = OS.get_real_window_size()
	$ColorRect.rect_size = deviceResolution
	
	# Configura el tamaño del viewport
	$ViewportContainer/GameViewport.set_size_override_stretch(true)
	$ViewportContainer/GameViewport.set_size_override(true, Vector2(512, 384))
	
	resize()
	
	game = load("res://IntroScenes/Intro.tscn")
	gameInstance = game.instance()
	$ViewportContainer/GameViewport.add_child(gameInstance)

func resize():
	deviceResolution = OS.get_real_window_size()
	
	# Mantén la proporción base de 512x384
	var base_resolution = Vector2(512, 384)
	var scale_factor = min(deviceResolution.x / base_resolution.x, deviceResolution.y / base_resolution.y)
	
	var viewport_size = base_resolution * scale_factor
	var viewport_position = (deviceResolution - viewport_size) / 2
	
	$ViewportContainer.rect_position = viewport_position
	$ViewportContainer.rect_size = viewport_size
	
	# Ajusta el tamaño y posición del CanvasLayer para los controles
	var controlScale = scale_factor
	
	# Ajusta el tamaño del D-Pad
	var dpad_size = Vector2(150 * controlScale, 150 * controlScale)
	$CanvasLayer/D_Pad.rect_size = dpad_size
	$CanvasLayer/D_Pad.rect_position = Vector2(20, deviceResolution.y - dpad_size.y - 20)
	
	# Ajusta el tamaño de los botones
	var button_size = Vector2(100 * controlScale, 100 * controlScale)
	$CanvasLayer/Buttons.rect_size = button_size
	$CanvasLayer/Buttons.rect_position = Vector2(deviceResolution.x - button_size.x - 20, deviceResolution.y - button_size.y - 20)
	
	DialogueSystem.rescale_mobile(deviceResolution)

func changeScene(scene):
	if gameInstance:
		gameInstance.queue_free()
	game = load(scene)
	gameInstance = game.instance()
	$ViewportContainer/GameViewport.add_child(gameInstance)

func send_input_event(action: String, pressed: bool):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _on_Up_pressed(): send_input_event("ui_up", true)
func _on_Down_pressed(): send_input_event("ui_down", true)
func _on_Left_pressed(): send_input_event("ui_left", true)
func _on_Right_pressed(): send_input_event("ui_right", true)
func _on_Up_released(): send_input_event("ui_up", false)
func _on_Down_released(): send_input_event("ui_down", false)
func _on_Left_released(): send_input_event("ui_left", false)
func _on_Right_released(): send_input_event("ui_right", false)
func _on_Z_button_down(): send_input_event("z", true)
func _on_X_button_down(): send_input_event("x", true)
func _on_C_button_down(): send_input_event("c", true)
func _on_S_button_down(): send_input_event("ui_accept", true)
func _on_Z_button_up(): send_input_event("z", false)
func _on_X_button_up(): send_input_event("x", false)
func _on_C_button_up(): send_input_event("c", false)
func _on_S_button_up(): send_input_event("ui_accept", false)
