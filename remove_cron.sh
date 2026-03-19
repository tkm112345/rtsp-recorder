#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECORD_CMD="${SCRIPT_DIR}/venv/bin/python ${SCRIPT_DIR}/record.py"
BACKUP_CMD="${SCRIPT_DIR}/backup.sh"

echo "=== cron 削除 ==="

CURRENT_CRON=$(crontab -l 2>/dev/null || true)

if [ -z "${CURRENT_CRON}" ]; then
  echo "[スキップ] crontab が空です。"
  exit 0
fi

# record.py と backup.sh に関するエントリをすべて削除
NEW_CRON=$(echo "${CURRENT_CRON}" | grep -vF "${RECORD_CMD}" | grep -vF "${BACKUP_CMD}" || true)

echo "${NEW_CRON}" | crontab -

echo "[OK] 削除しました。"
echo ""
echo "=== 現在の crontab ==="
crontab -l || echo "(空)"
