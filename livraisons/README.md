# Livraisons : construire le zip d'installation

Ce dossier contient les zips d'installation du plugin, un par version :
`livraisons/<version>/PagLuxembourg.zip`. Le README principal pointe vers le zip
de la version courante.

Ces zips sont prêts à installer dans QGIS (*Installer depuis un ZIP*) : ils
contiennent un seul dossier `PagLuxembourg/`, sans les fichiers de développement.
Le zip proposé par GitHub (*Code > Download ZIP*) ne convient pas : son dossier
porte le nom du dépôt et de la branche, et peut contenir un point, que Python
refuse dans un nom de module.

## Prérequis

- Windows 10 ou 11 (`tar.exe` est fourni avec le système) ;
- Git dans le `PATH`.

## Procédure pour une nouvelle version

Exemple pour la version 2.0.1, depuis la racine du dépôt :

1. Mettre à jour `version=2.0.1` dans `metadata.txt`, puis committer.
2. Créer le tag :
   ```
   git tag -a 2.0.1 -m "Version 2.0.1"
   ```
3. Construire le zip, par double-clic sur `package.bat` ou en ligne de commande :
   ```
   package.bat 2.0.1
   ```
   Le zip est créé dans `livraisons\2.0.1\PagLuxembourg.zip`.
4. Tester le zip dans un **profil QGIS de test** (*Extensions > Installer/Gérer
   les extensions > Installer depuis un ZIP*) : le plugin doit se charger et
   afficher la bonne version.
5. Committer le zip, puis mettre à jour le lien du README principal
   (`livraisons/2.0.1/PagLuxembourg.zip?raw=true`) et committer.
6. Pousser les commits et le tag :
   ```
   git push
   git push origin 2.0.1
   ```

## Ce que fait `package.bat`

1. Il vérifie que le tag existe et que `metadata.txt` du tag porte la même version.
2. Il clone le tag dans un dossier temporaire neuf (`%TEMP%\pag_package_NNNN`).
3. Il lance `Clean4Publish.bat` **dans ce clone uniquement**. Ce script supprime
   les fichiers de développement, en commençant par `.git` : il ne doit jamais
   être lancé à la main dans le dépôt.
4. Il retire aussi du clone `.vs/`, `livraisons/` et `package.bat`.
5. Il zippe le dossier nettoyé, contrôle le zip (dossier racine `PagLuxembourg/`,
   aucun fichier de développement, `metadata.txt` présent), puis supprime le
   dossier temporaire.

Les fichiers de développement sont uniquement ceux listés dans `Clean4Publish.bat`
et dans le complément de `package.bat` (`.vs/`, `livraisons/`, `package.bat`) :
tout autre fichier part dans le zip. Un nouveau fichier ou dossier de
développement doit donc être ajouté à ce complément, et à la liste du contrôle
final de `package.bat` pour être détecté s'il passait quand même.

Le dépôt n'est jamais modifié : seul le zip y est ajouté. Le zip est construit
à partir du tag, donc les modifications non committées n'y figurent pas.

## En cas d'erreur

| Message | Que faire |
|---|---|
| `le tag X n'existe pas` | Committer `metadata.txt`, puis `git tag -a X`. |
| `metadata.txt du tag X indique version=Y` | Corriger `metadata.txt`, committer, supprimer le tag (`git tag -d X`, seulement s'il n'a pas été poussé) et le recréer. |
| `... existe deja` | Le zip de cette version existe : le supprimer soi-même pour le reconstruire. |
| `le zip contient des fichiers de developpement` | Un fichier de la liste n'a pas été retiré : vérifier `Clean4Publish.bat` et le complément de `package.bat`. |
