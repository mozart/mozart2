%%%  Programming Systems Lab, Universitaet des Saarlandes,
%%%  Postfach 15 11 50, D-66041 Saarbruecken, Phone (+49) 681 302-5609
%%%  Author: Leif Kornstaedt <kornstae@ps.uni-sb.de>

proc {NewCompilerInterfaceEmacs Open OS ?CompilerInterfaceEmacs}
   MSG_ERROR = [17]
   EMU_OUT_START = [5]
   EMU_OUT_END = [6]
in
   class CompilerInterfaceEmacs
      prop locking final
      feat Compiler
      attr CompilerPanel: unit
      meth init()
         self.Compiler = {New CompilerClass init(self)}
         case {System.get standalone} then skip
         else
            {self.Compiler setSwitch(on(echoqueries unit))}
         end
      end

      meth !SetSwitches(_)=M
         CompilerInterfaceEmacs, DelegateToPanel(M _)
      end
      meth !SetMaxNumberOfErrors(_)=M
         CompilerInterfaceEmacs, DelegateToPanel(M _)
      end
      meth !ShowInfo(VS Coord <= unit)=M
         CompilerInterfaceEmacs, DelegateToPanel(M _)
         case {System.get standalone} then
            {System.printInfo VS}
         else
            {System.printInfo EMU_OUT_END#VS#EMU_OUT_START}
         end
      end
      meth !DisplaySource(Title Ext VS) Name File in
         Name = {OS.tmpnam}#Ext
         File = {New Open.file init(name: Name flags: [write create truncate])}
         {File write(vs: VS)}
         {File close()}
         {Print {String.toAtom {VirtualString.toString 'oz-show-temp '#Name}}}
      end
      meth !ToTop()=M
         CompilerInterfaceEmacs, DelegateToPanel(M _)
         case {System.get standalone} then skip
         else
            {System.printInfo EMU_OUT_END#MSG_ERROR#EMU_OUT_START}
         end
      end
      meth !DisplayEnv(_)=M
         CompilerInterfaceEmacs, DelegateToPanel(M _)
      end
      meth !AskAbort(?B)=M
         case CompilerInterfaceEmacs, DelegateToPanel(M $) then skip
         else B = true
         end
      end

      meth openPanel(Tk TkTools Open Browse)
         lock D in
            case @CompilerPanel == unit orelse {IsDet @CompilerPanel.isClosed}
            then
               CompilerPanel <- {New {NewCompilerInterfaceTk
                                      Tk TkTools Open Browse}
                                 init(self.Compiler)}
               D = {NewDictionary}
               {ForAll {Record.toListInd {self.Compiler getEnv($)}}
                proc {$ V#Value}
                   {Dictionary.put D V Value}
                end}
               {@CompilerPanel DisplayEnv(D)}
               {@CompilerPanel SetSwitches({self.Compiler getSwitches($)})}
            else
               CompilerPanel <- unit
            end
         end
      end
      meth putEnv(Env)=M
         case CompilerInterfaceEmacs, DelegateToPanel(M $) then skip
         else
            lock {self.Compiler putEnv(Env)} end
         end
      end
      meth mergeEnv(Env)=M
         case CompilerInterfaceEmacs, DelegateToPanel(M $) then skip
         else
            lock {self.Compiler mergeEnv(Env)} end
         end
      end
      meth getEnv(?Env)=M
         case CompilerInterfaceEmacs, DelegateToPanel(M $) then skip
         else
            lock {self.Compiler getEnv(?Env)} end
         end
      end
      meth feedFile(FileName ?RequiredInterfaces <= _)=M
         case CompilerInterfaceEmacs, DelegateToPanel(M $) then skip
         else
            lock {self.Compiler feedFile(FileName ?RequiredInterfaces)} end
         end
      end
      meth feedVirtualString(VS ?RequiredInterfaces <= _)=M
         case CompilerInterfaceEmacs, DelegateToPanel(M $) then skip
         else
            lock {self.Compiler feedVirtualString(VS ?RequiredInterfaces)} end
         end
      end

      meth DelegateToPanel(M $)
         case @CompilerPanel == unit then false
         elsecase {IsDet @CompilerPanel.isClosed} then
            CompilerPanel <- unit
            false
         else
            {@CompilerPanel M}
            true
         end
      end
   end
end
