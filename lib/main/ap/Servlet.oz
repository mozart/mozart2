functor
import
   GetArgs
export
   exit : Exit
   args : Args
   %% the idea is that the application should itself provide
   %% the value for Spec. Once this is done, the corresponding
   %% parser is invoked on demand
   spec : Spec
body
   Spec
   Exit = {`Builtin` shutdown 1}
   Args = {ByNeed fun {$} {GetArgs.servlet Spec} end}
end
