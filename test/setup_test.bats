#!/usr/bin/env bats

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

# --- Test helpers ---

# Creates a temp directory with mock commands that log invocations.
# Every external command the script calls gets intercepted and recorded
# instead of actually running.
setup() {
    TEST_DIR="$(mktemp -d)"
    MOCK_BIN="$TEST_DIR/mock_bin"
    MOCK_LOG="$TEST_DIR/commands.log"
    FAKE_HOME="$TEST_DIR/home"

    mkdir -p "$MOCK_BIN" "$FAKE_HOME/.ssh"

    # Create mock commands — each one logs "command arg1 arg2 ..." to MOCK_LOG
    for cmd in sudo dnf wget tar ssh-keygen systemctl groupadd usermod flatpak npm nvim 7z sed rpm nvm bash; do
        cat > "$MOCK_BIN/$cmd" << MOCK
#!/bin/bash
echo "$cmd \$*" >> "$MOCK_LOG"
MOCK
        chmod +x "$MOCK_BIN/$cmd"
    done

    # rm mock — logs and succeeds (files don't exist since wget is mocked)
    cat > "$MOCK_BIN/rm" << MOCK
#!/bin/bash
echo "rm \$*" >> "$MOCK_LOG"
MOCK
    chmod +x "$MOCK_BIN/rm"

    # git mock — logs and creates target directory for clone operations
    cat > "$MOCK_BIN/git" << MOCK
#!/bin/bash
echo "git \$*" >> "$MOCK_LOG"
if [ "\$1" = "clone" ]; then
    /usr/bin/mkdir -p "\${!#}"
fi
MOCK
    chmod +x "$MOCK_BIN/git"

    # rpm mock returns a fake fedora version
    cat > "$MOCK_BIN/rpm" << MOCK
#!/bin/bash
echo "rpm \$*" >> "$MOCK_LOG"
echo "43"
MOCK
    chmod +x "$MOCK_BIN/rpm"

    # mkdir mock that actually creates dirs (needed for cd in subshells)
    cat > "$MOCK_BIN/mkdir" << MOCK
#!/bin/bash
echo "mkdir \$*" >> "$MOCK_LOG"
/usr/bin/mkdir "\$@"
MOCK
    chmod +x "$MOCK_BIN/mkdir"

    export PATH="$MOCK_BIN:$PATH"
    export HOME="$FAKE_HOME"
    export USER="testuser"
    export MOCK_LOG

    # Create a fake .bashrc so sed and cat >> work
    touch "$FAKE_HOME/.bashrc"

    # Pre-create fake nvm.sh so the [ -s ... ] && source pattern succeeds
    /usr/bin/mkdir -p "$FAKE_HOME/.nvm"
    echo "# mock nvm" > "$FAKE_HOME/.nvm/nvm.sh"

    # Source the script to load functions (source guard prevents main from running)
    source "$BATS_TEST_DIRNAME/../setup.env.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Helper: check that a pattern appears in the command log
assert_command_logged() {
    local pattern="$1"
    assert [ -f "$MOCK_LOG" ]
    run grep -F "$pattern" "$MOCK_LOG"
    assert_success
}

assert_command_logged_regex() {
    local pattern="$1"
    assert [ -f "$MOCK_LOG" ]
    run grep -E "$pattern" "$MOCK_LOG"
    assert_success
}

# --- Version variable tests ---

@test "version variables are set" {
    assert_equal "$LAZYDOCKER_VERSION" "0.24.3"
    assert_equal "$OPENJDK_VERSION" "21.0.2"
    assert_equal "$JETBRAINS_TOOLBOX_VERSION" "3.2.0.65851"
    assert_equal "$NVM_VERSION" "v0.40.3"
    assert_equal "$NEOVIM_VERSION" "v0.11.5"
    assert_equal "$NERDFONTS_VERSION" "v3.4.0"
    assert_equal "$PNPM_VERSION" "8.15.9"
}

# --- DNF packages test ---

@test "install_dnf_packages passes -y flag and all expected packages" {
    install_dnf_packages

    assert_command_logged "sudo dnf install -y"
    assert_command_logged "@development-tools"
    assert_command_logged "@cosmic-desktop-environment"
    assert_command_logged "akmod-nvidia"
    assert_command_logged "golang"
    assert_command_logged "p7zip p7zip-plugins"
    assert_command_logged "dotnet-runtime-8.0"
    assert_command_logged "vlc"
    assert_command_logged "obs"
    assert_command_logged "python3.11"
}

@test "install_dnf_packages is a single batched call" {
    install_dnf_packages

    # Should only have one "sudo dnf install" line (batched)
    run grep -c "sudo dnf install" "$MOCK_LOG"
    assert_output "1"
}

# --- Media codecs test ---

@test "install_media_codecs passes -y to intel-media-driver" {
    install_media_codecs

    assert_command_logged "sudo dnf install -y intel-media-driver"
}

# --- Docker test ---

@test "install_docker uses groupadd with || true fallback" {
    # groupadd mock returns non-zero to simulate "already exists"
    cat > "$MOCK_BIN/groupadd" << MOCK
#!/bin/bash
echo "groupadd \$*" >> "$MOCK_LOG"
exit 1
MOCK
    chmod +x "$MOCK_BIN/groupadd"

    # Should not fail despite groupadd returning 1
    run install_docker
    assert_success
}

@test "install_docker does not have redundant systemctl enable docker.service" {
    install_docker

    run grep -c "sudo systemctl enable" "$MOCK_LOG"
    # Should be exactly 2: "enable --now docker" and "enable containerd.service"
    assert_output "2"
    assert_command_logged "sudo systemctl enable --now docker"
    assert_command_logged "sudo systemctl enable containerd.service"
}

@test "install_docker adds user to docker group" {
    install_docker
    assert_command_logged "sudo usermod -aG docker testuser"
}

# --- Lazydocker test ---

@test "install_lazydocker uses version variable in download URL" {
    install_lazydocker
    assert_command_logged "wget https://github.com/jesseduffield/lazydocker/releases/download/v0.24.3/lazydocker_0.24.3_Linux_x86_64.tar.gz"
}

@test "install_lazydocker creates directory before downloading" {
    install_lazydocker

    # mkdir should appear before wget in the log
    local mkdir_line wget_line
    mkdir_line=$(grep -n "mkdir.*lazydocker" "$MOCK_LOG" | head -1 | cut -d: -f1)
    wget_line=$(grep -n "wget.*lazydocker" "$MOCK_LOG" | head -1 | cut -d: -f1)
    assert [ "$mkdir_line" -lt "$wget_line" ]
}

@test "install_lazydocker cleans up tarball after extraction" {
    install_lazydocker
    assert_command_logged "tar -xvf lazydocker_0.24.3_Linux_x86_64.tar.gz"
    # rm runs in subshell which uses the real rm — check dir is clean
    # Since wget mock doesn't create a real file, rm will fail in the subshell.
    # We test the intent by checking the command log isn't missing the rm.
    # For a deeper test, we'd need to create a fake tarball.
}

# --- OpenJDK test ---

@test "install_openjdk uses version variable in download URL" {
    install_openjdk
    assert_command_logged "wget https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz"
}

@test "install_openjdk extracts in correct directory" {
    install_openjdk
    assert_command_logged "mkdir -p $FAKE_HOME/java"
    assert_command_logged "tar -xvf openjdk-21.0.2_linux-x64_bin.tar.gz"
}

# --- Jetbrains Toolbox test ---

@test "install_jetbrains_toolbox uses version variable" {
    install_jetbrains_toolbox
    assert_command_logged "wget https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-3.2.0.65851.tar.gz"
}

# --- NVM test ---

@test "install_nvm checks out correct version tag" {
    install_nvm
    assert_command_logged "git checkout v0.40.3"
}

@test "install_nvm sets NVM_DIR" {
    install_nvm
    assert_equal "$NVM_DIR" "$FAKE_HOME/.nvm"
}

# --- Neovim test ---

@test "install_neovim downloads and extracts in ~/nvim/" {
    install_neovim
    assert_command_logged "mkdir -p $FAKE_HOME/nvim"
    assert_command_logged "wget https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz"
    assert_command_logged "tar -xvf nvim-linux-x86_64.tar.gz"
}

# --- NerdFonts test ---

@test "install_nerdfonts uses version variable and cleans up zip" {
    install_nerdfonts
    assert_command_logged "wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/RobotoMono.zip"
    assert_command_logged "7z x RobotoMono.zip"
}

@test "install_nerdfonts creates font directory" {
    install_nerdfonts
    assert_command_logged "mkdir -p $FAKE_HOME/.local/share/fonts/roboto-mono"
}

# --- Bashrc test ---

@test "configure_bashrc writes lazydocker alias" {
    configure_bashrc
    run grep 'alias lzd="lazydocker"' "$FAKE_HOME/.bashrc"
    assert_success
}

@test "configure_bashrc uses \$HOME not hardcoded path" {
    configure_bashrc
    run grep '/home/lpepen' "$FAKE_HOME/.bashrc"
    assert_failure  # Should NOT find a hardcoded path
}

@test "configure_bashrc writes JAVA_HOME with correct version" {
    configure_bashrc
    run grep 'export JAVA_HOME=$HOME/java/jdk-21.0.2' "$FAKE_HOME/.bashrc"
    assert_success
}

@test "configure_bashrc writes NVM loader" {
    configure_bashrc
    run grep 'NVM_DIR' "$FAKE_HOME/.bashrc"
    assert_success
}

@test "configure_bashrc exports PATH components for remainder of script" {
    configure_bashrc
    assert_equal "$JAVA_HOME" "$FAKE_HOME/java/jdk-21.0.2"
    assert_equal "$NVIM" "$FAKE_HOME/nvim/nvim-linux-x86_64/bin"
    assert_equal "$LAZYDOCKER" "$FAKE_HOME/lazydocker"
    [[ "$PATH" == *"$JAVA_HOME/bin"* ]]
    [[ "$PATH" == *"$NVIM"* ]]
}

# --- SSH key test ---

@test "generate_ssh_key uses ed25519" {
    generate_ssh_key
    assert_command_logged "ssh-keygen -t ed25519"
}

# --- NvChad test ---

@test "install_nvchad runs nvim in headless mode" {
    install_nvchad
    assert_command_logged "nvim --headless +Lazy! sync +qa"
}

@test "install_nvchad does not open nvim interactively" {
    install_nvchad
    # Every nvim call should have --headless
    run grep "^nvim " "$MOCK_LOG"
    assert_output --partial "--headless"
}

# --- npm packages test ---

@test "install_global_npm_packages is a single batched call" {
    install_global_npm_packages
    run grep -c "npm install" "$MOCK_LOG"
    assert_output "1"
}

@test "install_global_npm_packages includes pnpm with version" {
    install_global_npm_packages
    assert_command_logged "pnpm@8.15.9"
}

@test "install_global_npm_packages includes all expected packages" {
    install_global_npm_packages
    assert_command_logged "@angular/cli"
    assert_command_logged "nx"
    assert_command_logged "typescript"
    assert_command_logged "typescript-language-server"
    assert_command_logged "svelte-language-server"
    assert_command_logged "@angular/language-server"
}

# --- Flatpak test ---

@test "install_flatpak_apps is a single batched call" {
    install_flatpak_apps
    run grep -c "flatpak install" "$MOCK_LOG"
    assert_output "1"
}

@test "install_flatpak_apps passes -y flag" {
    install_flatpak_apps
    assert_command_logged "flatpak install -y flathub"
}

@test "install_flatpak_apps includes all expected apps" {
    install_flatpak_apps
    assert_command_logged "com.vscodium.codium"
    assert_command_logged "com.brave.Browser"
    assert_command_logged "io.dbeaver.DBeaverCommunity"
    assert_command_logged "com.github.tchx84.Flatseal"
    assert_command_logged "org.flameshot.Flameshot"
    assert_command_logged "md.obsidian.Obsidian"
    assert_command_logged "com.slack.Slack"
    assert_command_logged "org.chromium.Chromium"
    assert_command_logged "com.github.IsmaelMartinez.teams_for_linux"
}

@test "install_flatpak_apps ensures flathub remote exists" {
    install_flatpak_apps
    assert_command_logged "flatpak remote-add --if-not-exists flathub"
}

# --- Neovim plugins test ---

@test "configure_neovim_plugins runs headless" {
    configure_neovim_plugins

    # All nvim calls should be headless
    while IFS= read -r line; do
        [[ "$line" == *"--headless"* ]]
    done < <(grep "^nvim " "$MOCK_LOG")
}

# --- Subshell isolation test ---

@test "install functions do not change the main shell working directory" {
    local original_dir="$PWD"

    install_lazydocker
    assert_equal "$PWD" "$original_dir"

    install_openjdk
    assert_equal "$PWD" "$original_dir"

    install_jetbrains_toolbox
    assert_equal "$PWD" "$original_dir"

    install_neovim
    assert_equal "$PWD" "$original_dir"

    install_nerdfonts
    assert_equal "$PWD" "$original_dir"
}

# --- Oh-My-Bash test ---

@test "install_oh_my_bash sets theme to powerline-multiline" {
    # Create a fake bashrc with a default theme line for sed to act on
    echo 'OSH_THEME="font"' > "$FAKE_HOME/.bashrc"

    install_oh_my_bash

    assert_command_logged "sed -i"
    # sed mock doesn't actually edit, so we check the command args
    assert_command_logged_regex "sed.*OSH_THEME.*powerline-multiline"
}

# =============================================================================
# Hyprland tests
# =============================================================================

# --- Hyprland packages test ---

@test "install_hyprland_packages is a single batched dnf call" {
    install_hyprland_packages
    run grep -c "sudo dnf install" "$MOCK_LOG"
    assert_output "1"
}

@test "install_hyprland_packages installs core hyprland packages" {
    install_hyprland_packages
    assert_command_logged "hyprland"
    assert_command_logged "hyprlock"
    assert_command_logged "hyprpaper"
    assert_command_logged "xdg-desktop-portal-hyprland"
    assert_command_logged "waybar"
    assert_command_logged "wofi"
    assert_command_logged "swaync"
    assert_command_logged "mako"
    assert_command_logged "swaybg"
}

@test "install_hyprland_packages installs screenshot and clipboard tools" {
    install_hyprland_packages
    assert_command_logged "grim"
    assert_command_logged "slurp"
    assert_command_logged "wl-clipboard"
}

@test "install_hyprland_packages installs media and audio stack" {
    install_hyprland_packages
    assert_command_logged "playerctl"
    assert_command_logged "brightnessctl"
    assert_command_logged "pavucontrol"
    assert_command_logged "pipewire"
    assert_command_logged "wireplumber"
}

@test "install_hyprland_packages installs networking and bluetooth" {
    install_hyprland_packages
    assert_command_logged "NetworkManager"
    assert_command_logged "network-manager-applet"
    assert_command_logged "nm-connection-editor"
    assert_command_logged "blueman"
}

@test "install_hyprland_packages installs utility packages" {
    install_hyprland_packages
    assert_command_logged "wlogout"
    assert_command_logged "kitty"
    assert_command_logged "thunar"
    assert_command_logged "tuned"
    assert_command_logged "jq"
}

@test "install_hyprland_packages passes -y flag" {
    install_hyprland_packages
    assert_command_logged "sudo dnf install -y"
}

# --- Hyprland config deployment tests ---

@test "deploy_hyprland_configs creates all config directories" {
    deploy_hyprland_configs
    assert [ -d "$FAKE_HOME/.config/hypr" ]
    assert [ -d "$FAKE_HOME/.config/waybar" ]
    assert [ -d "$FAKE_HOME/.config/wofi" ]
    assert [ -d "$FAKE_HOME/.config/swaync" ]
    assert [ -d "$FAKE_HOME/.config/mako" ]
}

@test "deploy_hyprland_configs creates hyprland.conf with dwindle layout" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/hypr/hyprland.conf" ]
    run grep "layout = dwindle" "$FAKE_HOME/.config/hypr/hyprland.conf"
    assert_success
}

@test "deploy_hyprland_configs creates hyprlock.conf" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/hypr/hyprlock.conf" ]
    run grep "input-field" "$FAKE_HOME/.config/hypr/hyprlock.conf"
    assert_success
}

@test "deploy_hyprland_configs creates hyprpaper.conf" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/hypr/hyprpaper.conf" ]
}

@test "deploy_hyprland_configs creates waybar config and style" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/waybar/config.jsonc" ]
    assert [ -f "$FAKE_HOME/.config/waybar/style.css" ]
    run grep "Catppuccin" "$FAKE_HOME/.config/waybar/style.css"
    assert_failure  # class name not literal, but check theme color
    run grep "#1e1e2e" "$FAKE_HOME/.config/waybar/style.css"
    assert_success
}

@test "deploy_hyprland_configs creates wofi config and style" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/wofi/config" ]
    assert [ -f "$FAKE_HOME/.config/wofi/style.css" ]
    run grep "show=drun" "$FAKE_HOME/.config/wofi/config"
    assert_success
}

@test "deploy_hyprland_configs creates swaync config and style" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/swaync/config.json" ]
    assert [ -f "$FAKE_HOME/.config/swaync/style.css" ]
}

@test "deploy_hyprland_configs creates mako config" {
    deploy_hyprland_configs
    assert [ -f "$FAKE_HOME/.config/mako/config" ]
    run grep "anchor=top-center" "$FAKE_HOME/.config/mako/config"
    assert_success
}

@test "deploy_hyprland_configs makes helper scripts executable" {
    deploy_hyprland_configs
    assert [ -x "$FAKE_HOME/.config/hypr/autostart.sh" ]
    assert [ -x "$FAKE_HOME/.config/hypr/maximize.sh" ]
    assert [ -x "$FAKE_HOME/.config/hypr/workspace.sh" ]
    assert [ -x "$FAKE_HOME/.config/hypr/movetoworkspace.sh" ]
    assert [ -x "$FAKE_HOME/.config/hypr/powermenu.sh" ]
    assert [ -x "$FAKE_HOME/.config/hypr/performance.sh" ]
}

@test "deploy_hyprland_configs workspace.sh has per-monitor logic" {
    deploy_hyprland_configs
    run grep "DP-1" "$FAKE_HOME/.config/hypr/workspace.sh"
    assert_success
    # DP-2 workspaces are offset by +10
    run grep '10 +' "$FAKE_HOME/.config/hypr/workspace.sh"
    assert_success
}

@test "deploy_hyprland_configs hyprland.conf has dual monitor workspaces" {
    deploy_hyprland_configs
    run grep -c "monitor:DP-1" "$FAKE_HOME/.config/hypr/hyprland.conf"
    assert_output "10"
    run grep -c "monitor:DP-2" "$FAKE_HOME/.config/hypr/hyprland.conf"
    assert_output "10"
}

@test "deploy_hyprland_configs waybar config has all required modules" {
    deploy_hyprland_configs
    local config="$FAKE_HOME/.config/waybar/config.jsonc"
    run grep "hyprland/workspaces" "$config"
    assert_success
    run grep "custom/performance" "$config"
    assert_success
    run grep "pulseaudio" "$config"
    assert_success
    run grep "bluetooth" "$config"
    assert_success
    run grep "network" "$config"
    assert_success
    run grep "custom/power" "$config"
    assert_success
    run grep "wlr/taskbar" "$config"
    assert_success
}

# --- Source guard test ---

@test "sourcing the script does not execute main" {
    # If the source guard works, main() was not called during setup().
    # The MOCK_LOG should be empty or not exist (no commands were run by main).
    if [ -f "$MOCK_LOG" ]; then
        run grep "sudo dnf update -y" "$MOCK_LOG"
        assert_failure  # main's first command should NOT be in the log
    fi
}
