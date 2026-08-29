#!/bin/sh
# Portable integration capability tests. Run from the repository root.
set -eu
repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-integrations.XXXXXX")
trap 'rm -rf "$tmp"; rm -rf "${zellij_fallback:-}"' EXIT HUP INT TERM
home=$tmp/home mock=$tmp/mock log=$tmp/log marker=$tmp/marker
discovery_log=$tmp/discovery.log
clean_path=$mock:/usr/bin:/bin
mkdir -p "$home" "$mock"
: >"$log"
fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
run_quiet() { output=$("$@" 2>&1) || fail "$* exited nonzero: $output"; [ -z "$output" ] || fail "$* wrote: $output"; }
run_bash_interactive() {
  baseline=$(env HOME="$home" CARGO_LOG="$tmp/cargo.log" PATH="$clean_path" bash --noprofile --norc -ic ':' 2>&1) || fail 'interactive Bash baseline failed'
  output=$(env HOME="$home" CARGO_LOG="$tmp/cargo.log" PATH="$clean_path" REPO="$repo" bash --noprofile --norc -ic "$1" 2>&1) || fail "interactive Bash startup failed: $output"
  [ "$output" = "$baseline" ] || fail "interactive Bash wrote unexpected output: $output"
}
make_tool() { cat >"$mock/$1"; chmod +x "$mock/$1"; }
has_zsh=false
if command -v zsh >/dev/null 2>&1; then
  has_zsh=true
else
  printf '%s\n' 'zsh: skipped (zsh not installed)'
fi

# The POSIX environment is shared by native Bash/Zsh startup and sh/ash profile adapters.
shared_home=$tmp/shared-home
mkdir -p "$shared_home/.bun/bin" "$shared_home/Library/pnpm/bin" "$shared_home/go/bin" "$shared_home/data/pnpm/bin"
for file in .profile .shrc .bashrc .bash_aliases .shell-aliases .shell-integrations .zshrc; do
  ln -s "$repo/$file" "$shared_home/$file"
done
cat >"$mock/uname" <<'EOF'
#!/bin/sh
printf '%s\n' "${DOTFILES_TEST_UNAME:-Darwin}"
EOF
cat >"$mock/go" <<'EOF'
#!/bin/sh
[ "$1" = env ] && [ "$2" = GOPATH ] && printf '%s\n' "$HOME/go"
EOF
cat >"$mock/vim" <<'EOF'
#!/bin/sh
exit 0
EOF
for tool in aws_completer fnm fzf; do
  cat >"$mock/$tool" <<EOF
#!/bin/sh
printf '%s\n' $tool >>"$log"
EOF
  chmod +x "$mock/$tool"
done
chmod +x "$mock/uname" "$mock/go" "$mock/vim"
case ${DOTFILES_TEST_UNAME:-Darwin} in
  Darwin) shared_pnpm=$shared_home/Library/pnpm ;;
  *) shared_pnpm=$shared_home/data/pnpm ;;
esac
assert_shared_environment='test "$BUN_INSTALL" = "$HOME/.bun" && test "$PNPM_HOME" = "$SHARED_PNPM" && test "$GOPATH" = "$HOME/go" && test "$EDITOR" = vim && test "$SYSTEMD_EDITOR" = vim && case ":$PATH:" in *":$HOME/.bun/bin:"*) ;; *) exit 1 ;; esac && case ":$PATH:" in *":$SHARED_PNPM/bin:"*) ;; *) exit 1 ;; esac && case ":$PATH:" in *":$SHARED_PNPM:"*) ;; *) exit 1 ;; esac && case ":$PATH:" in *":$HOME/go/bin:"*) ;; *) exit 1 ;; esac'
baseline=$(env HOME="$shared_home" PATH="$clean_path" bash --noprofile --norc -ic ':' 2>&1) || fail 'shared Bash baseline failed'
output=$(env HOME="$shared_home" PATH="$clean_path" XDG_DATA_HOME="$shared_home/data" REPO="$repo" SHARED_PNPM="$shared_pnpm" SHARED_ASSERT="$assert_shared_environment" bash --noprofile --norc -ic '. "$HOME/.bashrc"; eval "$SHARED_ASSERT"' 2>&1) || fail "shared Bash startup failed: $output"
[ "$output" = "$baseline" ] || fail "shared Bash wrote unexpected output: $output"
if "$has_zsh"; then
  run_quiet env HOME="$shared_home" PATH="$clean_path" XDG_DATA_HOME="$shared_home/data" REPO="$repo" SHARED_PNPM="$shared_pnpm" SHARED_ASSERT="$assert_shared_environment" zsh -df -c '. "$HOME/.zshrc"; eval "$SHARED_ASSERT"'
fi
cat >"$mock/zellij" <<EOF
#!/bin/sh
printf '%s\n' zellij >>"$log"
EOF
chmod +x "$mock/zellij"
: >"$log"
run_quiet env HOME="$shared_home" PATH="$clean_path" XDG_DATA_HOME="$shared_home/data" REPO="$repo" SHARED_PNPM="$shared_pnpm" SHARED_ASSERT="$assert_shared_environment" sh -c '. "$HOME/.profile"; eval "$SHARED_ASSERT"'
[ ! -s "$log" ] || fail 'sh profile invoked a shell-specific integration'
run_quiet env HOME="$shared_home" PATH="$clean_path" REPO="$repo" DOTFILES_TEST_UNAME=Linux XDG_DATA_HOME="$shared_home/data" JAVA_HOME=unchanged sh -c '. "$HOME/.profile"; test "$PNPM_HOME" = "$XDG_DATA_HOME/pnpm"; test "$JAVA_HOME" = unchanged; case ":$PATH:" in *":$XDG_DATA_HOME/pnpm/bin:"*) ;; *) exit 1 ;; esac; case ":$PATH:" in *":$XDG_DATA_HOME/pnpm:"*) ;; *) exit 1 ;; esac'
[ ! -s "$log" ] || fail 'non-Darwin sh profile invoked a shell-specific integration'
if command -v busybox >/dev/null 2>&1; then
  run_quiet env HOME="$shared_home" PATH="$clean_path" XDG_DATA_HOME="$shared_home/data" REPO="$repo" SHARED_PNPM="$shared_pnpm" SHARED_ASSERT="$assert_shared_environment" busybox ash -c '. "$HOME/.profile"; eval "$SHARED_ASSERT"'
  [ ! -s "$log" ] || fail 'ash profile invoked a shell-specific integration'
fi
rm -f "$mock/aws_completer" "$mock/fnm" "$mock/fzf" "$mock/zellij"

# Startup must not call the dispatcher when the integration file is unavailable or fails to source.
run_bash_interactive '. "$REPO/.bashrc"'
if "$has_zsh"; then
  run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" zsh -df -c '. "$REPO/.zshrc"'
fi
printf '%s\n' 'return 1' >"$home/.shell-integrations"
run_bash_interactive '. "$REPO/.bashrc"'
if "$has_zsh"; then
  run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" zsh -df -c '. "$REPO/.zshrc"'
fi
rm "$home/.shell-integrations"

# Invalid targets must return before either capability is discovered.
cat >"$mock/aws_completer" <<EOF
#!/bin/sh
echo aws >>"$log"
EOF
chmod +x "$mock/aws_completer"
cat >"$mock/fzf" <<EOF
#!/bin/sh
echo fzf >>"$log"
echo 'DOTFILES_FZF=bad'
EOF
chmod +x "$mock/fzf"
: >"$discovery_log"
for target in '' sh fish "bash; touch $marker"; do
  run_quiet env HOME="$home" PATH="$clean_path" MARKER="$marker" REPO="$repo" DISCOVERY_LOG="$discovery_log" bash --noprofile --norc -c 'command() { printf "discover:%s\n" "$*" >>"$DISCOVERY_LOG"; builtin command "$@"; }; . "$REPO/.shell-integrations"; dotfiles_integrations "$1"' x "$target"
done
[ ! -e "$marker" ] || fail 'invalid target evaluated injection'
[ ! -s "$log" ] || fail 'invalid target invoked a tool'
[ ! -s "$discovery_log" ] || fail 'invalid target discovered a tool'

# Missing tools are silent and successful.
run_quiet env HOME="$home" PATH="/usr/bin:/bin" REPO="$repo" bash --noprofile --norc -c '. "$REPO/.shell-integrations"; dotfiles_integrations bash'

# Missing AWS must not prevent fzf target generation.
: >"$log"
rm "$mock/aws_completer"
run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" bash --noprofile --norc -c '. "$REPO/.shell-integrations"; dotfiles_integrations bash; test "$DOTFILES_FZF" = bad'
grep -qx fzf "$log" || fail 'missing AWS prevented fzf'
: >"$log"

# AWS discovery precedes fzf execution, and registration uses the exact executable path.
cat >"$mock/aws_completer" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$mock/aws_completer"
cat >"$mock/fzf" <<EOF
#!/bin/sh
printf 'run:fzf:%s\n' "\$1" >>"$discovery_log"
printf '%s\n' 'DOTFILES_FZF_TARGET='"\$1"
EOF
chmod +x "$mock/fzf"
: >"$discovery_log"
run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" MOCK="$mock" DISCOVERY_LOG="$discovery_log" bash --noprofile --norc -c 'command() { if [ "$1" = -v ]; then printf "discover:%s\n" "$*" >>"$DISCOVERY_LOG"; fi; builtin command "$@"; }; . "$REPO/.shell-integrations"; dotfiles_integrations bash; test "$_dotfiles_aws_completer" = "$MOCK/aws_completer"; test "$(complete -p aws)" = "complete -C $MOCK/aws_completer aws"; test "$DOTFILES_FZF_TARGET" = --bash'
printf '%s\n' 'discover:-v aws_completer' 'run:fzf:--bash' >"$tmp/expected-discovery"
cmp -s "$tmp/expected-discovery" "$discovery_log" || fail 'capability discovery/execution ordering changed'
if "$has_zsh"; then
  run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" zsh -df -c '. "$REPO/.shell-integrations"; dotfiles_integrations zsh; test "$DOTFILES_FZF_TARGET" = --zsh; complete -p aws >/dev/null'
fi

# fzf must resolve and invoke the external executable even when a shell function shadows it.
: >"$log"
cat >"$mock/fzf" <<EOF
#!/bin/sh
printf 'external:%s\n' "\$1" >>"$log"
printf '%s\n' 'DOTFILES_FZF_TARGET=external'
EOF
chmod +x "$mock/fzf"
run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" bash --noprofile --norc -c 'fzf() { DOTFILES_FZF_TARGET=shadowed; }; . "$REPO/.shell-integrations"; dotfiles_integrations bash; test "$DOTFILES_FZF_TARGET" = external'
grep -qx 'external:--bash' "$log" || fail 'fzf function shadowed the external executable'

# Nonzero, empty, function-only, and non-executable resolutions are harmless.
cat >"$mock/fzf" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$mock/fzf"
run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" bash --noprofile --norc -c '. "$REPO/.shell-integrations"; dotfiles_integrations bash; test -z "${DOTFILES_FZF_TARGET:-}"'
cat >"$mock/fzf" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$mock/fzf"
run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" bash --noprofile --norc -c '. "$REPO/.shell-integrations"; dotfiles_integrations bash; test -z "${DOTFILES_FZF_TARGET:-}"'
printf 'not executable\n' >"$tmp/fzf"
printf 'not executable\n' >"$tmp/aws_completer"
run_quiet env HOME="$home" PATH="$tmp:/usr/bin:/bin" REPO="$repo" bash --noprofile --norc -c '. "$REPO/.shell-integrations"; dotfiles_integrations bash'
run_quiet env HOME="$home" PATH="$tmp:/usr/bin:/bin" REPO="$repo" bash --noprofile --norc -c 'fzf() { printf bad; }; aws_completer() { :; }; . "$REPO/.shell-integrations"; dotfiles_integrations bash'
[ "$(grep -c 'eval' "$repo/.shell-integrations")" -eq 1 ] || fail 'dispatcher has unexpected eval'
! grep -E 'aws.*eval|eval.*aws' "$repo/.shell-integrations" >/dev/null || fail 'AWS eval found'

# Startup bridges source Cargo once and do not re-enter one another.
for file in .profile .shrc .bash_profile .bashrc .bash_aliases .shell-aliases .shell-integrations .zshrc; do
  ln -s "$repo/$file" "$home/$file"
done
mkdir -p "$home/.cargo"
cat >"$home/.cargo/env" <<EOF
printf cargo >>"\$CARGO_LOG"
EOF
: >"$tmp/cargo.log"
run_bash_interactive '. "$HOME/.bash_profile"'
run_bash_interactive '. "$HOME/.bashrc"'
cargo_bytes=15
if "$has_zsh"; then
  run_quiet env HOME="$home" CARGO_LOG="$tmp/cargo.log" PATH="$clean_path" zsh -df -c '. "$HOME/.zshrc"'
  cargo_bytes=20
fi
run_quiet env HOME="$home" CARGO_LOG="$tmp/cargo.log" PATH="$clean_path" sh -c '. "$HOME/.profile"'
[ "$(wc -c <"$tmp/cargo.log" | tr -d ' ')" = "$cargo_bytes" ] || fail 'Cargo was not sourced once per startup flow'

# A non-interactive Bash login must follow the platform provided by the mocked uname.
case ${DOTFILES_TEST_UNAME:-Darwin} in
  Darwin) expected_login_pnpm=$home/Library/pnpm ;;
  *) expected_login_pnpm=$home/.local/share/pnpm ;;
esac
run_quiet env HOME="$home" CARGO_LOG="$tmp/cargo.log" PATH="$clean_path" EXPECTED_PNPM_HOME="$expected_login_pnpm" bash --noprofile --norc -c '. "$HOME/.bash_profile"; test "$XDG_CONFIG_HOME" = "$HOME/.config"; test "$BUN_INSTALL" = "$HOME/.bun"; test "$PNPM_HOME" = "$EXPECTED_PNPM_HOME"'
rm -rf "$home/.cargo"

# Zsh preserves an inherited runtime directory and evaluates Zellij generated code.
if "$has_zsh"; then
cat >"$mock/zellij" <<EOF
#!/bin/sh
printf 'zellij:%s\n' "\$*" >>"$log"
printf '%s\n' 'DOTFILES_ZELLIJ_RUNTIME_DIR='"\${XDG_RUNTIME_DIR:-}"
EOF
chmod +x "$mock/zellij"
: >"$log"
inherited_runtime=$tmp/inherited-runtime
run_quiet env HOME="$home" PATH="$clean_path" XDG_RUNTIME_DIR="$inherited_runtime" zsh -df -c 'unset ZELLIJ ZELLIJ_SESSION_NAME; . "$HOME/.zshrc"; test "$XDG_RUNTIME_DIR" = "$0"; test "$DOTFILES_ZELLIJ_RUNTIME_DIR" = "$0"' "$inherited_runtime"
grep -qx 'zellij:setup --generate-auto-start zsh' "$log" || fail 'inherited runtime did not generate Zellij integration'

# An unset runtime directory falls back only after mkdir and chmod succeed.
zellij_user="dotfiles-zellij-$$"
zellij_fallback="/tmp/zellij-$zellij_user"
rm -rf "$zellij_fallback"
: >"$log"
run_quiet env HOME="$home" PATH="$clean_path" USER="$zellij_user" zsh -df -c 'unset XDG_RUNTIME_DIR ZELLIJ ZELLIJ_SESSION_NAME; . "$HOME/.zshrc"; test "$XDG_RUNTIME_DIR" = "/tmp/zellij-$USER"; test "$DOTFILES_ZELLIJ_RUNTIME_DIR" = "$XDG_RUNTIME_DIR"'
[ -d "$zellij_fallback" ] || fail 'Zellij fallback runtime directory was not created'
grep -qx 'zellij:setup --generate-auto-start zsh' "$log" || fail 'fallback runtime did not generate Zellij integration'
rm -rf "$zellij_fallback"

# A fallback mkdir or chmod failure must not evaluate Zellij generated code.
cat >"$mock/mkdir" <<EOF
#!/bin/sh
exit 1
EOF
chmod +x "$mock/mkdir"
: >"$log"
run_quiet env HOME="$home" PATH="$clean_path" USER="$zellij_user" zsh -df -c 'unset XDG_RUNTIME_DIR ZELLIJ ZELLIJ_SESSION_NAME; . "$HOME/.zshrc"; test -z "${XDG_RUNTIME_DIR:-}"; test -z "${DOTFILES_ZELLIJ_RUNTIME_DIR:-}"'
! grep -q '^zellij:' "$log" || fail 'Zellij ran after fallback mkdir failure'
rm "$mock/mkdir"
cat >"$mock/chmod" <<EOF
#!/bin/sh
exit 1
EOF
chmod +x "$mock/chmod"
: >"$log"
run_quiet env HOME="$home" PATH="$clean_path" USER="$zellij_user" zsh -df -c 'unset XDG_RUNTIME_DIR ZELLIJ ZELLIJ_SESSION_NAME; . "$HOME/.zshrc"; test -z "${XDG_RUNTIME_DIR:-}"; test -z "${DOTFILES_ZELLIJ_RUNTIME_DIR:-}"'
! grep -q '^zellij:' "$log" || fail 'Zellij ran after fallback chmod failure'
rm "$mock/chmod"
fi

# BusyBox ash is exercised when installed; otherwise the skip is explicit.
if command -v busybox >/dev/null 2>&1; then
  run_quiet env HOME="$home" PATH="$clean_path" REPO="$repo" busybox ash -c '. "$REPO/.profile"; test "$XDG_CONFIG_HOME" = "$HOME/.config"'
  printf '%s\n' 'busybox ash: ok'
else
  printf '%s\n' 'busybox ash: skipped (busybox not installed)'
fi

# macOS ships Bash 3.2; the startup files and installer intentionally use Bash 3.2 syntax.
bash_version=$(bash -c 'printf "%s.%s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"')
if [ "$(uname -s)" = Darwin ]; then
  case $bash_version in
    3.2*) printf '%s\n' 'macOS Bash 3.2 compatibility: detected and exercised' ;;
    *) printf '%s\n' 'macOS Bash 3.2 compatibility: not installed; Bash 3.2-compatible syntax documented' ;;
  esac
fi
printf '%s\n' 'shell-integrations: ok'
