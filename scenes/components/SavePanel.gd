extends CanvasLayer

## SavePanel — セーブ・ロード共用パネル（layer=20で最前面）
## タイトルからはLOADモード、ゲーム中はSAVEモードで開く

signal slot_action_done(slot: String)   # セーブ完了 or ロード選択
signal panel_closed()

enum Mode { SAVE, LOAD }

const SLOT_NAMES    := ["autosave", "save1", "save2", "save3"]
const SLOT_LABELS   := ["オートセーブ", "セーブ 1", "セーブ 2", "セーブ 3"]
const AUTO_SAVE_IDX := 0   # autosave はゲーム中のセーブ対象外

var _mode: Mode = Mode.LOAD
var _current_scene: String = "morning"

@onready var panel_root: Panel          = $PanelRoot
@onready var title_label: Label         = $PanelRoot/VBox/TitleLabel
@onready var slots_container: VBoxContainer = $PanelRoot/VBox/SlotsContainer
@onready var close_button: Button       = $PanelRoot/VBox/CloseButton

# ------------------------------------------------------------------ #

func open_load_mode() -> void:
	_mode = Mode.LOAD
	title_label.text = "ロード"
	visible = true
	_rebuild_slots()

func open_save_mode(current_scene: String) -> void:
	_mode = Mode.SAVE
	_current_scene = current_scene
	title_label.text = "セーブ"
	visible = true
	_rebuild_slots()

func close() -> void:
	visible = false
	panel_closed.emit()

# ------------------------------------------------------------------ #

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)

func _rebuild_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	for i in SLOT_NAMES.size():
		var slot: String = SLOT_NAMES[i]
		var info: Dictionary = SaveManager.get_slot_info(slot)

		var btn := Button.new()
		var prefix: String = SLOT_LABELS[i]
		btn.text = "%s: %s" % [prefix, info.get("label", "（空）")]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 56)

		# SAVEモードではオートセーブスロットは選択不可
		if _mode == Mode.SAVE and i == AUTO_SAVE_IDX:
			btn.disabled = true
			btn.tooltip_text = "オートセーブは自動で行われます"
		else:
			btn.pressed.connect(_on_slot_pressed.bind(slot, info))

		slots_container.add_child(btn)

func _on_slot_pressed(slot: String, info: Dictionary) -> void:
	if _mode == Mode.SAVE:
		SaveManager.save_game(slot, _current_scene)
		slot_action_done.emit(slot)
		# ボタンラベルを更新
		_rebuild_slots()
	else:
		# LOADモード: データがあれば選択、なければ無視
		if info.get("exists", false):
			slot_action_done.emit(slot)
			visible = false
