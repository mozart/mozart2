%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local
   local
      fun {Deref A}
         case A of blocked(A) then {Deref A} else A end
      end
   in
      fun {Ask S}
         {Deref {Space.askVerbose S}}
      end
   end

   fun {RawTest P1 P2}
      thread
         try E={P1} in {P2 E}
         catch _ then false
         end
      end
   end

in

   fun {DoTest T}
      case T
      of test(P1 P2) then
         {RawTest P1 P2}
      [] equal(P1 X) then
         {RawTest P1 fun {$ E} E==X end}
      [] entailed(P0) then
         {RawTest
          fun {$}
             S={Space.new proc {$ _}
                             try {P0}
                             catch _ then fail
                             end
                          end}
          in
             {Ask S}
          end
          fun {$ X} X==succeeded(entailed) end}
      [] failed(P0) then
         {RawTest
          fun {$}
             S={Space.new proc {$ _}
                             try {P0}
                             catch _ then skip
                             end
                          end}
          in
             {Ask S}
          end
          fun {$ X} X==failed end}
      [] suspended(P0) then
         {RawTest
          fun {$}
             S={Space.new proc {$ _}
                             try {P0}
                             catch _ then fail
                             end
                          end}
          in
             {Ask S}
          end
          fun {$ X} X==succeeded(suspended) end}
      end
   end

end
