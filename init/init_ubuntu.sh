
make_ubuntu_symlinks()
{
    ln -s ~/local/scripts/ubuntu_scripts ~/scripts
    # For Hyrule
    ln -s /media/SSD_Extra ~/SSD_Extra
    ln -s /media/Store ~/Store
    ln -s /media/Store/data ~/data
}

donot_lock_screen()
{
    gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
}

update_locate()
{
    # Update the locate commannd
    sudo updatedb
}

install_packages()
{
    # For opencv
    sudo apt-get install openexr
    # For Lempisky Random Forsest Show
    sudo apt-get install libgtk2.0-dev
    sudo apt-get install deluge
}

virtualbox_guest_postinstall()
{
    git config --global user.name joncrall
    git config --global user.email crallj@rpi.edu
    git config --global push.default simple
}


install_virtualbox_additions()
{
    sudo apt-get install virtualbox-guest-additions-iso
    
    sudo apt-get update
    sudo apt-get install dkms build-essential linux-headers-generic
    
    sudo apt-get install build-essential linux-headers-$(uname -r)
    sudo apt-get install virtualbox-ose-guest-x11


    # setup virtualbox for ssh
    VBoxManage modifyvm virtual-ubuntu --natpf1 "ssh,tcp,,3022,,22"
    # To ssh to virtualserv
    #ssh -p 3022 user@127.0.0.1
    
}

virtual_init()
{
    # init on the virtual machine
    openssh-server

}

#config_clang()
#{
    ## INCOMPLETE
    ## use clang
    #sudo update-alternatives --config c++
#}

install_clang()
{
    # "update-alternatives --install" takes a link, name, path and priority.
    sudo update-alternatives --install /usr/bin/gcc gcc ~/data/clang3.3/bin/clang 50
    sudo update-alternatives --install /usr/bin/g++ g++ ~/data/clang3.3/bin/clang++ 50
    sudo update-alternatives --install /usr/bin/cpp cpp-bin /usr/bin/cpp-4.6 100
}

install_gcc()
{
    # "update-alternatives --install" takes a link, name, path and priority.
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 100
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 100
    sudo update-alternatives --install /usr/bin/cpp cpp-bin /usr/bin/cpp-4.6 100
}


install_python()
{
    sudo pip install pillow
}

install_gdrive()
{
    sudo add-apt-repository ppa:alessandro-strada/ppa
    sudo apt-get update
    sudo apt-get install google-drive-ocamlfuse
}

install_dark_theme()
{
    sudo add-apt-repository ppa:noobslab/themes
    sudo apt-get update
    sudo apt-get install mediterranean-theme
}

