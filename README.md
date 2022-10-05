TL;DR: \
  cd to wherever you cloned the workstation-genesis repo \
  $ ./init.sh \
  $ just install


An idempotent script that sets up a workstation with vim, tmux (with plugins) 
and a bunch of cargo binaries



$ git clone https://github.com/dug-dougw/workstation-genesis.git /tmp/workstation-genesis
$ /tmp/workstation-genesis/init.sh 
$ /tmp/just /tmp/workstation-genesis/ && rm -rf /tmp/just /tmp/workstation-genesis

