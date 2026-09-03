class_name UnityroomRankingResponse
extends RefCounted

# Score送信処理に成功したか
var success := false
# unityroom上のScoreが更新されたか
var score_updated := false
# HTTP Status Code
var response_code := 0
# Error種類
var error_type := ""
# Error内容
var error_message := ""

func get_error_text() -> String:
	# Errorが無ければ空文字
	if success:
		return ""
	
	# Error内容をまとめて返す
	return error_message

static func create_success(
	is_score_updated: bool,
	http_response_code: int
) -> UnityroomRankingResponse:
	# 成功Responseを生成
	var response := UnityroomRankingResponse.new()
	
	# 成功状態を設定
	response.success = true
	# Score更新状態を保存
	response.score_updated = is_score_updated
	# HTTP Status Codeを保存
	response.response_code = http_response_code
	
	return response

static func create_error(
	type: String,
	message: String,
	http_response_code := 0
) -> UnityroomRankingResponse:
	# Error Responseを生成
	var response := UnityroomRankingResponse.new()
	
	# Error情報を保存
	response.error_type = type
	response.error_message = message
	response.response_code = http_response_code
	
	return response
