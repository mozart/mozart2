%%%
%%% Authors:
%%%   Author's name (Author's email address)
%%%
%%% Contributors:
%%%   optional, Contributor's name (Contributor's email address)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
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
%%%  Programming Systems Lab, Universitaet des Saarlandes,
%%%  Postfach 15 11 50, D-66041 Saarbruecken, Phone (+49) 681 302-5609
%%%  Author: Leif Kornstaedt <kornstae@ps.uni-sb.de>

proc {NewCompilerInterfaceQuiet ?CompilerInterfaceQuiet}
   class CompilerInterfaceQuiet
      prop locking final
      feat Compiler
      attr AccVS: "" HasErrors: false
      meth init()
         self.Compiler = {New CompilerClass init(self)}
      end

      meth !SetSwitches(_)
         skip
      end
      meth !SetMaxNumberOfErrors(_)
         skip
      end
      meth !ShowInfo(VS _ <= unit)
         AccVS <- @AccVS#VS
      end
      meth !DisplaySource(_ _ VS)
         AccVS <- @AccVS#VS
      end
      meth !ToTop()
         HasErrors <- true
      end
      meth !DisplayEnv(_)
         skip
      end
      meth !AskAbort(?B)
         B = true
      end

      meth hasErrors($)
         lock @HasErrors end
      end
      meth getVS($)
         lock @AccVS end
      end
      meth reset()
         lock
            AccVS <- ""
            HasErrors <- false
         end
      end
      meth interrupt()
         {self.Compiler interrupt()}
      end

      meth putEnv(Env)
         lock {self.Compiler putEnv(Env)} end
      end
      meth mergeEnv(Env)
         lock {self.Compiler mergeEnv(Env)} end
      end
      meth getEnv(?Env)
         lock {self.Compiler getEnv(?Env)} end
      end
      meth feedFile(FileName ?RequiredInterfaces <= _)
         lock {self.Compiler feedFile(FileName ?RequiredInterfaces)} end
      end
      meth feedVirtualString(VS ?RequiredInterfaces <= _)
         lock {self.Compiler feedVirtualString(VS ?RequiredInterfaces)} end
      end
   end
end
