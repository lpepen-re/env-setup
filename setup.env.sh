!#/bin/bash

# THIS SCRIPT IS MEANT TO HELP SETUP MY DEVELOPER ENVIRONMENT FROM SCRATCH
# OS: FEDORA 43
# ARCH: x86

### Basic Setups ###
echo "Updating system..."
sudo dnf update -y


### Setup RPM Fusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf update @core -y


### Media Codec nonsense
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# TODO: LPM - For Intel only, if using another vendor change this https://rpmfusion.org/Howto/Multimedia
sudo dnf install intel-media-driver


### Oh-My-Bash ###
echo "Installing Oh-My-Bash. You may need to rerun this script since sourcing the terminal exits the script"
cd ~
bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
sed -i 's/^OSH_THEME=".*"/OSH_THEME="powerline-multiline"/' ~/.bashrc
source ~/.bashrc




echo "Installing @development-tools..."
sudo dnf install @development-tools -y

echo "Installing @cosmic-desktop-environment..."
sudo dnf install @cosmic-desktop-environment -y

echo "Installing Nvidia Drivers..."
sudo dnf install akmod-nvidia -y

# Golang
echo "Installing Go..."
sudo dnf install golang -y

# 7zip
echo "Installing 7zip..."
sudo dnf install p7zip p7zip-plugins -y

# Dotnet
echo "Installing Dotnet runtime..."
sudo dnf install glibc libgcc ca-certificates openssl-libs libstdc++ libicu tzdata krb5-libs -y
sudo dnf install dotnet-runtime-8.0 -y

# VLC
echo "Installing VLC Media Player..."
sudo dnf install vlc -y

# OBS Studio
echo "Installing OBS Studio..."
sudo dnf install obs -y

# Python
echo "Installing Python3.11..."
sudo dnf install python3.11 -y

# Generate SSH 
echo "Generating SSH key pair..."
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 <<< y >/dev/null 2>&1


### DOCKER ###
echo "Installing Docker..."
cd ~
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo -y
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable --now docker
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl enable containerd.service


### Lazy Docker ###
echo "Installing Lazy Docker..."
cd ~
wget -P ~/lazydocker/ https://github.com/jesseduffield/lazydocker/releases/download/v0.24.3/lazydocker_0.24.3_Linux_x86_64.tar.gz
cd ~/lazydocker
tar -xvf lazydocker_0.24.3_Linux_x86_64.tar.gz
rm lazydocker_0.24.3_Linux_x86_64.tar.gz


### JAVA 21 ###
echo "Installing OpenJDK 21..."
cd ~
wget -P ~/java/ https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz
cd ~/java
tar -xvf openjdk-21.0.2_linux-x64_bin.tar.gz
rm openjdk-21.0.2_linux-x64_bin.tar.gz


### Jetbrains Toolbox ###
echo "Installing Jetbrains Toolbox..."
cd ~
wget -P ~/jetbrains-toolbox/  https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-3.2.0.65851.tar.gz
cd ~/jetbrains-toolbox
tar -xvf jetbrains-toolbox-3.2.0.65851.tar.gz 
rm jetbrains-toolbox-3.2.0.65851.tar.gz 


### Node Version Manager ###
echo "Intalling Node Version Manager..."
cd ~
git clone https://github.com/nvm-sh/nvm.git .nvm
cd ~/.nvm
git checkout v0.40.3
. ./nvm.sh


### Neovim ###
echo "Installing Neovim..."
cd ~
wget -P ~/nvim/ https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz
tar -xvf nvim-linux-x86_64.tar.gz
rm  nvim-linux-x86_64.tar.gz


### NerdFonts Roboto Mono ###
echo "Installing Nerdfonts Roboto Mono ..."
cd ~
wget -P ~/.local/share/fonts/roboto-mono/  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/RobotoMono.zip
cd ~/.local/share/fonts/roboto-mono
7z x RobotoMono.zip


### EDIT BASH SCRIPT ###
echo "Adding global variables and aliases to .bashrc..."
cd ~
echo -e '\nalias lzd="lazydocker"\n' >> ~/.bashrc
echo 'export LAZYDOCKER=/home/lpepen/lazydocker' >> ~/.bashrc
echo 'export JAVA_HOME=/home/lpepen/java/jdk-21.0.2' >> ~/.bashrc
echo -e 'export NVIM=/home/lpepen/nvim/nvim-linux-x86_64/bin\n' >> ~/.bashrc

echo -e '\nexport PATH=$JAVA_HOME/bin:$NVIM:$PATH:$LAZYDOCKER\n\n' >> ~/.bashrc 

echo -e '\nexport NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.bashrc
echo -e '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion\n' >> ~/.bashrc


### Install Node LTS ###
echo "Installing Node LTS..."
cd ~
source ~/.bashrc
nvm install --lts
source ~/.bashrc


### NVCHAD ###
echo "Installing NVCHAD NVIM Config..."
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim


### Developer ENV stuff ###
echo "Installing Global Javascript Dependencies..."
npm install -g @angular/cli
npm install -g nx
npm install -g pnpm@8.15.9
npm install -g typescript typescript-language-server
npm install -g svelte-language-server
npm install -g @angular/language-server


### VSCodium ###
echo "Installing VSCodium..."
flatpak install flathub com.vscodium.codium -y

### BRAVE Browser ###
echo "Installing Brave Browser..."
flatpak install flathub com.brave.Browser -y

### DBeaver ###
echo "Installing DBeaver..."
flatpak install flathub io.dbeaver.DBeaverCommunity -y

### Flatseal ###
echo "Installing Flatseal..."
flatpak install flathub com.github.tchx84.Flatseal -y

### Flameshot ###
echo "Installing Flameshot....f"
flatpak install flathub org.flameshot.Flameshot -y

### Obsidian ###
echo "Installing Obsidia Notes..."
flatpak install flathub md.obsidian.Obsidian -y

### Slack ###
echo "Installing Slack..."
flatpak install flathub com.slack.Slack -y

### Chrome ###
echo "Installing Chromium..."
flatpak install flathub org.chromium.Chromium -y


### Neovim Basic Plugins ###
echo "Configuring Neovim..."
nvim --headless -c ":TSInstall c angular bash cmake css dockerfile dot gitignore go java javascript json lua make markdown nginx php python toml tsx typescript yaml vue" -c ":q"
nvim --headless -c ":MasonInstall svelte-language-server vue-language-server yaml-language-server angular-language-server cpplint cpptools css-lsp docker-language-server dockerfile-language-server gh-actions-language-server gopls go-debug-adapter jsonlint lua-language-server nginx-language-server nxls pyright" -c ":q"

