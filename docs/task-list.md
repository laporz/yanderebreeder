# Task List

## Documents

- [x] CLAUDE.mdを入口用に整理
- [x] game-spec.htmlを作成
- [x] character-spec.htmlを作成
- [x] status-system.htmlを作成
- [x] daily-routine.htmlを作成
- [x] scene-flow.htmlを作成
- [x] shop-items.htmlを作成
- [x] scenario-rules.mdを作成

## Scene Implementation

- [x] scripts/GameState.gd — ステータス管理シングルトン（AutoLoad登録済み）
- [x] scenes/title/TitleScene.tscn + .gd — タイトル画面
- [x] scenes/morning/MorningScene.tscn + .gd — 朝シーン（会話・ふれあい・ステータス確認）
- [x] scenes/night/NightScene.tscn + .gd — 夜シーン（買い物・食事・就寝）
- [x] scenes/midnight/MidnightScene.tscn + .gd — 深夜シーン（快感度・依存度）
- [x] project.godot — メインシーン・AutoLoad設定

## Future Design Tasks

- [ ] エンディング3種類の分岐条件を定義する
- [ ] 各シーンのUIレイアウトを定義する（ビジュアル強化）
- [ ] セーブデータ構造を定義する
- [ ] 会話イベントのデータ形式を定義する（シナリオテキスト実装）
- [ ] キャラクター画像・立ち絵の追加
- [ ] ショップ機能の実装（ドラッグストア・Yamizon）
