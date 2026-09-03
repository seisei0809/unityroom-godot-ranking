extends Control

# unityroom Ranking Client
@onready var unityroom_client: UnityroomRankingClient = (
	$UnityroomRankingClient
)
# Scoreboard ID入力欄
@onready var scoreboard_id_input: SpinBox = (
	$VBox/ScoreboardIdInput
)
# Score入力欄
@onready var score_input: LineEdit = (
	$VBox/ScoreInput
)
# Score送信Button
@onready var send_button: Button = (
	$VBox/SendButton
)
# 送信結果表示
@onready var result_label: Label = (
	$VBox/ResultLabel
)

func _ready() -> void:
	# Send Button押下時の処理を接続
	send_button.pressed.connect(
		_on_send_button_pressed
	)

func _on_send_button_pressed() -> void:
	# HMAC認証用キーが未設定なら終了
	if unityroom_client.hmac_key.strip_edges().is_empty():
		result_label.text = "HMAC認証用キーが設定されていません。"
		return
	
	# Score文字列
	var score_text := score_input.text.strip_edges()
	
	# Scoreが数値でなければ終了
	if not score_text.is_valid_float():
		result_label.text = "スコアには数値を入力してください。"
		return
	
	# 二重押し防止
	send_button.disabled = true
	# 送信中表示
	result_label.text = "送信中..."
	
	# unityroom RankingへScore送信
	var response := await unityroom_client.send_score(
		int(scoreboard_id_input.value),
		score_text.to_float()
	)
	
	# Buttonを再び押せるようにする
	send_button.disabled = false
	
	# 送信失敗
	if not response.success:
		result_label.text = response.get_error_text()
		return
	
	# 送信成功
	result_label.text = "送信成功"
