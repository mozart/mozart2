%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Christian Schulte, 1997
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

declare
   Loop
   For
   ForThread
in

%%
%% For
%%
local
   %% some speedup if +1 is statically known
   proc {HelpPlusOne C To P}
      case C=<To then {P C} {HelpPlusOne C+1 To P}
      else skip
      end
   end
   %% some speedup if -1 is statically known
   proc {HelpMinusOne C To P}
      case C>=To then {P C} {HelpMinusOne C-1 To P}
      else skip
      end
   end
   proc {HelpPlus C To Step P}
      case C=<To then {P C} {HelpPlus C+Step To Step P}
      else skip
      end
   end
   proc {HelpMinus C To Step P}
      case C>=To then {P C} {HelpMinus C+Step To Step P}
      else skip
      end
   end
in
   proc {For From To Step P}
      case
         Step==1 then {HelpPlusOne From To P}
      elsecase
         Step==~1 then {HelpMinusOne From To P}
      elsecase
         Step>0 then {HelpPlus From To Step P}
      else {HelpMinus From To Step P}
      end
   end
end

local
   fun {HelpPlusOne C To P In}
      case C=<To then {HelpPlusOne C+1 To P {P In C}}
      else In
      end
   end
   fun {HelpMinusOne C To P In}
      case C>=To then {HelpMinusOne C-1 To P {P In C}}
      else In
      end
   end
   fun {HelpPlus C To Step P In}
      case C=<To then {HelpPlus C+Step To Step P {P In C}}
      else In
      end
   end
   fun {HelpMinus C To Step P In}
      case C>=To then {HelpMinus C+Step To Step P {P In C}}
      else In
      end
   end
in
   fun {ForThread From To Step P In}
      case Step==1 then {HelpPlusOne From To P In}
      elsecase Step==~1 then {HelpMinusOne From To P In}
      elsecase Step>0 then {HelpPlus From To Step P In}
      else {HelpMinus From To Step P In}
      end
   end
end


local
   proc {MultiFor Size P}
      proc {Help LSize Index}
         case LSize of nil then {P {Reverse Index}}
         [] R|T then Low#High#Step=R in
            {For Low High Step proc {$ I} {Help T I|Index} end}
         end
      end
   in
      {Help Size nil}
   end

   fun {MultiForThread Size P In}
      fun {Help LSize Index InH}
         case LSize of nil then {P InH {Reverse Index}}
         [] R|T then Low#High#Step=R in
            {ForThread Low High Step
             fun {$ LIn I} {Help T I|Index LIn} end InH}
         end
      end
   in
      {Help Size nil In}
   end

in

   Loop=loop(for:            For
             forThread:      ForThread
             multiFor:       MultiFor
             multiForThread: MultiForThread)

end
