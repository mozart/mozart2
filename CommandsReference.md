# Référence des Commandes - Mozart 2 sur macOS ARM64

Ce document répertorie l'ensemble des commandes essentielles pour configurer, compiler, tester et maintenir le projet Mozart 2 après son portage sur Apple Silicon.

---

# 1. Initialisation et Configuration du Projet

## `cmake ..` — Configuration initiale

### Description

La commande `cmake ..` analyse l'arborescence des sources depuis le dossier de compilation (`build/`) et génère les fichiers de configuration nécessaires à la compilation.

Elle prend en compte :
- la plateforme hôte macOS ;
- l'architecture Apple Silicon (`arm64`) ;
- les correctifs CMake ajoutés pour supporter les versions modernes des dépendances ;
- la configuration des compilateurs LLVM/Clang.

### Utilisation

```bash
mkdir build
cd build
cmake ..
```

---

# 2. Compilation et Build

## `make`

### Description

Lance la compilation globale de l'ensemble du projet Mozart 2.

Cette commande compile notamment :

- la bibliothèque centrale de la machine virtuelle (`libmozartvm`) ;
- l'émulateur `ozemulator` ;
- le compilateur Oz ;
- les interfaces système ;
- les composants graphiques ;
- les outils associés.

### Utilisation

```bash
cd build
make
```

---

## `make mozartvm`

### Description

Compile uniquement la bibliothèque statique principale du cœur de la machine virtuelle :

```text
libmozartvm.a
```

Cette commande est particulièrement utile lors de modifications internes de la VM, par exemple :

- `unpickler.cc` ;
- le système de chargement des bytecodes `.ozf` ;
- les composants internes du Garbage Collector ;
- les structures fondamentales de la machine virtuelle.

Elle évite de reconstruire l'ensemble du projet.

### Utilisation

```bash
make mozartvm
```

---

## `make vmtest`

### Description

Compile l'exécutable de tests unitaires C++ basé sur Google Test.

Ce programme permet de vérifier le bon fonctionnement des composants fondamentaux de la VM :

- `SmallInt` ;
- `Float` ;
- `Atom` ;
- structures internes ;
- Garbage Collector.

### Utilisation

```bash
make vmtest
```

---

## `make platform-test`

### Description

Cible spéciale du système de build permettant de générer automatiquement l'ensemble des tests de plateforme.

Elle compile les scripts source Oz :

```text
.oz
```

en fichiers bytecode exécutables :

```text
.ozf
```

dans les différents sous-dossiers :

```text
base/
bench/
dp/
dp-bench/
debug/
```

Cette étape est nécessaire avant l'exécution complète de la suite CTest.

### Utilisation

```bash
make platform-test
```

---

# 3. Exécution et Validation des Tests (CTest)

## `ctest --output-on-failure`

### Description

Exécute l'ensemble de la suite de tests fonctionnels de la plateforme.

Cette commande lance :

- les tests unitaires C++ ;
- les tests de scripts Oz ;
- les tests d'intégration de la machine virtuelle.

En cas d'échec, l'option :

```text
--output-on-failure
```

affiche directement les logs détaillés permettant d'identifier l'origine du problème.

### Utilisation

```bash
ctest --output-on-failure
```

---

## `ctest --verbose -R "<nom_du_test>"`

### Description

Exécute un test spécifique en mode détaillé.

L'option :

```text
--verbose
```

permet d'afficher :

- la commande exacte exécutée par CTest ;
- les chemins des fichiers `.ozf` utilisés ;
- la sortie complète du script de test ;
- les éventuelles erreurs de chargement.

L'option :

```text
-R
```

permet de filtrer le test à exécuter grâce à son nom.

### Exemple

```bash
ctest --verbose -R "conversion.oz"
```

---

# 4. Utilitaires de Maintenance et Sécurité macOS

## `xattr -cr ../`

### Description

Supprime récursivement les attributs étendus macOS du projet.

Cette commande permet notamment de retirer les attributs de quarantaine ajoutés par macOS (`Gatekeeper` / `XProtect`) sur les fichiers compilés.

Elle est utile lorsque macOS bloque l'exécution de nouveaux binaires générés localement.

### Utilisation

```bash
xattr -cr ../
```

---

# 5. Nettoyage des Caches et Artefacts de Compilation

## Suppression des anciens fichiers générés

### Description

Supprime les anciens fichiers compilés, caches du compilateur et artefacts de tests.

Cette opération permet de repartir d'un environnement propre lors :

- d'une recompilation complète ;
- d'une modification importante du code source ;
- d'un changement de version de dépendance ;
- d'un test de validation du portage ARM64.

### Nettoyage du cache compilateur

```bash
rm -rf build/lib/cache
```

### Suppression des anciens fichiers `.ozf`

```bash
rm -f build/platform-test/*.ozf
```

---

# Résumé des Commandes Principales

| Objectif | Commande |
|---|---|
| Configurer le projet | `cmake ..` |
| Compiler entièrement Mozart 2 | `make` |
| Compiler uniquement la VM | `make mozartvm` |
| Compiler les tests C++ | `make vmtest` |
| Générer les fichiers `.ozf` de test | `make platform-test` |
| Lancer tous les tests | `ctest --output-on-failure` |
| Tester un fichier spécifique | `ctest --verbose -R "<nom_du_test>"` |
| Retirer les blocages macOS | `xattr -cr ../` |
| Nettoyer les caches | `rm -rf build/lib/cache` |
| Supprimer les artefacts `.ozf` | `rm -f build/platform-test/*.ozf` |