# qgis-pag-plugin
Plugin QGIS pour la gestion des PAG du Ministère de l'Intérieur du Grand-Duché de Luxembourg

## Installation

Version 2.0.0, pour **QGIS 4.2 ou plus récent**.

1. Construire le zip d'installation (voir [Compilation](#compilation)).
2. Dans QGIS : *Extensions > Installer/Gérer les extensions > Installer depuis un ZIP*, choisir le zip construit, puis *Installer l'extension*.
3. Dans l'onglet *Installées*, vérifier que les extensions **Geometry Checker** et **Topology Checker**, fournies avec QGIS, sont activées : le plugin en a besoin.

## Compilation

Le script `package.bat` construit le zip d'installation à partir des fichiers du
dossier, avec la version indiquée dans `metadata.txt`. Depuis la racine du
dossier, par double-clic ou en ligne de commande :

```
.\package.bat
```

Le zip est créé dans `dist\PagLuxembourg-<version>.zip` (le dossier `dist` est
ignoré par Git) ; un zip existant de la même version est remplacé. Il contient
un seul dossier `PagLuxembourg/`, sans les fichiers de développement.

Le zip proposé par GitHub (*Code > Download ZIP*) ne s'installe pas tel quel
dans QGIS. Il suffit de l'extraire et de lancer `package.bat` dans le dossier extrait.

### Contraintes

- **Windows 10 ou 11** uniquement : le script est un `.bat` et utilise
  `robocopy.exe` et `tar.exe`, fournis avec le système.

### Nouvelle version

1. Mettre à jour `version=` dans `metadata.txt`.
2. Lancer `package.bat`.
3. Tester le zip dans un **profil QGIS de test** : le plugin doit se charger et
   afficher la bonne version.

### Fonctionnement

1. `package.bat` copie le dossier dans un dossier temporaire
   (`%TEMP%\pag_package_NNNN\PagLuxembourg`), sans les fichiers de
   développement : `.git`, `.vs`, `__pycache__`, `*.pyc`, `dist`, `admin`,
   `assets\sample_data`, `help\source`, `help\make.bat`, `help\Makefile`,
   `i18n\*.bat`, fichiers Eclipse (`.settings`, `.project`, `.pydevproject`),
   `pylintrc`, `.gitignore`, `.gitattributes` et `package.bat`.
2. Il zippe cette copie, place le zip dans `dist\`, puis supprime le dossier
   temporaire.

Tout fichier non exclu part dans le zip. Un nouveau fichier de développement
doit donc être ajouté à la liste d'exclusion de `package.bat` (étape 1 du
script).

Si le message `impossible d'ecrire ...` s'affiche, fermer le zip de `dist\`
ouvert dans un autre programme, puis relancer : l'ancien zip reste intact.

## Documentation

[Aide utilisateur du plugin PAG Luxembourg](https://rawcdn.githack.com/Geoportail-Luxembourg/qgis-pag-plugin/d8acd21551f2b6f0a3e4f8c203c2cffca0c3dd3a/help/user/index.html)
