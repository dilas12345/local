# -*- coding: utf-8 -*-
# from __future__ import absolute_import, division, print_function, unicode_literals
import os
from rob_helpers import *  # NOQA
from rob_helpers import call
from six.moves import input
import sys
import rob_helpers
from datetime import datetime  # NOQA
import robos
import re
try:
    from itertools import izip as zip
except ImportError:
    pass
from os.path import split
import shutil
import platform
from os.path import basename, expanduser
from os.path import (normpath, realpath, join, isdir, exists, dirname,
                     splitext)
from rob_alarm import *  # NOQA
from rob_nav import *  # NOQA
import rob_nav
#
import textwrap  # NOQA

try:
    import psutil
except ImportError:
    pass

try:
    import six  # NOQA
except ImportError:
    pass


def make_complete(r):
    import utool as ut
    import rob_interface
    modname = 'rob'
    testnames = [ut.get_funcname(func) for func in
                 ut.get_module_owned_functions(rob_interface)]
    line = 'complete -W "%s" "%s"' % (' '.join(testnames), modname)
    print('add the following line to your bashrc')
    print(line)


def focus(r, window_name):
    print(robos.EnumWindowTest())
    print(robos.GetForegroundWindow())


def write_rob_pathcache(pathlist):
    fname = join(dirname(__file__), 'pathcache%s.txt' % sys.platform)
    with open(fname, 'a') as file:
        for path in pathlist:
            file.write('\n%s' % path)


def add_path(r, path_):
    print('Requested adding %r to the PATH' % path_)
    dpath = normpath(realpath(path_))
    #print('Exists? %r' % exists(dpath))
    #print('IsDir? %r' % isdir(dpath))
    #print('IsFile? %r' % isfile(dpath))
    if not exists(dpath):
        raise Exception('%r must exist' % dpath)
    if not isdir(dpath):
        raise Exception('%r must be a directory' % dpath)
    print(' * Adding adding %r to the PATH' % dpath)
    write_rob_pathcache([dpath])
    robos.add_path_vars([dpath])
    fixpath2(r)


def fixpath2(r):
    print('Hack fix this in a bit. Make general')
    os.environ['PATH']  = robos.get_env_var('PATH')
    print('Killing Autohokey')
    kill(r, 'AutoHotkey')
    print('Changeing dir to: %r' % r.d.AHK_SCRIPTS)
    cwd = os.getcwd()
    os.chdir(r.d.AHK_SCRIPTS)
    print('Starting Autohotkey')
    os.system('start crallj.ahk')
    os.system(r'echo set PATH=%PATH% > C:\newest_path.bat')
    print('Changeing dir to: %r' % cwd)
    os.chdir(cwd)
    print(r'Run C:\newest_path.bat')


def update_path(r):
    """
    this is the right command August31
    newpath.bat will do everything
    """
    pathvar_list = r.path_vars_list
    for pathvar in pathvar_list:
        print(pathvar)
    #robos.add_path_vars(pathvar_list)
    print('\n\nSend, #r newpath {enter}')
    print('Please run newpath.bat')


def update_env(r):
    envvar_list = r.env_vars_list
    for name, rob_val in envvar_list:
        print(' * ENVAR: %s %s' % (name, rob_val))
    robos.add_env_vars(r, envvar_list)


# https://code.google.com/p/psutil/
def ps(r, flags=None):
    for pid in psutil.get_pid_list():
        proc = psutil.Process(pid)
        if flags is not None and \
           (proc.name.find(flags) == -1 and ' '.join(proc.cmdline).find(flags) == -1):
            continue
        #print(proc)
        #print(proc.get_cpu_percent())
        #print(proc.get_cpu_times())
        printproc_2(proc)


def printproc_2(proc):
    print('pid=%r; username=%r; name=%r' % (proc.pid, proc.username, proc.name))
    print('cmdline=%r' % (proc.cmdline))
    #print('parent: '   +repr(proc.parent))
    print('----')


def printproc_(proc):
    if sys.platform == 'win32':
        attr_list = ['parent', 'status', 'pid', 'ppid',
                     'cmdline', 'name', 'username']
    else:
        attr_list = ['nice', 'pid', 'ppid', 'cmdline', 'exe',
                     'name', 'terminal', 'username']
    for attr in attr_list:
        try:
            val = eval('proc.%s' % attr)
            print('proc.%s=%r' % (attr, val))
        except Exception:
            print('proc.%s' % attr)
    try:
        print('proc.parent = %r' % proc.parent)
    except Exception:
        print('proc.parent')


def pykill(r, scriptname, needbash=True):
    needbash = bool(needbash)
    print(needbash)
    script_fname = '%s.py' % scriptname
    to_kill = []
    for proc in psutil.process_iter():
        if 'python' == proc.name:
            cmdstr = ' '.join(proc.cmdline)
            if proc.parent.name != 'bash' and not needbash:
                continue
            #printproc_2(proc)
            #print(cmdstr)
            #print(script_fname)
            if cmdstr.find(script_fname) == -1:
                continue
            to_kill.append(proc)
    for proc in to_kill:
        print(' --- killing ---')
        printproc_2(proc)
        proc.kill()


def hskill(r):
    pykill(r, '<defunct>')


def kill(r, procname):
    for proc in psutil.process_iter():
        if procname in proc.name:
            print(' killing: ')
            printproc_(proc)
            proc.kill()
    print('Finished killing tasks.')
    # windows only: os.system('taskkill /f /im exampleProcess.exe')
    ''' # Unix Only
    import subprocess, signal
    p = subprocess.Popen(['ps', '-A'], stdout=subprocess.PIPE)
    out, err = p.communicate()
    for line in out.splitlines():
        if procname in line:
            pid = int(line.split(None, 1)[0])
            os.kill(pid, signal.SIGKILL)'''


def project_dpaths():
    def import_module_from_fpath(module_fpath_, addpath=False):
        """ imports module from a file path """
        python_version = platform.python_version()
        module_fpath = expanduser(module_fpath_)
        modname = splitext(basename(module_fpath))[0]
        if addpath:
            import sys
            module_dpath = dirname(module_fpath)
            sys.path.append(module_dpath)
        if python_version.startswith('2'):
            import imp
            module = imp.load_source(modname, module_fpath)
        elif python_version.startswith('3'):
            import importlib.machinery
            loader = importlib.machinery.SourceFileLoader(modname, module_fpath)
            module = loader.load_module()
        else:
            raise AssertionError('invalid python version')
        return module
    REPOS1 = import_module_from_fpath('~/local/init/REPOS1.py', True)
    project_list = REPOS1.PROJECT_REPOS
    return project_list
    #project_list = [
    #    #'~/code/hotspotter',
    #    '~/code/hesaff',
    #    '~/code/ibeis',
    #    '~/code/vtool',
    #    '~/code/utool',
    #    '~/code/guitool',
    #    '~/code/plottool',
    #    '~/code/cyth',
    #    '~/code/detecttools',
    #    '~/code/pyrf',
    #    '~/code/gzc-client',
    #    '~/code/gzc-server',
    #]
    #return map(expanduser, project_list)


# Grep my projects
def gp(r, regexp):
    import utool as ut
    # exclude_fpaths = ut.get_argval(('--exclude_fpath', '--xf'), type_=list, default=None)
    ut.grep_projects([regexp], recursive=True)
    # rob_nav._grep(r, [regexp], recursive=True, dpath_list=project_dpaths(), regex=True)


# Sed my projects
def sp(r, regexpr, repl, force=False):
    rob_nav._sed(r, regexpr, repl, force=force, recursive=True, dpath_list=project_dpaths())


def grep(r, *tofind_list):
    import utool as ut
    #include_patterns = ['*.py', '*.cxx', '*.cpp', '*.hxx', '*.hpp', '*.c', '*.h', '*.vim']
    ut.grep(tofind_list, recursive=True, verbose=True)
    #rob_nav._grep(r, tofind_list, recursive=True)


def invgrep(r, *tofind_list):
    rob_nav._grep(r, tofind_list, recursive=True, invert=True)


def grepnr(r, *tofind_list):
    rob_nav._grep(r, tofind_list, recursive=False)


def grepc(r, *tofind_list):
    rob_nav._grep(r, tofind_list, case_insensitive=False)


def grepr(r, regexpr, recursive=True):
    rob_nav._grep(r, [regexpr], recursive=recursive, regex=True)


def sedr(r, regexpr, repl, force=False):
    sed(r, regexpr, repl, force=force, recursive=True)


def sed(r, regexpr, repl, force=False, recursive=False):
    rob_nav._sed(r, regexpr, repl, force, recursive)


def find(r, *tofind_list):
    search(r, *tofind_list)


def search(r, *tofind_list):
    import utool as ut
    dpath = os.getcwd()
    print('Searching %s for %r' % (dpath, tofind_list))
    num_found = 0
    for root, dname_list, fname_list in os.walk(dpath):
        for name in fname_list + dname_list:
            name_ = name.lower()
            if ut.find_in_list(name_, tofind_list, all):
                print(os.path.join(root, name_))
                num_found += 1
    print(' * num_found=%d' % (num_found))


def preprocess_research(input_str):
    """
    test of an em --- dash
    test of an em — dash
    """
    import utool as ut
    inside = ut.named_field('ref', '.*?')
    input_str = re.sub(r'\\emph{' + inside + '}', ut.bref_field('ref'), input_str)
    # input_str = input_str.decode('utf-8')
    input_str = ut.ensure_unicode(input_str)
    pause = re.escape(' <break time="300ms"/> ')
    # pause = ', '
    emdash = u'\u2014'  #
    # print('input_str = %r' % (input_str,))
    # print('emdash = %r' % (emdash,))
    # print('emdash = %s' % (emdash,))
    input_str = re.sub('\s?' + re.escape('---') + '\s?', pause, input_str)
    input_str = re.sub('\s?' + emdash + '\s?', pause, input_str)
    # print('input_str = %r' % (input_str,))
    input_str = re.sub('\\\\cite{[^}]*}', '', input_str)
    input_str = re.sub('et al.', 'et all', input_str)  # Let rob say et al.
    input_str = re.sub(' i\.e\.', ' i e ' + pause, input_str)  # Let rob say et al.
    input_str = re.sub(r'\\r', '', input_str)  #
    input_str = re.sub(r'\\n', '', input_str)  #
    input_str = re.sub('\\\\', '', input_str)  #
    #input_str = re.sub('[a-z]?[a-z]', 'et all', input_str) # Let rob say et al.
    input_str = re.sub('\\.[^a-zA-Z0-1]+', '.\n', input_str)  # Split the document at periods
    input_str = re.sub('\r\n', '\n', input_str)
    input_str = re.sub('^ *$\n', '', input_str)
    input_str = re.sub('\n\n*', '\n', input_str)
    return input_str


def process_research_line(line):
    line = re.sub('([A-Za-z ]*, 20[0-9][0-9])', '', line)  # (Name, Year) Citations
    line = re.sub('\\[[0-9, ]+\\]', '', line)  # remove numerical citations.
    line = re.sub('- ', '', line)  # Fix Qiqqa output
    line = re.sub('-', ' ', line)  # Remove remaining dashes
    # line = re.sub('[^A-Za-z0-9., ? ]', '', line)  # Remove remaining weird characters
    line = re.sub(' *,', ', ', line)  # Fix commas
    line = re.sub(',+', ', ', line)  # Fix commas
    line = re.sub('  *', ' ', line)
    line = re.sub('  *', ' ', line)
    line = re.sub('NBNN', 'Naive Bayes Nearest Neighbor', line)
    if True:
        try:
            import utool as ut
            nesting = ut.parse_nestings(line)
            transformed = []
            for item in nesting:
                if item[0] == 'curl' and item[1][1][1].startswith('displaystyle'):
                    # Skip the wiki displaystyle
                    pass
                else:
                    transformed.append(item)
            line = ut.recombine_nestings(transformed)
        except Exception:
            pass
        # For wiki formatting
    line = re.sub('\\bdisplaystyle\\b', '', line)
    line = re.sub('\\(i\\)', '1)', line)
    line = re.sub('\\(ii\\)', '2)', line)
    line = re.sub('\\(iii\\)', '3)', line)

    lots_of_numbers = re.compile('[0-9]+ [0-9]+ [0-9]+ [0-9]+')
    if len(lots_of_numbers.findall(line)) > 0:
        line = ''
    if len(line) < 3:
        line = ''
    return line


def research_clipboard(r, start_line_str=None, rate='2', sentence_mode=True, open_file=False):
    import utool as ut
    to_speak = ut.get_clipboard()
    #ut.embed()
    #to_speak = robos.get_clipboard()
    write_research(r, to_speak)
    research(r, start_line_str='0', rate=rate, sentence_mode=True, open_file=False)


def print_clipboard(r):
    clipboard = robos.get_clipboard()
    print(clipboard)


def sync_clipboard_to(r, remote):
    send_clipboard_to(r, remote)
    #DISPLAY=:10.0 xsel
    #remote_cmd = 'DISPLAY=:10.0 xsel --clipboard < ~/clipboard.txt'
    #send_command(r, remote, remote_cmd)


def dump_clipboard(r, clipboard_fname):
    clipboard = robos.get_clipboard()
    with open(clipboard_fname, 'w') as file_:
        file_.write(clipboard)


def send_clipboard_to(r, remote):
    clipboard_fname = 'clipboard.txt'
    dump_clipboard(r, clipboard_fname)
    rob_helpers.scp_push(remote, clipboard_fname)


def send_command(r, remote, remote_cmd):
    args = ['ssh', '-X', remote, '"' + remote_cmd + '"']
    cmdstr = ' '.join(args)
    print(cmdstr)
    rob_helpers.call(cmdstr)


def write_research(r, to_write, rate=-5):
    fname = join(split(__file__)[0], 'to_speak.txt')
    import utool as ut
    ut.write_to(fname, to_write)
    # with open(fname, 'w') as file_:
    #     file_.write(to_write)


def research(r, start_line_str=None, rate='3', sentence_mode=True, open_file=False):
    fname = join(split(__file__)[0], 'to_speak.txt')
    if start_line_str == "prep":
        os.system(fname)
        return
    if open_file is True:
        os.system(fname)
    import utool as ut

    input_str = preprocess_research(ut.readfrom(fname))
    if sentence_mode:
        input_str = input_str.replace('\n', ' ').replace('. ', '.\n')
        input_str = re.sub('  *', ' ', input_str)

    line_count = 0
    page = 0
    page_re = re.compile(' *--- Page [0-9]* *--- *')
    if start_line_str is None:
        try:
            start_page = 0
            start_line = int(input('Did you forget the start line?'))
        except Exception:
            pass
    elif start_line_str.find('page') != -1:
        start_page = int(start_line_str.replace('page', ''))
        start_line = 0
    else:
        start_page = 0
        start_line = int(start_line_str)

    print('Starting on line: %d' % (start_line))
    print('Starting on page: %d' % (start_page))
    for line in input_str.split('\n'):
        print('____')
        # Check for page marker
        if page_re.findall(line) != []:
            page = int(re.sub(' *--- Page ', '', line).replace('---', ''))
        # Print out what is being read
        line_count += 1
        print('%d, %d > %s' % (page, line_count, line))
        if start_line > line_count or start_page > page:
            continue
        # Preprocess the line
        line = process_research_line(line)
        if line == '':
            continue
        print('--')
        robos.speak(r, line, rate)
        #subprocess.call(r.f.nircmd_exe + ' speak text \"'+line+'\" '+str(rate))


def info(r):
    """ Provides interface help """
    import rob_interface
    import pydoc
    print("===================\n")
    print(pydoc.render_doc(rob_interface))
    #help(rob_interface)
    print("===================\n")


def foo(r):
    print('foo')


def symlink(r, source=None, target=None):
    'Creates a hard link to the source in the current directory or linked_dest if specified'
    if source is None:
        raise Exception('must at least specify a source')
    #if target == None:
        #target = slash_fix('C:/tmp/'+os.path.basename(source))
    if sys.platform == 'win32':
        if os.path.isdir(source):
            call('MKLINK /D "%s" "%s"' % (target, source))
        else:
            call('MKLINK "%s" "%s"' % (target, source))
    else:
        print(os.path.islink(target))
        call(['ln', '-s', os.path.normpath(source),  os.path.normpath(target)])


def make_dpath(r, dpath):
    if not os.path.exists(dpath):
        os.makedirs(dpath)


#=====================
# SETUP COMMANDS
#=====================
def print_path(r):
    print('\n----------------')
    print('os.environ["PATH"]:')
    path = os.environ['PATH']
    for line in path.split(';'):
        print(' * ' + line)

    print('\n----------------')
    print('robos.get_env_var("PATH"):')
    path = robos.get_env_var('PATH')
    for line in path.split(';'):
        print(' * ' + line)


def print_env(r):
    print(sys.environs)
    #print_path(r)
    #for varval in r.env_vars_list:
    #    print(varval[0]+' = '+varval[1])


def get_regstr(regtype, var, val):
    regtype_map = {
        'REG_EXPAND_SZ': 'hex(2):',
        'REG_DWORD': 'dword:',
        'REG_BINARY': None,
        'REG_MULTI_SZ': None,
        'REG_SZ': '',
    }
    # It is not a good idea to write these variables...
    EXCLUDE = ['USERPROFILE', 'USERNAME', 'SYSTEM32']
    if var in EXCLUDE:
        return ''
    def quotes(str_):
        return '"' + str_.replace('"', r'\"') + '"'
    sanitized_var = quotes(var)
    if regtype == 'REG_EXPAND_SZ':
        # Weird encoding
        #bin_ = binascii.hexlify(hex_)
        #val_ = ','.join([''.join(hex2) for hex2 in hex2zip])
        #import binascii  # NOQA
        x = val
        ascii_ = x.encode("ascii")
        hex_ = ascii_.encode("hex")
        hex_ = x.encode("hex")
        hex2zip = zip(hex_[0::2], hex_[1::2])
        spacezip = [('0', '0')] * len(hex2zip)
        hex3zip = zip(hex2zip, spacezip)
        sanitized_val = ','.join([''.join(hex2) + ',' + ''.join(space) for hex2, space in hex3zip])
    elif regtype == 'REG_DWORD':
        sanitized_val = '%08d' % int(val)
    else:
        sanitized_val = quotes(val)
    comment = '; ' + var + '=' + val
    regstr = sanitized_var + '=' + regtype_map[regtype] + sanitized_val
    return comment + '\n' + regstr


def write_regfile(fpath, key, varval_list, rtype):
    # Input: list of (var, val) tuples
    # key to put varval list in
    # fpath - path to write .reg file
    # rtype - type of registry variables
    envtxt_list = ['Windows Registry Editor Version 5.00',
                   '',
                   key]
    print('\n'.join(map(repr, varval_list)))
    varval_list = filter(lambda x: isinstance(x, tuple), varval_list)
    vartxt_list = [get_regstr(rtype, var, val) for (var, val) in varval_list]
    envtxt_list.extend(vartxt_list)
    with open(fpath, 'wb') as file_:
        file_.write('\n'.join(envtxt_list))


def reg_disable_automatic_reboot_122614(r):
    """
    rob reg_disable_automatic_reboot_122614

    writes a registry file that can be executed to produce desired changes

    References:
        http://www.makeuseof.com/tag/disable-forced-restarts-windows-update/
    """
    write_dir = join(r.d.HOME, 'Sync/win7/registry')
    envtxt_fpath = normpath(join(write_dir, 'disable_autoreboot.reg'))
    key = r'[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]'
    varval_list = [('NoAutoRebootWithLoggedOnUsers', '1')]
    rtype = 'REG_DWORD'
    write_regfile(envtxt_fpath, key, varval_list, rtype)
    rob_helpers.view_directory(write_dir)


def write_env(r):
    rtype = 'REG_SZ'
    rtype = 'REG_EXPAND_SZ'
    write_dir = join(r.d.HOME, 'Sync/win7/registry')
    envtxt_fpath = normpath(join(write_dir, 'UPDATE_ENVARS.reg'))
    key = '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment]'
    write_regfile(envtxt_fpath, key, r.env_vars_list, rtype)
    rob_helpers.view_directory(write_dir)


def write_path(r):
    """
    Writes a script to update the PATH variable into the sync registry
    The PATH update mirrors the current RobSettings

    SeeAlso:
        utool.util_win32.add_to_win32_PATH
    """
    import utool
    write_dir = join(r.d.HOME, 'Sync/win7/registry')
    path_fpath = normpath(join(write_dir, 'UPDATE_PATH.reg'))
    key = '[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment]'
    rtype = 'REG_EXPAND_SZ'
    pathsep = os.path.pathsep
    # Read current PATH values
    win_pathlist = list(os.environ['PATH'].split(os.path.pathsep))
    rob_pathlist = list(map(normpath, r.path_vars_list))
    new_path_list = utool.unique_ordered(win_pathlist + rob_pathlist)
    #new_path_list = unique_ordered(win_pathlist, rob_pathlist)
    print('\n'.join(new_path_list))
    pathtxt = pathsep.join(new_path_list)
    varval_list = [('Path', pathtxt)]
    write_regfile(path_fpath, key, varval_list, rtype)

    rob_helpers.view_directory(write_dir)


def update(r):
    upenv(r)


def upenv(r):
    write_env(r)
    write_path(r)


def pref_env(r):
    """ Function that sets Envirornment Preferences """
    for (envvar, envval) in r.env_vars_list:
        print(envvar + '=' + envval)
        #robos.set_env_var(envvar, envval)
        #robos.set_env_var('ROB_'+envvar, envval)
    path_list = r.path_vars_list
    for path in path_list:
        print(path)
        #robos.append_to_path(path)


def setup_global():
    pref_env()
    pass


def fix_youtube_names_ccl(r):
    import utool
    cwd = os.getcwd()
    fpath_list = utool.glob(cwd, '*.mp4')
    for fpath in fpath_list:
        #print(fpath)
        dpath, fname = split(fpath)
        found = utool.regex_search(r'Crash Course .*-', fname)
        if found is not None:
            found = found.replace('English', '').replace('-', ' - ')
            new_fpath = join(dpath, found + fname.replace(found, ''))
            print(new_fpath)
            shutil.move(fpath, new_fpath)
        #start = re.search(
        #print(fpath[start.pos:start.endpos])
        #break


def fix_path(r):
    """ Removes duplicates from the path Variable """
    PATH_SEP = os.path.pathsep
    pathstr = robos.get_env_var('PATH')
    import utool as ut

    pathlist = ut.unique(pathstr.split(PATH_SEP))

    new_path = ''
    failed_bit = False
    for p in pathlist:
        if os.path.exists(p):
            new_path = new_path + p + PATH_SEP
        elif p == '':
            pass
        elif p.find('%') > -1 or p.find('$') > -1:
            print('PATH=%s has a envvar. Not checking existance' % p)
            new_path = new_path + p + PATH_SEP
        else:
            print('PATH=%s does not exist!!' % p)
            failed_bit = True
    #remove trailing semicolons

    if failed_bit:
        ans = input('Should I overwrite the path? yes/no?')
        if ans == 'yes':
            failed_bit = False

    if len(new_path) > 0 and new_path[-1] == PATH_SEP:
        new_path = new_path[0:-1]

    if failed_bit is True:
        print("Path FIXING Failed. A Good path should be: \n%s" % new_path)
        print("\n\n====\n\n The old path was:\n%s" % pathstr)
    elif pathstr == new_path:
        print("The path was already clean")
    else:
        robos.set_env_var('PATH', new_path)


def create_shortcut(r, what, where=''):
    # TODO Move to windows helpers
    print('\n\n+---- Creating Shortcut ----')
    print('What = %s\n Where=%s' % (what, where))
    run_in    = ''
    what_args = ''
    if isinstance(what, tuple):
        tup       = what
        what      = tup[0]
        what_args = tup[1]
        run_in    = tup[2]
        if run_in == ' ':
            run_in = ''
        if what_args == ' ':
            what_args = ''
    if where == '':
        target = what + '.lnk'
    else:
        import utool as ut
        ut.ensuredir(where)
        base_what = os.path.basename(what)
        if len(base_what) > 0:
            if base_what[-1] in ['"', "'"]:
                base_what = base_what[0:-1]

        target = where + '/' + base_what + '.lnk'
    helpers_vbs = r.f.create_shortcut_vbs
    cmd = 'cscript "%s" "%s" "%s" "%s" "%s"' % (helpers_vbs, target, what,
                                                what_args, run_in)
    print(cmd)
    call(cmd)


def send(r, keys, pause=.05):
    import SendKeys
    pause = float(pause)
    SendKeys.SendKeys(keys, pause=pause, with_spaces=False, with_tabs=True,
                      with_newlines=False, turn_off_numlock=True)


def find_in_path(r, pattern):
    import fnmatch
    PATH = os.environ['PATH'].split(os.pathsep)
    fpaths_list = [os.listdir(dpath) for dpath in PATH]
    for dpath, fpaths_list in zip(PATH, fpaths_list):
        for x in fnmatch.filter(fpaths_list, 'msvcr90.dll'):
            print('Found %r in %r' % (x, dpath))
