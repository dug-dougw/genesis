# bring in ENV variables (kept in same dir as the justfile)
set dotenv-load


install: git dotfiles plugins direnv rust_packages


########################################################################### 
# Git plays funny buggers when passing in a string var with a space. 
# So when an ENV var has a space we transmorgify it to a just var.
GIT_NAME := env_var('GIT_COMMITNAME')
GIT_SSH := '"ssh -i ' + env_var('GIT_SSHKEY') + ' -o StrictHostKeyChecking=no -o IdentitiesOnly=yes"'
git:
  # Set up default configs for git
  @git config --global init.defaultBranch main
  @git config --global core.editor $GIT_EDITOR
  @git config --global user.name {{GIT_NAME}}
  @git config --global user.email $GIT_COMMITEMAIL
  @git config --global core.sshCommand {{GIT_SSH}}
# @git config --global alias.tree {{GIT_LOG}}

########################################################################### 

BINS := '~/.local/bin'

VCSHDIR := '~/.config/vcsh'
REPO := 'git@github.com:dug-dougw/configs.git'
vcshprep:
  # make dirs for vcsh
  @mkdir -p {{VCSHDIR}}/repo.d
  @mkdir -p {{VCSHDIR}}/hooks-enabled
  # fetch the git hook script which vcsh will use
  @module load git/2.37.3; \
  if [ "$(ls -A {{VCSHDIR}}/hooks-enabled)" ]; then \
    cd {{VCSHDIR}}/hooks-enabled; git fetch; \
  else \
    git clone -b vcsh --single-branch {{REPO}} {{VCSHDIR}}/hooks-enabled; \
  fi

VCSH_URL := 'https://github.com/RichiH/vcsh/releases/latest/download/vcsh-standalone.sh'
vcsh: vcshprep
  # Install vcsh
  @mkdir -p {{BINS}}
  @curl -fsLS {{VCSH_URL}} -o  {{BINS}}/vcsh
  @chmod u+x ~/.local/bin/vcsh

dotfiles: vcsh
  # deploy config files for various tools
  for i in $DOTFILES; do vcsh clone -b $i $CONFIGSREPO $i; done

pluginmanagers:
  # Install plugin managers for tmux and vim
  if [ ! -d ~/.vim/bundle/Vundle.vim ]; then \
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
  fi
  if [ ! -d ~/.tmux/plugins/tpm ]; then \
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

plugins: pluginmanagers
  # Install vim plugins
  vim +PluginInstall +qall
  # Install tmux plugins
  ~/.tmux/plugins/tpm//bin/install_plugins

########################################################################### 

direnv: 
  #Install direnv
  #!/usr/bin/env bash
  set -euxo pipefail
  bin_path={{BINS}} bash <(/usr/bin/curl -sfL https://direnv.net/install.sh)
  chmod +x {{BINS}}/direnv
########################################################################### 

rust:
  # Install Rust and cargo, its package manager
  @curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

PACKAGEFILE := './packages_rust.txt'
rust_packages: rust
  # Compile and install some rust binaries/tools
  @for bin in `cat {{PACKAGEFILE}}|awk -F# '{print $1}'`; do cargo install $bin; done

