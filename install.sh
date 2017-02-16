echo "Installing basics..."
sudo dnf install -y ctags curl git vim wget ncurses-devel sysstat screen

echo "Copying dotfiles..."
cp .bashrc ~/.bashrc
cp .vimrc ~/.vimrc
cp .inputrc ~/.inputrc
cp .screenrc ~/.screenrc

mkdir -p ~/.vim
git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git ~/.vim/bundle/ctrlp.vim
git clone --depth=1 https://github.com/majutsushi/tagbar ~/.vim/bundle/tagbar

function die {
	echo >&2 "$@"
	exit 1
}

function upgrade_kernel {
    read -p "Your kernel is too old. Upgrade to latest mainline? [y/N] " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    else
        curl -s https://repos.fedorapeople.org/repos/thl/kernel-vanilla.repo | sudo tee /etc/yum.repos.d/kernel-vanilla.repo
        sudo dnf --enablerepo=kernel-vanilla-mainline update -y
        echo "Reboot into the new kernel and then try this script again."
        exit 1
    fi
}

echo "Checking BPF config flags..."
for flag in CONFIG_BPF CONFIG_BPF_SYSCALL CONFIG_BPF_JIT CONFIG_BPF_EVENTS; do
    sysver=$(uname -r)
    present=`sudo cat /boot/config-$sysver | grep $flag= | cut -d= -f2`
    [[ "$present" = "y" ]] || die "$flag must be set"
done

echo "Checking if this version of Linux is supported..."
(uname -r | grep "fc2[345]" -q) || \
    die "Unsupported Linux version, only Fedora 23/24/25 is currently supported"

echo "Checking if this version of the kernel is supported..."
[[ $(uname -r) =~ ^([0-9]+)\.([0-9]+) ]]
majver=${BASH_REMATCH[1]}
minver=${BASH_REMATCH[2]}
if [[ "$majver" -lt "4" ]]
    then upgrade_kernel
fi
if [[ "$majver" -eq "4" && "$minver" -lt "6" ]]
    then upgrade_kernel
fi

echo "Installing perf and kernel headers..."
sudo dnf --enablerepo=kernel-vanilla-mainline install -y perf
sudo dnf --enablerepo=kernel-vanilla-mainline --best --allowerasing \
     install -y kernel-devel kernel-headers

INSTALL_ROOT=~/src
mkdir -p $INSTALL_ROOT || die "Unable to create installation directory"
pushd $INSTALL_ROOT

git clone https://github.com/goldshtn/bcc
pushd bcc
git remote add upstream https://github.com/iovisor/bcc
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
echo "Installing OpenJDK debuginfo..."
sudo dnf debuginfo-install -y java-1.8.0-openjdk

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
