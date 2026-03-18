#!/usr/bin/env bash
set -euo pipefail

REMOTE_USER="proxmox"
REMOTE_HOST="192.168.1.4"
REMOTE_DIR="/home/proxmox/tapo-child"
SSH_SOCKET="/tmp/ssh-deploy-${REMOTE_HOST}.sock"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=${SSH_SOCKET} -o ControlPersist=60"

echo "=== デプロイ開始: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR} ==="

# SSH接続を確立 (パスワード入力はここで1回のみ)
ssh ${SSH_OPTS} -o ControlMaster=yes -MNf "${REMOTE_USER}@${REMOTE_HOST}"

# ── ファイル転送 ──────────────────────────────────────
# .env / logs/ / recordings/ / .claude/ 等はデプロイ対象から除外
rsync -avz --delete \
  -e "ssh ${SSH_OPTS}" \
  --exclude='.env' \
  --exclude='logs/' \
  --exclude='recordings/' \
  --exclude='__pycache__/' \
  --exclude='*.pyc' \
  --exclude='.gitignore' \
  --exclude='claude resume.txt' \
  --exclude='.claude/' \
  --exclude='venv/' \
  . "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"

# ── リモートでセットアップ ────────────────────────────
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" bash << EOF
  set -euo pipefail
  cd "${REMOTE_DIR}"

  # .env がなければテンプレートからコピー
  if [ ! -f .env ]; then
    cp .env.example .env
    echo "[注意] .env を作成しました。${REMOTE_DIR}/.env を編集して認証情報を設定してください。"
  fi

  # python3-venv が未インストールの場合はインストール
  if ! python3 -m venv --help > /dev/null 2>&1; then
    echo "[セットアップ] python3-venv をインストール中..."
    sudo apt-get install -y python3-venv
  fi

  # venv が壊れている場合は再作成
  if [ ! -f venv/bin/pip ]; then
    rm -rf venv
    python3 -m venv venv
    echo "[OK] venv を作成しました。"
  fi

  venv/bin/pip install --quiet --upgrade pip
  venv/bin/pip install --quiet -r requirements.txt
  echo "[OK] 依存パッケージをインストールしました。"
EOF

# SSH接続を閉じる
ssh ${SSH_OPTS} -O exit "${REMOTE_USER}@${REMOTE_HOST}" 2>/dev/null || true

echo "=== デプロイ完了 ==="
echo ""
echo "実行方法:"
echo "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
echo "  cd ${REMOTE_DIR} && venv/bin/python record.py"
