# zcopy — Transparent Clipboard for Nested Zellij over SSH

Pipes Zellij's `copy_command` output to your local system clipboard,
whether you're running Zellij locally or inside an SSH session.

## How it works

```
Remote Zellij copy
│
▼
zcopy (detects $SSH_TTY)
│
├── SSH ──► nc 127.0.0.1:9999 ──► RemoteForward tunnel ──► local socat ──► pbcopy/wl-copy/xclip
│
└── Local ──► pbcopy / wl-copy / xclip (direct)
```

## Prerequisites

| Where   | Package | Install                        |
|---------|---------|--------------------------------|
| Local   | `socat` | `brew install socat` / `apt install socat` |
| Remote  | `nc`    | `ncat` (nmap) or `netcat` — usually pre-installed |
| Local   | clipboard tool | `pbcopy` (macOS) / `wl-clipboard` / `xclip` |

## 1. Install `zcopy`

On **both** your local machine and any remote you SSH into:

```bash
mkdir -p ~/.local/bin
cat > ~/.local/bin/zcopy << 'EOF'
#!/bin/bash
if [ -n "$SSH_TTY" ]; then
    nc -q0 127.0.0.1 9999
else
    if command -v pbcopy &>/dev/null; then
        pbcopy
    elif command -v wl-copy &>/dev/null; then
        wl-copy
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard
    fi
fi
EOF
chmod +x ~/.local/bin/zcopy
```

Ensure `~/.local/bin` is on your `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc   # or ~/.zshrc
```

## 2. Zellij config
In `~/.config/zellij/config.kdl` (on **both** machines):

`copy_command "zcopy"`

## 3. Local listener (persistent service)
This runs on your **local machine** and forwards port 9999 to your clipboard.

### macOS — LaunchAgent
Create and load `~/Library/LaunchAgents/com.zellij.clipboard.plist`:

```sh
cat > ~/Library/LaunchAgents/com.zellij.clipboard.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zellij.clipboard</string>
    <key>ProgramArguments</key>
    <array>
        <!-- Use `command -v socat` here, e.g. /opt/homebrew/bin/socat. -->
        <string>/opt/homebrew/bin/socat</string>
        <string>TCP-LISTEN:9999,bind=127.0.0.1,reuseaddr,fork</string>
        <string>EXEC:pbcopy</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.zellij.clipboard.plist
```

### Linux — systemd user service
Create and load `~/.config/systemd/user/zellij-clipboard.service`:

```sh
cat > ~/.config/systemd/user/zellij-clipboard.service << 'EOF'
[Unit]
Description=Zellij clipboard relay

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:9999,bind=127.0.0.1,reuseaddr,fork EXEC:wl-copy
Restart=always

[Install]
WantedBy=default.target
EOF
systemctl --user enable --now zellij-clipboard
```
> Swap wl-copy for xclip -selection clipboard on X11.

## 4. SSH config
In `~/.ssh/config` on your local machine:

```
Host *
    RemoteForward 9999 127.0.0.1:9999
```

Or scope to specific hosts:

```
Host myserver myserver2
    RemoteForward 9999 127.0.0.1:9999
```

## 5. Verify
1. SSH into your remote: `ssh myserver`
2. Open Zellij on the remote.
3. Select text in a pane and press your copy key (default `Ctrl+Space` → `c`).
4. Paste locally (`Cmd+V` / `Ctrl+Shift+V`) — text should appear.

## Troubleshooting
| Symptom | Fix |
| `nc: connection refused` | Local listener not running. Check `launchctl list | grep zellij` or `systemctl --user status zellij-clipboard`. |
| `nc: command not found` (remote) | Install `nmap` (`apt install nmap`) or `netcat`. |
| `Port already in use` | Change 9999 → 9998 in all four places (script, service, ssh config, this README). |
|  Works in terminal but not in Zellij | Ensure `copy_command` is set (not `copy_and_clear`). |
