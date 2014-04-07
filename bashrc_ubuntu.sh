# if running bash
#if [ -n "$BASH_VERSION" ]; then
    ## include .bashrc if it exists
    #if [ -f "$HOME/.bashrc" ]; then
	#. "$HOME/.bashrc"
    #fi
#fi

# set PATH so it includes user's private bin if it exists
#if [ -d "$HOME/bin" ] ; then
    #PATH="$HOME/bin:$PATH"
#fi


#Jon's Note: .profile runs this
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

shopt -s histappend # append to the history file, don't overwrite it

HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#sudo ssh-agent ~/.ssh/id_rsa

# TODO: Let ROB handle these
# some more ls aliases
export name=Hyrule
export platform=linux2
export CLOUD=~/Dropbox
export code=~/code
export latex=~/latex
export pvimrc=~/local/vim/portable_vimrc
export prob_interface=~/local/rob/ROB/rob_interface.py
export prob=~/local/rob/rob_interface.py
export prob_dir=~/local/rob

export PYQTDESIGNERPATH=/home/joncrall/Dropbox/Settings/PyQt4/plugins/designer/python

export VIMFILES=~/.vim
export IPYTHONDIR=~/.ipython
export LATEX='~/latex/'
export SITE_PACKAGES=/usr/local/lib/python2.7/dist-packages/

export CC=gcc
export CXX=g++

# MY PATH
export PATH=$PATH:~/scripts/:/usr/local/MATLAB/R2013a/bin
export PYTHONPATH=$PYTHONPATH
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgocnfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

#export mothers=/data/work/HSDB_
export VIEW_CMD=nautilus
vd ()
{
    if [ $# -eq 0 ]; then
        $VIEW_CMD .& > /dev/null 2>&1
    else
        $VIEW_CMD $1& > /dev/null 2>&1
    fi
}

#http://stackoverflow.com/questions/7031126/switching-between-gcc-and-clang-llvm-using-cmake
#export CC=/usr/local/bin/clang
#export CXX=/usr/local/bin/clang++
#alias cmake="cmake -DCMAKE_USER_MAKE_RULES_OVERRIDE=~/local/ClangOverrides.txt -D_CMAKE_TOOLCHAIN_PREFIX=llvm-"
 
# Windows-like commands
alias explorer=nautilus
alias start=nautilus
alias cmd=bash


alias gvim=gvim_ubuntu_hack 
gvim_ubuntu_hack()
{
    /usr/bin/gvim -f $@ 2> /dev/null &
}


alias resetftp='/etc/init.d/vsftpd restart'
alias noip='/usr/local/bin/noip2'

alias say='espeak -v en '

#alias sumatrapdf='wine "C:\Program Files (x86)\SumatraPDF\SumatraPDF"'
alias diskutility='palimpsest'
alias realrm='/bin/rm'
alias rm='trash-put'
alias viewimage='eog'

source ~/scripts/install_llvm.sh
