# rtsp-recorder

**TP-Link Tapo C225** の RTSPストリームに接続し，**映像＋音声** を録画して NAS に保存する Python スクリプトです。
録画はローカルに一時保存した後に NAS へ移動することで，HDD への書き込み回数を最小限に抑えています。

> 動作確認済みカメラ: TP-Link Tapo C225

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
CAMERA_IP=192.168.x.x                  # カメラのIPアドレス
USERNAME=camera_user                    # カメラアカウントのユーザー名
PASSWORD=camera_password                # カメラアカウントのパスワード
NAS_ROOT=/mnt/nas/tapo-c225            # NAS の録画保存先ルートパス
BACKUP_DIR=/mnt/nas/backups/tapo-child  # NAS のバックアップ保存先
LOG_BACKUP_DAYS=30                      # ログの保持日数
BACKUP_KEEP_DAYS=30                     # バックアップの保持日数
```

実行：

```bash
venv/bin/python record.py
```

## 保存先

録画ファイルはローカルに一時保存後，`NAS_ROOT` 配下に **年/月/日** のフォルダ階層で保存されます。

```
/mnt/nas/tapo-c225/
└── 2026/
    └── 03/
        └── 18/
            └── tapo_c225_20260318_080000.mp4
```

> NAS をマウントしていない場合，録画は失敗します。事前に `sudo mount -a` でマウントしてください。

## cron スケジュール

`setup_cron.sh` を実行すると以下のスケジュールが登録されます（録画時間: 6分）：

| 時刻 | 内容 |
|------|------|
| 深夜 1:00 | 録画 |
| 朝 8:00 | 録画 |
| 昼 14:00 | 録画 |
| 夕方 19:00 | 録画 |
| 夜 22:00 | 録画 |
| 早朝 4:30 | バックアップ |

```bash
# 既存のcronを削除してから再登録
./remove_cron.sh
./setup_cron.sh
```

## デプロイ

```bash
./deploy.sh
```

ローカルから `proxmox@192.168.1.4:/home/proxmox/tapo-child` へ rsync で転送し，venv のセットアップまで自動で行います。

## バックアップ

```bash
./backup.sh
```

ソースコードとログを `BACKUP_DIR` 配下にタイムスタンプ付きで保存します。`BACKUP_KEEP_DAYS` より古いバックアップは自動削除されます。

## RTSP URL 形式

```
rtsp://<ユーザー名>:<パスワード>@<IPアドレス>:554/stream1
```

| ストリーム | パス      | 画質   |
|-----------|----------|--------|
| メイン    | /stream1 | 高画質 |
| サブ      | /stream2 | 標準   |
