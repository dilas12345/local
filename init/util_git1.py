#!/usr/bin/env python
from __future__ import absolute_import, division, print_function
import sys
import os
from six.moves import zip
from os.path import exists, join, dirname, split, isdir
import REPOS1
import meta_util_git1 as mu  # NOQA
from meta_util_git1 import get_repo_dirs, get_repo_dname, unixpath  # NOQA

PROJECT_REPOS    = REPOS1.PROJECT_REPOS
IBEIS_REPOS_URLS = REPOS1.IBEIS_REPOS_URLS
CODE_DIR         = REPOS1.CODE_DIR
VIM_REPO_URLS    = REPOS1.VIM_REPO_URLS
BUNDLE_DPATH     = REPOS1.BUNDLE_DPATH
VIM_REPOS_WITH_SUBMODULES = REPOS1.VIM_REPOS_WITH_SUBMODULES


def gitcmd(repo, command):
    try:
        import utool as ut
    except ImportError:
        print()
        print("************")
        try:
            print('repo=%s' % ut.color_text(repo.dpath, 'yellow'))
        except Exception:
            print('repo = %r ' % (repo,))
        os.chdir(repo)
        if command.find('git') != 0 and command != 'gcwip':
            command = 'git ' + command
        os.system(command)
        print("************")
    else:
        repo_ = ut.Repo(dpath=repo)
        repo_.issue(command)


def gg_command(command):
    """ Runs a command on all of your PROJECT_REPOS """
    for repo in PROJECT_REPOS:
        if exists(repo) and exists(join(repo, '.git')):
            gitcmd(repo, command)


def checkout_repos(repo_urls, repo_dirs=None, checkout_dir=None):
    """ Checkout every repo in repo_urls into checkout_dir """
    # Check out any repo you dont have
    if checkout_dir is not None:
        repo_dirs = mu.get_repo_dirs(checkout_dir)
    assert repo_dirs is not None, 'specify checkout dir or repo_dirs'
    for repodir, repourl in zip(repo_dirs, repo_urls):
        print('[git] checkexist: ' + repodir)
        if not exists(repodir):
            mu.cd(dirname(repodir))
            mu.cmd('git clone ' + repourl)


def setup_develop_repos(repo_dirs):
    """ Run python installs """
    for repodir in repo_dirs:
        print('Installing: ' + repodir)
        mu.cd(repodir)
        assert exists('setup.py'), 'cannot setup a nonpython repo'
        mu.cmd('python setup.py develop')


def pull_repos(repo_dirs, repos_with_submodules=[]):
    for repodir in repo_dirs:
        print('Pulling: ' + repodir)
        mu.cd(repodir)
        assert exists('.git'), 'cannot pull a nongit repo'
        mu.cmd('git pull')
        reponame = split(repodir)[1]
        if reponame in repos_with_submodules or\
           repodir in repos_with_submodules:
            repos_with_submodules
            mu.cmd('git submodule init')
            mu.cmd('git submodule update')


def is_gitrepo(repo_dir):
    gitdir = join(repo_dir, '.git')
    return exists(gitdir) and isdir(gitdir)


if __name__ == '__main__':
    varargs = sys.argv[1:]
    varargs2 = []
    for a in varargs:
        # hack
        if a == '==':
            break
        varargs2.append(a)

    command = ' '.join(varargs2)
    # Apply command to all repos
    gg_command(command)
