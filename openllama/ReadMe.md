# OpenLLaMA Downloader (auto-install) 🦙⚡

A tiny, emoji-rich Bash script that **auto-installs deps** and downloads OpenLLaMA weights from **Hugging Face** into a local folder. It prefers `huggingface-cli` (resumable) and falls back to `git lfs`.

## Features

* 🔧 **Auto-install** `git-lfs`, `python3`, `pip`, and `huggingface_hub`
* 🔑 Optional `huggingface-cli login`
* ⏯️ Resumable downloads via `huggingface-cli` (or `git lfs` fallback)
* 🧾 Drops a small credit file: `README_BY_BIDHAN.txt`
* 🧰 Verbose mode for debugging

## Quick start

```bash
chmod +x get-openllama.sh
./get-openllama.sh --agree-tos -m openlm-research/open_llama_7b -d ./models
```

## Usage

```text
./get-openllama.sh [-m <model_id>] [-d <dir>] [--agree-tos] [--login] [-v] [--no-install] [-h]
```

**Common flags**

* `-m, --model`     Hugging Face repo (e.g. `openlm-research/open_llama_7b`)
* `-d, --dest`      Destination directory (default: `./openllama_models`)
* `--agree-tos`     Skip TOS prompt (you’ve already accepted on HF)
* `--login`         Run `huggingface-cli login` after install
* `-v, --verbose`   Extra logs
* `--no-install`    Don’t auto-install; fail if tools missing

## Requirements

* Linux (APT/DNF/Pacman) or macOS (Homebrew).
  The script auto-detects your package manager and installs what’s needed.
  If `huggingface-cli` still isn’t found, ensure `~/.local/bin` is on your `PATH`.

## Notes

* 📜 Some models require accepting terms on Hugging Face. Open the model page, click **“Access repository”**, accept, then run with `--agree-tos`.
* 🔐 Use `--login` if the model/repo is gated and needs your HF token.

## Credits

* Author: [bidhan948](https://github.com/bidhan948)
* Requested by: **Bidhan Baniya**

Happy building! 🚀
