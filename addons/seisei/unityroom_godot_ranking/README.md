# unityroom-godot-ranking

このフォルダがSDK本体です。

使用するGodotプロジェクトへ、次のパスになるように配置してください。

```text
res://addons/seisei/unityroom_godot_ranking/
```

`unityroom_ranking_client.tscn` を使用するシーンへドラッグ＆ドロップします。

インスペクターの `Hmac Key` にunityroomで取得したHMAC認証用キーを入力してください。

スコア送信は1行です。

```gdscript
await $UnityroomRankingClient.send_score(1, 100.0)
```

詳しい使い方はリポジトリ直下の `README.md` を参照してください。
