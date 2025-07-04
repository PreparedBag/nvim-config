<style>
@import url('https://fonts.googleapis.com/css2?family=Rubik:ital,wght@0,300..900;1,300..900&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Roboto+Slab:wght@100..900&display=swap');
</style>
    
# nvim-config

## installation

### update neovim

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
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
```

And create an alias to replace 'vim' (Optional):

```bash
alias vim='/opt/nvim-linux-x86_64/bin/nvim'
```

#### arm_64

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
export PATH="$PATH:$HOME/neovim/build/bin"
```

And create an alias to replace 'vim' (Optional):

```bash
alias vim="$HOME/neovim/build/bin/nvim"
```

### pre-requisites

For full functionality:

```sh
sudo apt install luarocks ripgrep nodejs npm golang cargo default-jdk-headless default-jre-headless fd-find
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

## optional

For markdown-preview:

```bash
cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app
npm install
npm audit fix
```

### updating mermaid.js

To update mermaid.js, copy the version you want to:

```
~/.local/share/nvim/lazy/markdown-preview.nvim/app/_static/
```

Version 11.6.0 is included and the latest as of the last commit.
