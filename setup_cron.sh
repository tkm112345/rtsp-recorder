#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON="${SCRIPT_DIR}/venv/bin/python"
RECORD_CMD="${PYTHON} ${SCRIPT_DIR}/record.py"
BACKUP_CMD="${SCRIPT_DIR}/backup.sh"
LOG_DIR="${SCRIPT_DIR}/logs"

# 追加したい cron エントリ一覧
declare -a CRON_JOBS=(
  "0  1 * * * ${RECORD_CMD} >> ${LOG_DIR}/record.log 2>&1"   # 深夜 1:00
  "0  8 * * * ${RECORD_CMD} >> ${LOG_DIR}/record.log 2>&1"   # 朝 8:00
  "0 14 * * * ${RECORD_CMD} >> ${LOG_DIR}/record.log 2>&1"   # 昼 14:00
  "0 19 * * * ${RECORD_CMD} >> ${LOG_DIR}/record.log 2>&1"   # 夕方 19:00
  "0 22 * * * ${RECORD_CMD} >> ${LOG_DIR}/record.log 2>&1"   # 夜 22:00
  "30 4 * * * ${BACKUP_CMD} >> ${LOG_DIR}/backup.log 2>&1"   # バックアップ 4:30
)

echo "=== cron 設定 ==="

CURRENT_CRON=$(crontab -l 2>/dev/null || true)
NEW_CRON="${CURRENT_CRON}"

for JOB in "${CRON_JOBS[@]}"; do
  # コマンド部分（スケジュール以外）で重複チェック
  CMD=$(echo "${JOB}" | awk '{$1=$2=""; print $0}' | xargs)
  if echo "${CURRENT_CRON}" | grep -qF "${CMD}"; then
    echo "[スキップ] 登録済み: ${CMD}"
  else
    NEW_CRON="${NEW_CRON}"$'\n'"${JOB}"
    echo "[OK] 登録: ${JOB}"
  fi
done

echo "${NEW_CRON}" | crontab -

echo ""
echo "=== 現在の crontab ==="
crontab -l
