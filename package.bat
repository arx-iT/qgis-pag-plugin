@echo off
rem ==========================================================================
rem  package.bat - construit le zip d'installation du plugin PAG Luxembourg
rem                en reutilisant Clean4Publish.bat, sur une copie jetable.
rem
rem  Usage : package.bat [VERSION] [DEPOT]      exemple : package.bat 2.0.0
rem          VERSION : par defaut, version de metadata.txt au dernier commit
rem          DEPOT   : dossier du depot Git, par defaut le dossier du script
rem                    (le script est place a la racine du depot)
rem
rem  Deroulement :
rem    1. clone du TAG VERSION dans un dossier temporaire neuf
rem       (%TEMP%\pag_package_NNNN\PagLuxembourg) ;
rem    2. Clean4Publish.bat (celui du tag, inchange) est lance DANS ce clone,
rem       et nulle part ailleurs ;
rem    3. le dossier nettoye est zippe en DEPOT\livraisons\VERSION\PagLuxembourg.zip,
rem       fichier a committer ensuite (le README pointe vers lui) ;
rem    4. le zip est controle, puis le dossier temporaire est supprime.
rem
rem  Securite : le depot n'est ni modifie ni nettoye (seul le zip y est ajoute,
rem  dans livraisons\VERSION\). Seuls sont supprimes
rem  le dossier temporaire cree par ce script et, s'il est non conforme,
rem  le zip qu'il vient de creer. Un zip existant n'est jamais ecrase.
rem ==========================================================================
setlocal EnableExtensions DisableDelayedExpansion
set "PLUGIN=PagLuxembourg"
set "RC=1"
set "MSG="
set "WORK="
set "SUF="

where git >nul 2>&1 || (set "MSG=git introuvable dans le PATH." & goto :erreur)
where tar >nul 2>&1 || (set "MSG=tar introuvable (fourni avec Windows 10 et 11)." & goto :erreur)

rem -- Depot : argument 2, sinon dossier du script (racine du depot)
set "REPO=%~2"
if not defined REPO set "REPO=%~dp0"
for %%r in ("%REPO%\.") do set "REPO=%%~fr"
git -C "%REPO%" rev-parse --is-inside-work-tree >nul 2>&1 || (set "MSG=%REPO% n'est pas un depot Git." & goto :erreur)

rem -- Version : argument 1, sinon metadata.txt du dernier commit
set "VERSION=%~1"
if not defined VERSION for /f "tokens=2 delims==" %%v in ('git -C "%REPO%" show HEAD:metadata.txt 2^>nul ^| findstr /b /c:"version="') do set "VERSION=%%v"
if not defined VERSION (set "MSG=version introuvable : passez-la en argument, ex. package.bat 2.0.0" & goto :erreur)
for /f "delims=0123456789." %%x in ("%VERSION%") do (set "MSG=version invalide : chiffres et points uniquement, ex. 2.0.0" & goto :erreur)

rem -- Le tag doit exister, contenir Clean4Publish.bat et la bonne version dans metadata.txt
git -C "%REPO%" rev-parse -q --verify refs/tags/%VERSION% >nul 2>&1 || (set "MSG=le tag %VERSION% n'existe pas. Creez-le apres le commit de metadata.txt, avec : git tag -a %VERSION%" & goto :erreur)
git -C "%REPO%" cat-file -e %VERSION%:Clean4Publish.bat 2>nul || (set "MSG=le tag %VERSION% ne contient pas Clean4Publish.bat." & goto :erreur)
set "META="
for /f "tokens=2 delims==" %%v in ('git -C "%REPO%" show %VERSION%:metadata.txt 2^>nul ^| findstr /b /c:"version="') do set "META=%%v"
if not "%META%"=="%VERSION%" (set "MSG=metadata.txt du tag %VERSION% indique version=%META%. Corrigez metadata.txt, committez, puis retaguez." & goto :erreur)

rem -- Zip dans DEPOT\livraisons\VERSION\, jamais ecrase
for %%z in ("%REPO%\livraisons\%VERSION%") do set "OUTDIR=%%~fz"
set "ZIP=%OUTDIR%\%PLUGIN%.zip"
if exist "%ZIP%" (set "MSG=%ZIP% existe deja. Deplacez-le ou supprimez-le vous-meme, puis relancez." & goto :erreur)

git -C "%REPO%" diff --quiet HEAD 2>nul || echo ATTENTION : modifications non committees dans le depot. Elles ne sont PAS dans le zip, qui vient du tag %VERSION%.

rem -- 1. Clone jetable du tag dans un dossier temporaire neuf
set "SUF=%RANDOM%%RANDOM%"
set "WORK=%TEMP%\pag_package_%SUF%"
if exist "%WORK%" (set "MSG=dossier temporaire deja present, relancez." & set "WORK=" & goto :erreur)
mkdir "%WORK%" || (set "MSG=impossible de creer le dossier temporaire." & set "WORK=" & goto :erreur)
echo Clone du tag %VERSION% dans un dossier temporaire...
git clone -q --no-hardlinks --branch %VERSION% "%REPO%" "%WORK%\%PLUGIN%" 2>nul || (set "MSG=echec du clone du tag %VERSION%." & goto :erreur)

rem -- 2. Clean4Publish.bat, lance uniquement si l'on est bien dans le clone jetable
pushd "%WORK%\%PLUGIN%" || (set "MSG=clone temporaire inaccessible." & goto :erreur)
if /i not "%CD%"=="%WORK%\%PLUGIN%" (popd & set "MSG=dossier courant inattendu, Clean4Publish.bat non lance." & goto :erreur)
if not exist "Clean4Publish.bat" (popd & set "MSG=Clean4Publish.bat absent du clone." & goto :erreur)
echo Nettoyage du clone par Clean4Publish.bat...
rem    Lance dans un cmd separe : Clean4Publish.bat se supprime lui-meme a la fin.
rem    Chemin explicite : certains postes interdisent la recherche dans le dossier courant.
cmd /d /c ".\Clean4Publish.bat" >nul 2>&1
rem    Complement a Clean4Publish.bat : le cache Visual Studio .vs (committe en 1.4.5),
rem    les zips des versions precedentes (livraisons) et ce script, s'il est committe,
rem    ne doivent pas partir dans le zip.
if exist ".vs\" rd /s /q ".vs"
if exist "livraisons\" rd /s /q "livraisons"
if exist "package.bat" del /q "package.bat"
popd
if exist "%WORK%\%PLUGIN%\.git\" (set "MSG=Clean4Publish.bat n'a pas nettoye le clone." & goto :erreur)

rem -- 3. Zip du dossier nettoye
if not exist "%OUTDIR%\" mkdir "%OUTDIR%" || (set "MSG=impossible de creer %OUTDIR%." & goto :erreur)
echo Construction de "%ZIP%"...
tar -a -c -f "%ZIP%" -C "%WORK%" %PLUGIN% || (set "MSG=echec de la creation du zip." & goto :zip_non_conforme)

rem -- 4. Controle du zip
tar -tf "%ZIP%" | findstr /v /b /c:"%PLUGIN%/" >nul && (set "MSG=le zip contient des fichiers hors du dossier %PLUGIN%/." & goto :zip_non_conforme)
tar -tf "%ZIP%" | findstr /i /c:"/.git/" /c:"/.vs/" /c:"/.settings/" /c:"/admin/" /c:"/help/source/" /c:"/pylintrc" /c:"/Clean4Publish.bat" /c:"/package.bat" /c:"/livraisons/" >nul && (set "MSG=le zip contient des fichiers de developpement." & goto :zip_non_conforme)
tar -tf "%ZIP%" | findstr /x /c:"%PLUGIN%/metadata.txt" >nul || (set "MSG=metadata.txt absent du zip." & goto :zip_non_conforme)
set "NB="
for /f %%n in ('tar -tf "%ZIP%" ^| findstr /v /r /c:"/$" ^| find /c /v ""') do set "NB=%%n"
echo Controle OK : dossier racine %PLUGIN%/, %NB% fichiers, version %VERSION%, aucun fichier de developpement.
echo.
echo Zip pret : "%ZIP%"
echo Etapes suivantes : tester "Installer depuis un ZIP" dans un profil QGIS de test,
echo puis committer livraisons\%VERSION%\%PLUGIN%.zip et mettre a jour le lien du README.
set "RC=0"
goto :nettoyage

:zip_non_conforme
del "%ZIP%" >nul 2>&1
echo ERREUR : %MSG%
echo Le zip non conforme vient d'etre supprime. Le depot n'a pas ete modifie.
goto :nettoyage

:erreur
echo ERREUR : %MSG%
echo Le depot n'a pas ete modifie.

:nettoyage
rem -- Suppression du seul dossier temporaire cree par ce script
if not defined WORK goto :pause
if not defined SUF goto :pause
if /i not "%WORK%"=="%TEMP%\pag_package_%SUF%" goto :pause
if exist "%WORK%\" rd /s /q "%WORK%"

:pause
rem -- Garder la fenetre ouverte en cas de double-clic (sans argument, lance par cmd /c).
rem    Expansion retardee : la ligne de commande n'est jamais interpretee.
setlocal EnableDelayedExpansion
set "CMDL=!cmdcmdline!"
if "%~1"=="" if /i not "!CMDL:%~nx0=!"=="!CMDL!" pause
endlocal
endlocal & exit /b %RC%
