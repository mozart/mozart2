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
         @HasErrors
      end
      meth getVS($)
         @AccVS
      end
      meth reset()
         AccVS <- ""
         HasErrors <- false
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
