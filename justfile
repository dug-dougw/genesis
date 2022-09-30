# bring in ENV variables (kept in same dir as the justfile)
set dotenv-load


install: sshtest git dotfiles plugins direnv rust_packages

sshtest:
  @if ! ssh -T git@github.com 2>&1|grep -q 'successfully authenticated'; then \
    echo "key for github not valid"; exit 1;\
  fi
  
  # NOT WORKING
  ## add ssh key to sshagent
  #if [ ! -S ~/.ssh/ssh_auth_sock ]; then \
  #  eval `ssh-agent` \
  #  ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock \
  #fi 
  #export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock; \
  #ssh-add -l > /dev/null || ssh-add


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

VCSHDIR := '~/.config/vcsh'
vcshprep:
  # make dirs for vcsh
  @mkdir -p {{VCSHDIR}}/repo.d
  @mkdir -p {{VCSHDIR}}/hooks-enabled
  # fetch the git hook script which vcsh will use
  @module load git/2.37.3; \
  if find {{VCSHDIR}}/hooks-enabled -maxdepth 0 -empty | read v; then \
    git clone -b vcsh --single-branch $CONFIGSREPO {{VCSHDIR}}/hooks-enabled; \
  else \
    cd {{VCSHDIR}}/hooks-enabled; git fetch; \
  fi

# Note that ENV vars don't propagate (can only be used once in a recipe) 
# which is why we are feeding $HOMEBINSDIR to a just var (so that it can be used
# throughout the recipe
VCSH_URL := 'https://github.com/RichiH/vcsh/releases/latest/download/vcsh-standalone.sh'
BIN := env_var('HOMEBINSDIR')
vcsh: vcshprep
  # Install vcsh
  @mkdir -p {{BIN}}
  @curl -fsLS {{VCSH_URL}} -o {{BIN}}/vcsh
  @chmod u+x {{BIN}}/vcsh

dotfiles: vcsh
  # deploy config files for various tools
  @for i in $DOTFILES; do \
    if [ -d {{VCSHDIR}}/repo.d/$i.git ]; then \
      cd {{VCSHDIR}}/repo.d/$i.git; git fetch; \
    else \
      vcsh clone -b $i $CONFIGSREPO $i; \
    fi; \
  done

pluginmanagers:
  # Install plugin managers for tmux and vim
  @if [ ! -d ~/.vim/bundle/Vundle.vim ]; then \
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim; \
  fi
  @if [ ! -d ~/.tmux/plugins/tpm ]; then \
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; \
  fi

plugins: pluginmanagers
  #!/usr/bin/env bash
  # Install vim plugins
  module load vim
  vim +PluginInstall +qall
  # Install tmux plugins
  #module load tmux; tmux new -d
  #tmux source ~/.tmux.conf
  #~/.tmux/plugins/tpm/bin/install_plugins
  
########################################################################### 

direnv: 
  #Install direnv
  #!/usr/bin/env bash
  set -euxo pipefail
  bin_path=$HOMEBINSDIR bash <(/usr/bin/curl -sfL https://direnv.net/install.sh)
  chmod +x $HOMEBINSDIR/direnv
########################################################################### 

rust:
  # Install Rust and cargo, its package manager
  @curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

PACKAGEFILE := './packages_rust.txt'
rust_packages: rust
  # Compile and install some rust binaries/tools
  @for bin in `cat {{PACKAGEFILE}}|awk -F# '{print $1}'`; do cargo install $bin; done

