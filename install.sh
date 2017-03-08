#!/bin/bash

echo "Installing basics..."
sudo dnf update -y
sudo dnf install -y ctags curl git vim wget ncurses-devel sysstat screen ack atop

echo "Copying dotfiles..."
$(dirname $0)/install-dotfiles.sh

git config --global user.email "goldshtn@gmail.com"
git config --global user.name "Sasha Goldshtein"

mkdir -p ~/.vim
git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git ~/.vim/bundle/ctrlp.vim
git clone --depth=1 https://github.com/majutsushi/tagbar ~/.vim/bundle/tagbar

function die {
	echo >&2 "$@"
	exit 1
}

echo "Installing perf and kernel headers..."
sudo dnf install -y perf
sudo dnf --best --allowerasing install -y kernel-devel kernel-headers

INSTALL_ROOT=~/src
mkdir -p $INSTALL_ROOT || die "Unable to create installation directory"
pushd $INSTALL_ROOT

git clone https://github.com/goldshtn/bcc
pushd bcc
git remote add upstream https://github.com/iovisor/bcc
git fetch upstream
git merge upstream/master
ctags -R .
popd
git clone --depth=1 https://github.com/brendangregg/FlameGraph
git clone --depth=1 https://github.com/jrudolph/perf-map-agent
git clone --depth=1 https://github.com/brendangregg/perf-tools

echo "Installing build tools..."
sudo dnf install -y systemtap-sdt-devel
sudo dnf install -y bison cmake ethtool flex git iperf libstdc++-static \
  python-netaddr python-pip gcc gcc-c++ make zlib-devel \
  elfutils-libelf-devel
sudo dnf install -y clang clang-devel llvm llvm-devel llvm-static
sudo dnf install -y luajit luajit-devel
sudo pip install pyroute2

NUMPROCS=$(nproc --all)

echo "Building BCC from source..."
mkdir bcc/build; pushd bcc/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j $NUMPROCS
echo "Installing into /usr/share/bcc..."
sudo make install
popd

echo "Installing perf-tools into /usr/share/perf-tools..."
sudo mkdir -p /usr/share/perf-tools
sudo cp -R ./perf-tools/bin /usr/share/perf-tools

echo "Installing OpenJDK..."
sudo dnf install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

echo "Building perf-map-agent..."
pushd perf-map-agent
cmake .
make
bin/create-links-in .
popd

echo "Setting environment variables for PATH and MANPATH..."
sudo bash -c 'cat >> /etc/profile << \EOF
  PATH=$PATH:/usr/share/bcc/tools:/usr/share/perf-tools
  MANPATH=$MANPATH:/usr/share/bcc/man/man8
EOF'

if [[ "$WORKSHOP" == "1" ]]; then
    $(dirname $0)/install-workshop.sh
fi
