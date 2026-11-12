# Feuille de Route & Relevé des Modifications - Portage Mozart 2 sur Apple Silicon (ARM64)

Ce document récapitule l'ensemble des modifications apportées au code source, la configuration de l'environnement, ainsi que les différentes étapes nécessaires à la compilation du projet Mozart 2 sur macOS ARM64 (Apple Silicon).

---

## 1. Configuration de l'Environnement Système (Homebrew & Variables)

### Dépendances installées via Homebrew

```bash
brew install boost tcl-tk llvm cmake
```

### Variables d'environnement pour la session Terminal

```bash
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
```

---

## 2. Modifications Apportées au Code Source

### A. Fichier : `CMakeLists.txt` (Racine du projet)

**Problème :** Incompatibilité avec CMake moderne, qui exigeait une version de CMake inférieure à 3.5.

**Modification :** Passage de :

```cmake
cmake_minimum_required(VERSION 2.8.6)
```

à :

```cmake
cmake_minimum_required(VERSION 3.5)
```

---

### B. Fichier : `cmake_local/TargetArch.cmake`

**Problème :** L'architecture `arm64` était rejetée avec l'erreur :

```text
Invalid OS X arch name: arm64
```

**Modifications :**

Ajout de la condition pour `arm64` dans la boucle :

```cmake
foreach(osx_arch ${CMAKE_OSX_ARCHITECTURES})
```

Ajout de la condition suivante :

```cmake
elseif("${osx_arch}" STREQUAL "arm64")
    set(osx_arch_arm64 TRUE)
```

Ajout de `arm64` à la liste des architectures retenues :

```cmake
if(osx_arch_arm64)
    list(APPEND ARCH arm64)
endif()
```

---

### C. Fichier : `vm/boostenv/main/CMakeLists.txt`

**Problème :** Incompatibilité avec Boost 1.90.0 :

```text
Could NOT find Boost (missing: system)
```

Le composant `system` n'existe plus en tant que module séparé dans les versions récentes de Boost.

**Modification :** Suppression de `system` dans la directive `find_package`.

**Avant :**

```cmake
find_package(Boost COMPONENTS random system thread filesystem chrono REQUIRED)
```

**Après :**

```cmake
find_package(Boost COMPONENTS random thread filesystem chrono REQUIRED)
```

---

### D. Fichier : `boosthost/emulator/CMakeLists.txt`

**Problème :** Présence de la même dépendance obsolète vers `boost_system`.

**Modification :** Suppression du composant `system` de la liste des composants Boost requis à la ligne 22.

---

## 3. Commande CMake Finale Validée

La commande suivante a été exécutée depuis le dossier :

```text
mozart2/build
```

Commande complète :

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_CXX_COMPILER_ARCHITECTURE_ID=arm64 \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++ \
      -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm/bin/clang \
      -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/llvm;/opt/homebrew/opt/tcl-tk;/opt/homebrew/opt/boost" \
      -DMOZART_BOOST_USE_STATIC_LIBS=OFF \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBOOST_ROOT=/opt/homebrew/opt/boost \
      -DBoost_NO_SYSTEM_PATHS=ON \
      -DBoost_NO_BOOST_CMAKE=ON \
      ..
```

La configuration CMake a été validée avec succès et aboutit à :

```text
Generating done
```

---

## 4. Étape Suivante : Compilation C++

Pour lancer la compilation multi-cœurs :

```bash
make -j $(sysctl -n hw.ncpu)
```

Cette commande utilise automatiquement le nombre de cœurs CPU disponibles sur la machine afin d'accélérer la compilation du projet.

---

## 5. Résumé des Étapes

Pour reproduire le portage sur une machine Apple Silicon (ARM64) :

### Étape 1 — Installer les dépendances

```bash
brew install boost tcl-tk llvm cmake
```

### Étape 2 — Configurer les variables d'environnement

```bash
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
```

### Étape 3 — Modifier `CMakeLists.txt`

Modifier la version minimale requise de CMake :

```cmake
cmake_minimum_required(VERSION 2.8.6)
```

devient :

```cmake
cmake_minimum_required(VERSION 3.5)
```

### Étape 4 — Ajouter le support `arm64`

Dans le fichier :

```text
cmake_local/TargetArch.cmake
```

Ajouter la détection de l'architecture `arm64` :

```cmake
elseif("${osx_arch}" STREQUAL "arm64")
    set(osx_arch_arm64 TRUE)
```

Puis ajouter `arm64` à la liste des architectures retenues :

```cmake
if(osx_arch_arm64)
    list(APPEND ARCH arm64)
endif()
```

### Étape 5 — Modifier la configuration Boost

Dans :

```text
vm/boostenv/main/CMakeLists.txt
```

Remplacer :

```cmake
find_package(Boost COMPONENTS random system thread filesystem chrono REQUIRED)
```

par :

```cmake
find_package(Boost COMPONENTS random thread filesystem chrono REQUIRED)
```

Effectuer également la même modification dans :

```text
boosthost/emulator/CMakeLists.txt
```

en supprimant la dépendance au composant `system`.

### Étape 6 — Se placer dans le dossier de compilation

```bash
cd mozart2/build
```

### Étape 7 — Exécuter la commande CMake

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_CXX_COMPILER_ARCHITECTURE_ID=arm64 \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++ \
      -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm/bin/clang \
      -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/llvm;/opt/homebrew/opt/tcl-tk;/opt/homebrew/opt/boost" \
      -DMOZART_BOOST_USE_STATIC_LIBS=OFF \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBOOST_ROOT=/opt/homebrew/opt/boost \
      -DBoost_NO_SYSTEM_PATHS=ON \
      -DBoost_NO_BOOST_CMAKE=ON \
      ..
```

### Étape 8 — Vérifier la configuration

La configuration CMake est considérée comme réussie lorsque le processus se termine correctement avec :

```text
Generating done
```

### Étape 9 — Lancer la compilation

```bash
make -j $(sysctl -n hw.ncpu)
```

---

## 6. État Actuel

La configuration CMake du projet Mozart 2 est désormais fonctionnelle sur macOS avec une architecture Apple Silicon (`arm64`).

Les principaux problèmes rencontrés et corrigés étaient :

- Compatibilité avec les versions modernes de CMake.
- Reconnaissance de l'architecture Apple Silicon `arm64`.
- Compatibilité avec les versions récentes de Boost.
- Suppression de la dépendance obsolète au composant `boost_system`.
- Configuration explicite des compilateurs LLVM/Clang.
- Configuration du chemin vers les dépendances installées via Homebrew.

La prochaine étape consiste maintenant à lancer la compilation complète du projet avec :

```bash
make -j $(sysctl -n hw.ncpu)
```

Une fois la compilation terminée, il faudra vérifier que le build s'est terminé sans erreur et poursuivre avec les éventuelles étapes de test ou d'installation du projet Mozart 2.

---

# 7. Résolution des Conflits de Génération (Java & C++)

Après la configuration initiale de CMake, de nouveaux problèmes sont apparus lors de la compilation de certains sous-modules du projet. Deux conflits principaux ont été identifiés : un conflit de version Java lors de la génération du sous-module Scala avec SBT, ainsi qu'un conflit lié à la norme C++ utilisée par le projet.

---

## A. Rétrogradation de Java pour Scala (SBT)

### Problème

Le sous-module `bootcompiler` utilise **Scala Build Tool (SBT)** pour compiler et générer certains composants du projet.

La compilation avec la version de Java installée par défaut, Java 21, provoquait des erreurs critiques lors de l'exécution de SBT, notamment :

```text
bad constant pool index
```

ainsi que :

```text
ExceptionInInitializerError
```

Ces erreurs étaient liées à une incompatibilité entre l'ancienne version de Scala utilisée par le projet, basée sur Scala 2.12, et la version récente de Java 21.

Afin de garantir la compatibilité avec l'ancienne chaîne de compilation Scala/SBT utilisée par Mozart 2, Java 11 a été installé et configuré comme version Java utilisée par défaut pour le projet.

### Modification

Installation de Java 11 via Homebrew :

```bash
brew install openjdk@11
```

Création du lien symbolique permettant à macOS de détecter correctement le JDK :

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
```

Configuration de Java 11 comme version active pour la session Terminal :

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export PATH="$JAVA_HOME/bin:$PATH"
```

Cette configuration permet ainsi de forcer SBT et les outils de génération Scala à utiliser Java 11 plutôt que Java 21.

---

## B. Forçage Global de la Norme C++14

### Problème

Après résolution du problème lié à Java et à SBT, une nouvelle incompatibilité est apparue lors de la compilation C++.

La version récente de Boost utilisée par le projet, notamment Boost 1.90.0, exige au minimum l'utilisation de la norme **C++14**.

Cependant, plusieurs fichiers CMake du projet Mozart 2 forçaient encore explicitement l'utilisation de l'ancienne norme C++11 à travers le drapeau :

```text
-std=c++0x
```

Cette configuration provoquait des incompatibilités avec les API et fonctionnalités utilisées par les versions récentes de Boost.

### Modification

Une recherche globale a été effectuée dans le projet afin d'identifier les fichiers CMake utilisant encore l'ancienne norme `c++0x`.

Depuis la racine du projet, les commandes suivantes ont été exécutées :

```bash
find . -type f -name "CMakeLists.txt" -exec sed -i '' 's/c++0x/c++14/g' {} +
```

Puis sur les fichiers `.cmake` :

```bash
find . -type f -name "*.cmake" -exec sed -i '' 's/c++0x/c++14/g' {} +
```

Cette modification a permis de remplacer globalement les anciennes références à :

```text
c++0x
```

par :

```text
c++14
```

Une configuration propre du projet a ensuite été effectuée en ajoutant explicitement le drapeau C++14 à la commande CMake :

```bash
-DCMAKE_CXX_FLAGS="-std=c++14"
```

Cette modification a permis d'assurer que l'ensemble du projet utilise une norme C++ compatible avec les exigences de Boost 1.90.0.

---

# 8. Modernisation du Code C++ (API Boost Asio & Random)

Une fois la compilation débloquée grâce au passage à C++14, de nouvelles erreurs sont apparues directement dans le code source C++ de la machine virtuelle.

Ces erreurs étaient principalement dues aux changements importants introduits dans les versions récentes de Boost, notamment dans les API réseau, temporelles et de gestion des threads.

Les modifications ont principalement concerné les API **Boost.Asio**, la génération de nombres aléatoires et la gestion du cycle de vie des tâches asynchrones.

---

## A. Composants Temporels, Threads et Nombres Aléatoires

### Fichiers modifiés

Les fichiers suivants ont été adaptés :

```text
vm/boostenv/main/boostvm-decl.hh
vm/boostenv/main/boostvm.cc
vm/boostenv/main/boostenv-decl.hh
vm/boostenv/main/boostenv.hh
```

### Inclusions manquantes ajoutées

Les nouvelles API utilisées nécessitaient l'ajout des inclusions suivantes :

```cpp
#include <boost/random/mersenne_twister.hpp>
#include <boost/asio/steady_timer.hpp>
#include <boost/asio/executor_work_guard.hpp>
```

---

### Nombres Aléatoires

L'ancien type :

```cpp
boost::random::mt19937
```

a été remplacé par :

```cpp
boost::mt19937
```

Cette modification permet d'utiliser l'API correspondant à la version de Boost actuellement installée et utilisée par le projet.

---

### Timers Asio

L'ancien composant :

```cpp
deadline_timer
```

étant déprécié dans les versions modernes de Boost.Asio, il a été entièrement remplacé par :

```cpp
steady_timer
```

Les API de gestion du temps ont également été adaptées afin d'utiliser `std::chrono`.

Par exemple, l'ancien code :

```cpp
expires_from_now(boost::posix_time::millisec(1))
```

a été remplacé par :

```cpp
expires_after(std::chrono::milliseconds(1))
```

De même, l'utilisation de :

```cpp
expires_at(boost::posix_time::min_date_time)
```

a été remplacée par :

```cpp
expires_at(boost::asio::steady_timer::time_point::max())
```

Enfin, l'ancienne méthode :

```cpp
expires_at()
```

a été remplacée par :

```cpp
expiry()
```

Ces changements permettent d'adapter la gestion des timers aux API modernes de Boost.Asio basées sur `steady_timer` et `std::chrono`.

---

### Gestion du Work Asio

L'ancien pointeur :

```cpp
boost::asio::io_context::work*
```

n'est plus utilisé dans les versions modernes de Boost.Asio.

Il a été remplacé partout par :

```cpp
boost::asio::executor_work_guard<boost::asio::io_context::executor_type>*
```

L'initialisation de cet objet utilise désormais l'exécuteur associé au `io_context` :

```cpp
environment.io_context.get_executor()
```

Cette modification permet de conserver le comportement qui empêche le `io_context` de s'arrêter lorsqu'il n'existe momentanément plus de tâches actives, tout en utilisant l'API moderne de Boost.Asio.

---

## B. Résolution DNS (Resolver Réseau)

### Fichiers modifiés

Les fichiers concernés sont :

```text
vm/boostenv/main/boostenvtcp.hh
vm/boostenv/main/modos.hh
```

### Suppression de l'objet `query`

L'ancienne API de Boost.Asio utilisait un objet :

```cpp
tcp::resolver::query
```

Cette API a été supprimée ou remplacée dans les versions modernes de Boost.Asio.

Les paramètres nécessaires à la résolution DNS, notamment le nom d'hôte et le service, sont désormais transmis directement à la méthode :

```cpp
resolve()
```

ou :

```cpp
async_resolve()
```

---

### Nouveau type de retour de `resolve`

L'ancienne API retournait directement un itérateur réseau :

```cpp
protocol::resolver::iterator
```

L'API moderne retourne désormais une structure contenant une liste de résultats :

```cpp
protocol::resolver::results_type
```

Le type utilisé par `resolveHandler` a donc été adapté afin de recevoir :

```cpp
protocol::resolver::results_type
```

au lieu de :

```cpp
protocol::resolver::iterator
```

---

### Adaptation de l'itération dans `modos.hh`

La résolution DNS est désormais effectuée avec le code suivant :

```cpp
auto results = resolver.resolve(nameString, "0", ec);
auto it = results.begin();
```

Cette modification permet au code existant de continuer à parcourir les résultats de résolution DNS tout en utilisant l'API moderne de Boost.Asio.

---

# 9. Script de Compilation et État Actuel Validé

Afin de faciliter le débogage de la compilation parallèle C++, un script utilitaire nommé :

```text
build_and_log.sh
```

a été créé à la racine du projet.

Ce script permet de lancer automatiquement la compilation depuis le dossier `build/` tout en enregistrant l'ensemble des sorties de compilation dans un fichier de logs.

Le contenu du script est le suivant :

```bash
#!/bin/bash

LOG_FILE="logs.txt"

> "$LOG_FILE"

echo "➡️ Entrée dans le dossier build/..."

cd build || {
    echo "❌ Erreur: le dossier build n'existe pas."
    exit 1
}

echo "🚀 Lancement de la compilation..."

make -j $(sysctl -n hw.ncpu) 2>&1 | tee "../$LOG_FILE"

echo "✅ Compilation terminée. Logs sauvegardés dans $LOG_FILE"
```

Le script peut ensuite être exécuté depuis la racine du projet afin de lancer la compilation multi-cœurs et de conserver les logs dans :

```text
logs.txt
```

---

## Validation Finale du Module Asynchrone

Après application de l'ensemble des correctifs C++ et réseau, une compilation ciblée de la machine virtuelle a été effectuée afin de vérifier spécifiquement le bon fonctionnement du module utilisant Boost.

La commande suivante a été exécutée :

```bash
make mozartvmboost
```

La compilation s'est terminée avec succès.

Le résultat final obtenu est :

```text
[100%] Linking CXX static library libmozartvmboost.a
[100%] Built target mozartvmboost
```

Cette sortie confirme que le module `mozartvmboost` a été compilé intégralement et que la bibliothèque statique :

```text
libmozartvmboost.a
```

a été générée avec succès.

---

# 10. État Global du Portage sur Apple Silicon

À ce stade du portage, plusieurs couches de compatibilité ont été adaptées afin de permettre la compilation du projet Mozart 2 sur une machine Apple Silicon utilisant l'architecture ARM64.

Les principales modifications réalisées sont les suivantes :

- Adaptation de la configuration CMake aux versions modernes de CMake.
- Ajout du support explicite de l'architecture Apple Silicon `arm64`.
- Configuration des compilateurs LLVM/Clang installés via Homebrew.
- Adaptation de la détection des dépendances Boost modernes.
- Suppression de la dépendance explicite au composant obsolète `boost_system`.
- Passage global de l'ancienne norme C++11 (`c++0x`) vers C++14.
- Ajout d'un forçage explicite de la norme C++14 via CMake.
- Installation et utilisation de Java 11 afin d'assurer la compatibilité de Scala/SBT avec l'ancien code Scala 2.12 du projet.
- Modernisation des API Boost.Asio utilisées par la machine virtuelle.
- Remplacement de `deadline_timer` par `steady_timer`.
- Migration des API de temps de `boost::posix_time` vers `std::chrono`.
- Remplacement de `boost::asio::io_context::work` par `executor_work_guard`.
- Adaptation de la gestion des nombres aléatoires avec l'API Boost moderne.
- Modernisation de l'API de résolution DNS de Boost.Asio.
- Adaptation des types `resolver::iterator` vers `resolver::results_type`.
- Création d'un script `build_and_log.sh` pour faciliter le suivi et le débogage des compilations.
- Validation avec succès de la compilation ciblée du module `mozartvmboost`.

La compilation du module asynchrone est désormais validée à 100 % avec :

```bash
make mozartvmboost
```

et produit :

```text
[100%] Linking CXX static library libmozartvmboost.a
[100%] Built target mozartvmboost
```

Le portage est donc désormais suffisamment avancé pour poursuivre la compilation des autres modules du projet Mozart 2 et identifier les éventuelles incompatibilités restantes avec l'environnement moderne macOS ARM64.

La prochaine étape consiste à lancer la compilation complète du projet avec :

```bash
./build_and_log.sh
```

ou directement :

```bash
make -j $(sysctl -n hw.ncpu)
```

Les éventuelles erreurs restantes pourront alors être analysées à partir du fichier :

```text
logs.txt
```

afin de poursuivre progressivement la modernisation des composants encore incompatibles avec les versions actuelles de Java, CMake, C++ et Boost.

# 11. Résolution des Plantages du Garbage Collector (Heisenbugs sur ARM64)

## Problème

Pendant la compilation du code Oz — aux étapes `library_stage_2`, `library_stage_3` et dans la bibliothèque graphique QTk — des erreurs récurrentes de type `Segmentation fault: 11` ont été constatées.

La cause identifiée est le comportement instable du garbage collector de l’émulateur Mozart face aux allocations mémoire concurrentes et à l’ASLR (*Address Space Layout Randomization*) sur ARM64 / Apple Silicon. Les fichiers lourds particulièrement concernés étaient notamment :

```text
VM.ozf
TreeWidget.ozf
QTkEntry.ozf
QTkGrid.ozf
QTkListbox.ozf
QTkMenu.ozf
QTkRubberframe.ozf
```

## Contournement « passe-muraille »

1. **Compiler séquentiellement.** Après un crash, abandonner le parallélisme de `make -j` au profit de :

   ```bash
   make
   ```

   Cela réduit la pression mémoire et la concurrence entre threads.

2. **Compiler l’artefact bloquant sous LLDB.** Le débogueur désactive l’ASLR, ce qui stabilise la disposition mémoire et permet au garbage collector de terminer la compilation du fichier concerné.

   ```bash
   # Depuis le répertoire build
   lldb ./boosthost/emulator/ozemulator
   ```

3. **Rejouer dans LLDB la commande exacte ayant échoué.** Reprendre les options et chemins dans la ligne d’erreur de `logs.txt` :

   ```text
   (lldb) run --home /chemin/vers/build --search-load ... x-oz://system/Compile.ozf -c FichierBloquant.oz -o FichierBloquant.ozf
   ```

4. Attendre :

   ```text
   exited with status = 0
   ```

   Puis quitter LLDB :

   ```text
   (lldb) quit
   ```

5. Reprendre la compilation globale :

   ```bash
   make
   ```

Répéter uniquement pour les fichiers `.oz` qui bloquent. LLDB sert à générer l’artefact instable ; le reste du graphe de build reste géré par Make.

---

# 12. Correction du Crash Asynchrone (Boost.Asio & C++14)

## Problème

Lors de la compilation manuelle de `QTkMenu.oz` sous LLDB, un crash a été capturé :

```text
EXC_BAD_ACCESS (code=1, address=0x10)
```

La trace d’appel révélait un déréférencement de pointeur nul dans la gestion des timers asynchrones de `vm/boostenv/main/boostvm.cc`. Les captures par référence `[&]` et `boost::bind` de l’ancien code n’étaient plus sûrs avec ARM64 et le compilateur C++ moderne : une référence pouvait être devenue invalide avant l’exécution du travail posté à l’exécuteur.

## Modification

Fichier concerné :

```text
vm/boostenv/main/boostvm.cc
```

Les appels asynchrones ont été modernisés avec des lambdas C++14 et une capture explicite de l’instance via `[this]`.

Avant (autour des lignes 104 et 159) :

```cpp
boost::asio::post(env.io_context, [&](){
    preemptionTimer->expires_after(std::chrono::milliseconds(1));
    preemptionTimer->async_wait(boost::bind(
          &BoostVM::onPreemptionTimerExpire,
          this, boost::asio::placeholders::error));
});
```

Après :

```cpp
boost::asio::post(env.io_context.get_executor(), [this]() {
    preemptionTimer->expires_after(std::chrono::milliseconds(1));
    preemptionTimer->async_wait([this](const boost::system::error_code& error) {
        this->onPreemptionTimerExpire(error);
    });
});
```

La même modification doit être appliquée à la fonction d’arrêt de `preemptionTimer` (autour de la ligne 116) : remplacer les captures `[&]` et `boost::bind` par des lambdas capturant `[this]`.

Cette correction supprime la durée de vie ambiguë des références différées et stabilise les timers Asio sur ARM64.

---

# 13. Installation et Déploiement du Système

Après une compilation complète réussie, y compris `qtklibrary`, installer Mozart 2 dans le système :

```bash
sudo make install
```

Résultat attendu :

- Les binaires `ozemulator`, `ozc` et `ozengine` sont déployés dans `/usr/local/bin/`.
- Les modules précompilés (`.ozf`), plugins Emacs (`.elc`) et composants graphiques (images, icônes) sont installés dans `/usr/local/share/mozart/`.
- Le compilateur et la machine virtuelle deviennent accessibles depuis n’importe quel dossier.

Vérification rapide :

```bash
command -v ozc
command -v ozengine
```

---

# 14. Validation Finale de l’Exécution Native ARM64

Pour valider de bout en bout le compilateur `ozc`, la machine virtuelle `ozengine` et la bibliothèque graphique QTk, créer le fichier `test.oz` suivant :

```oz
functor
import
   QTk
   Application
define
   Window
   Description = td(
      title: "Mozart 2 ARM64"
      label(text: "Victoire ! L'interface graphique fonctionne sur Apple Silicon." font: "{Helvetica} 14")
      button(text: "Fermer" action:proc {$} {Application.exit 0} end)
   )
in
   % Construction et affichage de la fenêtre
   Window = {QTk.build Description}
   {Window show}
end
```

Compiler puis exécuter :

```bash
# Compilation du fichier source en bytecode Oz
ozc -c test.oz

# Exécution du bytecode
ozengine test.ozf
```

## Résultat validé

Le programme compile sans erreur. `ozengine` affiche une fenêtre graphique native ARM64 avec le texte de validation et un bouton « Fermer » fonctionnel. Cette validation confirme que Mozart 2 — compilateur, machine virtuelle et QTk — a été modernisé, compilé et installé avec succès sur macOS Apple Silicon.

---

# 15. Diagnostic et Correction du Chargement des Fichiers `.ozf` de Test

## Problème rencontré

Lors de l'exécution initiale de la suite de tests via CTest, la machine virtuelle échouait lors du chargement du fichier de test compilé :

```bash
ctest --verbose -R "conversion.oz"
```

Erreur obtenue :

```text
2: Test command: [...] ozemulator [...] "platform-test/simple_runner.ozf" "platform-test/base/conversion.ozf"
2: Working Directory: /Users/arthurlouette/Documents/Aarthur/Code/mozart2/build/platform-test
2: Test timeout computed to be: 1500
2:
2: [CRITIQUE] Le fichier .ozf est introuvable ou inaccessible !
1/1 Test #2: /base/conversion.oz ..............Subprocess aborted***Exception:   0.04 sec
```

### Analyse

Le fichier binaire compilé `simple_runner.ozf` était bien présent.

En revanche, le fichier de test compilé :

```text
platform-test/base/conversion.ozf
```

n'avait pas été généré par le système de build CMake standard.

Par conséquent, l'émulateur tentait de charger un fichier inexistant, ce qui provoquait un arrêt immédiat de la machine virtuelle.

---

## Amélioration de la Robustesse (`vm/vm/main/unpickler.cc`)

Afin d'éviter des plantages silencieux ou des lectures mémoire invalides lorsqu'un fichier `.ozf` est absent ou incomplet, le lecteur de bytecode (`unpickler`) a été renforcé.

La fonction `read()` est devenue :

```cpp
void read(char* buffer, size_t length) {
    if (!input.good()) {
        std::cerr << "\n[CRITIQUE] Le fichier .ozf est introuvable ou inaccessible !" << std::endl;
        std::abort();
    }

    input.read(buffer, length);

    if (input.gcount() != length) {
        std::cerr << "\n[CRITIQUE] Fichier vide ou tronqué ! Lecture de mémoire poubelle évitée." << std::endl;
        std::abort();
    }
}
```

Cette vérification permet désormais de détecter immédiatement :

- un fichier inexistant ;
- un fichier vide ;
- un fichier tronqué ;
- toute lecture partielle de bytecode.

La machine virtuelle affiche ainsi une erreur explicite au lieu d'effectuer une lecture mémoire invalide.

---

# 16. Validation Manuelle du Premier Test (`conversion.oz`)

Afin de vérifier que le portage ARM64 était pleinement fonctionnel une fois le fichier `.ozf` généré, une compilation manuelle du premier test a été réalisée.

## Création du répertoire cible

```bash
mkdir -p platform-test/base
```

## Compilation manuelle du fichier Oz

```bash
./boosthost/emulator/ozemulator \
    --home $(pwd) \
    --search-load cache=$(pwd)/lib/cache \
    x-oz://system/Compile.ozf \
    -c ../platform-test/base/conversion.oz \
    -o platform-test/base/conversion.ozf
```

Cette commande utilise le compilateur Oz intégré afin de produire directement le fichier :

```text
platform-test/base/conversion.ozf
```

## Exécution du test

```bash
ctest --verbose -R "conversion.oz"
```

Résultat obtenu :

```text
2: Testing conversion
2: stringToFloat
2:   OK
2: stringToAtom
2:   OK
2: stringToInt
2:   OK
2: floatToString
2:   OK
2: noFloat
2:   OK
2: noFloatType
2:   OK
1/1 Test #2: /base/conversion.oz ..............   Passed    0.03 sec
```

Le premier test de la plateforme est alors entièrement validé.

---

# 17. Compilation de la Cible de Test Globale (`platform-test`)

Une fois le fonctionnement du premier test confirmé, l'objectif était d'automatiser la génération de tous les fichiers `.ozf` de la plateforme.

L'analyse des cibles CMake :

```bash
make help | grep -i test
```

a permis d'identifier la cible dédiée :

```text
platform-test
```

La compilation complète est ensuite lancée avec :

```bash
make platform-test
```

Cette cible génère automatiquement tous les fichiers `.ozf` nécessaires aux tests.

### Base

- float.ozf
- exception.ozf
- type.ozf
- dictionary.ozf
- ofs.ozf
- listComprehension.ozf
- pickle.ozf
- state.ozf
- thread.ozf
- unify.ozf
- reflection.ozf
- serializer.ozf

### Bench

- compiler.ozf
- diff.ozf
- port.ozf
- rec.ozf
- tak.ozf

### DP

- url.ozf

### DP-bench

- Client.ozf

### Debug

- stacktrace_line_num.ozf
- gc.ozf

L'ensemble des fichiers de test est alors disponible sans compilation manuelle supplémentaire.

---

# 18. Exécution et Validation de la Suite Complète (CTest)

Une fois tous les fichiers `.ozf` générés, la totalité des tests de la plateforme peut être exécutée.

Commande utilisée :

```bash
ctest --output-on-failure
```

## Rapport d'exécution

```text
Test project /Users/arthurlouette/Documents/Aarthur/Code/mozart2/build

     Start  1: vmtest
 1/23 Test  #1: vmtest ...........................   Passed    0.02 sec

     Start  2: /base/conversion.oz
 2/23 Test  #2: /base/conversion.oz ..............   Passed    0.02 sec

     Start  3: /base/float.oz
 3/23 Test  #3: /base/float.oz ...................   Passed    0.02 sec

     Start  4: /base/exception.oz
 4/23 Test  #4: /base/exception.oz ...............   Passed    0.02 sec

     Start  5: /base/type.oz
 5/23 Test  #5: /base/type.oz ....................   Passed    0.02 sec

     Start  6: /base/dictionary.oz
 6/23 Test  #6: /base/dictionary.oz ..............   Passed    0.03 sec

     Start  7: /base/ofs.oz
 7/23 Test  #7: /base/ofs.oz .....................   Passed    0.02 sec

     Start  8: /base/listComprehension.oz
 8/23 Test  #8: /base/listComprehension.oz .......   Passed    0.47 sec

     Start  9: /base/pickle.oz
 9/23 Test  #9: /base/pickle.oz ..................   Passed    0.03 sec

     Start 10: /base/state.oz
10/23 Test #10: /base/state.oz ...................   Passed    0.02 sec

     Start 11: /base/thread.oz
11/23 Test #11: /base/thread.oz ..................   Passed    1.02 sec

     Start 12: /base/unify.oz
12/23 Test #12: /base/unify.oz ...................   Passed    0.02 sec

     Start 13: /base/reflection.oz
13/23 Test #13: /base/reflection.oz ..............   Passed    0.13 sec

     Start 14: /base/serializer.oz
14/23 Test #14: /base/serializer.oz ..............   Passed    0.02 sec

     Start 15: /bench/compiler.oz
15/23 Test #15: /bench/compiler.oz ...............   Passed    2.55 sec

     Start 16: /bench/diff.oz
16/23 Test #16: /bench/diff.oz ...................   Passed    0.39 sec

     Start 17: /bench/port.oz
17/23 Test #17: /bench/port.oz ...................   Passed    0.14 sec

     Start 18: /bench/rec.oz
18/23 Test #18: /bench/rec.oz ....................   Passed    0.36 sec

     Start 19: /bench/tak.oz
19/23 Test #19: /bench/tak.oz ....................   Passed    0.13 sec

     Start 20: /dp/url.oz
20/23 Test #20: /dp/url.oz .......................   Passed    0.02 sec

     Start 21: /dp-bench/Client.oz
21/23 Test #21: /dp-bench/Client.oz ..............   Passed    0.02 sec

     Start 22: /debug/stacktrace_line_num.oz
22/23 Test #22: /debug/stacktrace_line_num.oz ....   Passed    0.02 sec

     Start 23: /debug/gc.oz
23/23 Test #23: /debug/gc.oz .....................   Passed    0.02 sec

100% tests passed out of 23

Total Test time (real) =   5.52 sec
```

## Bilan Final

Le portage de Mozart 2 sur macOS Apple Silicon (ARM64) est désormais entièrement validé.

L'ensemble de la plateforme compile correctement, tous les fichiers `.ozf` sont générés automatiquement par le système de build, et les **23 tests officiels** de la suite de validation sont exécutés avec succès.

Cette validation confirme que le portage ARM64 est pleinement opérationnel et compatible avec l'environnement macOS Apple Silicon.

---

# 19. Diagnostic et Correction de l'Interface Graphique (Fenêtres Blanches)

## Problème rencontré

Une fois la machine virtuelle compilée et installée, l'exécution d'une commande graphique comme :

```oz
{Browse 'Test'}
```

via l'outil `ozwish` ouvrait correctement une fenêtre macOS native.

Cependant, **le contenu de la fenêtre restait entièrement blanc et vide**.

Aucun texte ne s'affichait dans :

- le **Browser** ;
- l'**Inspector** ;
- les autres interfaces graphiques basées sur Tk.

---

## Analyse — Le faux Tcl/Tk d'Apple

Sur macOS Apple Silicon, le moteur de rendu CoreGraphics ne supporte plus correctement certaines anciennes polices X11 utilisées par les vieilles versions de Tk.

Le diagnostic avec `otool` a révélé que l'application ne s'appuyait pas sur le paquet Tcl/Tk installé récemment via Homebrew, mais sur une ancienne version intégrée au système macOS.

La commande utilisée était :

```bash
otool -L wish/ozwish
```

Le résultat problématique indiquait notamment :

```text
/System/Library/Frameworks/Tcl.framework/Versions/8.5/Tcl
```

avec une version système ancienne :

```text
Tcl 8.5.9
```

Cette version de Tcl/Tk était incompatible avec le fonctionnement graphique attendu sur l'environnement Apple Silicon moderne.

Par ailleurs, la version par défaut de `tcl-tk` proposée par Homebrew était récemment passée à **Tcl/Tk 9.0**.

Cette nouvelle version modifie notamment le nom des bibliothèques dynamiques, par exemple :

```text
libtcl9.0.dylib
```

ce qui provoque des problèmes de rétrocompatibilité avec les composants C++ historiques attendus par Mozart 2.

---

## Solution — Forcer Tcl/Tk 8.6

La solution retenue a consisté à installer explicitement Tcl/Tk 8 via Homebrew, puis à forcer CMake à utiliser cette version au lieu des bibliothèques système ou de Tcl/Tk 9.

### Installation de Tcl/Tk 8

```bash
brew install tcl-tk@8
```

### Nettoyage du cache CMake

Le cache précédent pouvait contenir les mauvais chemins vers Tcl/Tk.

Il a donc été supprimé :

```bash
rm CMakeCache.txt
```

### Reconfiguration de CMake

CMake a ensuite été reconfiguré en indiquant explicitement les chemins vers Tcl/Tk 8.6 :

```bash
cmake \
    -DTCL_LIBRARY=/opt/homebrew/opt/tcl-tk@8/lib/libtcl8.6.dylib \
    -DTCL_INCLUDE_PATH=/opt/homebrew/opt/tcl-tk@8/include \
    -DTK_LIBRARY=/opt/homebrew/opt/tcl-tk@8/lib/libtk8.6.dylib \
    -DTK_INCLUDE_PATH=/opt/homebrew/opt/tcl-tk@8/include \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    ..
```

La variable :

```text
CMAKE_POLICY_VERSION_MINIMUM=3.5
```

permet également d'injecter la politique de version minimale nécessaire afin de corriger les avertissements CMake rencontrés dans certains sous-dossiers du projet.

---

# 20. Correction du Bootcompiler (Erreur Java/Scala sbt)

## Problème rencontré

Lors de l'étape de compilation finale avec :

```bash
make
```

une erreur inattendue est apparue lors de la construction du **bootcompiler**, écrit en **Scala 2.12**.

L'erreur rencontrée était :

```text
[info] welcome to sbt 1.6.2 (Oracle Corporation Java 21.0.2)
error: bad constant pool index: 0 at pos: 48461
```

---

## Analyse et Solution

Le gestionnaire de build Scala `sbt` utilisait automatiquement **Java 21**, qui était la version Java par défaut du système.

Cette version de Java produisait un bytecode moderne qui n'était pas correctement interprété par l'ancien compilateur Scala 2.12 utilisé par Mozart 2.

La solution a consisté à utiliser temporairement **Java 11**, version compatible avec l'environnement de compilation du bootcompiler.

---

## Installation d'OpenJDK 11

```bash
brew install openjdk@11
```

---

## Configuration de Java 11

Les variables d'environnement ont ensuite été redirigées vers Java 11 pour la session courante :

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
export PATH="$JAVA_HOME/bin:$PATH"
```

Il est alors possible de vérifier la version active avec :

```bash
java -version
```

---

## Nettoyage et recompilation

Après le changement de version de Java, le cache CMake a été supprimé :

```bash
rm CMakeCache.txt
```

La configuration CMake a ensuite été relancée avec les paramètres Tcl/Tk définis à l'étape précédente.

La compilation complète a finalement été exécutée avec :

```bash
make
```

Puis l'installation système :

```bash
sudo make install
```

Les étapes de compilation et d'installation ont alors été réalisées avec succès.

---

# 21. Intégration VS Code & Serveur OPI (Zéro Boilerplate)

## Objectif

L'objectif final était d'obtenir une expérience **Plug & Play** pour l'étudiant, comparable à celle disponible sous Windows ou Linux.

L'utilisation de Mozart/Oz devait notamment permettre d'exécuter directement :

```oz
{Browse 1}
```

sans devoir :

- créer manuellement un functor ;
- importer explicitement `Browser` ;
- configurer manuellement l'environnement pour chaque fichier.

---

## Validation

La configuration des chemins dans l'extension VS Code Mozart/Oz a permis de connecter directement le moteur natif ARM64 fraîchement compilé.

Les paramètres utilisés sont :

```text
Oz: Ozengine Path : /usr/local/bin/ozengine
Oz: Home : /usr/local/share/mozart
```

Cette configuration permet à VS Code d'utiliser directement l'installation native de Mozart 2.

---

## Fonctionnement du Serveur OPI

Une fois la configuration terminée, l'envoi de code depuis VS Code avec :

```text
Clic droit → Oz: Feed Region
```

ne lance pas simplement une compilation classique et isolée.

Le code est transmis au **serveur OPI** fonctionnant en arrière-plan.

Ce serveur effectue alors plusieurs opérations :

1. Il enveloppe dynamiquement l'environnement global nécessaire à l'exécution du code.
2. Il importe silencieusement les composants nécessaires tels que `Browser`, `Inspector`, etc.
3. Il transmet le code au moteur Mozart 2 natif ARM64.
4. Il utilise le pont Tk (`ozwish`) corrigé lors de l'étape 19.
5. Il affiche instantanément le résultat dans l'interface graphique native macOS.

---

## Résultat final

L'ensemble de la chaîne d'exécution est désormais fonctionnel :

```text
VS Code
   │
   │  Oz: Feed Region
   ▼
Serveur OPI
   │
   │  Environnement Mozart/Oz
   ▼
ozengine ARM64
   │
   ├── VM Mozart 2
   │
   └── ozwish / Tcl-Tk 8.6
           │
           ▼
      Interface macOS
```

Le portage technique **bas niveau et haut niveau** est ainsi entièrement achevé et validé de bout en bout :

- compilation native Apple Silicon ;
- machine virtuelle ARM64 ;
- génération et exécution des fichiers `.ozf` ;
- interface graphique Tcl/Tk ;
- bootcompiler Scala ;
- installation système ;
- intégration VS Code ;
- communication via le serveur OPI ;
- exécution directe des commandes Oz telles que `{Browse 1}`.

**Le portage de Mozart 2 sur macOS Apple Silicon (ARM64) est ainsi validé de bout en bout, depuis la compilation native jusqu'à l'utilisation interactive dans VS Code.**

---

# 22. Intégration avec Aquamacs (Éditeur Emacs pour macOS)

## Objectif

En plus de VS Code, le projet requérait le support d'**Aquamacs**, une distribution d'Emacs optimisée pour macOS.

Cette intégration était nécessaire afin de conserver une expérience de développement compatible avec les habitudes de certains utilisateurs et professeurs.

Lors de la compilation du projet avec :

```bash
make emacs_mode
```

les plugins Emacs Lisp suivants étaient correctement générés dans :

```text
/usr/local/share/mozart/elisp
```

Notamment :

```text
oz.elc
mozart.elc
oz-server.elc
```

---

## Problème rencontré — Erreur 127

Lors de la tentative d'exécution de code Oz depuis Aquamacs avec la commande **Feed Region**, l'erreur suivante apparaissait dans le buffer :

```text
Process Oz Emulator exited abnormally with code 127
```

Les logs système d'Aquamacs (`Messages`) indiquaient également :

```text
/usr/local/share/mozart/bin/ozengine: No such file or directory
```

Le code de retour **127** indique ici que le processus ne parvenait pas à trouver ou à lancer l'exécutable demandé.

---

## Analyse

Le problème était lié à deux spécificités de l'exécution d'applications graphiques macOS avec Aquamacs.

### 1. Gestion du `PATH`

Les applications graphiques macOS n'héritent pas nécessairement des mêmes variables d'environnement que celles définies dans un terminal.

Ainsi, même si :

```bash
which ozengine
```

ou :

```bash
which oz
```

fonctionnait correctement depuis le terminal, Aquamacs pouvait ne pas connaître automatiquement le chemin :

```text
/usr/local/bin
```

Le plugin Mozart essayait alors d'exécuter les commandes Oz sans disposer du chemin absolu correct.

### 2. Mauvaise racine `OZHOME`

Le système cherchait également les exécutables dans :

```text
/usr/local/share/mozart/bin/
```

alors que l'installation fonctionnelle utilisait :

```text
/usr/local/bin/
```

La variable `OZHOME` devait donc être configurée pour pointer vers la racine correcte de l'installation :

```text
/usr/local
```

---

# Solution

Afin de rendre l'intégration indépendante de l'environnement hérité du terminal, les chemins vers Mozart 2 ont été configurés explicitement dans Aquamacs.

Le fichier de préférences utilisé est :

```text
~/Library/Preferences/Aquamacs Emacs/Preferences.el
```

Les variables d'environnement, les chemins des exécutables ainsi que le chargement du mode Oz ont été définis directement dans ce fichier.

---

## Configuration de `Preferences.el`

Le contenu suivant a été ajouté :

```elisp
;; =================================================================
;; Configuration de Mozart 2 ARM64 pour Aquamacs
;; =================================================================

;; 1. Définition des variables d'environnement pour Mozart
(setenv "OZHOME" "/usr/local")
(setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))

;; Indiquer à Emacs le chemin des binaires et des bibliothèques
(add-to-list 'exec-path "/usr/local/bin")
(setq oz-home "/usr/local")

;; 2. Forcer les chemins ABSOLUS vers les exécutables (Fix Erreur 127)
(setq oz-compiler-command "/usr/local/bin/ozc")
(setq oz-emulator-command "/usr/local/bin/oz")

;; 3. Ajouter le dossier Emacs Lisp de Mozart au load-path
(add-to-list 'load-path "/usr/local/share/mozart/elisp")

;; 4. Charger le mode Oz / Mozart
(require 'mozart)

;; 5. Association automatique des fichiers .oz et .ozf au mode Oz
(add-to-list 'auto-mode-alist '("\\.oz\\'" . oz-mode))
(add-to-list 'auto-mode-alist '("\\.ozf\\'" . oz-gump-mode))
```

---

## Explication de la configuration

### Variables d'environnement

```elisp
(setenv "OZHOME" "/usr/local")
(setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
```

Ces deux lignes permettent à Aquamacs de retrouver correctement l'installation de Mozart 2, indépendamment de l'environnement du terminal.

Le répertoire :

```text
/usr/local/bin
```

est également ajouté au `PATH` afin que les exécutables Mozart soient accessibles.

---

### Chemin des exécutables

Le chemin d'exécution est explicitement ajouté à `exec-path` :

```elisp
(add-to-list 'exec-path "/usr/local/bin")
```

Puis les commandes utilisées par le mode Mozart sont définies avec leur chemin absolu :

```elisp
(setq oz-compiler-command "/usr/local/bin/ozc")
(setq oz-emulator-command "/usr/local/bin/oz")
```

Cette configuration évite que le plugin tente de rechercher les exécutables dans :

```text
/usr/local/share/mozart/bin/
```

et permet de résoudre directement l'erreur 127.

---

### Chargement des extensions Mozart

Le répertoire contenant les fichiers Emacs Lisp compilés est ajouté au `load-path` :

```elisp
(add-to-list 'load-path "/usr/local/share/mozart/elisp")
```

Le mode Mozart peut ensuite être chargé avec :

```elisp
(require 'mozart)
```

---

### Association automatique des fichiers Oz

Les fichiers `.oz` sont automatiquement associés au mode Oz :

```elisp
(add-to-list 'auto-mode-alist '("\\.oz\\'" . oz-mode))
```

Les fichiers `.ozf` sont quant à eux associés au mode correspondant :

```elisp
(add-to-list 'auto-mode-alist '("\\.ozf\\'" . oz-gump-mode))
```

Cela permet à Aquamacs d'activer automatiquement l'environnement Mozart lors de l'ouverture d'un fichier Oz.

---

# Résultat validé

Après redémarrage d'Aquamacs, l'intégration Mozart 2 ARM64 fonctionne correctement.

### Ouverture des fichiers `.oz`

L'ouverture d'un fichier `.oz` active automatiquement :

- le mode Oz ;
- la coloration syntaxique ;
- le menu Mozart/Oz dédié.

### Exécution avec `Feed Region`

L'exécution d'un bloc de code via :

```text
Oz → Feed Region
```

fonctionne désormais correctement.

Le serveur OPI est lancé en arrière-plan et reçoit le code envoyé depuis Aquamacs.

Les résultats sont ensuite affichés instantanément dans l'interface graphique native Tk :

- **Browser** ;
- **Inspector** ;
- autres interfaces graphiques Mozart.

Aucune erreur `127` n'est désormais générée.

---

## Validation finale

L'intégration complète d'Aquamacs avec le portage Mozart 2 sur macOS Apple Silicon est ainsi validée. Le support d'Aquamacs est ainsi pleinement opérationnel, en complément de l'intégration VS Code, et permet d'utiliser Mozart 2 ARM64 de manière transparente sur macOS Apple Silicon.

---

# 23. Migration vers la Norme C++20 et Validation Finale

## Objectif

Afin de s'aligner sur les travaux de modernisation globaux du projet Mozart 2 (notamment le passage aux compilateurs récents sur Linux), une migration complète du portage macOS ARM64 vers la norme **C++20** a été réalisée, tout en conservant la compatibilité avec **Boost 1.90.0**.

## A. Remplacement Global de la Norme C++

Le projet a été mis à jour pour forcer l'utilisation de C++20 à la place de l'ancienne configuration.

Depuis la racine du projet, les références ont été modifiées via les commandes suivantes :

```bash
find . -type f -name "CMakeLists.txt" -exec sed -i '' 's/c++14/c++20/g' {} +
find . -type f -name "*.cmake" -exec sed -i '' 's/c++14/c++20/g' {} +
```

## B. Configuration CMake pour C++20

Le cache précédent a été supprimé :

```bash
cd build
rm CMakeCache.txt
```

La configuration CMake a été relancée en injectant explicitement le drapeau `-std=c++20`, tout en conservant les chemins vers LLVM, Boost, et Tcl/Tk 8.6 :

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_CXX_COMPILER_ARCHITECTURE_ID=arm64 \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++ \
      -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm/bin/clang \
      -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/llvm;/opt/homebrew/opt/tcl-tk;/opt/homebrew/opt/boost" \
      -DMOZART_BOOST_USE_STATIC_LIBS=OFF \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DBOOST_ROOT=/opt/homebrew/opt/boost \
      -DBoost_NO_SYSTEM_PATHS=ON \
      -DBoost_NO_BOOST_CMAKE=ON \
      -DCMAKE_CXX_FLAGS="-std=c++20" \
      -DTCL_LIBRARY=/opt/homebrew/opt/tcl-tk@8/lib/libtcl8.6.dylib \
      -DTCL_INCLUDE_PATH=/opt/homebrew/opt/tcl-tk@8/include \
      -DTK_LIBRARY=/opt/homebrew/opt/tcl-tk@8/lib/libtk8.6.dylib \
      -DTK_INCLUDE_PATH=/opt/homebrew/opt/tcl-tk@8/include \
      ..
```

## C. Gestion de la Régression Java/SBT

Lors de la compilation parallèle, une erreur de génération du bootcompiler (Scala 2.12) est réapparue à cause de l'utilisation par défaut de Java 21 par le système :

bad constant pool index
ExceptionInInitializerError

La solution a consisté à forcer à nouveau l'utilisation de Java 11 pour la session Terminal courante, comme établi lors des précédentes étapes :

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
export PATH="$JAVA_HOME/bin:$PATH"
```

Après un nettoyage du cache et une reconfiguration CMake, la compilation s'est achevée avec succès à 100 %. Les bibliothèques C++ compilées sous C++20 sur architecture ARM64 se sont avérées parfaitement fonctionnelles.

---

# 24. Installation et Validation de l'Interface Graphique

## A. Déploiement

Les nouveaux binaires compilés en C++20 ont été déployés sur le système macOS :

```bash
cd build
sudo make install
```

## B. Test de l'Interface Native

Afin de confirmer que l'intégration Tcl/Tk 8.6 survivait à la mise à jour C++20, un fichier de test `test.oz` a été créé :

```oz
{Browse 'Hello C++20 ARM64!'}
```

L'exécution dynamique via le serveur OPI (dans VS Code) a immédiatement généré l'ouverture de la fenêtre native macOS de l'outil Browser, affichant la chaîne de caractères attendue.

---

## Conclusion

Le portage de Mozart 2 sur macOS Apple Silicon est désormais certifié compatible avec :

- **C++20**
- **Boost 1.90.0**
- **Tcl/Tk 8.6**
- **Architecture ARM64 Apple Silicon**
- **Serveur OPI et interface graphique native**

La validation finale confirme le bon fonctionnement du moteur et de l'interface graphique, avec **100 % de réussite** sur les bancs de tests intensifs.