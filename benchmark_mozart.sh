#!/bin/bash
# sur Mozart2 MacOs ARM : 44sec +-
echo "==================================================="
echo " 🏁 Benchmark Mozart 2 - Test de CPU (Fibonacci 38) "
echo "==================================================="

# 1. Définition des chemins standards
MOZART_APP="/Applications/Mozart2.app"
OZC="${MOZART_APP}/Contents/Resources/bin/ozc"
OZENGINE="${MOZART_APP}/Contents/Resources/bin/ozengine"

# Vérification que l'application est bien là
if [ ! -f "$OZC" ] || [ ! -f "$OZENGINE" ]; then
    echo "❌ Erreur : L'application Mozart2.app est introuvable dans le dossier /Applications."
    echo "Veuillez vérifier votre installation."
    exit 1
fi

echo "✅ Moteur Mozart trouvé."
echo "📄 Création du fichier de test (benchmark.oz)..."

# 2. Création dynamique du code Oz
cat << 'EOF' > benchmark.oz
functor
import
   System
   Application
define
   fun {Fib N}
      if N =< 2 then 1 else {Fib N-1} + {Fib N-2} end
   end
   Result
in
   Result = {Fib 38}
   {System.showInfo "Resultat exact : "#Result}
   {Application.exit 0}
end
EOF

# 3. Compilation
echo "⚙️  Compilation avec ozc..."
"$OZC" -c benchmark.oz -o benchmark.ozf

if [ ! -f benchmark.ozf ]; then
    echo "❌ Erreur de compilation."
    exit 1
fi

# 4. Exécution et Chronométrage
echo "🚀 Lancement du test de performance..."
echo "⏳ Veuillez patienter..."
echo "---------------------------------------------------"

time "$OZENGINE" benchmark.ozf

echo "---------------------------------------------------"
echo "🧹 Nettoyage des fichiers temporaires..."
rm benchmark.oz benchmark.ozf

echo "✅ Test terminé ! Regardez la ligne real ci-dessus pour voir le temps total."