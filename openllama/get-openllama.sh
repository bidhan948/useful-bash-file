#!/usr/bin/env bash
# ============================================================
# 🚀 OpenLLaMA Downloader (auto-install)
#    Author       : https://github.com/bidhan948
#    Requested by : Bidhan Baniya
#    Purpose      : Download OpenLLaMA from Hugging Face with auto deps
# ============================================================

set -Eeuo pipefail
trap 'echo -e "\n❌ \033[31mError\033[0m: command failed on line \033[33m$LINENO\033[0m: \033[2m$BASH_COMMAND\033[0m\n" >&2' ERR

# --------------------- 🎨 Styling ----------------------------
BOLD="\033[1m"; DIM="\033[2m"; GREEN="\033[32m"; CYAN="\033[36m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
echo_info() { echo -e "ℹ️  $*"; }
echo_ok()   { echo -e "✅ $*"; }
echo_warn() { echo -e "⚠️  $*"; }
echo_err()  { echo -e "❌ ${RED}$*${RESET}"; }

banner() {
  echo -e "${BOLD}${CYAN}"
  cat <<'EOF'
   ____                  _ _ _ _                              
  / __ \                | (_) | |                             
 | |  | |_ __   ___  ___| |_| | | __ _ _ __ ___   __ _  ___   
 | |  | | '_ \ / _ \/ __| | | | |/ _` | '_ ` _ \ / _` |/ _ \  
 | |__| | | | |  __/\__ \ | | | | (_| | | | | | | (_| | (_) | 
  \____/|_| |_|\___||___/_|_|_|_|\__,_|_| |_| |_|\__,_|\___/  
EOF
  echo -e "${RESET}${DIM}✨ OpenLLaMA one-liner downloader — by ${BOLD}Bidhan Baniya${RESET}\n"
}
banner

# --------------------- ⚙️ Defaults ---------------------------
MODEL_ID="${MODEL_ID:-openlm-research/open_llama_7b}"
DEST_DIR="${DEST_DIR:-./openllama_models}"
AGREE_TOS="${AGREE_TOS:-false}"
VERBOSE="${VERBOSE:-false}"
NO_LOGIN="${NO_LOGIN:-true}"      # default: don’t prompt HF login
NO_INSTALL="${NO_INSTALL:-false}" # set true to skip auto-install

usage() {
  cat <<EOF
${BOLD}Usage:${RESET} $0 [-m <model_id>] [-d <dir>] [--agree-tos] [--login] [-v] [--no-install] [-h]

Options:
  -m, --model        Hugging Face model repo (default: ${MODEL_ID})
                     Examples:
                       openlm-research/open_llama_3b
                       openlm-research/open_llama_7b
                       openlm-research/open_llama_13b
  -d, --dest         Destination directory (default: ${DEST_DIR})
      --agree-tos    Skip the terms prompt (you've already accepted on HF)
      --login        Run 'huggingface-cli login' after install
      --no-install   Do not auto-install deps (fail if missing)
  -v, --verbose      Extra debug while downloading
  -h, --help         Show this help
EOF
}

# --------------------- 🧰 Helpers ----------------------------
need() { command -v "$1" >/dev/null 2>&1; }
shortname_from_model() { basename "$1"; }

ensure_localbin_in_path() {
  # Ensure ~/.local/bin is in PATH for pip --user scripts like huggingface-cli
  local LOCALBIN="$HOME/.local/bin"
  if [[ ":$PATH:" != *":$LOCALBIN:"* ]]; then
    export PATH="$LOCALBIN:$PATH"
    echo_info "Added ${BOLD}$LOCALBIN${RESET} to PATH for this session."
    # persist for bash/zsh
    if [[ -n "${SHELL:-}" && "$SHELL" == */bash ]]; then
      grep -q 'PATH=.*\.local/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    elif [[ -n "${SHELL:-}" && "$SHELL" == */zsh ]]; then
      grep -q 'PATH=.*\.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
  fi
}

detect_pm() {
  if need apt; then echo "apt"
  elif need dnf; then echo "dnf"
  elif need pacman; then echo "pacman"
  elif need brew; then echo "brew"
  else echo "unknown"
  fi
}

install_with_pm() {
  local pm="$1"
  case "$pm" in
    apt)
      echo_info "🛠️  Installing deps via APT..."
      sudo apt update -y
      sudo apt install -y git-lfs python3 python3-pip
      ;;
    dnf)
      echo_info "🛠️  Installing deps via DNF..."
      sudo dnf install -y git-lfs python3-pip
      ;;
    pacman)
      echo_info "🛠️  Installing deps via Pacman..."
      sudo pacman -Sy --noconfirm git-lfs python-pip
      ;;
    brew)
      echo_info "🛠️  Installing deps via Homebrew..."
      brew update
      brew install git-lfs python
      ;;
    *)
      echo_warn "Package manager not detected. Skipping system packages."
      ;;
  esac
}

install_hf_cli() {
  # Try user install first (no sudo)
  if need python3; then
    python3 -m pip install --user -U huggingface_hub || true
  else
    echo_warn "python3 not found; trying 'pip3' directly..."
    pip3 install --user -U huggingface_hub || true
  fi
  ensure_localbin_in_path
}

install_gitlfs() {
  if need git && need git-lfs; then
    git lfs install --skip-repo || true
  fi
}

auto_install() {
  [[ "${NO_INSTALL}" == "true" ]] && return 0
  local pm; pm="$(detect_pm)"
  install_with_pm "$pm"
  install_hf_cli
  install_gitlfs
}

write_readme() {
  local outdir="$1"
  cat > "${outdir}/README_BY_BIDHAN.txt" <<EOF
OpenLLaMA Model Downloaded

Requested by : Bidhan Baniya
GitHub       : https://github.com/bidhan948
Model ID     : ${MODEL_ID}
Downloaded   : $(date -u +"%Y-%m-%dT%H:%M:%SZ")

Notes:
- Files fetched from Hugging Face.
- If you use these weights, ensure you comply with their license/terms.
EOF
}

# --------------------- 🧾 Parse Args -------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model) MODEL_ID="$2"; shift 2 ;;
    -d|--dest)  DEST_DIR="$2"; shift 2 ;;
    --agree-tos) AGREE_TOS="true"; shift ;;
    --login)   NO_LOGIN="false"; shift ;;
    --no-install) NO_INSTALL="true"; shift ;;
    -v|--verbose) VERBOSE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo_err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# --------------------- 📋 Summary ----------------------------
echo_info "${BOLD}Author:${RESET} ${CYAN}https://github.com/bidhan948${RESET}"
echo_info "${BOLD}Requested by:${RESET} ${GREEN}Bidhan Baniya${RESET}"
echo_info "${BOLD}Model:${RESET} ${YELLOW}${MODEL_ID}${RESET}"
echo_info "${BOLD}Destination:${RESET} ${YELLOW}${DEST_DIR}${RESET}\n"

# --------------------- 🔐 TOS Check --------------------------
if [[ "${AGREE_TOS}" != "true" ]]; then
  echo_warn "Some models require accepting terms on Hugging Face."
  echo -e "   Make sure you've accepted TOS for: ${BOLD}${MODEL_ID}${RESET}"
  read -rp "✅ Have you accepted the terms (y/N)? " ans
  case "${ans,,}" in
    y|yes) echo_ok "Proceeding...\n" ;;
    *) echo_err "Aborting. Visit the model page on Hugging Face, accept terms, or re-run with --agree-tos."; exit 1 ;;
  esac
fi

# --------------------- 🧩 Auto-install deps ------------------
echo_info "🔍 Checking tools & installing if missing..."
auto_install
ensure_localbin_in_path

# Re-check availability
HAS_HF="no"; HAS_GITLFS="no"
need huggingface-cli && HAS_HF="yes"
(need git && need git-lfs) && HAS_GITLFS="yes"

if [[ "${HAS_HF}" == "no" && "${HAS_GITLFS}" == "no" ]]; then
  echo_err "Neither 'huggingface-cli' nor 'git lfs' available even after install."
  echo -e "   Try reopening your terminal or ensure ${BOLD}~/.local/bin${RESET} is in PATH."
  exit 1
fi

# Optional login
if [[ "${NO_LOGIN}" == "false" && "${HAS_HF}" == "yes" ]]; then
  echo_info "🔐 Launching Hugging Face login (paste your token)..."
  huggingface-cli login || echo_warn "Skipping login..."
fi

# --------------------- 📁 Prep -------------------------------
SUBDIR="$(shortname_from_model "${MODEL_ID}")"
TARGET="${DEST_DIR}/${SUBDIR}"
mkdir -p "${TARGET}"

# --------------------- ⬇️ Download ---------------------------
if [[ "${HAS_HF}" == "yes" ]]; then
  echo_info "⚡ Using ${BOLD}huggingface-cli download${RESET} (resumable)"
  [[ "${VERBOSE}" == "true" ]] && set -x
  huggingface-cli download "${MODEL_ID}" \
    --repo-type model \
    --local-dir "${TARGET}" \
    --resume-download
  [[ "${VERBOSE}" == "true" ]] && set +x
elif [[ "${HAS_GITLFS}" == "yes" ]]; then
  echo_info "🐙 Using ${BOLD}git lfs clone${RESET}"
  [[ "${VERBOSE}" == "true" ]] && set -x
  git lfs install --skip-repo
  git lfs clone "https://huggingface.co/${MODEL_ID}" "${TARGET}"
  [[ "${VERBOSE}" == "true" ]] && set +x
fi

# --------------------- 🧾 Credit file ------------------------
write_readme "${TARGET}"

# --------------------- 🎉 Done -------------------------------
echo
echo_ok "${BOLD}All set!${RESET} OpenLLaMA files are in: ${BOLD}${TARGET}${RESET}"
echo_info "📝 Added ${BOLD}README_BY_BIDHAN.txt${RESET} with credit."
echo_info "🤖 Happy building with OpenLLaMA + Go & Laravel!"
echo_info "⭐ If this helped, consider starring ${CYAN}https://github.com/bidhan948${RESET} 😉"
