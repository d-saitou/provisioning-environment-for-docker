@echo off

:: get vagrant.exe path
for /f "usebackq delims=" %%a in (`where vagrant`) do set VAGRANTEXE=%%a
if "%VAGRANTEXE%" equ "" (
	echo Please install vagrant.
	pause
	exit
)

:: install vagrant-vbguest plugin
for /f "usebackq tokens=*" %%i IN (`vagrant plugin list`) DO @set RESULT=%%i
echo %RESULT% | find "vagrant-vbguest" >NUL
if ERRORLEVEL 1 vagrant plugin install vagrant-vbguest

:: change current directory
cd /d %~dp0

:: vagrant up
set TEEEXE=%VAGRANTEXE:\bin\vagrant.exe=%\embedded\usr\bin\tee.exe
set LOGFILE=init.log
vagrant up 2>&1 | %TEEEXE% -a %LOGFILE%

pause
