# unityroom-godot-ranking

Godot から unityroom のランキングAPIへスコアを送信するための、非公式コミュニティSDKです。

※ このSDKは unityroom 公式のものではありません。

## 動作環境

- Godot 4.6.3 で開発・確認
- GDScript
- Web書き出し
- MIT License

## 主な機能

- 1行でスコア送信
- 必要な場合だけ `await` で送信完了や結果を取得
- シグナルでも送信結果を受け取り可能
- 同じランキングへの連続送信は自動で順番待ち
- タイムアウト設定

## インストール

Releasesから `v1.0` のZIPをダウンロードして展開します。

https://github.com/seisei0809/unityroom-godot-ranking/releases/tag/v1.0

ZIPの中には次の `addons` フォルダが入っています。

```text
addons/
└─ seisei/
   └─ unityroom_godot_ranking/
```

展開した `addons` フォルダを、使用するGodotプロジェクトのルートディレクトリへ移動、またはドラッグ＆ドロップしてください。

`project.godot` と同じ階層に `addons` があればOKです。

```text
使用するGodotプロジェクト/
├─ addons/
│  └─ seisei/
│     └─ unityroom_godot_ranking/
└─ project.godot
```

すでに `addons` フォルダがある場合は、そのまま中身を追加してください。

最終的にSDK本体が次のパスになればインストール完了です。

```text
res://addons/seisei/unityroom_godot_ranking/
```

<img width="389" height="175" alt="image" src="https://github.com/user-attachments/assets/f37a7519-a757-4807-926e-f9963ad61631" />


## unityroom側の設定

unityroomのゲーム設定からAPI利用を有効にし、HMAC認証用キーを取得してください。

その後、ランキング設定からランキングを作成します。

<img width="519" height="240" alt="image" src="https://github.com/user-attachments/assets/38273084-b136-4e55-bef7-6ea3d673f09b" />

<img width="186" height="148" alt="image" src="https://github.com/user-attachments/assets/9bd79c9f-ad80-4f61-9ee1-0718ddeb10bd" />

<img width="479" height="148" alt="image" src="https://github.com/user-attachments/assets/80674217-0016-4414-9368-b8f1e03f3e41" />

## セットアップ

ファイルシステムから次のシーンを、使用するシーンへドラッグ＆ドロップします。

```text
res://addons/seisei/unityroom_godot_ranking/unityroom_ranking_client.tscn
```

<img width="239" height="27" alt="image" src="https://github.com/user-attachments/assets/822355df-2007-4dbf-bb0a-5cf5946ef70e" />

ノードを選択するとインスペクターに `Hmac Key` が表示されるので、unityroomで取得したHMAC認証用キーを入力します。

<img width="283" height="156" alt="image" src="https://github.com/user-attachments/assets/72876903-df92-4daa-bd9b-163bb15781f1" />

これで準備完了です。

## スコアを送る

ユーザー側で書く基本コードは1行です。

```gdscript
$UnityroomRankingClient.send_score(1, score)
```

第1引数がランキングID、第2引数が送信するスコアです。

同じランキングへ短時間に複数回 `send_score()` を呼んだ場合は、自動でQueueに入り、6秒間隔で順番に送信されます。

別のランキングIDへの送信はそれぞれ独立して処理されるため、同時に送信できます。

例えば100点を送る場合は次の1行です。

```gdscript
$UnityroomRankingClient.send_score(1, 100.0)
```

送信完了まで待ちたい場合だけ `await` を付けます。

```gdscript
await $UnityroomRankingClient.send_score(1, 100.0)
```

送信結果も使いたい場合はレスポンスを受け取ります。

```gdscript
var response := await $UnityroomRankingClient.send_score(1, 100.0)

if not response.success:
	push_error(
		response.get_error_text()
	)
	return

if response.score_updated:
	print("スコアが更新されました")
```

## シグナルで送信結果を受け取る

`score_sent` シグナルでも送信結果を受け取れます。

```gdscript
func _ready() -> void:
	$UnityroomRankingClient.score_sent.connect(
		_on_score_sent
	)

	$UnityroomRankingClient.send_score(
		1,
		100.0
	)

func _on_score_sent(
	response: UnityroomRankingResponse
) -> void:
	if response.success:
		print("送信成功")
```

## 設定

クライアントには次の設定があります。

| 項目 | 初期値 | 内容 |
| --- | ---: | --- |
| `timeout` | `10.0` | HTTP通信のタイムアウト秒数 |

インスペクターから変更できます。

## 送信結果

`send_score()` は `UnityroomRankingResponse` を返します。

| 項目 | 内容 |
| --- | --- |
| `success` | 送信処理に成功したか |
| `score_updated` | unityroom上のScoreが更新されたか |
| `response_code` | HTTPステータスコード |
| `error_type` | エラーの種類 |
| `error_message` | エラー内容 |

エラー内容を文字列で取得したい場合は、次のようにできます。

```gdscript
print(
	response.get_error_text()
)
```

## デモ

このリポジトリ自体がデモプロジェクトになっています。

ローカルでは日本語表示確認用のフォントを別途配置しています。

```text
demo/scenes/main.tscn
```

デモシーンの `UnityroomRankingClient` ノードを選択し、インスペクターの `Hmac Key` にテスト用キーを設定してからWeb書き出ししてください。

unityroomへアップロード後、デモ画面でランキングIDとスコアを入力すると送信確認できます。

<img width="704" height="456" alt="image" src="https://github.com/user-attachments/assets/46dd85a3-5093-4c29-9b92-dddf576022d6" />

<img width="564" height="182" alt="image" src="https://github.com/user-attachments/assets/491bd3b9-0bb7-44e6-bc5c-a7301daa46cf" />

## デモプロジェクトのディレクトリ構成

```text
unityroom-godot-ranking/
├─ addons/
│  └─ seisei/
│     └─ unityroom_godot_ranking/
│        ├─ README.md
│        ├─ LICENSE
│        ├─ unityroom_ranking_client.gd
│        ├─ unityroom_ranking_client.tscn
│        └─ unityroom_ranking_response.gd
├─ demo/
├─ LICENSE
└─ project.godot
```

SDK本体は `addons/seisei/unityroom_godot_ranking/` の中だけです。

## 注意

- ランキングAPIへの送信はWeb書き出しで使用してください。
- HMAC認証用キーを公開リポジトリへコミットしないでください。
- スコアを毎フレーム送信しないでください。

## License

MIT License

Copyright (c) 2026 seisei0809

## Credits

- [nnnnnnn0090](https://github.com/nnnnnnn0090)
