# Tapo C225 録画スクリプト

Tapo C225 カメラから **映像＋音声** を10分間録画します。

## 必要なもの

- Python 3.7+
- ffmpeg: `sudo apt-get install ffmpeg`
- python-dotenv: `pip install python-dotenv`

## 事前準備（カメラアカウントの作成）

Tapo アプリで以下の手順を実行：

1. カメラを選択 → 右上の歯車アイコン（設定）
2. **詳細設定 → カメラアカウント**
3. ユーザー名とパスワードを設定する

> ※ Tapoクラウドアカウントとは **別の** カメラ専用アカウントです

## 使い方

`.env.example` をコピーして `.env` を作成し，各値を設定する：

```bash
cp .env.example .env
```

```ini
CAMERA_IP=192.168.x.x       # カメラのIPアドレス
USERNAME=camera_user         # カメラアカウントのユーザー名
PASSWORD=camera_password     # カメラアカウントのパスワード
NAS_ROOT=/mnt/nas/tapo-c225  # NAS の保存先ルートパス
```

実行：

```bash
python3 record.py
```

## 保存先

録画ファイルは `NAS_ROOT` 配下に **年/月/日** のフォルダ階層で保存されます。

```
/mnt/nas/tapo-c225/
└── 2026/
    └── 03/
        └── 18/
            └── tapo_c225_20260318_162402.mp4
```

> NAS をマウントしていない場合は，事前に `sudo mount` などでマウントしてください。

## RTSP URL 形式

```
rtsp://<ユーザー名>:<パスワード>@<IPアドレス>:554/stream1
```

| ストリーム | パス      | 画質   |
|-----------|----------|--------|
| メイン    | /stream1 | 高画質 |
| サブ      | /stream2 | 標準   |
