#!/usr/bin/env bash
set -euo pipefail

# .env を読み込む
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/.env" ]; then
  export $(grep -v '^#' "${SCRIPT_DIR}/.env" | xargs)
fi

: "${BACKUP_DIR:?BACKUP_DIR が .env に設定されていません}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEST="${BACKUP_DIR}/${TIMESTAMP}"

echo "=== バックアップ開始: ${DEST} ==="
mkdir -p "${DEST}"

# ── ソースコードのバックアップ ────────────────────────
echo "[1/2] ソースコードをアーカイブ中..."
tar -czf "${DEST}/source_${TIMESTAMP}.tar.gz" \
  --exclude='.env' \
  --exclude='./logs' \
  --exclude='./recordings' \
  --exclude='./venv' \
  --exclude='./__pycache__' \
  --exclude='*.pyc' \
  -C "${SCRIPT_DIR}" .
echo "      -> ${DEST}/source_${TIMESTAMP}.tar.gz"

# ── ログファイルのバックアップ ────────────────────────
LOG_DIR="${SCRIPT_DIR}/logs"
if [ -d "${LOG_DIR}" ] && [ -n "$(ls -A "${LOG_DIR}" 2>/dev/null)" ]; then
  echo "[2/2] ログファイルをアーカイブ中..."
  tar -czf "${DEST}/logs_${TIMESTAMP}.tar.gz" \
    -C "${SCRIPT_DIR}" logs/
  echo "      -> ${DEST}/logs_${TIMESTAMP}.tar.gz"
else
  echo "[2/2] ログファイルなし。スキップ。"
fi

# ── 古いバックアップの削除 ────────────────────────────
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-30}"
echo "古いバックアップを削除中 (${BACKUP_KEEP_DAYS}日以前)..."
find "${BACKUP_DIR}" -maxdepth 1 -type d \
  -mtime "+${BACKUP_KEEP_DAYS}" \
  -exec rm -rf {} + 2>/dev/null || true

echo "=== バックアップ完了 ==="
