simple_setup_manual()
{
    sudo apt-get install git -y
    # If local does not exist
    if [ ! -f ~/local ]; then
        git clone https://github.com/Erotemic/local.git
        cd local/init 
    fi

    source ~/local/init/freshstart_ubuntu.sh && simple_setup_auto
}

simple_setup_auto(){
    "
    Does setup on machines without root access
    "
    # Just in case
    deactivate

    mkdir -p ~/tmp
    mkdir -p ~/code
    cd ~
    ensure_config_symlinks

    source ~/.bashrc

    git config --global user.name joncrall
    #git config --global user.email crallj@rpi.edu
    git config --global user.email jon.crall@kitware.com
    git config --global push.default current

    git config --global core.editor "vim"
    git config --global rerere.enabled true
    git config core.fileMode false
    git config --global alias.co checkout

    git config --global merge.conflictstyle diff3

    setup_venv3
    source ~/venv3/bin/activate

    pip install setuptools --upgrade
    pip install six
    pip install jedi
    pip install ipython
    pip install pep8 autopep8 flake8 pylint line_profiler

    mkdir -p ~/local/vim/vimfiles/bundle
    source ~/local/vim/init_vim.sh
    echo "source ~/local/vim/portable_vimrc" > ~/.vimrc
    python ~/local/init/ensure_vim_plugins.py

    # Install utool
    echo "Installing utool"
    if [ ! -d ~/code/utool ]; then
        git clone -b next http://github.com/Erotemic/utool.git ~/code/utool
    fi
    if [ "$(has_pymodule ubelt)" == "False" ]; then
        pip install -e ~/code/utool
    fi

    echo "Installing ubelt"
    if [ ! -d ~/code/ubelt ]; then
        git clone http://github.com/Erotemic/ubelt.git ~/code/ubelt
    fi
    if [ "$(has_pymodule ubelt)" == "False" ]; then
        pip install -e ~/code/ubelt
    fi

    git clone http://github.com/Erotemic/networkx.git ~/code/networkx
    pip install -e ~/code/networkx

    python ~/local/init/init_ipython_config.py

}




entry_prereq_git_and_local()
{
    # This is usually done manually
    sudo apt-get install git -y
    cd ~

    # sudo usermod -l newUsername oldUsername
    # usermod -d /home/newHomeDir -m newUsername

    # If on a new computer, then make a new ssh key
    
    if [[ "$HOSTNAME" == "calculex"  ]]; then 
        cd ~/.ssh
        ssh-keygen -t rsa -b 4096 -C "jon.crall@kitware.com"

        # Add new key to ssh agent if it is already running

        ssh-add
        # Manual Step:
        # Add key to github https://github.com/settings/keys
    fi


    # Fix ssh keys if you have them
    ls -al ~/.ssh
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/known_hosts
    chmod 600 ~/.ssh/config
    chmod 400 ~/.ssh/id_rsa*

    # If local does not exist
    if [ ! -f ~/local ]; then
        git clone https://github.com/Erotemic/local.git
        cd local/init 
    fi
}


have_sudo(){
    python -c "$(codeblock "
        import grp, pwd 
        user = '$(whoami)'
        groups = [g.gr_name for g in grp.getgrall() if user in g.gr_mem]
        gid = pwd.getpwnam(user).pw_gid
        groups.append(grp.getgrgid(gid).gr_name)
        print('sudo' in groups)
    ")"
}


has_pymodule(){
    if [ "$2" ]; then
        PYEXE="$1"
        PYMOD="$2"
    else
        PYEXE=python
        PYMOD="$1"
    fi
    $PYEXE -c "$(codeblock "
        try:
            import $PYMOD
            print(True)
        except ImportError:
            print(False)
    ")"
}

ensure_config_symlinks()
{
    "
    CommandLine:
        source ~/local/init/freshstart_ubuntu.sh && ensure_config_symlinks

    "

    HAVE_SUDO=$(have_sudo)

    if [ "$(which symlinks)" == "" ]; then
        # Program to remove dead symlinks
        if [ "$HAVE_SUDO" == "True" ]; then 
            sudo apt-get install symlinks -y
        fi
        if [ "$(which symlinks)" == "" ]; then
            # bypass symlinks
            alias symlinks=echo "bypass symlinks not installed"
        fi
    fi

    # TODO: make symbolic links relative to the home directory

    echo "==============================="
    echo "STARTING ensure_config_symlinks"
    echo "==============================="


    # Try to link relative to home
    cd $HOME
    #RELHOME="~"

    # If that doesnt work use absolute home link
    RELHOME="$HOME"
    
    HOMELINKS=$RELHOME/local/homelinks

    # Symlink all homelinks files 
    #================
    BASEDIR=""
    # NOTE: these path names are files
    PNAMES=$(/bin/ls -Ap $HOMELINKS/$BASEDIR | grep -v /)
    echo "* SYMLINK BASEDIR=$BASEDIR"
    #echo "* PNAMES=$PNAMES"
    echo "* --- BEGIN ---"
    echo "* mkdir"
    mkdir -pv $RELHOME/.$BASEDIR
    echo "* cleanup"
    symlinks -d $RELHOME/.$BASEDIR
    echo "* symlink"
    for p in $PNAMES; do 
        SOURCE=$HOMELINKS/$BASEDIR$p
        TARGET=$RELHOME/.$BASEDIR$p
        if [ -L $TARGET ]; then
            unlink $TARGET
        else
            mv $TARGET $TARGET."$(date +"%T")".old
        fi
        ln -vs $SOURCE $TARGET;
    done
    echo "* Convert to relative symlinks"
    symlinks -c $RELHOME/.$BASEDIR
    echo "* --- END ---"
    #================

    # Symlink nautlius scripts
    #================
    BASEDIR="gnome2/nautilus-scripts/"
    # NOTE: these path names are files
    PNAMES=$(/bin/ls -Ap $HOMELINKS/$BASEDIR | grep -v /)
    echo "* SYMLINK BASEDIR=$BASEDIR"
    #echo "* PNAMES=$PNAMES"
    echo "* --- BEGIN ---"
    echo "* mkdir"
    mkdir -pv $RELHOME/.$BASEDIR
    echo "* cleanup"
    symlinks -d $RELHOME/.$BASEDIR
    echo "* symlink"
    for p in $PNAMES; do 
        SOURCE=$HOMELINKS/$BASEDIR$p
        TARGET=$RELHOME/.$BASEDIR$p
        if [ -L $TARGET ]; then
            unlink $TARGET
        else
            mv $TARGET $TARGET."$(date +"%T")".old
        fi
        ln -vs $SOURCE $TARGET;
    done
    echo "* Convert to relative symlinks"
    symlinks -c $RELHOME/.$BASEDIR
    echo "* --- END ---"
    #================

    # Symlink config subdirs (note these are directories)
    #================
    BASEDIR="config/"
    # NOTE: these path names are directories
    PNAMES=$(/bin/ls -A $HOMELINKS/$BASEDIR)
    echo "* SYMLINK BASEDIR=$BASEDIR"
    #echo "* PNAMES=$PNAMES"
    echo "* --- BEGIN ---"
    echo "* mkdir"
    mkdir -pv $RELHOME/.$BASEDIR
    echo "* cleanup"
    symlinks -d $RELHOME/.$BASEDIR
    echo "* symlink"
    for p in $PNAMES; do 
        SOURCE=$HOMELINKS/$BASEDIR$p
        TARGET=$RELHOME/.$BASEDIR$p
        if [ -L $TARGET ]; then
            unlink $TARGET
        else
            mv $TARGET $TARGET."$(date +"%T")".old
        fi
        ln -vs $SOURCE $TARGET;
    done
    echo "* Convert to relative symlinks"
    symlinks -c $RELHOME/.$BASEDIR
    echo "* --- END ---"
    #================

    # Extras

    if [ ! -L ~/.vim ]; then
        ln -s ~/local/vim/vimfiles ~/.vim
        symlinks -c ~
        symlinks -d ~/.vim/
        mkdir -p ~/local/vim/vimfiles/files/info
    fi
    if [ -d ~/scripts ]; then
        unlink ~/scripts
    fi
    ln -s ~/local/scripts ~/scripts
    

    echo "==============================="
    echo "FINISHED ensure_config_symlinks"
    echo "==============================="
}

freshtart_ubuntu_script()
{ 
    "
    CommandLine:
        source ~/local/init/freshstart_ubuntu.sh
        freshtart_ubuntu_script
    "
    mkdir -p ~/tmp
    mkdir -p ~/code
    cd ~
    if [ ! -d ~/local ]; then
        git clone https://github.com/Erotemic/local.git
    fi

    sudo apt-get install symlinks -y

    source ~/local/init/freshstart_ubuntu.sh
    ensure_config_symlinks

    source ~/.bashrc

    git config --global user.name joncrall
    #git config --global user.email crallj@rpi.edu
    git config --global user.email jon.crall@kitware.com
    git config --global push.default current

    git config --global core.editor "vim"
    git config --global rerere.enabled true
    git config core.fileMode false
    git config --global alias.co checkout

    make_sshkey

    #sudo apt-get install trash-cli
    sudo apt-get install -y exuberant-ctags 

    # Vim
    #sudo apt-get install -y vim
    #sudo apt-get install -y vim-gtk
    sudo apt-get install -y vim-gnome

    # Terminal settings
    #sudo apt-get install terminator -y

    if [ "$(which terminator)" == "" ]; then
        # Dont use buggy gtk2 version 
        # https://bugs.launchpad.net/ubuntu/+source/terminator/+bug/1568132

        #sudo add-apt-repository ppa:gnome-terminator
        #sudo apt-get update
        #sudo apt-get install terminator -y
        #cat /etc/apt/sources.list
        #sudo apt remove terminator
        #sudo add-apt-repository --remove ppa:gnome-terminator

        sudo add-apt-repository ppa:gnome-terminator/nightly-gtk3
        sudo apt-get update
        sudo apt-get install terminator -y
    fi

    # Development Environment
    sudo apt-get install gcc g++ gfortran build-essential -y
    sudo apt-get install -y python3-dev python3-tk

    #sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 10

    # Python 
    setup_venv3
    source ~/venv3/bin/activate

    pip install setuptools --upgrade
    pip install six
    pip install jedi
    pip install ipython
    pip install pep8 autopep8 flake8 pylint line_profiler

    mkdir -p ~/local/vim/vimfiles/bundle
    source ~/local/vim/init_vim.sh
    #mkdir ~/.vim_tmp
    echo "source ~/local/vim/portable_vimrc" > ~/.vimrc
    python ~/local/init/ensure_vim_plugins.py

    source ~/local/init/ubuntu_core_packages.sh

    # Get latex docs
    cd ~/latex
    if [ ! -f ~/latex ]; then
        mkdir -p ~/latex
        git clone git@hyrule.cs.rpi.edu.com:crall-candidacy-2015.git
    fi

    # Install machine specific things

    if [[ "$HOSTNAME" == "hyrule"  ]]; then 
        echo "SETUP HYRULE STUFF"
        customize_sudoers
        source settings_hyrule.sh
        hyrule_setup_sshd
        hyrule_setup_fstab
        hyrule_create_users
    elif [[ "$HOSTNAME" == "Ooo"  ]]; then 
        echo "SETUP Ooo STUFF"
        install_dropbox
        customize_sudoers
        nautilus_settings
        gnome_settings
        install_chrome
        # Make sure dropbox has been initialized first
        install_fonts

        # 
        install_spotify
    else
        echo "UNKNOWN HOSTNAME"
    fi

    # Extended development environment
    sudo apt-get install -y pkg-config
    sudo apt-get install -y libtk-img-dev
    sudo apt-get install -y libblas-dev liblapack-dev
    sudo apt-get install -y libav-tools libgeos-dev 
    sudo apt-get install -y libfftw3-dev libfreetype6-dev 
    sudo apt-get install -y libatlas-base-dev liblcms1-dev zlib1g-dev
    sudo apt-get install -y libjpeg-dev libopenjpeg-dev libpng12-dev libtiff5-dev

    pip install numpy
    pip install scipy
    pip install Cython
    pip install pandas
    pip install requests

    pip install six
    pip install parse
    pip install Pygments
    pip install colorama

    pip install matplotlib

    pip install statsmodels
    pip install scikit-learn

    #pip install functools32
    #pip install psutil
    #pip install dateutils
    #pip install pyreadline
    #pip install pyparsing
    
    #pip install networkx

    #pip install simplejson
    #pip install flask
    #pip install flask-cors

    #pip install lockfile
    #pip install lru-dict
    #pip install shapely

    # pydot is currently broken
    #http://stackoverflow.com/questions/15951748/pydot-and-graphviz-error-couldnt-import-dot-parser-loading-of-dot-files-will
    #pip uninstall pydot
    pip uninstall pyparsing
    pip install -Iv 'https://pypi.python.org/packages/source/p/pyparsing/pyparsing-1.5.7.tar.gz#md5=9be0fcdcc595199c646ab317c1d9a709'
    pip install pydot
    python -c "import pydot"

    # Ubuntu hack for pyqt4
    # http://stackoverflow.com/questions/15608236/eclipse-and-google-app-engine-importerror-no-module-named-sysconfigdata-nd-u
    #sudo apt-get install python-qt4-dev
    #sudo apt-get remove python-qt4-dev
    #sudo apt-get remove python-qt4
    #sudo ln -s /usr/lib/python2.7/plat-*/_sysconfigdata_nd.py /usr/lib/python2.7/
    #python -c "import PyQt4"
    # TODO: install from source this is weird it doesnt work
    # sudo apt-get autoremove

    # Install utool
    if [ ! -d ~/code/utool ]; then
        git clone git@github.com:Erotemic/utool.git ~/code/utool
        pip install -e ~/code/utool
    fi

    if [ ! -d ~/code/ubelt ]; then
        git clone git@github.com:Erotemic/ubelt.git ~/code/ubelt
        pip install -e ~/code/ubelt
    fi

    git clone git@github.com:Erotemic/networkx.git ~/code/networkx
    pip install -e ~/code/networkx

    python ~/local/init/init_ipython_config.py
}

ensure_curl(){
    HAVE_SUDO=$(have_sudo)
    if [ "$(which curl)" == "" ]; then
        echo "Need to install curl"
        if [ "$HAVE_SUDO" == "True" ]; then
            sudo apt-get install curl -y
        else
            echo "Cannot install curl without sudo"
        fi
    fi
}

setup_venv3(){
    "
    CommandLine:
        source ~/local/init/freshstart_ubuntu.sh && setup_venv3
    "
    # Ensure PIP, setuptools, and virtual are on the SYSTEM
    if [ "$(has_pymodule python3 pip)" == "False" ]; then
    #if [ "$(which pip3)" == "" ]; then
        ensure_curl
        curl https://bootstrap.pypa.io/get-pip.py > ~/tmp/get-pip.py
        python3 ~/tmp/get-pip.py --user
    fi
    python3 -m pip install pip setuptools virtualenv -U --user

    PYTHON3_VENV="$HOME/venv3"
    mkdir -p $PYTHON3_VENV
    python3 -m virtualenv -p /usr/bin/python3 $PYTHON3_VENV
    python3 -m virtualenv --relocatable $PYTHON3_VENV 
    # source $PYTHON3_VENV/bin/activate

    # Now ensure the correct pip is installed locally
    #pip3 --version
    # should be for 3.x
}


setup_venv2(){
    "
    CommandLine:
        source ~/local/init/freshstart_ubuntu.sh && setup_venv2
    "
    # ENSURE SYSTEM PIP IS SAME AS SYSTEM PYTHON
    # sudo update-alternatives --set pip /usr/local/bin/pip2.7
    # sudo rm /usr/local/bin/pip
    # sudo ln -s /usr/local/bin/pip2.7 /usr/local/bin/pip
    echo "setup venv2"

    if [ "$(has_pymodule python2 pip)" == "False" ]; then
    #if [ "$(which pip2)" == "" ]; then
        ensure_curl
        curl https://bootstrap.pypa.io/get-pip.py > ~/tmp/get-pip.py
        python2 ~/tmp/get-pip.py --user
    fi
    PYTHON2_VENV="$HOME/venv2"
    mkdir -p $PYTHON2_VENV
    python2.7 -m pip install pip setuptools virtualenv -U --user
    python2.7 -m virtualenv -p $(which python2.7) $PYTHON2_VENV 
    #python2 -m virtualenv -p /usr/bin/python2.7 $PYTHON2_VENV 
    #python2 -m virtualenv --relocatable $PYTHON2_VENV 
}


codeblock()
{
    if [ "-h" == "$1" ] || [ "--help" == "$1" ]; then 
        # Use codeblock to show the usage of codeblock, so you can use
        # codeblock while you codeblock.
        echo "$(codeblock '
            Unindents code before its executed so you can maintain a pretty
            indentation in your code file. Multiline strings simply begin  
            with 
                "$(codeblock "
            and end with 
                ")"

            Example:
               echo "$(codeblock "
                    a long
                    multiline string.
                    this is the last line that will be considered.
                    ")"
        ')"
    else
        # Prevents python indentation errors in bash
        #python -c "from textwrap import dedent; print(dedent('''$1''').strip('\n'))"
        echo "$1" | python -c "import sys; from textwrap import dedent; print(dedent(sys.stdin.read()).strip('\n'))"
    fi
}

__heredoc__(){
    echo "$@" > /dev/null
}



patch_venv_with_shared_libs(){
    __heredoc__ "
    References:
        https://github.com/pypa/virtualenv/pull/1045/files
    "

    python -c "$(codeblock "
        import shutil
        import os
        import sys
        from os.path import join

        def is_relative_lib():
            # Check if the python was compiled with LDFLAGS -rpath and $ORIGIN
            import distutils
            ldflags_var = distutils.sysconfig.get_config_var('LDFLAGS')
            if ldflags_var is None:
                return False
            ldflags = ldflags_var.split(',')
            n_flags = len(ldflags)
            idx = 0
            while idx < n_flags - 1:
                flag = ldflags[idx]
                if flag == '-rpath':
                    # rpath can contain multiple entries:
                    rpaths = ldflags[idx+1].split(os.pathsep)
                    for rpath in rpaths:
                        rpath = rpath.strip()
                        if rpath.startswith(''''$'ORIGIN'''):
                            return True
                    idx += 1
                idx += 1
            return False

        def copyfile(src, dest, symlink=True):
            if not os.path.exists(src):
                # Some bad symlink in the src
                print('Cannot find file %s (bad symlink)' % src)
                return
            if os.path.exists(dest):
                print('File %s already exists' % dest)
                return
            if not os.path.exists(os.path.dirname(dest)):
                print('Creating parent directories for %s' % os.path.dirname(dest))
                os.makedirs(os.path.dirname(dest))
            if not os.path.islink(src):
                srcpath = os.path.abspath(src)
            else:
                srcpath = os.readlink(src)
            if symlink and hasattr(os, 'symlink') and not is_win:
                print('Symlinking %s' % dest)
                try:
                    os.symlink(srcpath, dest)
                except (OSError, NotImplementedError):
                    print('Symlinking failed, copying to %s' % dest)
                    copyfileordir(src, dest, symlink)
            else:
                print('Copying to %s' % dest)
                copyfileordir(src, dest, symlink)

        def copyfileordir(src, dest, symlink=True):
            if os.path.isdir(src):
                shutil.copytree(src, dest, symlink)
            else:
                shutil.copy2(src, dest)
                    
        def install_shared(bin_dir, symlink=True):
            # copy (symlink by default) the python shared library to the target
            print('Installing shared lib...')

            sys.real_prefix
            real_executable = join(sys.real_prefix, os.path.relpath(sys.executable, sys.prefix))

            current_shared = os.path.realpath(join(os.path.dirname(real_executable), '..', 'lib'))

            target_shared = os.path.normpath(join(bin_dir, '..', 'lib'))

            import glob

            lib_subdirs = ['', 'x86_64-linux-gnu', 'i386-linux-gnu']
            for subdir in lib_subdirs:
                major = sys.version_info.major
                minor = sys.version_info.minor
                libfiles = list(glob.glob(join(current_shared, subdir, 'libpython*{}.{}*'.format(major, minor))))
                if libfiles:
                    break

            assert len(libfiles) > 0, 'no python libs found' 

            for libpython in libfiles:
                target_file = join(target_shared, os.path.basename(libpython))

                copyfile(libpython, target_file)
                
            print('done.')

        bin_dir = join(os.environ['VIRTUAL_ENV'], 'bin')  # hack
        install_shared(bin_dir, symlink=True)
    ")"
}

patch_venv_with_ld_library(){
    __heredoc__ "
    CommandLine:
        source ~/local/init/freshstart_ubuntu.sh && patch_venv_with_ld_library

    References:
        https://github.com/pypa/virtualenv/pull/1045
        https://github.com/bastibe/lunatic-python/issues/35

    Ignore:
        # FIXME:
        ln -s /usr/lib/python2.7/config-x86_64-linux-gnu ~/venv2/lib
        ln -s /usr/lib/python2.7/config-x86_64-linux-gnu_d ~/venv2/lib
    "
    ACTIVATE_SCRIPT=$VIRTUAL_ENV/bin/activate

    # apply the patch 
    python -c "$(codeblock "
        import textwrap
        from os.path import exists
        new_path = '$ACTIVATE_SCRIPT'
        old_path = '$ACTIVATE_SCRIPT.old'
        if not exists(old_path):
            import shutil
            shutil.copy(new_path, old_path)

        text = open(old_path, 'r').read()
        lines = text.splitlines(True)

        def absindent(text, prefix=''):
            text = textwrap.dedent(text).lstrip()
            text = prefix + prefix.join(text.splitlines(True))
            return text.splitlines(True)

        if len(lines) != 78:
            # hacky way of preventing extra patches
            print('length of file {} is unexpected'.format(new_path))
        else:
            print('patching {}'.format(new_path))
            new_lines = []
            for old_lineno, line in enumerate(lines, start=1):
                new_lines.append(line)
                if old_lineno == 10:
                    new_lines.extend(absindent('''
                            C_INCLUDE_PATH=\"\$_OLD_C_INCLUDE_PATH\"
                            LD_LIBRARY_PATH=\"\$_OLD_VIRTUAL_LD_LIBRARY_PATH\"

                        ''', ' ' * 8))
                elif old_lineno == 11:
                    new_lines.extend(absindent('''
                            export C_INCLUDE_PATH
                            export LD_LIBRARY_PATH

                            unset _OLD_C_INCLUDE_PATH
                            unset _OLD_VIRTUAL_LD_LIBRARY_PATH
                        ''', ' ' * 8))
                elif old_lineno == 46:
                    new_lines.extend(absindent('''
                            _OLD_C_INCLUDE_PATH=\"\$C_INCLUDE_PATH\"
                            _OLD_VIRTUAL_LD_LIBRARY_PATH=\"\$LD_LIBRARY_PATH\"

                        '''))
                elif old_lineno == 47:
                    new_lines.extend(absindent('''
                            C_INCLUDE_PATH=\"\$VIRTUAL_ENV/include:\$C_INCLUDE_PATH\"
                            LD_LIBRARY_PATH=\"\$VIRTUAL_ENV/lib:\$LD_LIBRARY_PATH\"

                        '''))
                elif old_lineno == 48:
                    new_lines.extend(absindent('''
                            export C_INCLUDE_PATH
                            export LD_LIBRARY_PATH
                        '''))
            new_text = ''.join(new_lines)
            open(new_path, 'w').write(new_text)
    ")"
    #diff -u $VIRTUAL_ENV/bin/activate.old $VIRTUAL_ENV/bin/activate 
}

setup_venv37(){
    echo "setup venv37"
    # Make sure you install 3.7 to ~/.local from source
    PYTHON3_VENV="$HOME/venv3_7"
    mkdir -p $PYTHON3_VENV
    ~/.local/bin/python3 -m venv $PYTHON3_VENV
    ln -s $PYTHON3_VENV ~/venv3 

}

setupt_venvpypy(){
    echo "setup venvpypy"

    PYPY_VENV="$HOME/venvpypy"
    mkdir -p $PYPY_VENV
    virtualenv-3.4 -p /usr/bin/pypy $PYPY_VENV 

    pypy -m ensurepip
    sudo apt-get install pypy-pip
}

install_chrome()
{
    # Google PPA
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt-get update
    # Google Chrome
    sudo apt-get install -y google-chrome-stable 
}


install_fonts()
{
    # Download fonts
    sudo apt-get -y install nautilus-dropbox

    mkdir -p ~/tmp 
    cd ~/tmp
    wget https://github.com/antijingoist/open-dyslexic/archive/master.zip
    7z x master.zip

    wget https://downloads.sourceforge.net/project/cm-unicode/cm-unicode/0.7.0/cm-unicode-0.7.0-ttf.tar.xz
    7z x cm-unicode-0.7.0-ttf.tar.xz && 7z x cm-unicode-0.7.0-ttf.tar && rm cm-unicode-0.7.0-ttf.tar

    _SUDO ""
    FONT_DIR=$HOME/.fonts

    #_SUDO sudo
    #FONT_DIR=/usr/share/fonts

    TTF_FONT_DIR=$FONT_DIR/truetype
    OTF_FONT_DIR=$FONT_DIR/truetype

    mkdir -p $TTF_FONT_DIR
    mkdir -p $OTF_FONT_DIR

    $_SUDO cp -v ~/Dropbox/Fonts/*.ttf $TTF_FONT_DIR/
    $_SUDO cp -v ~/Dropbox/Fonts/*.otf $OTF_FONT_DIR/
    $_SUDO cp -v ~/tmp/open-dyslexic-master/otf/*.otf $OTF_FONT_DIR/
    $_SUDO cp -v ~/tmp/cm-unicode-0.7.0/*.ttf $TTF_FONT_DIR/

    $_SUDO fc-cache -f -v

    # Delete matplotlib cache if you install new fonts
    rm ~/.cache/matplotlib/fontList*
}

virtualbox_ubuntu_init()
{
    sudo apt-get install dkms 
    sudo apt-get update
    sudo apt-get upgrade
    # Press Ctrl+D to automatically install virtualbox addons do this
    sudo apt-get install virtualbox-guest-additions-iso
    sudo apt-get install dkms build-essential linux-headers-generic
    sudo apt-get install build-essential linux-headers-$(uname -r)
    sudo apt-get install virtualbox-ose-guest-x11
    # setup virtualbox for ssh
    VBoxManage modifyvm virtual-ubuntu --natpf1 "ssh,tcp,,3022,,22"
}

customize_sudoers()
{ 
    # References: http://askubuntu.com/questions/147241/execute-sudo-without-password
    # Make timeout for sudoers a bit longer
    sudo cat /etc/sudoers > ~/tmp/sudoers.next  
    sed -i 's/^Defaults.*env_reset/Defaults    env_reset, timestamp_timeout=480/' ~/tmp/sudoers.next 
    # Copy over the new sudoers file
    sudo visudo -c -f ~/tmp/sudoers.next
    if [ "$?" -eq "0" ]; then
        sudo cp ~/tmp/sudoers.next /etc/sudoers
    fi 
    rm ~/tmp/sudoers.next
    #cat ~/tmp/sudoers.next  
    #sudo cat /etc/sudoers 
} 


nopassword_on_sudo()
{ 
    # CAREFUL. THIS IS HUGE SECURITY RISK
    # References: http://askubuntu.com/questions/147241/execute-sudo-without-password
    sudo cat /etc/sudoers > ~/tmp/sudoers.next  
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> ~/tmp/sudoers.next  
    # Copy over the new sudoers file
    visudo -c -f ~/tmp/sudoers.next
    if [ "$?" -eq "0" ]; then
        sudo cp ~/tmp/sudoers.next /etc/sudoers
    fi 
    rm ~/tmp/sudoers.next
} 

 
gnome_settings()
{
    # NOTE: mouse scroll wheel behavior was fixed by unplugging and replugging
    # the mouse. Odd. 

    #gconftool-2 --all-dirs "/"
    #gconftool-2 --all-dirs "/desktop/url-handlers"
    #gconftool-2 -a "/desktop/url-handlers"
    #gconftool-2 -a "/desktop/applications"
    #gconftool-2 --all-dirs "/schemas/desktop"
    #gconftool-2 --all-dirs "/apps"
    #gconftool-2 -R /desktop
    #gconftool-2 -R /
    #gconftool-2 --get /apps/nautilus/preferences/desktop_font
    #gconftool-2 --get /desktop/gnome/interface/monospace_font_name

    #gconftool-2 -a "/apps/gnome-terminal/profiles/Default" 
    #gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    #sudo -u gdm gconftool-2 --type=bool --set /desktop/gnome/sound/event_sounds false
    #sudo apt-get install -y gnome-tweak-tool

    gconftool-2 --set "/apps/gnome-terminal/profiles/Default/background_color" --type string "#1111111"
    gconftool-2 --set "/apps/gnome-terminal/profiles/Default/foreground_color" --type string "#FFFF6999BBBB"
    gconftool-2 --set /apps/gnome-screensaver/lock_enabled --type bool false
    gconftool-2 --set /desktop/gnome/sound/event_sounds --type=bool false

    # try and disable password after screensaver lock
    gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    gsettings set org.gnome.desktop.screensaver lock-enabled false


    # Fix search in nautilus (remove recurison)
    # http://askubuntu.com/questions/275883/traditional-search-as-you-type-on-newer-nautilus-versions
    gsettings set org.gnome.nautilus.preferences enable-interactive-search true
    #gsettings set org.gnome.nautilus.preferences enable-interactive-search false

    gconftool-2 --get /apps/gnome-screensaver/lock_enabled 
    gconftool-2 --get /desktop/gnome/sound/event_sounds

    #sudo apt-get install nautilus-open-terminal
}


nautilus_settings()
{
    # Get rid of anyonying nautilus sidebar items
    echo "Get Rid of anoying sidebar items"
    chmod +w ~/.config/user-dirs.dirs
    sed -i 's/XDG_TEMPLATES_DIR/#XDG_TEMPLATES_DIR/' ~/.config/user-dirs.dirs 
    sed -i 's/XDG_PUBLICSHARE_DIR/#XDG_PUBLICSHARE_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_DOCUMENTS_DIR/#XDG_DOCUMENTS_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_MUSIC_DIR/#XDG_MUSIC_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_PICTURES_DIR/#XDG_PICTURES_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_VIDEOS_DIR/#XDG_VIDEOS_DIR/' ~/.config/user-dirs.dirs
    echo "enabled=true" >> ~/.config/user-dirs.conf
    chmod -w ~/.config/user-dirs.dirs
    #cat ~/.config/user-dirs.conf 
    #cat ~/.config/user-dirs.dirs 
    #cat ~/.config/user-dirs.locale
    #cat /etc/xdg/user-dirs.conf 
    #cat /etc/xdg/user-dirs.defaults 
    ###
    sudo sed -i 's/TEMPLATES/#TEMPLATES/'     /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/PUBLICSHARE/#PUBLICSHARE/' /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/DOCUMENTS/#DOCUMENTS/'     /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/MUSIC/#MUSIC/'             /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/PICTURES/#PICTURES/'       /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/VIDEOS/#VIDEOS/'           /etc/xdg/user-dirs.defaults 
    ###
    sudo sed -i "s/enabled=true/enabled=false/" /etc/xdg/user-dirs.conf
    sudo echo "enabled=false" >> /etc/xdg/user-dirs.conf
    sudo sed -i "s/enabled=true/enabled=false/" /etc/xdg/user-dirs.conf
    xdg-user-dirs-gtk-update

    #echo "Get Open In Terminal in context menu"
    #sudo apt-get install nautilus-open-terminal -y

    # Tree view for nautilus
    gsettings set org.gnome.nautilus.window-state side-pane-view "tree"


    #http://askubuntu.com/questions/411430/open-the-parent-folder-of-a-symbolic-link-via-right-click

    mkdir -p ~/.gnome2/nautilus-scripts
}

setup_ibeis()
{
    mkdir -p ~/code
    cd ~/code
    if [ ! -f ~/ibeis ]; then
        git clone https://github.com/Erotemic/ibeis.git
    fi
    cd ~/code/ibeis
    git pull
    git checkout next
    ./_scripts/bootstrap.py
    ./_scripts/__install_prereqs__.sh
    ./super_setup.py --build --develop
    ./super_setup.py --checkout next
    ./super_setup.py --build --develop

    # Options
    ./_scripts/bootstrap.py --no-syspkg --nosudo

    cd 
    IBEIS_WORK_DIR="$(python -c 'import ibeis; print(ibeis.get_workdir())')"
    echo $IBEIS_WORK_DIR
    ln -s $IBEIS_WORK_DIR  work
}


setup_development_environment(){
    "
    CommandLine:
        source ~/local/init/freshstart_ubuntu.sh
        setup_development_environment
    "

    pip install bs4
    pip install pyperclip

    python ~/local/init/ensure_vim_plugins.py
    python ~/local/init/ensure_repos.py

    # Install utool
    cd ~/code
    if [ ! -f ~/utool ]; then
        git clone git@github.com:Erotemic/utool.git
        cd utool
        pip install -e .
    fi

    # Get latex docs
    cd ~/latex
    if [ ! -f ~/latex ]; then
        mkdir -p ~/latex
        git clone git@hyrule.cs.rpi.edu.com:crall-candidacy-2015.git
    fi

    # Install machine specific things

    if [[ "$HOSTNAME" == "hyrule"  ]]; then 
        echo "SETUP HYRULE STUFF"
        customize_sudoers
        source settings_hyrule.sh
        hyrule_setup_sshd
        hyrule_setup_fstab
        hyrule_create_users
    elif [[ "$HOSTNAME" == "Ooo"  ]]; then 
        echo "SETUP Ooo STUFF"
        install_dropbox
        customize_sudoers
        nautilus_settings
        gnome_settings
        install_chrome
        # Make sure dropbox has been initialized first
        install_fonts

        # 
        install_spotify
    else
        echo "UNKNOWN HOSTNAME"
    fi

    # Extended development environment
    sudo apt-get install -y pkg-config
    sudo apt-get install -y libtk-img-dev
    sudo apt-get install -y libav-tools libgeos-dev 
    sudo apt-get install -y libfftw3-dev libfreetype6-dev 
    sudo apt-get install -y libatlas-base-dev liblcms1-dev zlib1g-dev
    sudo apt-get install -y libjpeg-dev libopenjpeg-dev libpng12-dev libtiff5-dev

    # Commonly used and frequently forgotten
    sudo apt-get install -y wmctrl xsel xdotool xclip
    sudo apt-get install -y gparted htop tree
    sudo apt-get install -y tmux astyle
    sudo apt-get install -y synaptic okular
    sudo apt-get install -y openssh-server

    sudo apt-get install -y valgrind synaptic vlc gitg expect
    sudo apt-get install sshfs -y

    pip install numpy
    pip install scipy
    pip install Cython
    pip install pandas
    pip install statsmodels
    pip install scikit-learn

    pip install matplotlib

    pip install functools32
    pip install psutil
    pip install six
    pip install dateutils
    pip install pyreadline
    #pip install pyparsing
    pip install parse
    
    pip install networkx
    pip install Pygments
    pip install colorama

    pip install requests
    pip install simplejson
    pip install flask
    pip install flask-cors

    pip install lockfile
    pip install lru-dict
    pip install shapely

    # pydot is currently broken
    #http://stackoverflow.com/questions/15951748/pydot-and-graphviz-error-couldnt-import-dot-parser-loading-of-dot-files-will
    #pip uninstall pydot
    pip uninstall pyparsing
    pip install -Iv 'https://pypi.python.org/packages/source/p/pyparsing/pyparsing-1.5.7.tar.gz#md5=9be0fcdcc595199c646ab317c1d9a709'
    pip install pydot
    python -c "import pydot"

    # Ubuntu hack for pyqt4
    # http://stackoverflow.com/questions/15608236/eclipse-and-google-app-engine-importerror-no-module-named-sysconfigdata-nd-u
    #sudo apt-get install python-qt4-dev
    #sudo apt-get remove python-qt4-dev
    #sudo apt-get remove python-qt4
    #sudo ln -s /usr/lib/python2.7/plat-*/_sysconfigdata_nd.py /usr/lib/python2.7/
    #python -c "import PyQt4"
    # TODO: install from source this is weird it doesnt work
    # sudo apt-get autoremove
    
    pip install bs4
    ./
    

    if [ "$(which cmake)" == "" ]; then
        python ~/local/build_scripts/init_cmake_latest.py
    fi
}


local_apt(){
    #--------
    # apt-get without root permissions
    PKG_NAME=tmux
    apt download $PKG_NAME
    PKG_DEB=$(echo $PKG_NAME*.deb)
    # Cant get this to work
    dpkg -i $PKG_DEB --force-not-root --root=$HOME 
    #--------
}

install_chrome()
{
    # Google PPA
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt-get update
    # Google Chrome
    sudo apt-get install -y google-chrome-stable 
}


install_fonts()
{
    # Download fonts
    sudo apt-get -y install nautilus-dropbox

    mkdir -p ~/tmp 
    cd ~/tmp
    wget https://github.com/antijingoist/open-dyslexic/archive/master.zip
    7z x master.zip

    wget https://downloads.sourceforge.net/project/cm-unicode/cm-unicode/0.7.0/cm-unicode-0.7.0-ttf.tar.xz
    7z x cm-unicode-0.7.0-ttf.tar.xz && 7z x cm-unicode-0.7.0-ttf.tar && rm cm-unicode-0.7.0-ttf.tar

    _SUDO ""
    FONT_DIR=$HOME/.fonts

    #_SUDO sudo
    #FONT_DIR=/usr/share/fonts

    TTF_FONT_DIR=$FONT_DIR/truetype
    OTF_FONT_DIR=$FONT_DIR/truetype

    mkdir -p $TTF_FONT_DIR
    mkdir -p $OTF_FONT_DIR

    $_SUDO cp -v ~/Dropbox/Fonts/*.ttf $TTF_FONT_DIR/
    $_SUDO cp -v ~/Dropbox/Fonts/*.otf $OTF_FONT_DIR/
    $_SUDO cp -v ~/tmp/open-dyslexic-master/otf/*.otf $OTF_FONT_DIR/
    $_SUDO cp -v ~/tmp/cm-unicode-0.7.0/*.ttf $TTF_FONT_DIR/

    $_SUDO fc-cache -f -v

    # Delete matplotlib cache if you install new fonts
    rm ~/.cache/matplotlib/fontList*
}

customize_sudoers()
{ 
    # References: http://askubuntu.com/questions/147241/execute-sudo-without-password
    # Make timeout for sudoers a bit longer
    sudo cat /etc/sudoers > ~/tmp/sudoers.next  
    sed -i 's/^Defaults.*env_reset/Defaults    env_reset, timestamp_timeout=480/' ~/tmp/sudoers.next 
    # Copy over the new sudoers file
    sudo visudo -c -f ~/tmp/sudoers.next
    if [ "$?" -eq "0" ]; then
        sudo cp ~/tmp/sudoers.next /etc/sudoers
    fi 
    rm ~/tmp/sudoers.next
    #cat ~/tmp/sudoers.next  
    #sudo cat /etc/sudoers 
} 


gnome_settings()
{
    # NOTE: mouse scroll wheel behavior was fixed by unplugging and replugging
    # the mouse. Odd. 

    #gconftool-2 --all-dirs "/"
    #gconftool-2 --all-dirs "/desktop/url-handlers"
    #gconftool-2 -a "/desktop/url-handlers"
    #gconftool-2 -a "/desktop/applications"
    #gconftool-2 --all-dirs "/schemas/desktop"
    #gconftool-2 --all-dirs "/apps"
    #gconftool-2 -R /desktop
    #gconftool-2 -R /
    #gconftool-2 --get /apps/nautilus/preferences/desktop_font
    #gconftool-2 --get /desktop/gnome/interface/monospace_font_name

    #gconftool-2 -a "/apps/gnome-terminal/profiles/Default" 
    #gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    #sudo -u gdm gconftool-2 --type=bool --set /desktop/gnome/sound/event_sounds false
    #sudo apt-get install -y gnome-tweak-tool

    gconftool-2 --set "/apps/gnome-terminal/profiles/Default/background_color" --type string "#1111111"
    gconftool-2 --set "/apps/gnome-terminal/profiles/Default/foreground_color" --type string "#FFFF6999BBBB"
    gconftool-2 --set /apps/gnome-screensaver/lock_enabled --type bool false
    gconftool-2 --set /desktop/gnome/sound/event_sounds --type=bool false

    # try and disable password after screensaver lock
    gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    gsettings set org.gnome.desktop.screensaver lock-enabled false


    # Fix search in nautilus (remove recurison)
    # http://askubuntu.com/questions/275883/traditional-search-as-you-type-on-newer-nautilus-versions
    gsettings set org.gnome.nautilus.preferences enable-interactive-search true
    #gsettings set org.gnome.nautilus.preferences enable-interactive-search false

    gconftool-2 --get /apps/gnome-screensaver/lock_enabled 
    gconftool-2 --get /desktop/gnome/sound/event_sounds

    #sudo apt-get install nautilus-open-terminal
}


nautilus_settings()
{
    # Get rid of anyonying nautilus sidebar items
    echo "Get Rid of anoying sidebar items"
    chmod +w ~/.config/user-dirs.dirs
    sed -i 's/XDG_TEMPLATES_DIR/#XDG_TEMPLATES_DIR/' ~/.config/user-dirs.dirs 
    sed -i 's/XDG_PUBLICSHARE_DIR/#XDG_PUBLICSHARE_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_DOCUMENTS_DIR/#XDG_DOCUMENTS_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_MUSIC_DIR/#XDG_MUSIC_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_PICTURES_DIR/#XDG_PICTURES_DIR/' ~/.config/user-dirs.dirs
    sed -i 's/XDG_VIDEOS_DIR/#XDG_VIDEOS_DIR/' ~/.config/user-dirs.dirs
    echo "enabled=true" >> ~/.config/user-dirs.conf
    chmod -w ~/.config/user-dirs.dirs
    #cat ~/.config/user-dirs.conf 
    #cat ~/.config/user-dirs.dirs 
    #cat ~/.config/user-dirs.locale
    #cat /etc/xdg/user-dirs.conf 
    #cat /etc/xdg/user-dirs.defaults 
    ###
    sudo sed -i 's/TEMPLATES/#TEMPLATES/'     /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/PUBLICSHARE/#PUBLICSHARE/' /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/DOCUMENTS/#DOCUMENTS/'     /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/MUSIC/#MUSIC/'             /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/PICTURES/#PICTURES/'       /etc/xdg/user-dirs.defaults 
    sudo sed -i 's/VIDEOS/#VIDEOS/'           /etc/xdg/user-dirs.defaults 
    ###
    sudo sed -i "s/enabled=true/enabled=false/" /etc/xdg/user-dirs.conf
    sudo echo "enabled=false" >> /etc/xdg/user-dirs.conf
    sudo sed -i "s/enabled=true/enabled=false/" /etc/xdg/user-dirs.conf
    xdg-user-dirs-gtk-update

    #echo "Get Open In Terminal in context menu"
    #sudo apt-get install nautilus-open-terminal -y

    # Tree view for nautilus
    gsettings set org.gnome.nautilus.window-state side-pane-view "tree"


    #http://askubuntu.com/questions/411430/open-the-parent-folder-of-a-symbolic-link-via-right-click
    mkdir -p ~/.gnome2/nautilus-scripts
}

jupyter_mime_association(){
    python -m utool.util_ubuntu --exec-add_new_mimetype_association --mime-name=ipynb+json --ext=.ipynb --exe-fpath=/usr/local/bin/ipynb
    python -m utool.util_ubuntu --exec-add_new_mimetype_association --mime-name=ipynb+json --ext=.ipynb --exe-fpath=jupyter-notebook --force
}
