@echo off

:: Change current directory
cd /d %~dp0

:: Open command-prompt & startup vagrant
start cmd /k vagrant up
