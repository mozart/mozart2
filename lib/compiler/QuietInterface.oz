%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

class CompilerInterfaceQuiet from CompilerInterfaceGeneric
   prop final
   attr
      Verbose: false AccVS: "" SourceVS: ""
      HasErrors: false HasBeenTopped: false
   meth init(CompilerObject DoVerbose <= false)
      Verbose <- DoVerbose
      CompilerInterfaceGeneric, init(CompilerObject Serve)
   end
   meth reset()
      lock
         AccVS <- ""
         SourceVS <- ""
         HasErrors <- false
         HasBeenTopped <- false
      end
   end
   meth Serve(Ms)
      case Ms of M|Mr then OutputVS in
         case M of info(VS) then
            OutputVS = VS
         [] info(VS _) then
            OutputVS = VS
         [] displaySource(_ _ VS) then
            SourceVS <- VS
            OutputVS = ""
         [] errorFound() then
            HasErrors <- true
            OutputVS = ""
         [] toTop() then
            HasBeenTopped <- true
            OutputVS = ""
         else
            OutputVS = ""
         end
         case OutputVS of "" then skip
         elsecase @Verbose then {System.printError OutputVS}
         else AccVS <- @AccVS#OutputVS
         end
         CompilerInterfaceQuiet, Serve(Mr)
      end
   end

   meth setVerbosity(B)
      Verbose <- B
   end
   meth hasErrors($)
      @HasErrors
   end
   meth hasBeenTopped($)
      @HasBeenTopped
   end
   meth getVS($)
      @AccVS
   end
   meth getSource($)
      @SourceVS
   end
end
