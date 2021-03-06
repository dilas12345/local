EnvGet ahk_scripts, AHK_SCRIPTS
EnvGet userprofile, USERPROFILE
;msgbox  %ahk_scripts%
SendMode Input
SetWorkingDir %ahk_scripts%
return
#NoEnv 
#SingleInstance force

;#include %userprofile%\local\ahk_scripts\middle_click.ahk
#include C:\Users\joncrall\local\scripts\ahk_scripts\middle_click.ahk
;#include middle_click.ahk
;#include crallj_funcs.ahk
;#include ctrl_h.ahk

; ======================================================
; NUMPAD HOTKEYS
; 7(    LATEX   )  8(   HOTSPOTTER  )    9(    CLOUD      )
; 4(     vim    )  5(     cmd       )    6(    chrome     )
; 1(    TODO    )  2(     SPEAK     )    3(     qtc       )

; Capslock::Ctrl

;#IfWinActive ahk_class Notepad
;GetKeyState("CapsLock")
;NumPadHome::  ; Numpad-7
;Send '('
;return 
;NumpadUp::    ; Numpad-8
;Send '('
;return 
;#IfWinActive  ; This puts subsequent remappings and hotkeys in effect for all windows.

;---------------------
;  1 - Todo, Notes 
;NumpadEnd:: ; NumPad-1
    ;Open("todo")
    ;return
^NumpadEnd:: ; NumPad-1
    Open("personal")
    return
;---------------------
    
;--------------   
;  2 - Rob Speak 
NumpadDown:: ; NumPad-2
; copies clipboard to to speak
    EnvGet rob, ROB
    ;ClipboardTemp := Clipboard*/
    ;StringReplace,ClipboardTemp,ClipboardTemp,`r," ",A
    ;StringReplace,ClipboardTemp,ClipboardTemp,`n," ",A
    ;Run, "cmd" /c "rob write_research %ClipboardTemp%"
    Runwait, taskkill /im nircmd.exe /f
    Runwait, taskkill /im nircmd.exe /f
    Run, "cmd" /c "rob research_clipboard"
    return
!NumpadDown:: ; Alt + Numpad-2 ; opens to speak
    EnvGet rob, ROB
    rob_to_speak = %rob%\to_speak.txt
    GVIMFocus(rob_to_speak)
    return
+NumpadDown:: ; Shift NumPad-2 ; reads to speak
    WinClose C:\Windows\system32\cmd.exe - rob  research 0
    Runwait, taskkill /im nircmd.exe /f
    Runwait, taskkill /im nircmd.exe /f
    Run, "cmd" /c "rob research"
    return
^+2::  ; Control+shift+2
^NumpadDown::  ; Control copys clipboard and reads to speak
    Send, ^c
    EnvGet rob, ROB
    ClipboardTemp := Clipboard
    StringReplace,ClipboardTemp,ClipboardTemp,`r," ",A
    StringReplace,ClipboardTemp,ClipboardTemp,`n," ",A
    Run, "cmd" /c "rob write_research %ClipboardTemp%"
    WinClose C:\Windows\system32\cmd.exe - rob  research
    Runwait, taskkill /im nircmd.exe /f
    Runwait, taskkill /im nircmd.exe /f
    Run, "cmd" /c "rob research 0 3"
    return
;---------------------

;--------------  
;  3 - Qt Console
;NumpadPgDn:: ; NumPad-3
    ;Focus("Calculator")
    ;return
^NumpadPgDn:: ; Ctrl+Numpad-3
    Open("qtc")
    return 
^+;:: ; Control Shift Semicolon
    Focus("qtc")
    return
;---------------------


;--------------------- 
; 4 - VIM Open and Focus
^NumpadLeft::  ; Numpad-4
    Open("vim")
    return
NumpadLeft::  ; Numpad-4
    Focus("vim")
    return
#v:: ; Win+'V'
^;:: ; Ctrl+';'
!':: ; Alt+"'"
    Focus("vim")
    return
;---------------------


;---------------------
;  5 - Terminal Open and Focus
NumpadClear:: ; NumPad-5
#c::   ; Win+'C'
!;::   ; Alt + ';'
    Focus("cmd")
    return
^!;::   ; Ctrl + Alt + ';'
^!t::  ; Ctrl + Alt + t
^NumpadClear:: ; NumPad-5
    Open("cmd")
    return
;---------------------


;---------------------
;  6 - Chrome 
NumpadRight:: ; Numpad-6
^/::          ; Ctrl + / 
!/::          ; Alt + / 
    Focus("chrome")
    return
^NumpadRight:: ; Numpad-6
    ;python pullmyrepos
    Send, git pull {Enter}
    return
;---------------------


;--------------------- 
; 7 - Latex and Rob Directory
NumPadHome::  ; Numpad-7
    EnvGet dpath, LATEX
    FocusDPath(dpath)
    return
^NumPadHome:: ; Control+Numpad-7
    EnvGet dpath, ROB
    FocusDPath(dpath)
    return
;--------------------- 

;--------------------- 
; 8 - HotSpotter directory
NumpadUp::    ; Numpad-8
    ;EnvGet home, USERPROFILE
    ;dpath = %home%\code\hotspotter
    ;FocusDPath(dpath)
    Focus("qtc")
    Sleep 50
    Send, ^v
    Sleep 50
    Send, {Enter}
    return
;--------------------- 


;--------------------- 
; 9 - Cloud Directory
NumpadPgUp::  ; Numpad-9
    EnvGet dpath, CLOUD
    FocusDPath(dpath)
    return
^NumpadPgUp::  ; Numpad-9 Downloads
    EnvGet dpath, CLOUD
    FocusDPath(dpath/../Downloads)
    return
return
;--------------------- 




;--------------------- 
; Hotkey - Run Main
^+.:: ; Ctrl + Shift + '.'
;    SendRaw, `%run main.py --cmd
;    SendInput, {Enter}
;    return
;--------------------- 
;^+.:: ; Ctrl + Shift + '.'
    ;SendRaw, `%run main.py --cmd
    ;SendInput, {Enter}
    ;return
;--------------------- 
    ;SendRaw, with open('run_experiments.py') as file:
    ;SendRaw, exec(file.read())
    SendRaw, `%run main.py --cmd 
    SendInput, {Enter}
    return


;--------------------- 
; Remap - Escape

;^Space:: ; Control+Escape
   ;send, {Esc}
   ;return
;--------------------- 


;=====================
; Alt + h / j / k / l
; Emulates Vim Movement
;!h::
    ;send, {Left}
    ;return
;!j::
    ;send, {Down}
    ;return
;!k::
    ;send, {Up}
    ;return
;!l::
    ;send, {Right}
    ;return
;=====================
; WindowsKey + h / j / k / l
; Emulates Vim Movement
;#h::
    ;send, #{Left}
    ;return
;#j::
    ;send, #{Down}
    ;return
;#k::
    ;send, #{Up}
    ;return
;#l::
    ;send, #{Right}
    ;return
;---------------------    
;#ScrollLock::
;    Run, % "rundll32.exe user32.dll,LockWorkStation"
;    return
;---------------------    
^q:: ; Ctrl+Q
    IfWinActive ahk_class ConsoleWindowClass 
    {
        SendInput, {Enter} exit {Enter}
    }
    else
    {
    sendInput, !{F4}
    }
    return
;---------------------    
#o:: ; Win+O
    Open("ControlPanel")
    return
#u:: ; Win+U
    Open("ControlPanel")
    return
;---------------------
;#a:: ; Win+A
    ;ClipTemp := Clipboard
    ;Send ^c
    ;Run, http://alternativeto.net
    ;Clipboard := ClipTemp
    ;return
;---------------------
;#q:: ; Win+Q
    ;EnvGet port_apps, PORT_APPS
    ;Run, "%port_apps%\\procexp.exe"
    ;return
;--------------------
#s:: ; Win+S
    ClipTemp := Clipboard
    Send ^c
    Run, http://www.scholar.google.com//scholar?hl=en&q=%Clipboard%&btnG=&as_sdt=1\`%2C33&as_sdtp=
    Clipboard := ClipTemp
    return
;---------------------
;#g:: ; Win+G
    ;ClipTemp := Clipboard
    ;Send ^c
    ;Run, http://www.google.com/search?q=%Clipboard%
    ;Clipboard := ClipTemp
    ;return
;---------------------
#e:: ; Win+E
    ; Opens My Computer
    FocusDpath("/root,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}")
    ; Highlights the navbar 
    Sleep 500
    Send {F6}
    Send {Space}
    return
;---------------------

;#NumpadIns:: 
    ;MsgBox, "hi"
    ;Send {#R}
    ;return

;=====================
; FUNCTION KEYS
;=====================
f7::
    EnvGet local, LOCAL
    dfscript  = %local%/speech/startdf.bat
    Run, %dfscript%
    return
;---------------------
f8::
    EnvGet local, LOCAL
    port_vimrc  = %local%\vim\portable_vimrc
    GVIMReopen(port_vimrc)
    return
;---------------------
f9:: 
    EnvGet rob, ROB
    rob_win = "%rob%\rob_settings.py"
    GVIMFocus(rob_win)
    return
;---------------------
f10:: 
    EnvGet rob, ROB
    rob_win = "%rob%\rob_interface.py"
    GVIMFocus(rob_win)
    return
;---------------------
f11:: 
    EnvGet local, LOCAL
    dragonflymain  = %local%\speech\commands.py
    GVIMFocus(dragonflymain)
    return
;---------------------
f12:: 
    EnvGet ahk_scripts, AHK_SCRIPTS
    crall_ahk = "%ahk_scripts%\crallj.ahk"
    GVIMFocus(crall_ahk)
    return
;;---------------------
;^NumpadIns:: ; Control+NumPad-0
^f12:: 
    EnvGet ahk_scripts, AHK_SCRIPTS
    ahk_scripts = "%ahk_scripts%\crallj.ahk"
    Reload %crall_ahk%
    return
;---------------------
; WINDOWS KEY + H TOGGLES HIDDEN FILES
#IfWinActive ahk_class CabinetWClass
^h:: 
    update_cwd()
    Run, attrib +h *.pyc /s ; Hide Python Compiled Files

    RegRead, HiddenFiles_Status, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden 
    If HiddenFiles_Status = 2 
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1 
    Else 
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2 
    WinGetClass, eh_Class,A 
    ;If (eh_Class = "#32770" OR A_OSVersion = "WIN_VISTA") 
    send, {F5} 
    ;Else PostMessage, 0x111, 28931,,, A 
    Return
#IfWinActive ahk_class ExploreWClass
    ^L::
    Send {F6}
    Send {F6}
    Send {Space}
    return
#IfWinActive ahk_class CabinetWClass
    ^L::
    Send {F6}
    Send {F6}
    Send {Space}
    return
#IfWinActive

;---------------------
; Current Working Directory funcs
get_cwd()
{
    ; Gets the CWD as the explorer window you are in. 
    ; Otherwise defaults to the some directory
    WinGetText, cwd, A
    StringSplit, word_array, cwd, `n
    cwd = %word_array1%   
    cwd := RegExReplace(cwd, "^Address: ", "")
    StringReplace, cwd, cwd, `r, , all
    IfInString cwd, \
        {
        return cwd
        }
    else
        {
        cwd := "?Uknown?String?"
        ; EnvGet cwd, HOME
        }
    return cwd
}
get_cwd_or_env(envvar)
{
    startdir := get_cwd()
    if startdir = ?Uknown?String?
    {
    startdir := envvar
    }
    return startdir
}
; -
update_cwd()
{
    EnvGet envvar, HOME
    new_cwd = get_cwd_or_env(envvar)
    SetWorkingDir, %new_cwd%
}
;--------------------
; The applications I like to open

Open(arg)
{
    if (arg = "ControlPanel")
    {
        Run, CMD /C "Control Panel"
    }
    else if (arg = "cmd" )
    {
        EnvGet envvar, home
        ;EnvGet envvar, hs
        startdir := get_cwd_or_env(envvar)
        Run,  "cmd" /k cd /D "%startdir%"
    }
    else if (arg = "chrome" )
    {
        Run, Chrome
    }
    else if (arg = "qtc")
    {
        EnvGet home, USERPROFILE
        envar = %home%\code\ibeis
        SetWorkingDir, %envvar%
        Run, qtc.bat
    }
    else if (arg = "Calculator")
    {
        Run, calc
    }
    else if (arg = "vim")
    {
        ; EnvGet home, USERPROFILE
        ; start_dir = %home%\code\ibeis
        ; GVIM(start_dir)
        EnvGet vim_bin, VIM_BIN
        Run, "%vim_bin%\gvim.exe"
    }
    else if (arg = "todo")
    {
        ; EnvGet clouddir, CLOUD
        EnvGet home, USERPROFILE
        crall_todo = %home%\Dropbox\Notes\TODO.txt
        crall_havedone = %home%\Dropbox\Notes\HAVEDONE.txt
        ;GVIMFocus(crall_todo, crall_havedone)
        GVIMFocus(crall_todo)
    }    
    else if (arg = "personal")
    {
        EnvGet home, USERPROFILE
        crall_personal = %home%\Dropbox\Notes\Personal\notes.txt
        GVIMFocus(crall_personal)
    }
    return
}

Focus(arg)
{
    focused := "False"
    if (arg = "chrome")
    {
        IfWinExist, ahk_class Chrome_WidgetWin_1
        {
            focused := "True"
            WinActivate
        }
    }
    else if (arg = "vim") 
    {
        IfWinExist, ahk_class Vim
        {
            focused := "True"
            WinActivate
        }
    }
    else if (arg = "cmd")
    {
        IfWinExist, ahk_class ConsoleWindowClass
        {
            focused := "True"
            WinActivate
        }
    }
    else if (arg = "qtc")
    {
        IfWinExist, IPython
        {
            focused := "True"
            WinActivate
        }
    }
    else if (arg = "Calculator")
    {
        IfWinExist, ahk_class CalcFrame
        {
            focused := "True"
            WinActivate
        }
    }

    if ( focused = "False" )
    {
        Open(arg)
    }
    return
}

FocusDPath(dpath)
{
    ; Check Focus
    SplitPath, dpath, dname, parent_dpath   
    SetTitleMatchMode 3 ; match exactely
    IfWinExist , %dname%
    {
        IfWinNotActive , %dname%
        {
            WinActivate
        }
    }
    else
    {
    RunWait, explorer.exe %dpath%
    }
    return
}
;    focusfirst(dpath, dpath)

GVIM(file, splitfile="")
{
    EnvGet vim_bin, VIM_BIN
    SplitPath, file, file_name, file_path   
    SetWorkingDir, %file_path%
    Run, "%vim_bin%\gvim.exe" -O %file% %splitfile%
    return
}

GVIMFocus(file, splitfile="")
{ 
    SplitPath, file, file_name, file_path   
    IfWinExist %file_name%
    {
        WinActivate
    }
    else
    {
        GVIM(file, splitfile)
    }
    return
}

GVIMReopen(file)
{
    SplitPath, file, file_name, file_path   
    IfWinExist, %file_name% 
    {
        WinClose
    }
    GVIM(file)
    return
}

