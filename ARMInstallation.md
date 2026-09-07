# 🚀 Guide d'installation de Mozart 2 sur macOS (Apple Silicon)

Ce guide est destiné aux étudiants en **BAC 2 Informatique à l'École Polytechnique de Louvain** dans le cadre du cours de **Concepts de Langages de Programmation (LINFO1104)**. Il permet d'installer l'environnement Mozart 2 sur les Mac équipés de puces **Apple Silicon (M1, M2, M3, M4)**.

---

## 1. Préparation et Installation

Fini les lignes de commande complexes, l'installation se fait désormais de manière graphique et native !

### Installer l'éditeur de base

Téléchargez et installez **Aquamacs** depuis [le site officiel](https://aquamacs.org/downloads/).

Glissez simplement l'application dans votre dossier **Applications**.

### Télécharger Mozart 2

Rendez-vous sur la page des versions du projet et téléchargez le fichier d'installation **`Mozart2-ARM64.dmg`** via [ce lien direct](https://github.com/Arthvrr/mozart2/releases/tag/macos-beta).

### Installer l'environnement

Ouvrez le fichier `.dmg` que vous venez de télécharger, puis glissez l'icône **Mozart2** dans le dossier **Applications**.

---

## 2. Contourner la sécurité macOS (Gatekeeper)

Comme l'application ne provient pas du Mac App Store, macOS va la bloquer lors du premier lancement. C'est un comportement normal.

1. Ouvrez votre dossier **Applications** et double-cliquez sur **Mozart2**.
2. Un message d'avertissement s'affichera. Cliquez sur **Terminé** (Pas sur Placer dans la corbeille).
3. Ouvrez vos **Réglages Système (System Settings)** et rendez-vous dans l'onglet **Confidentialité et sécurité (Privacy & Security)**.
4. Faites défiler la page vers le bas. Vous verrez un message indiquant que le lancement de **Mozart2** a été bloqué.
5. Cliquez sur le bouton **Ouvrir quand même (Open Anyway)**.
6. Confirmez avec votre mot de passe ou **Touch ID**.
7. Rouvrez l'application **Mozart2**.

Aquamacs se lancera automatiquement avec l'interface Oz (**OPI**) parfaitement configurée !

---

## 3. Test de l'environnement (Le Hello World)

Vérifions que le moteur graphique de l'application fonctionne correctement.

Dans la fenêtre **Aquamacs** qui vient de s'ouvrir, tapez la ligne de code suivante :

```oz
{Browse 'Hello, World!'}
```

Sélectionnez ce texte avec votre curseur.
Allez dans le menu supérieur (ou faites un clic-droit) et choisissez **Oz** puis **Feed Region**.
Si la fenêtre du Oz Browser s'ouvre avec votre message, félicitations, l'installation est un succès ! 🎉

--- 

## 4. Alternative : Visual Studio Code

Si vous êtes plus à l'aise avec VS Code qu'avec Aquamacs, il est tout à fait possible d'y coder en Oz.

Installez l'extension officielle depuis le Marketplace : Mozart Oz. [Lien ici au besoin](https://marketplace.visualstudio.com/items?itemName=mozart-oz.vscode-oz)

```
⚠️ Étape cruciale
Par défaut, l'extension cherchera le moteur Mozart dans les dossiers systèmes profonds de votre Mac.
Vous devez lui indiquer où se trouve la nouvelle application.
```

Ouvrez les paramètres de l'extension dans VS Code et modifiez les chemins absolus (Absolute path) comme ceci :

> Ozengine Path : /Applications/Mozart2.app/Contents/Resources/bin/ozengine