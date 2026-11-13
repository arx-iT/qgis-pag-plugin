@echo off
rem ==========================================================================
rem  package.bat - construit le zip d'installation du plugin PAG Luxembourg
rem                a partir des fichiers de ce dossier.
rem
rem  Usage    : .\package.bat   (ou double-clic)
rem  Resultat : dist\PagLuxembourg-<version>.zip, version lue dans metadata.txt.
rem             Un zip existant de la meme version est remplace.
rem
rem  Les fichiers de developpement exclus du zip sont listes a l'etape 1.
rem ==========================================================================
setlocal
set "RC=1"
for %%r in ("%~dp0.") do set "SRC=%%~fr"
set "WORK=%TEMP%\pag_package_%RANDOM%%RANDOM%"

set "VERSION="
for /f "tokens=2 delims==" %%v in ('findstr /b /c:"version=" "%SRC%\metadata.txt" 2^>nul') do set "VERSION=%%v"
if not defined VERSION (echo ERREUR : version= introuvable dans metadata.txt. & goto :fin)
set "ZIP=%SRC%\dist\PagLuxembourg-%VERSION%.zip"

rem -- 1. Copie du plugin dans un dossier temporaire, sans les fichiers de developpement
echo Copie des fichiers du plugin (version %VERSION%)...
rem    /R:1 /W:1 : un fichier verrouille fait echouer la copie au lieu de la bloquer.
robocopy "%SRC%" "%WORK%\PagLuxembourg" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP ^
  /XD .git .vs __pycache__ "%SRC%\dist" "%SRC%\.settings" "%SRC%\admin" "%SRC%\assets\sample_data" "%SRC%\help\source" ^
  /XF *.pyc "%SRC%\.gitignore" "%SRC%\.gitattributes" "%SRC%\.project" "%SRC%\.pydevproject" "%SRC%\pylintrc" ^
      "%SRC%\package.bat" "%SRC%\help\make.bat" "%SRC%\help\Makefile" ^
      "%SRC%\i18n\release.bat" "%SRC%\i18n\update.bat"
if errorlevel 8 (echo ERREUR : echec de la copie des fichiers, voir le message ci-dessus. & goto :fin)

rem -- 2. Zip, puis remplacement de celui de la meme version dans dist\
rem    tar de Windows appele explicitement : un tar GNU (Git, MSYS) ne sait pas faire de zip.
"%SystemRoot%\System32\tar.exe" -a -c -f "%WORK%\plugin.zip" -C "%WORK%" PagLuxembourg || (echo ERREUR : echec de la creation du zip. & goto :fin)
if not exist "%SRC%\dist\" mkdir "%SRC%\dist"
move /y "%WORK%\plugin.zip" "%ZIP%" >nul || (echo ERREUR : impossible d'ecrire "%ZIP%", fichier ouvert ailleurs ? & goto :fin)
echo Zip pret : "%ZIP%"
set "RC=0"

:fin
if exist "%WORK%\" rd /s /q "%WORK%"
rem -- Double-clic : garder la fenetre ouverte pour lire le resultat
setlocal EnableDelayedExpansion
if /i not "!cmdcmdline:%~nx0=!"=="!cmdcmdline!" pause
endlocal & exit /b %RC%
