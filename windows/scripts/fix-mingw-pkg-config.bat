:: autogenerated in build_tpl.py
set pkgconfig_name=pkg-config-lite-0.28-1
set pkgconfig_zip=%pkgconfig_name%-win32.zip
set MINGW_BIN="C:\MinGW\bin"
set MINGW_SHARE="C:\MinGW\bin"
set pkg_config_dlsrc=^
http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/%pkgconfig_name%_bin-win32.zip

:: Download pkg-config-lite
wget %pkg_config_dlsrc%

:: Unzip and remove zipfile
unzip %pkgconfig_zip%
rm %pkgconfig_zip%

:: Install contents to MSYS
cp %pkgconfig_name%/bin/pkg-config.exe %MINGW_BIN%
cp -r %pkgconfig_name%/share/aclocal %MINGW_SHARE%