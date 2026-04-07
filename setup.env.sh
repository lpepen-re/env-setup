#!/bin/bash

# THIS SCRIPT IS MEANT TO HELP SETUP MY DEVELOPER ENVIRONMENT FROM SCRATCH
# OS: FEDORA 43
# ARCH: x86

### Version Variables ###
LAZYDOCKER_VERSION="0.24.3"
OPENJDK_VERSION="21.0.2"
OPENJDK_BUILD="f2283984656d49d69e91c558476027ac/13"
JETBRAINS_TOOLBOX_VERSION="3.2.0.65851"
NVM_VERSION="v0.40.3"
NEOVIM_VERSION="v0.11.5"
NERDFONTS_VERSION="v3.4.0"
PNPM_VERSION="8.15.9"

### Hyprland Config Directories ###
HYPR_DIR="$HOME/.config/hypr"
WAYBAR_DIR="$HOME/.config/waybar"
WOFI_DIR="$HOME/.config/wofi"
SWAYNC_DIR="$HOME/.config/swaync"
MAKO_DIR="$HOME/.config/mako"

### Logging Helpers ###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }


setup_rpm_fusion() {
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    sudo dnf update @core -y
}

install_media_codecs() {
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    # TODO: LPM - For Intel only, if using another vendor change this https://rpmfusion.org/Howto/Multimedia
    sudo dnf install -y intel-media-driver
}

install_oh_my_bash() {
    echo "Installing Oh-My-Bash..."
    OSH_UNATTENDED=1 bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
    sed -i 's/^OSH_THEME=".*"/OSH_THEME="powerline-multiline"/' ~/.bashrc
}

install_dnf_packages() {
    echo "Installing DNF packages..."
    sudo dnf install -y \
        @development-tools \
        @cosmic-desktop-environment \
        akmod-nvidia \
        golang \
        p7zip p7zip-plugins \
        glibc libgcc ca-certificates openssl-libs libstdc++ libicu tzdata krb5-libs \
        dotnet-runtime-8.0 \
        vlc \
        obs \
        python3.11
}

generate_ssh_key() {
    echo "Generating SSH key pair..."
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 <<< y >/dev/null 2>&1
}

install_docker() {
    echo "Installing Docker..."
    sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo -y
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo groupadd docker || true
    sudo usermod -aG docker "$USER"
    sudo systemctl enable containerd.service
}

install_lazydocker() {
    echo "Installing Lazy Docker..."
    (
        mkdir -p "$HOME/lazydocker"
        cd "$HOME/lazydocker"
        wget "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
        tar -xvf "lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
        rm "lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
    )
}

install_openjdk() {
    echo "Installing OpenJDK ${OPENJDK_VERSION}..."
    (
        mkdir -p "$HOME/java"
        cd "$HOME/java"
        wget "https://download.java.net/java/GA/jdk${OPENJDK_VERSION}/${OPENJDK_BUILD}/GPL/openjdk-${OPENJDK_VERSION}_linux-x64_bin.tar.gz"
        tar -xvf "openjdk-${OPENJDK_VERSION}_linux-x64_bin.tar.gz"
        rm "openjdk-${OPENJDK_VERSION}_linux-x64_bin.tar.gz"
    )
}

install_jetbrains_toolbox() {
    echo "Installing Jetbrains Toolbox..."
    (
        mkdir -p "$HOME/jetbrains-toolbox"
        cd "$HOME/jetbrains-toolbox"
        wget "https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-${JETBRAINS_TOOLBOX_VERSION}.tar.gz"
        tar -xvf "jetbrains-toolbox-${JETBRAINS_TOOLBOX_VERSION}.tar.gz"
        rm "jetbrains-toolbox-${JETBRAINS_TOOLBOX_VERSION}.tar.gz"
    )
}

install_nvm() {
    echo "Installing Node Version Manager..."
    (
        cd "$HOME"
        git clone https://github.com/nvm-sh/nvm.git .nvm
        cd "$HOME/.nvm"
        git checkout "$NVM_VERSION"
    )
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

install_neovim() {
    echo "Installing Neovim..."
    (
        mkdir -p "$HOME/nvim"
        cd "$HOME/nvim"
        wget "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
        tar -xvf nvim-linux-x86_64.tar.gz
        rm nvim-linux-x86_64.tar.gz
    )
}

install_nerdfonts() {
    echo "Installing Nerdfonts Roboto Mono..."
    (
        mkdir -p "$HOME/.local/share/fonts/roboto-mono"
        cd "$HOME/.local/share/fonts/roboto-mono"
        wget "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERDFONTS_VERSION}/RobotoMono.zip"
        7z x RobotoMono.zip
        rm RobotoMono.zip
    )
}

configure_bashrc() {
    echo "Adding global variables and aliases to .bashrc..."
    cat >> ~/.bashrc << EOF

alias lzd="lazydocker"

export LAZYDOCKER=\$HOME/lazydocker
export JAVA_HOME=\$HOME/java/jdk-${OPENJDK_VERSION}
export NVIM=\$HOME/nvim/nvim-linux-x86_64/bin

export PATH=\$JAVA_HOME/bin:\$NVIM:\$PATH:\$LAZYDOCKER

export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
EOF

    # Export paths directly for use in the remainder of this script
    # (source ~/.bashrc is unreliable in non-interactive shells due to early-exit guards)
    export LAZYDOCKER="$HOME/lazydocker"
    export JAVA_HOME="$HOME/java/jdk-${OPENJDK_VERSION}"
    export NVIM="$HOME/nvim/nvim-linux-x86_64/bin"
    export PATH="$JAVA_HOME/bin:$NVIM:$PATH:$LAZYDOCKER"
}

install_node_lts() {
    echo "Installing Node LTS..."
    nvm install --lts
}

install_nvchad() {
    echo "Installing NvChad Neovim Config..."
    git clone https://github.com/NvChad/starter ~/.config/nvim
    nvim --headless "+Lazy! sync" +qa
}

install_global_npm_packages() {
    echo "Installing Global Javascript Dependencies..."
    npm install -g \
        @angular/cli \
        nx \
        "pnpm@${PNPM_VERSION}" \
        typescript \
        typescript-language-server \
        svelte-language-server \
        @angular/language-server
}

install_flatpak_apps() {
    echo "Installing Flatpak applications..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub \
        com.vscodium.codium \
        com.brave.Browser \
        io.dbeaver.DBeaverCommunity \
        com.github.tchx84.Flatseal \
        org.flameshot.Flameshot \
        md.obsidian.Obsidian \
        com.slack.Slack \
        org.chromium.Chromium \
        com.github.IsmaelMartinez.teams_for_linux
}

configure_neovim_plugins() {
    echo "Configuring Neovim..."
    nvim --headless -c "TSInstall c angular bash cmake css dockerfile dot gitignore go java javascript json lua make markdown nginx php python toml tsx typescript yaml vue" -c "q"
    nvim --headless -c "MasonInstall svelte-language-server vue-language-server yaml-language-server angular-language-server cpplint cpptools css-lsp docker-language-server dockerfile-language-server gh-actions-language-server gopls go-debug-adapter jsonlint lua-language-server nginx-language-server nxls pyright" -c "q"
}

install_hyprland_packages() {
    log "Installing Hyprland and companion packages..."
    sudo dnf install -y \
        hyprland \
        hyprlock \
        hyprpaper \
        xdg-desktop-portal-hyprland \
        waybar \
        wofi \
        swaync \
        mako \
        swaybg \
        grim \
        slurp \
        wl-clipboard \
        playerctl \
        brightnessctl \
        pavucontrol \
        pipewire \
        wireplumber \
        NetworkManager \
        network-manager-applet \
        nm-connection-editor \
        blueman \
        wlogout \
        kitty \
        thunar \
        tuned \
        jq \
        python3 \
        flatpak
}

deploy_hyprland_configs() {
    log "Creating config directories..."
    mkdir -p "$HYPR_DIR" "$WAYBAR_DIR" "$WOFI_DIR" "$SWAYNC_DIR" "$MAKO_DIR"

    # --- Hyprland main config ---
    log "Writing $HYPR_DIR/hyprland.conf"
    cat > "$HYPR_DIR/hyprland.conf" << 'HYPRCONF'
# Monitor configuration
# See https://wiki.hyprland.org/Configuring/Monitors/
monitor = , preferred, auto, 1

# Programs
$terminal = kitty
$fileManager = thunar
$menu = wofi --show drun

# Autostart
exec-once = waybar
exec-once = swaybg -i ~/Downloads/wallpaper/2d-flat-2.jpg -m fill
exec-once = swaync
exec-once = /usr/libexec/xdg-desktop-portal-hyprland
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = ~/.config/hypr/autostart.sh

# Environment variables
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct

# Look and feel
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    resize_on_border = true
    allow_tearing = false
    layout = dwindle
}

decoration {
    rounding = 10
    active_opacity = 1.0
    inactive_opacity = 0.95
    shadow {
        enabled = true
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
    }
    blur {
        enabled = true
        size = 3
        passes = 1
        vibrancy = 0.1696
    }
}

animations {
    enabled = true
    bezier = easeOutQuint, 0.23, 1, 0.32, 1
    bezier = easeInOutCubic, 0.65, 0.05, 0.36, 1
    bezier = linear, 0, 0, 1, 1
    animation = windows, 1, 4, easeOutQuint, popin 80%
    animation = windowsOut, 1, 4, easeOutQuint, popin 80%
    animation = fade, 1, 3, easeOutQuint
    animation = workspaces, 0
    animation = layers, 1, 3, easeOutQuint, fade
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_status = master
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
}

# Input
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
    }
}

gesture = 3, horizontal, workspace

# Keybindings
$mainMod = SUPER

bind = $mainMod, Return, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, E, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, space, exec, pkill wofi || $menu
bind = $mainMod, P, pseudo,
bind = $mainMod, T, layoutmsg, togglesplit
bind = $mainMod, M, exec, ~/.config/hypr/maximize.sh

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move focus (vim keys)
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Move windows
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, J, movewindow, d

# Bind workspaces to monitors (DP-1: 1-10, DP-2: 11-20)
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-1
workspace = 5, monitor:DP-1
workspace = 6, monitor:DP-1
workspace = 7, monitor:DP-1
workspace = 8, monitor:DP-1
workspace = 9, monitor:DP-1
workspace = 10, monitor:DP-1
workspace = 11, monitor:DP-2, default:true
workspace = 12, monitor:DP-2
workspace = 13, monitor:DP-2
workspace = 14, monitor:DP-2
workspace = 15, monitor:DP-2
workspace = 16, monitor:DP-2
workspace = 17, monitor:DP-2
workspace = 18, monitor:DP-2
workspace = 19, monitor:DP-2
workspace = 20, monitor:DP-2

# Switch workspaces (per-monitor independent)
bind = $mainMod, 1, exec, ~/.config/hypr/workspace.sh 1
bind = $mainMod, 2, exec, ~/.config/hypr/workspace.sh 2
bind = $mainMod, 3, exec, ~/.config/hypr/workspace.sh 3
bind = $mainMod, 4, exec, ~/.config/hypr/workspace.sh 4
bind = $mainMod, 5, exec, ~/.config/hypr/workspace.sh 5
bind = $mainMod, 6, exec, ~/.config/hypr/workspace.sh 6
bind = $mainMod, 7, exec, ~/.config/hypr/workspace.sh 7
bind = $mainMod, 8, exec, ~/.config/hypr/workspace.sh 8
bind = $mainMod, 9, exec, ~/.config/hypr/workspace.sh 9
bind = $mainMod, 0, exec, ~/.config/hypr/workspace.sh 10

# Move active window to workspace (per-monitor independent)
bind = $mainMod SHIFT, 1, exec, ~/.config/hypr/movetoworkspace.sh 1
bind = $mainMod SHIFT, 2, exec, ~/.config/hypr/movetoworkspace.sh 2
bind = $mainMod SHIFT, 3, exec, ~/.config/hypr/movetoworkspace.sh 3
bind = $mainMod SHIFT, 4, exec, ~/.config/hypr/movetoworkspace.sh 4
bind = $mainMod SHIFT, 5, exec, ~/.config/hypr/movetoworkspace.sh 5
bind = $mainMod SHIFT, 6, exec, ~/.config/hypr/movetoworkspace.sh 6
bind = $mainMod SHIFT, 7, exec, ~/.config/hypr/movetoworkspace.sh 7
bind = $mainMod SHIFT, 8, exec, ~/.config/hypr/movetoworkspace.sh 8
bind = $mainMod SHIFT, 9, exec, ~/.config/hypr/movetoworkspace.sh 9
bind = $mainMod SHIFT, 0, exec, ~/.config/hypr/movetoworkspace.sh 10

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Resize windows
bind = $mainMod CTRL, left, resizeactive, -20 0
bind = $mainMod CTRL, right, resizeactive, 20 0
bind = $mainMod CTRL, up, resizeactive, 0 -20
bind = $mainMod CTRL, down, resizeactive, 0 20

bind = $mainMod CTRL, H, resizeactive, -20 0
bind = $mainMod CTRL, L, resizeactive, 20 0
bind = $mainMod CTRL, K, resizeactive, 0 -20
bind = $mainMod CTRL, J, resizeactive, 0 20

# Move/resize with mouse
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshot
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Audio (requires playerctl and pactl/wpctl)
binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Brightness (requires brightnessctl)
binde = , XF86MonoBrightnessUp, exec, brightnessctl set 5%+
binde = , XF86MonoBrightnessDown, exec, brightnessctl set 5%-

# Lock screen
bind = $mainMod, escape, exec, hyprlock

# Window rules
windowrule {
    name = suppress-maximize-events
    match:class = .*
    suppress_event = maximize
}

windowrule {
    name = float-pavucontrol
    match:class = ^(pavucontrol)$
    float = yes
}

windowrule {
    name = float-nm-connection-editor
    match:class = ^(nm-connection-editor)$
    float = yes
}

windowrule {
    name = float-blueman-manager
    match:class = ^(blueman-manager)$
    float = yes
}

windowrule {
    name = opacity-ptyxis
    match:class = ^(org\.gnome\.Ptyxis)$
    opacity = 0.94 0.85
}

windowrule {
    name = opacity-intellij
    match:class = ^(jetbrains-idea)$
    opacity = 0.94 0.90
}

windowrule {
    name = float-file-operation-progress
    match:title = ^(File Operation Progress)$
    float = yes
}

windowrule {
    name = float-wlogout
    match:class = ^(wlogout)$
    float = yes
    fullscreen = true
}
HYPRCONF

    # --- Hyprlock ---
    log "Writing $HYPR_DIR/hyprlock.conf"
    cat > "$HYPR_DIR/hyprlock.conf" << 'LOCKCONF'
background {
    monitor =
    color = rgba(30, 30, 46, 1.0)
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.15
    outer_color = rgba(51, 204, 255, 1)
    inner_color = rgba(69, 71, 90, 1)
    font_color = rgba(205, 214, 244, 1)
    fade_on_empty = true
    placeholder_text = <i>Password...</i>
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    color = rgba(205, 214, 244, 1)
    font_size = 64
    font_family = sans-serif
    halign = center
    valign = center
    position = 0, 120
}
LOCKCONF

    # --- Hyprpaper ---
    log "Writing $HYPR_DIR/hyprpaper.conf"
    cat > "$HYPR_DIR/hyprpaper.conf" << 'PAPERCONF'
# Set your wallpaper path here
# preload = ~/path/to/wallpaper.jpg
# wallpaper = DP-1,~/path/to/wallpaper.jpg
# wallpaper = DP-2,~/path/to/wallpaper.jpg
PAPERCONF

    # --- Autostart script ---
    log "Writing $HYPR_DIR/autostart.sh"
    cat > "$HYPR_DIR/autostart.sh" << 'AUTOSTART'
#!/bin/bash

# Autostart script - launches apps on their workspaces in the correct order
# to reproduce the tiling layout via dwindle splits.

# Check if a flatpak app is installed
has_flatpak() {
    flatpak info "$1" &>/dev/null
}

# Check if a command or file exists
has_command() {
    command -v "$1" &>/dev/null || [ -x "$1" ]
}

# Helper: launch app on a specific workspace and wait for it to appear
launch_on_workspace() {
    local workspace="$1"
    local class="$2"
    shift 2
    local cmd="$@"

    hyprctl dispatch workspace "$workspace"
    $cmd &disown
    # Wait for the window to appear (up to 10 seconds)
    for i in $(seq 1 100); do
        if hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
for c in clients:
    if c['class'] == '$class' and c['workspace']['id'] == $workspace:
        sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
            sleep 0.3
            return 0
        fi
        sleep 0.1
    done
}

# WS 1: JetBrains IDEA (fullscreen on workspace)
if has_command "$HOME/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea.sh"; then
    launch_on_workspace 1 "jetbrains-idea" "$HOME/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea.sh"
fi

# WS 2: Brave browser
if has_flatpak com.brave.Browser; then
    launch_on_workspace 2 "brave-browser" flatpak run com.brave.Browser
fi

# WS 3: Terminal (Ptyxis)
if has_command ptyxis; then
    launch_on_workspace 3 "org.gnome.Ptyxis" ptyxis
fi

# WS 4: Outlook (left) -> Slack (right) -> Teams (below Slack)
# Launch order matters for dwindle tiling:
# 1. Outlook first (takes full workspace)
# 2. Slack second (splits right)
# 3. Teams third (splits below Slack)
if has_flatpak com.brave.Browser; then
    launch_on_workspace 4 "brave-eoficlgicibekocmfdomjbfnjmehnhcd-Default" flatpak run --command=brave com.brave.Browser --profile-directory=Default --app-id=eoficlgicibekocmfdomjbfnjmehnhcd
fi
if has_flatpak com.slack.Slack; then
    launch_on_workspace 4 "Slack" flatpak run com.slack.Slack
fi
if has_flatpak com.github.IsmaelMartinez.teams_for_linux; then
    launch_on_workspace 4 "com.github.IsmaelMartinez.teams_for_linux" flatpak run com.github.IsmaelMartinez.teams_for_linux
fi

# Return to workspace 1
sleep 0.5
hyprctl dispatch workspace 1
AUTOSTART

    # --- Maximize toggle script ---
    log "Writing $HYPR_DIR/maximize.sh"
    cat > "$HYPR_DIR/maximize.sh" << 'MAXIMIZE'
#!/bin/bash

workspace_id=$(hyprctl activewindow -j | python3 -c "import json,sys; print(json.load(sys.stdin)['workspace']['id'])")
is_fullscreen=$(hyprctl activewindow -j | python3 -c "import json,sys; print(json.load(sys.stdin).get('fullscreen',0))")

if [ "$is_fullscreen" = "0" ]; then
    hyprctl keyword workspace "$workspace_id, gapsout:0, gapsin:0, bordersize:0"
    hyprctl dispatch fullscreen 1
else
    hyprctl dispatch fullscreen 1
    hyprctl keyword workspace "$workspace_id, gapsout:10, gapsin:5, bordersize:2"
fi
MAXIMIZE

    # --- Workspace switch script ---
    log "Writing $HYPR_DIR/workspace.sh"
    cat > "$HYPR_DIR/workspace.sh" << 'WORKSPACE'
#!/bin/bash
# Switch to a workspace on the currently focused monitor.
# DP-1 uses workspaces 1-10, DP-2 uses workspaces 11-20.

ACTIVE_MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitor')

if [ "$ACTIVE_MONITOR" = "DP-1" ]; then
    hyprctl dispatch workspace "$1"
else
    hyprctl dispatch workspace "$((10 + $1))"
fi
WORKSPACE

    # --- Move-to-workspace script ---
    log "Writing $HYPR_DIR/movetoworkspace.sh"
    cat > "$HYPR_DIR/movetoworkspace.sh" << 'MOVEWS'
#!/bin/bash
# Move active window to a workspace on the currently focused monitor.
# DP-1 uses workspaces 1-10, DP-2 uses workspaces 11-20.

ACTIVE_MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitor')

if [ "$ACTIVE_MONITOR" = "DP-1" ]; then
    hyprctl dispatch movetoworkspace "$1"
else
    hyprctl dispatch movetoworkspace "$((10 + $1))"
fi
MOVEWS

    # --- Power menu script (legacy — wlogout is now primary) ---
    log "Writing $HYPR_DIR/powermenu.sh"
    cat > "$HYPR_DIR/powermenu.sh" << 'POWERMENU'
#!/bin/bash

choice=$(printf "🔒  Lock\n🚪  Logout\n🔄  Restart\n⏻  Shut Down" | wofi --dmenu --prompt "Power" --width 250 --height 220)

case "$choice" in
    *Lock) hyprlock ;;
    *Logout) hyprctl dispatch exit ;;
    *Restart) systemctl reboot ;;
    *"Shut Down") systemctl poweroff ;;
esac
POWERMENU

    # --- Performance profile script ---
    log "Writing $HYPR_DIR/performance.sh"
    cat > "$HYPR_DIR/performance.sh" << 'PERFSCRIPT'
#!/bin/bash

# Performance profile switcher using tuned-adm
# Used by Waybar custom/performance module

PROFILES=("powersave" "balanced" "throughput-performance" "latency-performance")
LABELS=("Powersave" "Balanced" "Performance" "Low Latency")

get_current() {
    tuned-adm active 2>/dev/null | sed 's/Current active profile: //'
}

get_label() {
    local current="$1"
    for i in "${!PROFILES[@]}"; do
        if [ "${PROFILES[$i]}" = "$current" ]; then
            echo "${LABELS[$i]}"
            return
        fi
    done
    echo "$current"
}

case "$1" in
    status)
        current=$(get_current)
        get_label "$current"
        ;;
    cycle)
        current=$(get_current)
        next_index=0
        for i in "${!PROFILES[@]}"; do
            if [ "${PROFILES[$i]}" = "$current" ]; then
                next_index=$(( (i + 1) % ${#PROFILES[@]} ))
                break
            fi
        done
        pkexec tuned-adm profile "${PROFILES[$next_index]}"
        ;;
    pick)
        choice=$(printf '%s\n' "${LABELS[@]}" | wofi --dmenu --prompt "Performance Profile" --width 300 --height 250)
        [ -z "$choice" ] && exit 0
        for i in "${!LABELS[@]}"; do
            if [ "${LABELS[$i]}" = "$choice" ]; then
                pkexec tuned-adm profile "${PROFILES[$i]}"
                break
            fi
        done
        ;;
esac
PERFSCRIPT

    # Make all helper scripts executable
    chmod +x "$HYPR_DIR"/{autostart,maximize,workspace,movetoworkspace,powermenu,performance}.sh

    # --- Waybar config ---
    log "Writing $WAYBAR_DIR/config.jsonc"
    cat > "$WAYBAR_DIR/config.jsonc" << 'WAYBARCONF'
{
    "layer": "top",
    "position": "top",
    "height": 35,

    "modules-left": ["wlr/taskbar"],
    "modules-center": ["clock"],
    "modules-right": ["hyprland/workspaces", "custom/performance", "pulseaudio", "bluetooth", "network", "tray", "custom/power"],

    "hyprland/workspaces": {
        "format": "{id}"
    },

    "clock": {
        "format": "{:%I:%M %p}",
        "format-alt": "{:%A, %B %d, %Y  %I:%M %p}",
        "tooltip-format": "<span font='20'><tt>{calendar}</tt></span>",
        "calendar": {
            "mode": "month",
            "weeks-pos": "left",
            "format": {
                "months": "<span color='#cdd6f4'><b>{}</b></span>",
                "weeks": "<span color='#6c7086'>{}</span>",
                "weekdays": "<span color='#a6e3a1'><b>{}</b></span>",
                "today": "<span color='#f38ba8'><b>{}</b></span>"
            }
        }
    },

    "custom/performance": {
        "format": "󰓅 {}",
        "exec": "~/.config/hypr/performance.sh status",
        "interval": 5,
        "on-click": "~/.config/hypr/performance.sh cycle",
        "on-click-right": "~/.config/hypr/performance.sh pick",
        "tooltip-format": "Click: cycle profiles\nRight-click: pick profile"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟 Muted",
        "format-icons": {
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        "on-click-right": "pavucontrol",
        "on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
        "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    },

    "bluetooth": {
        "format": "󰂯",
        "format-connected": "󰂱 {device_alias}",
        "format-connected-battery": "󰂱 {device_alias} {device_battery_percentage}%",
        "format-disabled": "󰂲",
        "format-off": "󰂲",
        "tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
        "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
        "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
        "tooltip-format-enumerate-connected-battery": "{device_alias}\t{device_address}\t{device_battery_percentage}%",
        "on-click": "blueman-manager"
    },

    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀",
        "format-disconnected": "󰤭",
        "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}",
        "tooltip-format-ethernet": "{ifname}\n{ipaddr}/{cidr}",
        "tooltip-format-disconnected": "Disconnected",
        "on-click": "nm-connection-editor"
    },

    "tray": {
        "spacing": 10
    },

    "custom/power": {
        "format": "⏻",
        "on-click": "wlogout",
        "tooltip": false
    },

    "wlr/taskbar": {
        "format": "{icon}",
        "icon-size": 18,
        "on-click": "activate",
        "on-click-right": "close",
        "tooltip-format": "{title}"
    }
}
WAYBARCONF

    # --- Waybar stylesheet (Catppuccin Mocha) ---
    log "Writing $WAYBAR_DIR/style.css"
    cat > "$WAYBAR_DIR/style.css" << 'WAYBARSTYLE'
* {
    font-family: "RobotoMono Nerd Font", "Font Awesome 6 Free", sans-serif;
    font-size: 15px;
}

window#waybar {
    background-color: #1e1e2e;
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    color: #cdd6f4;
    background: transparent;
    border: none;
    border-radius: 4px;
}

#workspaces button.active {
    background-color: #45475a;
}

#workspaces {
    margin-right: 200px;
}

#clock {
    font-weight: bold;
}

#taskbar button {
    padding: 0 4px;
    background: transparent;
    border: none;
    border-radius: 4px;
}

#taskbar button.active {
    background-color: #45475a;
}

#pulseaudio,
#bluetooth,
#network,
#tray {
    padding: 0 10px;
}

#bluetooth.disabled,
#bluetooth.off {
    color: #6c7086;
}

#custom-performance {
    padding: 0 10px;
    color: #a6e3a1;
}

#custom-power {
    padding: 0 12px;
    color: #f38ba8;
    font-weight: bold;
}
WAYBARSTYLE

    # --- Wofi config ---
    log "Writing $WOFI_DIR/config"
    cat > "$WOFI_DIR/config" << 'WOFICONF'
show=drun
allow_images=true
image_size=24
content_halign=fill
prompt=Search...
width=540
height=420
insensitive=true
WOFICONF

    log "Writing $WOFI_DIR/style.css"
    cat > "$WOFI_DIR/style.css" << 'WOFISTYLE'
window {
    background-color: #1e1e2e;
    color: #cdd6f4;
    border: 2px solid #45475a;
    border-radius: 10px;
    font-family: sans-serif;
    font-size: 17px;
}

#outer-box {
    margin: 5px;
}

#input {
    background-color: #313244;
    color: #cdd6f4;
    border: none;
    border-radius: 8px;
    padding: 8px 12px;
    margin: 5px;
}

#scroll {
    margin: 2px 0px;
}

#inner-box {
    background-color: #1e1e2e;
}

#entry {
    padding: 5px 10px;
    border-radius: 6px;
}

#entry:selected {
    background-color: #45475a;
}

#img {
    margin-right: 8px;
}

#entry > #img {
    margin-left: 40px;
}

#text {
    color: #cdd6f4;
}

#entry:selected #text {
    font-weight: bold;
}
WOFISTYLE

    # --- SwayNC config ---
    log "Writing $SWAYNC_DIR/config.json"
    cat > "$SWAYNC_DIR/config.json" << 'SWAYNCCONF'
{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "ignore-gtk-theme": true,
  "positionX": "center",
  "positionY": "top",
  "layer": "overlay",
  "control-center-layer": "top",
  "layer-shell": true,
  "layer-shell-cover-screen": true,
  "cssPriority": "user",
  "control-center-margin-top": 10,
  "control-center-margin-bottom": 10,
  "control-center-margin-right": 10,
  "notification-2fa-action": true,
  "notification-inline-replies": false,
  "notification-body-image-height": 100,
  "notification-body-image-width": 200,
  "timeout": 10,
  "timeout-low": 5,
  "timeout-critical": 0,
  "fit-to-screen": true,
  "relative-timestamps": true,
  "control-center-width": 400,
  "control-center-height": 600,
  "notification-window-width": 400,
  "keyboard-shortcuts": true,
  "notification-grouping": true,
  "image-visibility": "when-available",
  "transition-time": 200,
  "hide-on-clear": false,
  "hide-on-action": true,
  "text-empty": "No Notifications",
  "widgets": [
    "title",
    "dnd",
    "notifications"
  ],
  "widget-config": {
    "notifications": {
      "vexpand": true
    },
    "title": {
      "text": "Notifications",
      "clear-all-button": true,
      "button-text": "Clear All"
    },
    "dnd": {
      "text": "Do Not Disturb"
    }
  }
}
SWAYNCCONF

    log "Writing $SWAYNC_DIR/style.css"
    cat > "$SWAYNC_DIR/style.css" << 'SWAYNCSTYLE'
* {
  font-family: sans-serif;
  font-size: 14px;
}

.control-center {
  background: #1e1e2e;
  color: #cdd6f4;
  border-radius: 10px;
  border: 2px solid #45475a;
}

.control-center .notification-row {
  margin: 4px 8px;
}

.notification-row {
  outline: none;
}

.notification {
  background: #313244;
  color: #cdd6f4;
  border-radius: 10px;
  border: 1px solid #45475a;
  margin: 4px 0;
  padding: 0;
}

.notification-content {
  padding: 8px 12px;
}

.close-button {
  background: #45475a;
  color: #cdd6f4;
  border-radius: 6px;
  padding: 2px 6px;
  margin: 8px;
  border: none;
}

.close-button:hover {
  background: #f38ba8;
  color: #1e1e2e;
}

.notification-default-action {
  border-radius: 10px;
}

.notification-default-action:hover {
  background: #45475a;
}

.notification-action {
  background: #45475a;
  color: #cdd6f4;
  border-radius: 6px;
  border: none;
  margin: 4px;
  padding: 4px 8px;
}

.notification-action:hover {
  background: #585b70;
}

.summary {
  color: #cdd6f4;
  font-weight: bold;
  font-size: 14px;
}

.body {
  color: #a6adc8;
  font-size: 13px;
}

.time {
  color: #6c7086;
  font-size: 12px;
}

.widget-title {
  color: #cdd6f4;
  font-weight: bold;
  font-size: 16px;
  margin: 8px 12px;
}

.widget-title button {
  background: #45475a;
  color: #cdd6f4;
  border-radius: 6px;
  border: none;
  padding: 4px 12px;
}

.widget-title button:hover {
  background: #f38ba8;
  color: #1e1e2e;
}

.widget-dnd {
  color: #cdd6f4;
  margin: 4px 12px;
}

.widget-dnd > switch {
  background: #45475a;
  border-radius: 10px;
  border: none;
}

.widget-dnd > switch:checked {
  background: #33ccff;
}

.widget-dnd > switch slider {
  background: #cdd6f4;
  border-radius: 50%;
}

.floating-notifications {
  background: transparent;
}

.blank-window {
  background: transparent;
}

.text-empty {
  color: #6c7086;
  font-size: 14px;
}
SWAYNCSTYLE

    # --- Mako config ---
    log "Writing $MAKO_DIR/config"
    cat > "$MAKO_DIR/config" << 'MAKOCONF'
anchor=top-center
default-timeout=5000
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#45475a
border-radius=10
padding=10
MAKOCONF
}

print_hyprland_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}  Hyprland installation complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Installed configs:"
    echo "  ~/.config/hypr/        - Hyprland, hyprlock, hyprpaper + helper scripts"
    echo "  ~/.config/waybar/      - Waybar panel (Catppuccin Mocha, Nerd Font icons)"
    echo "  ~/.config/wofi/        - Application launcher + dmenu backend"
    echo "  ~/.config/swaync/      - Notification center"
    echo "  ~/.config/mako/        - Notification daemon"
    echo ""
    echo "Helper scripts deployed:"
    echo "  autostart.sh           - Launches apps on workspaces at login"
    echo "  workspace.sh           - Per-monitor workspace switching"
    echo "  movetoworkspace.sh     - Per-monitor window-to-workspace moves"
    echo "  maximize.sh            - Fullscreen toggle with gap removal"
    echo "  powermenu.sh           - Wofi-based power menu (legacy, wlogout is primary)"
    echo "  performance.sh         - Performance profile switcher (tuned-adm)"
    echo ""
    echo "Manual steps remaining:"
    echo "  1. Update wallpaper path in hyprland.conf (swaybg line) if needed"
    echo "  2. Install Ptyxis terminal (dnf install ptyxis) if needed"
    echo "  3. Set up Brave PWAs for Outlook/Teams (app IDs in autostart.sh)"
    echo "  4. Deploy ~/.config/gtk-3.0/gtk.css for tooltip font overrides"
    echo "  5. Log out and select 'Hyprland' from your display manager"
    echo ""
    echo "Monitor setup: DP-1 (workspaces 1-10), DP-2 (workspaces 11-20)"
    echo "Edit monitor names in hyprland.conf and workspace/movetoworkspace scripts if yours differ."
    echo ""
}

main() {
    set -eo pipefail
    cd "$HOME"

    echo "Updating system..."
    sudo dnf update -y

    setup_rpm_fusion
    install_media_codecs
    install_oh_my_bash
    install_dnf_packages
    generate_ssh_key
    install_docker
    install_lazydocker
    install_openjdk
    install_jetbrains_toolbox
    install_nvm
    install_neovim
    install_nerdfonts
    configure_bashrc
    install_node_lts
    install_nvchad
    install_global_npm_packages
    install_flatpak_apps
    configure_neovim_plugins

    ### Hyprland Desktop Environment ###
    install_hyprland_packages
    deploy_hyprland_configs
    print_hyprland_summary
}

# Only run main when executed directly, not when sourced for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
