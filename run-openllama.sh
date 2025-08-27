#!/usr/bin/env bash
set -Eeuo pipefail

BOLD="\033[1m"; DIM="\033[2m"; GREEN="\033[32m"; CYAN="\033[36m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
ok(){ echo -e "✅ $*"; } info(){ echo -e "ℹ️  $*"; } warn(){ echo -e "⚠️  $*"; } err(){ echo -e "❌ ${RED}$*${RESET}"; }
trap 'err "Failed on line $LINENO: $BASH_COMMAND"' ERR

banner(){ echo -e "${BOLD}${CYAN}
   ____                  _ _ _ _                              
  / __ \\                | (_) | |                             
 | |  | |_ __   ___  ___| |_| | | __ _ _ __ ___   __ _  ___   
 | |  | | '_ \\ / _ \\/ __| | | | |/ _\` | '_ \` _ \\ / _\` |/ _ \\  
 | |__| | | | |  __/\\__ \\ | | | | (_| | | | | | | (_| | (_) | 
  \\____/|_| |_|\\___||___/_|_|_|_|\\__,_|_| |_| |_|\\__,_|\\___/  
${RESET}${DIM}✨ One-touch OpenLLaMA → llama.cpp (GGUF) runner — by ${BOLD}Bidhan Baniya${RESET}\n"; }
banner

MODEL_DIR=""
LLAMA_DIR="${LLAMA_DIR:-./llama.cpp}"
OUT_DIR="${OUT_DIR:-./gguf_models}"
QTYPE="${QTYPE:-Q4_K_M}"
CTX="${CTX:-4096}"
THREADS="${THREADS:-}"
NGL="${NGL:-0}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
DAEMON="false"
START_GO="false"
ENV_FILE=""
AGREE_TOS="false"

usage(){
  cat <<EOF
${BOLD}Usage:${RESET} $0 --model-dir <hf_folder> [options]

Required:
  --model-dir PATH      Folder with HF weights (e.g., ./open_llama_7b)

Options:
  --llama-dir PATH      llama.cpp directory (default: ${LLAMA_DIR})
  --out-dir PATH        GGUF output dir (default: ${OUT_DIR})
  --qtype TYPE          Quant type (default: ${QTYPE})
  --ctx TOKENS          Context size (default: ${CTX})
  --threads N           CPU threads (default: auto)
  --ngl N               GPU layers (default: ${NGL})
  --host HOST           Server host (default: ${HOST})
  --port PORT           Server port (default: ${PORT})
  --daemon              Run llama.cpp server in background (nohup)
  --start-go            Build & start Go NLQ server (background)
  --env FILE            .env with POSTGRES_URL & LLM_HOST
  --agree-tos           You have accepted any model TOS on Hugging Face
  -h, --help            Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model-dir) MODEL_DIR="$2"; shift 2 ;;
    --llama-dir) LLAMA_DIR="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --qtype) QTYPE="$2"; shift 2 ;;
    --ctx) CTX="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --ngl) NGL="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --daemon) DAEMON="true"; shift ;;
    --start-go) START_GO="true"; shift ;;
    --env) ENV_FILE="$2"; shift 2 ;;
    --agree-tos) AGREE_TOS="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

[[ -z "$MODEL_DIR" ]] && { err "Missing --model-dir"; usage; exit 1; }

if [[ "$AGREE_TOS" != "true" ]]; then
  warn "Some models require accepting terms on Hugging Face."
  read -rp "Have you accepted terms for this model? (y/N) " a
  case "${a,,}" in y|yes) : ;; *) err "Please accept TOS and rerun with --agree-tos"; exit 1;; esac
fi

detect_pm(){ command -v apt >/dev/null && echo apt && return; command -v dnf >/dev/null && echo dnf && return; command -v pacman >/dev/null && echo pacman && return; command -v brew >/dev/null && echo brew && return; echo unknown; }
install_deps(){
  local pm; pm="$(detect_pm)"
  info "Installing build deps via ${BOLD}${pm}${RESET}…"
  case "$pm" in
    apt) sudo apt update -y && sudo apt install -y build-essential cmake git python3-venv python3-pip curl ;;
    dnf) sudo dnf install -y @development-tools cmake git python3 python3-pip python3-virtualenv curl ;;
    pacman) sudo pacman -Sy --noconfirm base-devel cmake git python python-pip curl ;;
    brew) brew update && brew install cmake git python curl || true ;;
    *) warn "Unknown package manager. Ensure cmake, make, git, python3, pip are installed." ;;
  esac
}

install_deps

mkdir -p "$OUT_DIR"
[[ -z "$THREADS" ]] && { THREADS="$(command -v nproc >/dev/null && nproc || sysctl -n hw.ncpu)"; }

if [[ ! -d "$LLAMA_DIR/.git" ]]; then
  info "Cloning llama.cpp → ${BOLD}$LLAMA_DIR${RESET}"
  git clone https://github.com/ggerganov/llama.cpp "$LLAMA_DIR"
else
  info "Updating llama.cpp in ${BOLD}$LLAMA_DIR${RESET}"
  git -C "$LLAMA_DIR" pull --ff-only || true
fi

info "Building llama.cpp (server + quantize)…"
make -C "$LLAMA_DIR" -j"$(($THREADS))" server quantize

info "Preparing Python venv for conversion…"
python3 -m venv "$LLAMA_DIR/.venv"
# shellcheck disable=SC1091
source "$LLAMA_DIR/.venv/bin/activate"
pip install -U pip
pip install -r "$LLAMA_DIR/requirements.txt"

SHORT="$(basename "$MODEL_DIR" | tr ' ' '_' )"
F16_GGUF="${OUT_DIR}/${SHORT}-f16.gguf"
Q_GGUF="${OUT_DIR}/${SHORT}.${QTYPE}.gguf"

if [[ ! -f "$F16_GGUF" ]]; then
  info "Converting HF → GGUF: ${BOLD}$F16_GGUF${RESET}"
  python3 "$LLAMA_DIR/convert_hf_to_gguf.py" "$MODEL_DIR" --outfile "$F16_GGUF"
else
  info "Found existing: ${BOLD}$F16_GGUF${RESET}"
fi

if [[ ! -f "$Q_GGUF" ]]; then
  info "Quantizing → ${BOLD}$Q_GGUF${RESET} (${QTYPE})"
  "$LLAMA_DIR/quantize" "$F16_GGUF" "$Q_GGUF" "$QTYPE"
else
  info "Found existing: ${BOLD}$Q_GGUF${RESET}"
fi

deactivate || true

CMD=( "$LLAMA_DIR/server" -m "$Q_GGUF" -c "$CTX" -t "$THREADS" -ngl "$NGL" --host "$HOST" --port "$PORT" )
info "Starting llama.cpp server: ${BOLD}${CMD[*]}${RESET}"

if [[ "$DAEMON" == "true" ]]; then
  mkdir -p logs
  nohup "${CMD[@]}" > "logs/llama_server_${PORT}.log" 2>&1 &
  echo $! > "logs/llama_server_${PORT}.pid"
  ok "llama.cpp running (PID $(cat logs/llama_server_${PORT}.pid)) → http://${HOST}:${PORT}"
else
  "${CMD[@]}" &
  SRV_PID=$!
  ok "llama.cpp started (PID ${SRV_PID}) → http://${HOST}:${PORT}"
fi

sleep 1
if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
  ok "Health check passed on :${PORT}"
else
  warn "Health check not responding yet; it might take a few seconds."
fi

if [[ "$START_GO" == "true" ]]; then
  [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]] && { set -a; source "$ENV_FILE"; set +a; }
  : "${LLM_HOST:=http://127.0.0.1:${PORT}}"
  export LLM_HOST
  if [[ -f main.go ]]; then
    info "Building Go NLQ server…"
    go build -o nlq-server .
    mkdir -p logs
    nohup ./nlq-server > logs/nlq_server.log 2>&1 &
    echo $! > logs/nlq_server.pid
    ok "Go NLQ server started (PID $(cat logs/nlq_server.pid)) → POST http://127.0.0.1:8090/nlq"
    info "Example: curl -s localhost:8090/nlq -H 'content-type: application/json' -d '{\"question\":\"give me all data of patient whose lab_id is 6666\",\"limit\":100}'"
  else
    warn "No main.go in current directory; skipping Go server."
  fi
fi

ok "Done. GGUF: ${BOLD}$Q_GGUF${RESET} | Server: http://${HOST}:${PORT}"
