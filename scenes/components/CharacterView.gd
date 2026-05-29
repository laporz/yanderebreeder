extends Control

## CharacterView — ヒロイン立ち絵表示コンポーネント
## outfit と expression の組み合わせで画像を切り替える

@onready var heroine_sprite: TextureRect = $HeroineSprite

var _current_outfit: String = "normal"
var _current_expression: String = "default"

func _ready() -> void:
	pass

## 表情・衣装を指定して表示
func show_expression(outfit: String, expression: String) -> void:
	_current_outfit = outfit
	_current_expression = expression
	_apply_texture(outfit, expression)

## 衣装のデフォルト表情を表示
func show_default(outfit: String) -> void:
	show_expression(outfit, "default")

## 現在の衣装のまま表情だけ変更
func set_expression(expression: String) -> void:
	show_expression(_current_outfit, expression)

## 現在の表情のまま衣装だけ変更
func set_outfit(outfit: String) -> void:
	show_expression(outfit, _current_expression)

# --- 内部処理 ---

func _apply_texture(outfit: String, expression: String) -> void:
	var path := DialogueDB.resolve_image_path(outfit, expression)
	if path.is_empty():
		heroine_sprite.texture = null
		return
	var tex: Texture2D = load(path)
	heroine_sprite.texture = tex
