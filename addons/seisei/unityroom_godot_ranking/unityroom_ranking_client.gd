class_name UnityroomRankingClient
extends Node

const API_ORIGIN := "https://unityroom.com"
const SCORE_PATH := "/gameplay_api/v1/scoreboards/%d/scores"

@export_group("unityroom設定")
# unityroomで発行したHMAC認証用キー
@export var hmac_key := ""

@export_group("通信設定")
# HTTP通信のタイムアウト秒数
@export_range(1.0, 60.0, 1.0) var timeout := 10.0

# スコア送信完了時に通知
signal score_sent(response: UnityroomRankingResponse)

# 現在スコア送信中か
var is_sending := false

func send_score(
	scoreboard_id: int,
	score: float
) -> UnityroomRankingResponse:
	# Web版以外では送信しない
	if not OS.has_feature("web"):
		return finish_request(
			UnityroomRankingResponse.create_error(
				"unsupported_platform",
				"unityroomランキングAPIはWeb書き出しでのみ使用できます。"
			)
		)

	# HMAC認証用キーが未設定
	if hmac_key.strip_edges().is_empty():
		return finish_request(
			UnityroomRankingResponse.create_error(
				"hmac_key_empty",
				"HMAC認証用キーが設定されていません。"
			)
		)

	# ランキングIDが不正
	if scoreboard_id <= 0:
		return finish_request(
			UnityroomRankingResponse.create_error(
				"invalid_scoreboard_id",
				"ランキングIDには1以上の値を指定してください。"
			)
		)

	# 同時送信は行わない
	if is_sending:
		return finish_request(
			UnityroomRankingResponse.create_error(
				"busy",
				"別のスコアを送信中です。送信完了後にもう一度お試しください。"
			)
		)

	# 送信中状態にする
	is_sending = true

	# スコア送信
	var response := await send_score_once(
		scoreboard_id,
		score
	)

	# 送信中状態を解除
	is_sending = false

	return finish_request(response)

func send_scores(
	scores: Dictionary
) -> Dictionary:
	# ランキングごとの送信結果
	var responses := {}

	# 指定されたスコアを順番に送信
	for scoreboard_key in scores:
		# ランキングID
		var scoreboard_id := int(
			scoreboard_key
		)
		# スコア
		var score := float(
			scores[scoreboard_key]
		)

		# スコア送信
		responses[scoreboard_id] = await send_score(
			scoreboard_id,
			score
		)

	return responses

func send_score_once(
	scoreboard_id: int,
	score: float
) -> UnityroomRankingResponse:
	# unityroom APIのパス
	var path := (
		SCORE_PATH
		% scoreboard_id
	)

	# 現在時刻をUNIX秒で取得
	var unix_time := str(
		int(Time.get_unix_time_from_system())
	)

	# スコアを文字列へ変換
	var score_text := str(score)

	# unityroom仕様の署名元文字列
	var signature_source := (
		"POST\n%s\n%s\n%s"
		% [
			path,
			unix_time,
			score_text
		]
	)

	# HMAC-SHA256署名を生成
	var signature := create_signature(
		hmac_key,
		signature_source
	)

	# 署名生成失敗
	if signature.is_empty():
		return UnityroomRankingResponse.create_error(
			"invalid_hmac_key",
			"HMAC認証用キーが正しくないため、署名を作成できませんでした。"
		)

	# HTTPヘッダー
	var headers := PackedStringArray([
		"Content-Type: application/x-www-form-urlencoded",
		"X-Unityroom-Signature: %s" % signature,
		"X-Unityroom-Timestamp: %s" % unix_time
	])

	# POSTするデータ
	var body := (
		"score=%s"
		% score_text.uri_encode()
	)

	# HTTPRequestを生成
	var http_request := HTTPRequest.new()

	# タイムアウトを設定
	http_request.timeout = timeout

	# SceneTreeへ追加
	add_child(http_request)

	# HTTP通信開始
	var request_error := http_request.request(
		API_ORIGIN + path,
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	# HTTP通信を開始できなかった場合
	if request_error != OK:
		http_request.queue_free()
		return UnityroomRankingResponse.create_error(
			"request_error",
			"HTTP通信を開始できませんでした。"
		)

	# HTTP通信完了まで待つ
	var raw_response = await http_request.request_completed

	# Godot側の通信結果
	var request_result: int = raw_response[0]
	# HTTPステータスコード
	var response_code: int = raw_response[1]
	# 返ってきたデータ
	var response_body: PackedByteArray = raw_response[3]

	# 返ってきたデータを文字列へ変換
	var response_text := response_body.get_string_from_utf8()

	# HTTPRequestを破棄
	http_request.queue_free()

	# 通信そのものに失敗
	if request_result != HTTPRequest.RESULT_SUCCESS:
		return UnityroomRankingResponse.create_error(
			"network_error",
			"通信に失敗しました。ネットワーク接続を確認してください。",
			response_code
		)

	# HTTPエラー
	if response_code < 200 or response_code >= 300:
		return parse_error_response(
			response_text,
			response_code
		)

	# JSONを解析
	var response_data = JSON.parse_string(
		response_text
	)

	# JSON形式が不正
	if not response_data is Dictionary:
		return UnityroomRankingResponse.create_error(
			"invalid_response",
			"unityroomから正しくない形式の応答が返されました。",
			response_code
		)

	# スコアが更新されたか取得
	var score_updated := bool(
		response_data.get(
			"saved",
			false
		)
	)

	# 成功結果を返す
	return UnityroomRankingResponse.create_success(
		score_updated,
		response_code
	)

func parse_error_response(
	response_text: String,
	response_code: int
) -> UnityroomRankingResponse:
	# JSONを解析
	var response_data = JSON.parse_string(
		response_text
	)

	# JSON形式でない場合
	if not response_data is Dictionary:
		return UnityroomRankingResponse.create_error(
			"http_error",
			"unityroom APIでエラーが発生しました。（HTTP %d）"
			% response_code,
			response_code
		)

	# APIが返したエラー種類
	var error_type := str(
		response_data.get(
			"type",
			"http_error"
		)
	)

	# ユーザーへ表示する日本語エラーを取得
	var error_message := get_api_error_message(
		error_type,
		response_code
	)

	return UnityroomRankingResponse.create_error(
		error_type,
		error_message,
		response_code
	)

func get_api_error_message(
	error_type: String,
	response_code: int
) -> String:
	# 短時間に送信しすぎた場合
	if error_type == "rate_limit_exceeded":
		return "短時間に送信しすぎています。しばらく待ってからもう一度お試しください。"

	# 認証に失敗した場合
	if error_type == "invalid_signature":
		return "HMAC認証に失敗しました。認証用キーを確認してください。"

	# 送信時刻が不正な場合
	if error_type == "invalid_timestamp":
		return "送信時刻が正しくありません。端末の時刻設定を確認してください。"

	# その他のAPIエラー
	return (
		"unityroom APIでエラーが発生しました。（HTTP %d）"
		% response_code
	)

func finish_request(
	response: UnityroomRankingResponse
) -> UnityroomRankingResponse:
	# スコア送信完了を通知
	score_sent.emit(response)

	return response

static func create_signature(
	key_text: String,
	source: String
) -> String:
	# Base64形式のHMAC認証用キーをByte配列へ戻す
	var key_bytes := Marshalls.base64_to_raw(
		key_text.strip_edges()
	)

	# Key変換失敗
	if key_bytes.is_empty():
		return ""

	# HMAC生成器
	var hmac := HMACContext.new()

	# SHA-256でHMAC生成開始
	var error := hmac.start(
		HashingContext.HASH_SHA256,
		key_bytes
	)

	# 初期化失敗
	if error != OK:
		return ""

	# 署名元文字列を渡す
	error = hmac.update(
		source.to_utf8_buffer()
	)

	# 更新失敗
	if error != OK:
		return ""

	# HMACを16進文字列にして返す
	return hmac.finish().hex_encode()
