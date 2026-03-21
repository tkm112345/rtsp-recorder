#!/usr/bin/env python3
"""
Tapo C225 カメラから10分間，映像と音声を録画するスクリプト

事前準備:
  1. Tapoアプリ → カメラ設定 → 詳細設定 → カメラアカウント でアカウントを作成
  2. ffmpeg をインストール: sudo apt-get install ffmpeg
  3. .env.example をコピーして .env を作成し，各値を設定する
"""

import logging
import os
import shutil
import subprocess
import sys
from datetime import datetime
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

# ── 設定 ──────────────────────────────────────────────
CAMERA_IP       = os.environ["CAMERA_IP"]
USERNAME        = os.environ["USERNAME"]
PASSWORD        = os.environ["PASSWORD"]
NAS_ROOT        = Path(os.environ["NAS_ROOT"])
DURATION        = 6 * 60             # 録画時間 (秒)  6分 = 360秒
STREAM          = "stream1"           # "stream1" (高画質) / "stream2" (標準画質)
LOCAL_TMP_DIR   = Path("./recordings")  # 録画中の一時保存先 (録画後にNASへ移動し削除)
LOG_DIR         = Path("./logs")
LOG_BACKUP_DAYS = int(os.environ.get("LOG_BACKUP_DAYS", 30))  # ログ保持日数
# ──────────────────────────────────────────────────────


def setup_logger() -> logging.Logger:
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    handler = TimedRotatingFileHandler(
        filename=LOG_DIR / "record.log",
        when="midnight",          # 毎日深夜にローテーション
        backupCount=LOG_BACKUP_DAYS,
        encoding="utf-8",
    )
    handler.suffix = "%Y-%m-%d"   # record.log.2026-03-17 のような形式

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[handler, logging.StreamHandler()],  # ファイルと標準出力の両方に出力
    )
    return logging.getLogger(__name__)


def build_rtsp_url(ip: str, user: str, password: str, stream: str) -> str:
    return f"rtsp://{user}:{password}@{ip}:554/{stream}"


def record(rtsp_url: str, output_file: Path, duration_sec: int, logger: logging.Logger) -> int:
    cmd = [
        "ffmpeg",
        "-rtsp_transport", "tcp",   # TCPで安定接続
        "-i", rtsp_url,
        "-c:v", "copy",             # 映像はH.264のままコピー (再エンコードなし)
        "-c:a", "aac",              # 音声はAACに変換 (pcm_alawはMP4非対応のため)
        "-t", str(duration_sec),    # 録画時間
        str(output_file),
    ]

    logger.info("録画開始: %s  (%d分間)", output_file.name, duration_sec // 60)
    logger.info("接続先: %s", rtsp_url.split("@")[-1])  # パスワードをログに残さない

    try:
        result = subprocess.run(cmd, check=False, capture_output=True, text=True)
        if result.returncode != 0:
            logger.error("ffmpeg エラー:\n%s", result.stderr[-2000:])  # 末尾2000文字
        return result.returncode
    except FileNotFoundError:
        logger.error("ffmpeg が見つかりません。インストール: sudo apt-get install ffmpeg")
        return 1


def is_nas_available(nas_root: Path) -> bool:
    try:
        nas_root.stat()
        return True
    except OSError:
        return False


def move_to_nas(local_file: Path, nas_root: Path, now: datetime, logger: logging.Logger) -> bool:
    """NASへ移動する。成功したら True，失敗したら False を返す。"""
    try:
        nas_dir = nas_root / now.strftime("%Y") / now.strftime("%m") / now.strftime("%d")
        nas_dir.mkdir(parents=True, exist_ok=True)
        dest = nas_dir / local_file.name
        logger.info("NASへ移動中: %s -> %s", local_file, dest)
        shutil.move(str(local_file), dest)
        logger.info("移動完了。ローカルファイルを削除しました。")
        return True
    except OSError as e:
        logger.warning("NASへの移動失敗 (%s)。ローカルに保持します: %s", e, local_file)
        return False


def flush_pending_to_nas(nas_root: Path, logger: logging.Logger) -> None:
    """NAS復旧後に recordings/ に残っているファイルをNASへ移動する。"""
    pending = list(LOCAL_TMP_DIR.glob("tapo_c225_*.mp4"))
    if not pending:
        return

    logger.info("未転送ファイルが %d 件あります。NASへ移動します。", len(pending))
    for f in pending:
        try:
            # ファイル名のタイムスタンプから日付を復元
            ts = datetime.strptime(f.stem.split("_", 1)[1], "%Y%m%d_%H%M%S")
            if move_to_nas(f, nas_root, ts, logger):
                logger.info("移動済み: %s", f.name)
        except Exception as e:
            logger.warning("移動スキップ (%s): %s", f.name, e)


def main() -> None:
    logger = setup_logger()
    logger.info("=== 録画スクリプト起動 ===")

    now = datetime.now()
    LOCAL_TMP_DIR.mkdir(parents=True, exist_ok=True)

    # NASが復旧していれば未転送ファイルを先に移動
    if is_nas_available(NAS_ROOT):
        flush_pending_to_nas(NAS_ROOT, logger)

    timestamp = now.strftime("%Y%m%d_%H%M%S")
    local_file = LOCAL_TMP_DIR / f"tapo_c225_{timestamp}.mp4"

    rtsp_url = build_rtsp_url(CAMERA_IP, USERNAME, PASSWORD, STREAM)

    returncode = record(rtsp_url, local_file, DURATION, logger)

    if returncode != 0:
        logger.error("録画失敗: ffmpeg が終了コード %d で終了", returncode)
        sys.exit(returncode)

    logger.info("録画完了: %s", local_file)

    if is_nas_available(NAS_ROOT):
        move_to_nas(local_file, NAS_ROOT, now, logger)
    else:
        logger.warning("NAS未接続のためローカルに保持します: %s", local_file)


if __name__ == "__main__":
    main()
