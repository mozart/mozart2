functor
import
   GetArgs System.exit
export
   exit : Exit
   args : Args
   %% the idea is that the application should itself provide
   %% the value for Spec. Once this is done, the corresponding
   %% parser is invoked on demand
   spec : Spec
body
   Spec
   Exit = System.exit
   Args = {ByNeed fun {$} {GetArgs.syslet Spec} end}
end
