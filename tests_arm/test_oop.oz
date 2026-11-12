functor
import System Application
define
   class Counter
      attr val
      meth init(Value) val := Value end
      meth inc(Step) val := @val + Step end
      meth get(Result) Result = @val end
   end
   
   C = {New Counter init(0)}
   R
in
   {System.showInfo "=== TEST ORIENTE OBJET & ETAT ==="}
   {C inc(10)}
   {C inc(32)}
   {C get(R)}
   {System.showInfo "Valeur finale du compteur (attendu: 42) : "#R}
   {Application.exit 0}
end