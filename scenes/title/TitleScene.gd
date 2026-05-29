extends Node

@onready var continue_button: Button = $CanvasLayer/Center/VBox/ContinueButton
@onready var load_button: Button     = $CanvasLayer/Center/VBox/LoadButton
@onready var save_panel              = $SavePanel

func _ready() -> void:
	# セーブデータが一つもなければ「続きから」「ロード」を無効化
	var has_save := SaveManager.any_save_exists()
	continue_button.disabled = not has_save
	load_button.disabled     = not has_save

	save_panel.slot_action_done.connect(_on_load_slot_selected)

func _on_start_button_pressed() -> void:
	# 新規ゲーム: GameState をリセットしてから開始
	GameState.affection            = 0
	GameState.lust                 = 0
	GameState.dependency           = 0
	GameState.pleasure             = 0
	GameState.day                  = 1
	GameState.has_bought_drugstore = false
	GameState.has_bought_yamizon   = false
	GameState.inventory.clear()
	get_tree().change_scene_to_file("res://scenes/morning/MorningScene.tscn")

func _on_continue_button_pressed() -> void:
	# オートセーブを直接ロード
	if SaveManager.load_game("autosave"):
		var path := SaveManager.get_scene_path("autosave")
		get_tree().change_scene_to_file(path)

func _on_load_button_pressed() -> void:
	save_panel.open_load_mode()

func _on_load_slot_selected(slot: String) -> void:
	if SaveManager.load_game(slot):
		var path := SaveManager.get_scene_path(slot)
		get_tree().change_scene_to_file(path)
