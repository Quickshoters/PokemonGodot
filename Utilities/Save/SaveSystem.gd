extends Node

const SAVE_STATE = preload('res://Utilities/Save/State.gd')

var SAVE_FOLDER # The location of where the save is stored
var android_external_save_folder : String = "/storage/emulated/0/Android/data/org.godotengine.pokmonuranium/files"
var SAVE_NAME_TEMPLATE = "save_%03d.tres"

var save_state : SAVE_STATE

# save_id starts at 1 to n
var error_messages = ""

func _ready():
	if OS.is_debug_build() and not OS.get_name() == "Android":
		SAVE_FOLDER = "res://Utilities/Save"
	else:
		if OS.get_name() == "Android":
			# Attempt to use the external folder path you provided
			if check_external_save_folder():
				SAVE_FOLDER = android_external_save_folder
			else:
				# Fallback to internal storage if external is not accessible
				SAVE_FOLDER = "user://"
		else:
			SAVE_FOLDER = "user://"

	save_state = SAVE_STATE.new()

func check_external_save_folder() -> bool:
	var directory : Directory = Directory.new()
	# Check if the folder exists, if not try to create it
	if not directory.dir_exists(android_external_save_folder):
		print("External save folder does not exist. Attempting to create it.")
		var error = directory.make_dir_recursive(android_external_save_folder)
		if error != OK:
			print("Failed to create external save folder. Using internal storage instead.")
			return false
	return true

func has_state(key):
	return save_state.has_key(key)

func get_state(key):
	return save_state.get_data(key)

func set_state(key, state):
	save_state.update_data(key, state)

func load_game(save_id):
	save_state = load_file(save_id)
	for node in get_tree().get_nodes_in_group("save"):
		node.load_state()

func save_game(save_id):
	for node in get_tree().get_nodes_in_group("save"):
		node.save_state()
	save_file(save_id)

func load_file(id):
	var save_file_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var file : File = File.new()
	if not file.file_exists(save_file_path):
		print("Save file %s doesn't exist. Creating new save file." % save_file_path)
		var new_save = SAVE_STATE.new()
		return new_save
	print("Loading existing file.")
	var save_game = load(save_file_path)
	return save_game

func save_file(id):
	var directory : Directory = Directory.new()
	if not directory.dir_exists(SAVE_FOLDER):
		directory.make_dir_recursive(SAVE_FOLDER)

	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var error = ResourceSaver.save(save_path, save_state)

	if error != OK:
		print('There was an issue writing the save %s to %s' % [id, save_path])

func get_number_of_saves():
	var directory : Directory = Directory.new()

	var error = directory.open(SAVE_FOLDER)

	if error != 0:
		print("Error opening save folder")
		error_messages += "Error opening save folder\n"
		print("Error code: %d" % error)
		error_messages += "Error code: %d\n" % error
		return 0

	var num = 0
	while directory.file_exists(SAVE_NAME_TEMPLATE % (num + 1)):
		num += 1
	return num
