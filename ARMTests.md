# ARMTests — Tests de Robustesse Mozart 2 ARM64

Cette suite regroupe des **edge cases** et **stress tests** destinés à valider la robustesse de Mozart 2 sur macOS Apple Silicon (ARM64).

---

## 1. OS — `os_edge_cases.oz`

Tests des interactions avec macOS.

- Création de fichiers/dossiers avec des noms Unicode (`🚀`, `é`, cyrillique, etc.).
- Vérification de la monotonie de `OS.time`.

**Objectif :** valider la gestion UTF-8 et la fiabilité des horloges utilisées par le scheduler.

---

## 2. Limites numériques — `arch_limits.oz`

Tests des limites mathématiques.

- Calcul de très grands nombres, par exemple `100000!`.
- Division par zéro et gestion des `NaN`.

**Objectif :** vérifier la gestion des grands nombres, GMP et des exceptions sans crash natif.

---

## 3. Stress des threads — `thread_stress.oz`

Création massive de micro-threads Oz, jusqu'à environ :

```text
1 000 000 threads
```

Les threads communiquent via un port partagé.

**Objectif :** mettre le scheduler et les files d'attente sous forte pression et vérifier leur stabilité sur ARM64.

---

## 4. Stress du Garbage Collector — `gc_stress.oz`

Allocation intensive de structures temporaires :

- listes ;
- gros enregistrements ;
- structures imbriquées.

Plusieurs threads effectuent simultanément ces allocations.

**Objectif :** forcer le GC à fonctionner continuellement et détecter les problèmes de mémoire ou de concurrence.

---

## 5. Concurrence graphique — `qtk_concurrency.oz`

Ouverture, modification et fermeture répétées de fenêtres Tcl/Tk depuis plusieurs threads Oz.

**Objectif :** détecter les deadlocks, problèmes de synchronisation ou crashs entre le scheduler Oz et la boucle graphique macOS.

---

## 6. Réseau distribué — `dp_network_stress.oz`

Communication intensive entre deux nœuds Oz locaux via `localhost` / IPv6.

Échange de milliers de messages complexes :

- gros tuples ;
- structures imbriquées ;
- données sérialisées ;
- closures.

**Objectif :** tester les sockets, la sérialisation et la programmation distribuée sur la pile réseau ARM64/macOS.

---

## 7. Dépassement de pile — `stack_overflow.oz`

Fonction récursive non terminale descendant volontairement très profondément dans la pile.

Le comportement attendu est une exception Oz de type :

```text
system(kernel(stackoverflow ...))
```

plutôt qu'un crash de `ozengine`.

**Objectif :** vérifier la protection de la pile et la gestion correcte des stack overflows.

---

## 8. Cohérence Mémoire (Weak Memory Ordering) — `arm_memory_coherence.oz`

### Le piège ARM

Contrairement à Intel, ARM64 utilise un modèle mémoire plus faible (*Weak Memory Model*). Si le moteur C++ de Mozart oublie certaines barrières mémoire (`memory barriers` / `std::atomic`), deux threads pourraient observer les données dans un ordre différent.

### Le Test

Créer des cellules partagées (`Cells` ou `Dictionary`) modifiées de manière concurrente par plusieurs dizaines de threads.

Vérifier à la fin que l'état global reste parfaitement cohérent, sans :

- corruption ;
- perte de données ;
- `Data Race`.

---

## 9. Dérive des Timers sur les cœurs P/E — `timer_drift.oz`

### Le piège ARM

Les processeurs Apple Silicon possèdent des cœurs de Performance (P-Cores) et d'Efficience (E-Cores). Lorsqu'un thread Oz utilise `{Delay N}`, macOS peut le déplacer entre différents cœurs, ce qui peut entraîner une dérive du temps d'attente.

### Le Test

Lancer des centaines de threads effectuant des `{Delay N}` très courts.

Mesurer le temps avant et après chaque attente avec `OS.time` ou le module temporel utilisé par la VM.

**Objectif :** vérifier que l'ordonnanceur de Mozart ne subit pas de dérive excessive lorsque les threads sont exécutés sur les différents types de cœurs.

---

## 10. Alignement binaire et Pickling — `pickle_alignment.oz`

### Le piège ARM

ARM64 peut être plus strict que x86 concernant l'alignement des données en mémoire. Le module `Pickle`, qui effectue de nombreuses opérations binaires, constitue donc un bon candidat pour détecter d'éventuels problèmes d'alignement.

### Le Test

Créer des structures de données complexes :

- listes imbriquées ;
- Floats ;
- Atoms très longs ;
- variables libres.

Les passer en boucle à travers :

```text
Pickle.pack
Pickle.unpack
```

**Objectif :** vérifier que la sérialisation binaire fonctionne correctement sans provoquer de `Bus Error` ou d'erreur d'alignement mémoire native.

---

## 11. Convention d'Appel ARM64 (AAPCS64) — `ffi_arguments.oz`

### Le piège ARM

Lorsqu'Oz appelle une fonction C/C++ native, les arguments suivent la convention d'appel ARM64 (AAPCS64).

Les premiers arguments sont transmis via les registres CPU (`x0` à `x7`), tandis que les arguments supplémentaires utilisent la pile.

### Le Test

Créer ou identifier une fonction native prenant **12 à 15 arguments** et l'appeler depuis Oz.

Vérifier que les arguments :

- arrivent dans le bon ordre ;
- ne sont pas écrasés ;
- ne sont pas décalés ;
- sont correctement récupérés depuis les registres et la pile.

**Objectif :** valider la compatibilité entre la VM Mozart 2 et la convention d'appel native ARM64.

---

## 12. Système de fichiers APFS et Unicode — `apfs_unicode.oz`

### Le piège macOS

APFS applique des règles de normalisation Unicode aux noms de fichiers. Des caractères visuellement identiques peuvent avoir des représentations Unicode différentes.

### Le Test

Utiliser les modules `Open` ou `OS` pour créer, lire et lister des fichiers contenant des noms Unicode complexes :

- caractères précomposés et décomposés ;
- emojis ;
- modificateurs ;
- accents ;
- combinaisons Unicode inhabituelles.

**Objectif :** stresser la couche d'abstraction système de Mozart 2 et vérifier que les différences de représentation et de longueur UTF-8 ne provoquent aucune erreur ou corruption.

---

## Synthèse

| Test | Domaine |
|---|---|
| `os_edge_cases.oz` | OS / Unicode / Horloges |
| `arch_limits.oz` | Mathématiques / GMP |
| `thread_stress.oz` | Scheduler / Concurrence |
| `gc_stress.oz` | Mémoire / Garbage Collector |
| `qtk_concurrency.oz` | Tcl/Tk / Interface graphique |
| `dp_network_stress.oz` | Réseau / Distribution |
| `stack_overflow.oz` | Pile / Exceptions |
| `arm_memory_coherence.oz` | Mémoire / Weak Memory Ordering |
| `timer_drift.oz` | Timers / P-Cores / E-Cores |
| `pickle_alignment.oz` | Pickling / Alignement mémoire |
| `ffi_arguments.oz` | FFI / Convention d'appel AAPCS64 |
| `apfs_unicode.oz` | APFS / Unicode / Système de fichiers |

Ces tests complètent les tests fonctionnels existants afin de valider la robustesse de Mozart 2 dans des conditions extrêmes sur macOS Apple Silicon.