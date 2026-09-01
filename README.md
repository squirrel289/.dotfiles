# Dotfiles

Run `bash init.sh` to link the managed files into the current user's home directory. The installer is intentionally fast and local-first; it sources the managed-file manifest from `manifest.sh`.

It refuses conflicting managed targets by default. Use `bash init.sh --backup-existing` to move a conflicting managed child aside first, or `bash init.sh --force` to replace conflicting non-directory targets without keeping a backup. The installer never downloads editor plugins.

Useful commands:

```sh
bash init.sh
bash init.sh --dry-run
bash init.sh --verbose
bash init.sh --backup-existing
bash init.sh --force
```

Ansible and other provisioning tools should treat this repository as self-installing. Clone or update it, then run `bash init.sh`. For check mode or previews, run `bash init.sh --dry-run`; for changed/ok/error reporting, consume the installer's `change:`, `ok:`, and `error:` output. Keep dotfile link policy in `manifest.sh` and `init.sh`; do not reimplement the manifest in an external automation repository.

Pi keeps mutable state, credentials, sessions, caches, and installed packages in `~/.pi`; that directory is never linked. The installer links only the reviewed files in `pi-config/agent/` into `~/.pi/agent/`. It refuses an existing `~/.pi` symlink, including the legacy `~/.dotfiles/.pi` link, so that state can be migrated deliberately rather than modified through a symlink.

Bash uses `.bash_profile`/`.bashrc` and Zsh uses `.zshrc`. POSIX `sh` and BusyBox `ash` users can opt in by sourcing `~/.profile`; it loads only the POSIX-safe `.shrc` environment and intentionally does not load aliases, completions, or generated integrations.

`.shrc` centralizes shared environment policy: XDG and user paths, Bun, pnpm, guarded Go and Vim editor settings, plus Darwin-only Java and VS Code CLI paths. It uses `uname` and command/file checks so the same file is safe on Linux, macOS, `sh`, and `ash`. Bash and Zsh retain only their shell-specific aliases, completions, plugins, and generated fnm/fzf/Zellij initialization; Bun completion remains Zsh-specific.

The Bash startup files and `init.sh` use Bash 3.2-compatible syntax for the version bundled with macOS. The tests report whether that system version is installed but do not require a separate Bash 3.2 executable.

Run the complete automated regression suite with `./test/run.sh`. For a fail-closed, isolated automated Zsh UAT, run `sh test/uat-zsh.sh` from this repository. It installs only into a temporary home, runs every available deterministic check automatically, and ends with a colorized checklist: green pass, red failure, and yellow skipped checks. It verifies external integrations with mocks and intentionally does not attach to a real Zellij session.

Run the complete isolated regression suite with:

```sh
sh test/run.sh
```

The suite uses temporary `HOME` directories and mocked executables. Zsh and BusyBox `ash` coverage is run when installed and otherwise reports an explicit skip.
