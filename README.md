# NVIM-CONFIG

## INSTALLATION

***NOTE:*** Before continuing, backup any local nvim configurations you may have in ~/.config/nvim

Open terminal and clone the repo into the nvim folder:

```bash
git clone https://github.com/PreparedBag/nvim-config.git ~/.config/nvim
```

### UPDATE NEOVIM

Make sure you are using the latest neovim. The ones in the apt sources are usually too old for these plugins:

https://github.com/neovim/neovim/blob/master/INSTALL.md

#### x86_64

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
```

Then add to your .bashrc to add to PATH on login:

```bash
grep -qxF 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' ~/.bashrc || echo 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' >> ~/.bashrc
```

And create an alias in ~/.bash_aliases to replace 'vim' (Optional):

```bash
grep -qxF "alias vim='/opt/nvim-linux-x86_64/bin/nvim'" ~/.bash_aliases || echo "alias vim='/opt/nvim-linux-x86_64/bin/nvim'" >> ~/.bash_aliases
```

#### ARM_64

```sh
sudo apt install ninja-build gettext cmake unzip curl build-essential
cd
git clone https://github.com/neovim/neovim
cd neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
```

Then add to your .bashrc to add to PATH on login:

```bash
grep -qxF 'export PATH="$PATH:$HOME/neovim/build/bin"' ~/.bashrc || echo 'export PATH="$PATH:$HOME/neovim/build/bin"' >> ~/.bashrc
```

And create an alias to replace 'vim' (Optional):

```bash
grep -qxF "alias vim='$HOME/neovim/build/bin/nvim'" ~/.bash_aliases || echo "alias vim='$HOME/neovim/build/bin/nvim'" >> ~/.bash_aliases
```

### PRE-REQUISITES

For full functionality:

```sh
sudo apt install luarocks ripgrep nodejs npm golang cargo default-jdk-headless default-jre-headless fd-find python3-neovim
sudo npm install -g neovim
```

Make sure node is updated using nvm:

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install --lts
```

Check health of plugins by going into nvim and running:

```bash
:checkhealth
```

You can add additional dependencies if needed.

## OPTIONAL

### INSTALL CATPUCCIN

Navigate to a directory where you want to clone the repo and run:

```bash
git clone https://github.com/catppuccin/gnome-terminal.git
cd gnome-terminal
./install.py
```

### MARKDOWN-PREVIEW

Install markdown preview with npm:

```bash
cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app
npm install
npm audit fix
```

### UPDATING MERMAID.JS

To update mermaid.js, copy the version you want to:

```bash
~/.local/share/nvim/lazy/markdown-preview.nvim/app/_static/
```

Version 11.6.0 is included and can be copied with:

```bash
cp ~/.config/nvim/mermaid-11.6.0.min.js ~/.local/share/nvim/lazy/markdown-preview.nvim/app/_static/
```
