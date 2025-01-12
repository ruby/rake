@ECHO OFF

ECHO ---------------------------------------------------------------
ruby -I lib -r rake -e "print '    platform: ' + (Rake::Win32.windows? ? 'Windows' : 'Unix')"
ruby -e "puts ' / branch: ' + %%x{git symbolic-ref --quiet --short HEAD}.chomp"
ECHO:

GOTO :main

:echoWindowsEnv
ECHO [Windows] %%HOME%%=%HOME%
ECHO [Windows] %%HOMEDRIVE%%=%HOMEDRIVE%
ECHO [Windows] %%HOMEPATH%%=%HOMEPATH%
ECHO [Windows] %%APPDATA%%=%APPDATA%
ECHO [Windows] %%USERPROFILE%%=%USERPROFILE%
ECHO:
GOTO :eof

:putsRubyEnv
ruby -e 'puts "[Ruby] ENV[\"HOME\"] = " + ENV.fetch("HOME", "nil")'
ruby -e 'puts "[Ruby] ENV[\"HOMEDRIVE\"] = " + ENV.fetch("HOMEDRIVE", "nil")'
ruby -e 'puts "[Ruby] ENV[\"HOMEPATH\"] = " + ENV.fetch("HOMEPATH", "nil")'
ruby -e 'puts "[Ruby] ENV[\"APPDATA\"] = " + ENV.fetch("APPDATA", "nil")'
ruby -e 'puts "[Ruby] ENV[\"USERPROFILE\"] = " + ENV.fetch("USERPROFILE", "nil")'
ECHO:
GOTO :eof

:returnRubyDirHome
for /f "delims=" %%i in ('ruby -e "puts File.join(Dir.home, \"Rake\")"') do set RUBY_DIR=%%i
GOTO :eof

:returnRakeWin32SystemDir
for /f "delims=" %%i in ('ruby -I lib -r rake -e "puts Rake::Win32::win32_system_dir"') do set RAKE_DIR=%%i
GOTO :eof

:compareValues
CALL :returnRubyDirHome
CALL :returnRakeWin32SystemDir
ECHO [Ruby] File.join^(Dir.home, "Rake"^)   =^> %RUBY_DIR%
ECHO [Rake] Rake::Win32::win32_system_dir =^> %RAKE_DIR%
if "%RUBY_DIR%"=="%RAKE_DIR%" (
    ECHO ✅ PASS: Values match
) else (
    ECHO ❌ FAIL: Values do not match
    set /a FAILURE_COUNT+=1
)
GOTO :eof

:main

SET FAILURE_COUNT=0

ECHO ---------------------------------------------------------------
ECHO 1/5 - %%HOME%% set in Windows env
ECHO ---------------------------------------------------------------

SET HOME=C:\HP
SET HOMEDRIVE=
SET HOMEPATH=
SET APPDATA=
SET USERPROFILE=

CALL :echoWindowsEnv
CALL :putsRubyEnv

CALL :compareValues

ECHO:

ECHO ---------------------------------------------------------------
ECHO 2/5 - %%HOMEDRIVE%% and %%HOMEPATH%% set in Windows env
ECHO ---------------------------------------------------------------

SET HOME=
SET HOMEDRIVE=C:
SET HOMEPATH=\HP
SET APPDATA=
SET USERPROFILE=

CALL :echoWindowsEnv
CALL :putsRubyEnv

CALL :compareValues

ECHO:

ECHO ---------------------------------------------------------------
ECHO 3/5 - %%APPDATA%% set in Windows env
ECHO ---------------------------------------------------------------

SET HOME=
SET HOMEDRIVE=
SET HOMEPATH=
SET APPDATA=C:\Documents and Settings\HP\Application Data
SET USERPROFILE=

CALL :echoWindowsEnv
CALL :putsRubyEnv

CALL :compareValues

ECHO:

ECHO ---------------------------------------------------------------
ECHO 4/5 - %%USERPROFILE%% set in Windows env
ECHO ---------------------------------------------------------------

SET HOME=
SET HOMEDRIVE=
SET HOMEPATH=
SET APPDATA=
SET USERPROFILE=C:\Documents and Settings\HP

CALL :echoWindowsEnv
CALL :putsRubyEnv

CALL :compareValues

ECHO:

ECHO ---------------------------------------------------------------
ECHO 5/5 - nothing set in Windows env
ECHO ---------------------------------------------------------------
ECHO       Ruby *always* sets HOME [and USER for that matter]
ECHO       in *its* environment, even if these are not set in
ECHO       the Windows environment.
ECHO:
ECHO       https://github.com/ruby/ruby/commit/c41cefd492
ECHO ---------------------------------------------------------------

SET HOME=
SET HOMEDRIVE=
SET HOMEPATH=
SET APPDATA=
SET USERPROFILE=

CALL :echoWindowsEnv
CALL :putsRubyEnv

CALL :compareValues

ECHO:

ECHO ----------------------------------
ECHO:

if %FAILURE_COUNT% GTR 0 (
    ECHO ❌ OVERALL RESULT: %FAILURE_COUNT% test^(s^) failed
    exit /b 1
) else (
    ECHO ✅ OVERALL RESULT: All tests passed
    exit /b 0
)

