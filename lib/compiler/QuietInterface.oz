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
   attr Verbose: false AccVS: "" HasErrors: false
   meth init(CompilerObject)
      CompilerInterfaceGeneric, init(CompilerObject Serve)
   end
   meth reset()
      lock
         AccVS <- ""
         HasErrors <- false
      end
   end
   meth Serve(Ms)
      case Ms of M|Mr then OutputVS in
         case M of info(VS) then
            OutputVS = VS
         [] info(VS _) then
            OutputVS = VS
         [] displaySource(_ _ VS) then
            OutputVS = VS
         [] toTop() then
            HasErrors <- true
            OutputVS = ""
         else
            OutputVS = ""
         end
         case @Verbose then
            File = {New Open.file init(name: stderr flags: [write])}
         in
            {File write(vs: OutputVS)}
            {File close()}
         elsecase OutputVS of "" then skip
         else
            AccVS <- @AccVS#OutputVS
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
   meth getVS($)
      @AccVS
   end
end
