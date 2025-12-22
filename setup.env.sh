!#/bin/bash

### Basic Setups ###
sudo dnf update -y

sudo dnf install @development-tools -y

sudo dnf install @cosmic-desktop-environment -y

# Dotnet
sudo dnf install glibc libgcc ca-certificates openssl-libs libstdc++ libicu tzdata krb5-libs -y
sudo dnf install dotnet-runtime-8.0 -y

# Generate SSH Keys
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 <<< y >/dev/null 2>&1



### Oh-My-Bash ###
cd ~

bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"

if grep -q '^OSH_THEME=' ~/.bashrc; then
    sed -i 's/^OSH_THEME=".*"/OSH_THEME="powerline-multiline"/' ~/.bashrc
else
    echo 'OSH_THEME="powerline-multiline"' >> ~/.bashrc
fi

source ~/.bashrc



### DOCKER ###
cd ~

sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl enable --now docker

sudo groupadd docker

sudo usermod -aG docker $USER

sudo systemctl enable docker.service

sudo systemctl enable containerd.service



### Lazy Docker ###
cd ~
wget -P ~/lazydocker/ https://github.com/jesseduffield/lazydocker/releases/download/v0.24.3/lazydocker_0.24.3_Linux_x86_64.tar.gz

cd ~/lazydocker

tar -xvf lazydocker_0.24.3_Linux_x86_64.tar.gz

rm lazydocker_0.24.3_Linux_x86_64.tar.gz



### JAVA ###
cd ~
wget -P ~/java/ https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz

cd ~/java

tar -xvf openjdk-21.0.2_linux-x64_bin.tar.gz

rm openjdk-21.0.2_linux-x64_bin.tar.gz


### Jetbrains Toolbox ###
cd ~
wget -P ~/jetbrains-toolbox/  https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-3.2.0.65851.tar.gz
cd ~/jetbrains-toolbox
tar -xvf jetbrains-toolbox-3.2.0.65851.tar.gz 
rm jetbrains-toolbox-3.2.0.65851.tar.gz 



### Node Version Manager ###
cd ~
git clone https://github.com/nvm-sh/nvm.git .nvm
cd ~/.nvm
git checkout v0.40.3
. ./nvm.sh



### PYENV ###
sudo dnf install -y make gcc gcc-c++ zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz-devel libffi-devel ncurses-devel tk-devel tcl-devel gdbm-devel libuuid-devel

curl -fsSL https://pyenv.run | bash

sudo dnf install bzip2-devel -y



### EDIT BASH SCRIPT ###
echo 'alias lzd="lazydocker"' >> ~/.bashrc
echo 'export LAZYDOCKER=/home/lpepen/lazydocker' >> ~/.bashrc
echo 'export JAVA_HOME=/home/lpepen/java/jdk-21.0.2' >> ~/.bashrc

echo 'export PATH=$JAVA_HOME/bin:$PATH:$LAZYDOCKER' >> ~/.bashrc 

echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.bashrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion' >> ~/.bashrc



echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc


### RRC Project Specifics ###

cd ~
source ~/.bashrc

nvm install --lts

source ~/.bashrc

npm install --global @angular/cli
npm install --global nx
npm install pnpm@8.15.9 -g

pyenv install 3.11.14
