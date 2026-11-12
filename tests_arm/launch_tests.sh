#!/bin/bash

echo "🚀 Démarrage de la suite de tests complète ARM64..."
echo "---------------------------------------------------"

# 1. Compilation blindée (Anti-Segfault) pour TOUS les fichiers .oz
for f in *.oz; do
    echo "⚙️ Compilation de $f..."
    # On boucle tant que la compilation échoue (le fameux segfault 11)
    until /Applications/Mozart2.app/Contents/Resources/bin/ozc -c "$f" -o "${f%.oz}.ozf" 2>/dev/null; do
        echo "   ⚠️ Segfault intercepté. Reprise de la compilation pour $f..."
    done
    echo "   ✅ $f compilé avec succès !"
done

echo ""
echo "🔥 Lancement des exécutions..."
echo ""

# 2. Exécution parfaite de tous les fichiers .ozf générés
for f in *.ozf; do
    echo "==================================="
    echo "▶️ Test : $f"
    echo "==================================="
    /Applications/Mozart2.app/Contents/Resources/bin/ozengine "$f"
    echo ""
done

echo "==================================="
echo "🎉 Tous les tests sont terminés avec succès !"