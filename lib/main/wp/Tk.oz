%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
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


local
   VoidEntry = {NewName}

   class Counter
      prop locking final
      attr n:0
      meth get(?N)
         lock N=@n n <- N+1 end
      end
   end

   %%
   %% Printing error messages
   %%
   proc {Error S Tcl}
      P={System.get errors}
   in
      {System.showError 'Tk Module: '#S#
       case Tcl==unit then '' else '\n'#
          {System.valueToVirtualString Tcl P.depth P.width}
       end}
   end

   %%
   %% Some Character/String stuff
   %%
   local
      fun {TkNum Is BI ?BO}
         case Is of nil then BO=BI nil
         [] I|Ir then
            case I
            of &- then &~|{TkNum Ir BI BO}
            [] &. then &.|{TkNum Ir true BO}
            [] &e then &e|{TkNum Ir true BO}
            [] &E then &E|{TkNum Ir true BO}
            else I|{TkNum Ir BI BO}
            end
         end
      end
   in
      fun {TkStringToString S}
         S
      end

      TkStringToAtom = StringToAtom

      fun {TkStringToInt S}
         %% Read a number and convert it to an integer
         OS IsAFloat in OS={TkNum S false ?IsAFloat}
         case IsAFloat andthen {String.isFloat OS} then
            {FloatToInt {String.toFloat OS}}
         elsecase {Not IsAFloat} andthen {String.isInt OS} then
            {String.toInt OS}
         else false
         end
      end

      fun {TkStringToFloat S}
         %% Read a number and convert it to a float
         OS IsAFloat in OS={TkNum S false ?IsAFloat}
         case IsAFloat andthen {String.isFloat OS} then
            {String.toFloat OS}
         elsecase {Not IsAFloat} andthen {String.isInt OS} then
            {IntToFloat {String.toInt OS}}
         else false
         end
      end

      fun {TkStringToListString S}
         {String.tokens S & }
      end

      fun {TkStringToListAtom S}
         {Map {String.tokens S & } TkStringToAtom}
      end

      fun {TkStringToListInt S}
         {Map {String.tokens S & } TkStringToInt}
      end

      fun {TkStringToListFloat S}
         {Map {String.tokens S & } TkStringToFloat}
      end
   end


   %% expand a quoted Tcl/Tk string
   %%  \n     -> newline
   %%  \<any> -> <any>
   fun {Expand Is}
      case Is of nil then nil
      [] I|Ir then
         case I==&\\ then
            case Ir of nil then nil
            [] II|Irr then
               case II==&n then &\n else II end|{Expand Irr}
            end
         else I|{Expand Ir}
         end
      end
   end

   local
      proc {EnterMessageArgs As I T}
         case As of nil then skip
         [] A|Ar then T.I=A {EnterMessageArgs Ar I+1 T}
         end
      end

      proc {EnterPrefixArgs I MP M}
         case I>0 then  M.I=MP.I {EnterPrefixArgs I-1 MP M}
         else skip
         end
      end

      fun {MaxInt As M}
         case As of nil then M
         [] A|Ar then
            {MaxInt Ar case {IsInt A} then {Max M A} else M end}
         end
      end

      fun {NumberArgs As I}
         case As of nil then nil
         [] A|Ar then J=I+1 in J#A|{NumberArgs Ar J}
         end
      end
   in
      proc {InvokeAction Action Args NoArgs Thread}
         case Action
         of OP # M then SM in
            case NoArgs==0 then SM=M
            elsecase {IsTuple M} then W={Width M} in
               SM = {MakeTuple {Label M} NoArgs + W}
               {EnterPrefixArgs W M SM}
               {EnterMessageArgs Args {Width M}+1 SM}
            else
               SM={AdjoinList M {NumberArgs Args {MaxInt {Arity M} 0}}}
            end
            case {IsPort OP} then {Send OP SM}
            elsecase Thread then thread {OP SM} end
            else {OP SM}
            end
         else
            case NoArgs==0 then
               case Thread then
                  thread {Action} end
               else {Action}
               end
            else
               case Thread then
                  thread {System.apply Action Args} end
               else {System.apply Action Args}
               end
            end
         end
      end
   end

   fun {GetFields Ts}
      case Ts of nil then ''
      [] T|Tr then
         ' %' # case T
                of list(T) then
                   case T
                   of atom(A)   then A
                   [] int(I)    then I
                   [] float(F)  then F
                   [] string(S) then S
                   else T
                   end
                [] string(S) then S
                [] atom(A)   then A
                [] int(I)    then I
                [] float(F)  then F
                else T
                end # {GetFields Tr}
      end
   end

   fun {GetCasts Ts}
      case Ts of nil then nil
      [] T|Tr then
         case {Label T}
         of list then
            case {Label T.1}
            of atom  then TkStringToListAtom
            [] int   then TkStringToListInt
            [] float then TkStringToListFloat
            else          TkStringToString
            end
         [] atom  then TkStringToAtom
         [] int   then TkStringToInt
         [] float then TkStringToFloat
         else TkStringToString
         end | {GetCasts Tr}
      end
   end

   IdCharacters = i(&a &b &c &d &e &f &g &h &i &j &k &l &m
                    &n &o &p &q &r &s &t &u &v &w &x &y &z
                    &A &B &C &D &E &F &G &H &I &J &K &L &M
                    &N &O &P &Q &R &S &T &U &V &W &X &Y &Z)

   IdNumber     = {Width IdCharacters}

   fun {GenString N}
      case N>=IdNumber then
         IdCharacters.((N mod IdNumber) + 1)|{GenString N div IdNumber}
      else [IdCharacters.N]
      end
   end

   Magic = "Oz aPpLeT: the MOZART release"

   class TextFile from Open.text Open.file
      prop final
   end

   class TextSock from Open.text Open.socket
      prop final
   end

   fun {BrowserAppletGetArgs}
      SI
   in
      try
         SI = {New TextFile init(name: stdin flags: [read])}
         {SI getS(Magic)}
         {ForThread 1 {String.toInt {SI getS($)}} 1
          fun {$ AVs _}
             {SI getS($)}#{SI getS($)}|AVs
          end nil}
      finally
         {SI close()}
      end
   end

   proc {CreateSocket ?Sock0}
      SO
   in
      try Sock Port in
         SO = {New TextFile init(name:stdout)}
         thread
            Sock = {New TextSock server(port: ?Port)}
         end
         {SO write(vs: {OS.uName}.nodename#'\n')}
         {SO write(vs: Port#'\n')}
         Sock0 = Sock
      finally
         {SO close()}
      end
   end

   SGI = {System.get internal}
   Stream Applet
   case SGI.browser then
      %% Connect to already running plugin
      Stream = {CreateSocket}
      thread
         Applet         = {New BrowserAppletToplevel tkInit}
         Applet.rawArgs = {BrowserAppletGetArgs}
      end
   else
      HOME   = {OS.getEnv 'OZHOME'}
      {OS.putEnv 'TCL_LIBRARY' HOME#'/lib/wish/tcl'}
      {OS.putEnv 'TK_LIBRARY'  HOME#'/lib/wish/tk'}
      OSS#CPU = {System.get platform}
      Cmd    = HOME # '/platform/'#OSS#'-'#CPU#'/oz.wish.bin'
   in
      Stream = {New class $ from Open.pipe Open.text
                       prop final
                    end
                init(cmd:Cmd)}

      case SGI.applet then
         thread
            Applet={New AppletToplevel tkInit(withdraw:true)}

            local
               Args = Applet.args
            in
               {TkBatch Session
                case Args.width>0 andthen Args.height>0 then
                   [wm(title Applet Args.title)
                    wm(geometry  Applet Args.width#x#Args.height)
                    wm(resizable Applet false false)
                    update(idletasks)
                    wm(deiconify Applet)]
                else
                   [wm(title Applet Args.title)
                    update(idletasks)
                    wm(deiconify Applet)]
                end}
            end
         end
      else
         Applet = unit
      end
   end

   ActionIdServer = {New Counter get(_)}
   TkDict         = {Dictionary.new}
   AppletClosed   = {NewName}

   local
      TkInitStr =
      \insert TkInit.oz
   in
      {Stream write(vs:TkInitStr)}
      {Stream flush(how:[send])}
   end

   RetStream

   Session = {{`Builtin` initTclSession 4}
              {Stream getDesc(_ $)} TkDict RetStream}

   local
      fun {GetArgs N Ps}
         %% Get the next N line lines expanded
         case N>0 then E={Expand {Stream getS($)}} in
            case Ps
            of nil  then E | {GetArgs N-1 nil}
            [] P|Pr then {P E} | {GetArgs N-1 Pr}
            end
         else nil
         end
      end

      fun {ReadUntilDot}
         case {Stream getS($)}
         of "." then ''
         [] false then ''
         elseof S then S#'\n'#{ReadUntilDot}
         end
      end
   in
      %% Message formats
      %% call a procedure
      %%   p <ProcedureId> <N>
      %%   <Arg1>
      %%   ...
      %%   <ArgN>
      %% compose a message
      %%   p 0 <N>
      %%   <ObjectId>
      %%   <MessageName>
      %%   <Arg1>
      %%   ...
      %%   <ArgN>
      %% stop
      %%   s
      %% errors
      %%   w
      %%   <data>
      %%   .

      proc {TkReadLoop Rs}
         Is={Stream getS($)}
      in
         case Is
         of I|Ir then Irr=Ir.2 in
            case I
            of &r then (R|Cast)|Rr = Rs in
               R={Cast {Expand Irr}} {TkReadLoop Rr}
            [] &p then
               Irr1
               Id     = {String.toInt {String.token Irr  & $ ?Irr1}}
               NoArgs = {String.toInt {String.token Irr1 & $ _}}
            in
               case {Dictionary.condGet TkDict Id VoidEntry}
               of O # M # Ps then
                  {InvokeAction O#M {GetArgs NoArgs Ps} NoArgs true}
               [] P # Ps then
                  {InvokeAction P {GetArgs NoArgs Ps} NoArgs true}
               else
                  _={GetArgs NoArgs nil}
               end
               {TkReadLoop Rs}
            [] &s then
               {TkSend Session
                v('puts stdout {s end}; flush stdout; destroy .')}
               {Stream close}
            [] &w then
               {Error Irr#'\n'#{ReadUntilDot} unit}
               {TkReadLoop Rs}
            else {TkReadLoop Rs}
            end
         [] false then
            %% This must happen _before_ closing the session!
            case Applet of unit then skip else
               {Applet AppletClosed}
            end
            {{`Builtin` closeTclSession 1} Session}
            {Stream close}
         end
      end

      %% Start reading wish's output
      thread
         {{`Builtin` 'Thread.setId' 2} {Thread.this} 2}
         {Thread.setThisPriority high}
         {TkReadLoop RetStream}
      end
   end

   local
      IdBaseServer = {New Counter get(_)}
   in
      fun {TkGetPrefix}
         &o|&Z|{GenString {IdBaseServer get($)}}
      end
   end

   local
      IdBase   = {String.toAtom {TkGetPrefix}}
      IdServer = {New Counter get(_)}
   in
      fun {TkGetId}
         IdBase#{IdServer get($)}
      end
   end

   fun {TkGetTclName W}
      {VirtualString.toString W.TclName}
   end

   %%
   %% Sending tickles
   %%
   TkSend         = {`Builtin` 'Tk.send'          2}
   TkBatch        = {`Builtin` 'Tk.batch'         2}
   TkReturn       = {`Builtin` tclWriteReturn     4}
   TkReturnMess   = {`Builtin` tclWriteReturnMess 5}
   TkSendTuple    = {`Builtin` tclWriteTuple      3}
   TkSendTagTuple = {`Builtin` tclWriteTagTuple   4}
   TkSendFilter   = {`Builtin` tclWriteFilter     6}
   TkClose        = {`Builtin` tclClose           3}
   TkCloseApplet  = {`Builtin` tclCloseWeb        2}

   %%
   %% Generation of Identifiers
   %%
   GenTopName    = {`Builtin` genTopName    2}
   GenWidgetName = {`Builtin` genWidgetName 3}
   GenTagName    = {`Builtin` genTagName    2}
   GenVarName    = {`Builtin` genVarName    2}
   GenImageName  = {`Builtin` genImageName  2}

   %%
   %% Master slave mechanism for widgets
   %%
   AddSlave  = {`Builtin` addFastGroup    3}
   DelSlave  = {`Builtin` delFastGroup    1}

   TkReturnMethod = {NewName}
   TkClass        = {NewName}
   TkWidget       = {NewName}

   TclSlaves TclSlaveEntry TclName
   {{`Builtin` getTclNames 3} ?TclSlaves ?TclSlaveEntry ?TclName}

   proc {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
      Fields = {GetFields Args}
      Casts  = {GetCasts Args}
   in
      ActionId = {ActionIdServer get($)}
      {Dictionary.put TkDict ActionId case Action
                                      of O#M then O#M#Casts
                                      elseof P then P # Casts
                                      end}
      Command = '{'#case AddIt then '+' else '' end#'ozp '#ActionId#
      Fields #
      case BreakIt then '; break' else '' end#'}'
   end

   proc {DefineCommand Action Args ?ActionId ?Command}
      Casts = {GetCasts Args}
   in
      ActionId = {ActionIdServer get($)}
      {Dictionary.put TkDict ActionId case Action of O#M then O#M#Casts
                                      else Action#Casts
                                      end}
      Command = '{ozp '#ActionId#'}'
   end

   class TkAction
      feat
         ActionId
         !TclName
         !TclSlaveEntry

      meth tkInit(parent:Parent action:Action args:Args<=nil) = M
         ParentSlaves = {CondSelect Parent TclSlaves unit}
         ThisTclName  = self.TclName
         ThisActionId = self.ActionId
         GetTclName
      in
         case ParentSlaves==unit then
            {`RaiseError` tk(wrongParent self M)}
         elsecase {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self M)}
         else
            self.TclSlaveEntry = {AddSlave ParentSlaves self}
            {DefineCommand Action Args ?ThisActionId ?GetTclName}
            _ = {AddSlave ParentSlaves ThisActionId}
            ThisTclName = GetTclName
         end
      end

      meth tkAction(action:Action args:Args<=nil)
         Casts        = {GetCasts Args}
      in
         {Dictionary.put TkDict self.ActionId
          case Action of O#M then O#M#Casts else Action#Casts end}
      end

      meth tkClose
         {Dictionary.remove TkDict self.ActionId}
         {DelSlave self.TclSlaveEntry}
      end

   end

   fun {TkReturnString M}
      {TkReturn Session M TkStringToString}
   end

   fun {TkReturnAtom M}
      {TkReturn Session M TkStringToAtom}
   end

   fun {TkReturnInt M}
      {TkReturn Session M TkStringToInt}
   end

   fun {TkReturnFloat M}
      {TkReturn Session M TkStringToFloat}
   end

   fun {TkReturnListString M}
      {TkReturn Session M TkStringToListString}
   end

   fun {TkReturnListAtom M}
      {TkReturn Session M TkStringToListAtom}
   end

   fun {TkReturnListInt M}
      {TkReturn Session M TkStringToListInt}
   end

   fun {TkReturnListFloat M}
      {TkReturn Session M TkStringToListFloat}
   end

   class ReturnClass
      meth tkReturn(...) = M
         {self TkReturnMethod(M TkStringToString)}
      end
      meth tkReturnString(...) = M
         {self TkReturnMethod(M TkStringToString)}
      end
      meth tkReturnAtom(...) = M
         {self TkReturnMethod(M TkStringToAtom)}
      end
      meth tkReturnInt(...) = M
         {self TkReturnMethod(M TkStringToInt)}
      end
      meth tkReturnFloat(...) = M
         {self TkReturnMethod(M TkStringToFloat)}
      end
      meth tkReturnList(...) = M
         {self TkReturnMethod(M TkStringToListString)}
      end
      meth tkReturnListString(...) = M
         {self TkReturnMethod(M TkStringToListString)}
      end
      meth tkReturnListAtom(...) = M
         {self TkReturnMethod(M TkStringToListAtom)}
      end
      meth tkReturnListInt(...) = M
         {self TkReturnMethod(M TkStringToListInt)}
      end
      meth tkReturnListFloat(...) = M
         {self TkReturnMethod(M TkStringToListFloat)}
      end
   end


   class Widget
      from ReturnClass

      feat
         !TclSlaves
         !TclSlaveEntry
         !TclName        % widget name

      meth tkBind(event:  Event
                  action: Action  <= _
                  args:   Args    <= nil
                  append: AddIt   <= false
                  break:  BreakIt <= false) = Message
         case {HasFeature Message action} then
            ActionId Command
         in
            {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
            {AddSlave self.TclSlaves ActionId _}
            {TkSend Session bind(self Event v(Command))}
         else
            {TkSend Session bind(self Event '')}
         end
      end

      meth !TkReturnMethod(M Cast)
         {TkReturnMess Session self M unit Cast}
      end

      meth tk(...) = M
         {TkSendTuple Session self M}
      end

      meth tkClose
         {TkClose Session destroy(self) self}
      end

   end


   class CommandWidget
      from Widget

      meth tkInit(parent:Parent ...) = Message
         ThisTclName = self.TclName
         case {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self Message)}
         else skip end
         NewTkName  =
         case {IsObject Parent} then
            ParentSlaves = {CondSelect Parent TclSlaves unit}
         in
            case ParentSlaves==unit then
               {`RaiseError` tk(wrongParent self Message)} _
            else
               self.TclSlaveEntry = {AddSlave ParentSlaves self}
               {GenWidgetName Session Parent.TclName}
            end
         elsecase {IsVirtualString Parent} then
            self.TclSlaveEntry = nil
            {GenWidgetName Session Parent}
         else
            {`RaiseError` tk(wrongParent self Message)} _
         end
      in
         case {HasFeature Message action} then
            ActionId Command
         in
            {DefineCommand Message.action {CondSelect Message args nil}
             ?ActionId ?Command}
            self.TclSlaves = [nil ActionId]
            {TkSendFilter Session self.TkClass NewTkName Message
             [action args parent] v('-command '#Command)}
         else
            self.TclSlaves = [nil]
            {TkSendFilter Session self.TkClass NewTkName Message [parent] unit}
         end
         ThisTclName = NewTkName
      end

      meth tkAction(action:Action<=_ args:Args <= nil) = Message
         case {HasFeature Message action} then ActionId Command in
            {DefineCommand Action Args ?ActionId ?Command}
            {AddSlave self.TclSlaves ActionId _}
            {TkSend Session o(self configure command: v(Command))}
         else {TkSend Session o(self configure command:'')}
         end
      end

   end

   class NoCommandWidget
      from Widget

      meth tkInit(parent:Parent ...) = Message
         ThisTclName = self.TclName
         case {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self Message)}
         else skip
         end
         NewTkName =
         case {IsObject Parent} then
            ParentSlaves = {CondSelect Parent TclSlaves unit}
         in
            case ParentSlaves==unit then
               {`RaiseError` tk(wrongParent self Message)} _
            else
               self.TclSlaveEntry = {AddSlave ParentSlaves self}
               {GenWidgetName Session Parent.TclName}
            end
         elsecase {IsVirtualString Parent} then
            self.TclSlaveEntry = nil
            {GenWidgetName Session Parent}
         else
            {`RaiseError` tk(wrongParent self Message)} _
         end
      in
         self.TclSlaves = [nil]
         {TkSendFilter Session self.TkClass NewTkName Message [parent] unit}
         ThisTclName = NewTkName
      end

   end


   class TkToplevel from Widget

      meth tkInit(...) = Message
         ThisTclName = self.TclName
         case {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self Message)}
         else skip end
         MyTitle  = {CondSelect Message title 'Oz Window'}
         MyTkName =
         case {HasFeature Message parent} then
            Parent = Message.parent
         in
            case {IsObject Parent} then
               ParentSlaves = {CondSelect Parent TclSlaves unit}
            in
               case ParentSlaves==unit then
                  {`RaiseError` tk(wrongParent self Message)} _
               else
                  self.TclSlaveEntry = {AddSlave ParentSlaves self}
                  {GenWidgetName Session Parent.TclName}
               end
            elsecase {IsVirtualString Parent} then
               self.TclSlaveEntry = nil
               {GenWidgetName Session Parent}
            else
               {`RaiseError` tk(wrongParent self Message)} _
            end
         else
            self.TclSlaveEntry = nil
            {GenTopName Session}
         end
         CloseId  CloseCommand
      in
         {DefineCommand {CondSelect Message delete self#tkClose} nil
          ?CloseId ?CloseCommand}
         self.TclSlaves = [nil CloseId]
         {TkSendFilter Session toplevel MyTkName Message
          [delete parent title withdraw]
          o(case {CondSelect Message withdraw false} then
               v('; wm withdraw '#MyTkName)
            else unit
            end
            v('; wm title '#MyTkName) MyTitle
            v('; wm protocol '#MyTkName#' WM_DELETE_WINDOW '# CloseCommand))}
         ThisTclName = MyTkName
      end

      meth tkWM(...) = M
         {TkSendTagTuple Session wm self M}
      end

   end


   class AppletToplevel from TkToplevel
      prop final
      feat args

      meth tkClose
         TkToplevel, tkClose
         {System.exit 0}
      end

   end

   class BrowserAppletToplevel from Widget
      prop final
      attr Action
      feat rawArgs args
      meth tkInit
         ThisTclName = self.TclName
         case {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self tkInit)}
         else skip end
      in
         self.TclSlaveEntry = nil
         self.TclSlaves = [nil]
         ThisTclName = ''
         Action <- self#tkClose
      end

      meth tkDeleteAction(A)
         Action <- A
      end

      meth !AppletClosed
         case @Action of O#M then {O M} elseof A then {A} end
      end

      meth tkClose
         {TkCloseApplet Session self}
         {System.exit 0}
      end

   end


   class TkFrame from NoCommandWidget
      feat !TkClass:frame
   end

   class TkButton from CommandWidget
      feat !TkClass:button
   end

   class TkCheckbutton from CommandWidget
      feat !TkClass:checkbutton
   end

   class TkListbox from NoCommandWidget
      feat !TkClass:listbox
   end

   class TkRadiobutton from CommandWidget
      feat !TkClass:radiobutton
   end

   class TkScrollbar from CommandWidget
      feat !TkClass:scrollbar
   end

   class TkScale from CommandWidget
      feat !TkClass:scale
   end

   class TkEntry from NoCommandWidget
      feat !TkClass:entry
   end

   class TkLabel from NoCommandWidget
      feat !TkClass:label
   end

   class TkMessage from NoCommandWidget
      feat !TkClass:message
   end

   class TkMenubutton from NoCommandWidget
      feat !TkClass:menubutton
   end

   class TkText from NoCommandWidget
      feat !TkClass: text
   end

   class TkCanvas from NoCommandWidget
      feat !TkClass: canvas
   end


   local
      TkType      = {NewName}
      EntryVar    = {NewName}
      EntryLock   = {NewName}
      AddEntry    = {NewName}
      InsertEntry = {NewName}
      RemoveEntry = {NewName}

      fun {MkMove Es I}
         case Es of nil then nil
         [] E|Er then v(';')|set(E.EntryVar I)|{MkMove Er I+1}
         end
      end

      fun {Add Es EA I ?Tcl}
         case Es of nil then Tcl=[v(';') set(EA.EntryVar I)] [EA]
         [] E|Er then E|{Add Er EA I+1 ?Tcl}
         end
      end

      fun {Insert Es EA EB I ?Tcl}
         case Es of nil then Tcl=[v(';') set(EA.EntryVar I)] [EA]
         [] E|Er then
            case E==EB then Tcl={MkMove EA|Es I} EA|Es
            else E|{Insert Er EA EB I+1 ?Tcl}
            end
         end
      end

      fun {Remove Es EA I ?Tcl}
         case Es of nil then Tcl=[unit] nil
         [] E|Er then
            case E==EA then Tcl={MkMove Er I} Er
            else E|{Remove Er EA I+1 ?Tcl}
            end
         end
      end


      class TkMenuentry
         feat
            !TclSlaves
            !TclSlaveEntry
            !TclName        % widget name
            !EntryVar
            !TkWidget

         meth tkInit(parent: Parent
                     before: Before <= _
                     action: Action <= _
                     args:   Args   <= nil ...) = Message
            ThisTclName = self.TclName
            case {IsDet ThisTclName} then
               {`RaiseError` tk(alreadyInitialized self Message)}
            else skip end
            ParentLock  = {CondSelect Parent EntryLock unit}
            case ParentLock==unit then
               {`RaiseError` tk(wrongParent self Message)}
            else skip end
         in
            lock ParentLock then
               IsInsert = {HasFeature Message before}
               MoveTcl  = case IsInsert then
                             {Parent InsertEntry(self Before $)}
                          else {Parent AddEntry(self $)}
                          end
               VarName  = {GenVarName Session}
            in
               case MoveTcl of unit then skip else
                  self.TkWidget      = Parent
                  self.TclSlaveEntry = {AddSlave Parent.TclSlaves self}
                  self.EntryVar      = VarName
                  case {HasFeature Message action} then
                     ActionId Command
                  in
                     {DefineCommand Action Args ?ActionId ?Command}
                     self.TclSlaves = [nil ActionId]
                     {TkSendFilter Session
                      o(Parent case IsInsert then insert(Before)
                               else add
                               end)
                      self.TkType Message [action args before parent]
                      o(v('-command '#Command) b(MoveTcl))}
                  else
                     self.TclSlaves = [nil]
                     {TkSendFilter Session
                      o(Parent case IsInsert then insert(Before)
                               else add
                               end)
                      self.TkType Message [action args before parent]
                      b(MoveTcl)}
                  end
                  ThisTclName = '[ozm $'#VarName#' '#Parent.TclName#']'
               end
            end
         end

         meth tk(...) = M
            Parent = self.TkWidget
         in
            lock Parent.EntryLock then
               {TkSendTagTuple Session Parent self M}
            end
         end

         meth tkClose
            Parent = self.TkWidget
         in
            lock Parent.EntryLock then
               case {Parent RemoveEntry(self $)} of unit then skip
               elseof MoveTcl then
                  {TkClose Session o(Parent delete self v(';')
                                     unset self.EntryVar       v(';')
                                     b(MoveTcl)) self}
               end
            end
         end
      end

   in

      class TkMenu from NoCommandWidget
         feat
            !TkClass: menu
            !EntryLock
         attr
            Entries: nil
         meth tkInit(...) = Message
            self.EntryLock = {NewLock}
            NoCommandWidget,Message
         end
         meth !AddEntry(E ?Tcl)
            case @Entries of unit then ?Tcl=unit else
               Entries <- {Add @Entries E 0 ?Tcl}
            end
         end
         meth !InsertEntry(E EB ?Tcl)
            case @Entries of unit then ?Tcl=unit else
               Entries <- {Insert @Entries E EB 0 ?Tcl}
            end
         end
         meth !RemoveEntry(E ?Tcl)
            case @Entries of unit then ?Tcl=unit else
               Entries <- {Remove @Entries E 0 ?Tcl}
            end
         end
         meth tkClose
            lock self.EntryLock then
               Entries <- unit
            end
            NoCommandWidget,tkClose
         end
      end

      TkMenuentries = menuentry(cascade:     class $ from TkMenuentry
                                                feat !TkType:cascade
                                             end
                                checkbutton: class $ from TkMenuentry
                                                feat !TkType:checkbutton
                                             end
                                command:     class $ from TkMenuentry
                                                feat !TkType:command
                                             end
                                radiobutton: class $ from TkMenuentry
                                                feat !TkType:radiobutton
                                             end
                                separator:   class $ from TkMenuentry
                                                feat !TkType:separator
                                             end)

   end



   %%
   %% Tcl/Tk variables
   %%
   class TkVariable
      feat !TclName

      meth tkInit(...) = Message
         MyTclName   = {GenVarName Session}
         ThisTclName = self.TclName
      in
         case {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self Message)}
         else skip end
         case {Width Message}
         of 0 then skip
         [] 1 then {TkSend Session set(v(MyTclName) Message.1)}
         end
         ThisTclName = MyTclName
      end

      meth tkSet(X)
         {TkSend Session set(self X)}
      end

      meth tkReturn($)
         {TkReturn Session set(self) TkStringToString}
      end
      meth tkReturnString($)
         {TkReturn Session set(self) TkStringToString}
      end
      meth tkReturnAtom($)
         {TkReturn Session set(self) TkStringToAtom}
      end
      meth tkReturnInt($)
         {TkReturn Session set(self) TkStringToInt}
      end
      meth tkReturnFloat($)
         {TkReturn Session set(self) TkStringToFloat}
      end
      meth tkReturnList($)
         {TkReturn Session set(self) TkStringToListString}
      end
      meth tkReturnListString($)
         {TkReturn Session set(self) TkStringToListString}
      end
      meth tkReturnListAtom($)
         {TkReturn Session set(self) TkStringToListAtom}
      end
      meth tkReturnListInt($)
         {TkReturn Session set(self) TkStringToListInt}
      end
      meth tkReturnListFloat($)
         {TkReturn Session set(self) TkStringToListFloat}
      end

   end




   class TkTagAndMark from ReturnClass
      feat
         !TkWidget
         !TclSlaves
         !TclSlaveEntry
         !TclName        % widget name

      meth tkInit(parent:Parent)
         ThisTclName  = self.TclName
         ParentSlaves = {CondSelect Parent TclSlaves unit}
      in
         case ParentSlaves==unit then
            {`RaiseError` tk(wrongParent self tkInit(parent:Parent))}
         else skip end
         case {IsDet ThisTclName} then
            {`RaiseError` tk(alreadyInitialized self tkInit(parent:Parent))}
         else skip end
         self.TclSlaves     = [nil]
         self.TclSlaveEntry = {AddSlave ParentSlaves self}
         self.TkWidget      = Parent
         ThisTclName        = {GenTagName Session}
      end

   end


   class TkTextMark
      from TkTagAndMark

      meth tk(...) = M
         {TkSendTagTuple Session o(self.TkWidget mark) self M}
      end

      meth !TkReturnMethod(M Cast)
         {TkReturnMess Session o(self.TkWidget mark) M self Cast}
      end

      meth tkClose
         {TkClose Session o(self.TkWidget mark delete self) self}
      end

   end


   class TkCanvasTag
      from TkTagAndMark

      meth tkBind(event:  Event
                  action: Action  <= _
                  args:   Args    <= nil
                  append: AddIt   <= false
                  break:  BreakIt <= false) = Message
         case {HasFeature Message action} then
            ActionId Command
         in
            {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
            {AddSlave self.TclSlaves ActionId _}
            {TkSend Session o(self.TkWidget bind self Event v(Command))}
         else
            {TkSend Session o(self.TkWidget bind self Event '')}
         end
      end

      meth tk(...) = M
         {TkSendTagTuple Session self.TkWidget self M}
      end

      meth !TkReturnMethod(M Cast)
         {TkReturnMess Session self.TkWidget M self Cast}
      end

      meth tkClose
         {TkClose Session o(self.TkWidget delete self) self}
      end

   end


   class TkTextTag
      from TkTagAndMark

      meth tkBind(event:  Event
                  action: Action  <= _
                  args:   Args    <= nil
                  append: AddIt   <= false
                  break:  BreakIt <= false) = Message
         case {HasFeature Message action} then
            ActionId Command
         in
            {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
            {AddSlave self.TclSlaves ActionId _}
            {TkSend Session o(self.TkWidget tag bind self Event v(Command))}
         else
            {TkSend Session o(self.TkWidget tag bind self Event '')}
         end
      end

      meth tk(...) = M
         {TkSendTagTuple Session o(self.TkWidget tag) self M}
      end

      meth !TkReturnMethod(M Cast)
         {TkReturnMess Session o(self.TkWidget tag) M self Cast}
      end

      meth tkClose
         {TkClose Session o(self.TkWidget tag delete self) self}
      end

   end

   local
      ImRes = {URL.makeResolver image
               vs('all=.:cache='#{OS.getEnv 'OZHOME'}#'/cache')}
   in
      class TkImage
         from ReturnClass
         feat !TclName
         attr ToUnlink: nil

         meth Resolve(Url $)
            case {ImRes.localize Url}
            of old(F) then F
            [] new(F) then ToUnlink <- F|@ToUnlink F
            end
         end

         meth Unlink(Fs)
            case Fs of nil then skip
            [] F|Fr then {OS.unlink F} TkImage,Unlink(Fr)
            end
         end

         meth tkInit(type:Type ...) = Message
            ThisTclName = self.TclName
            case {IsDet ThisTclName} then
               {`RaiseError` tk(alreadyInitialized self Message)}
            else skip end
            NewTkName   = {GenImageName Session}
            MessUrl = case {HasFeature Message url} then
                         {AdjoinAt Message file
                          TkImage,Resolve(Message.url $)}
                      else Message
                      end
            MessAll = case {HasFeature MessUrl maskurl} then
                         {AdjoinAt MessUrl maskfile
                          TkImage,Resolve(MessUrl.maskurl $)}
                      else MessUrl
                      end
         in
            {TkSendFilter Session v('image create '#Type) NewTkName
             MessAll [maskurl type url] unit}
            ThisTclName = NewTkName
            /*
            Currently disbaled, because of synchronisation problems
            {Wait {TkReturnString update(idletasks)}}
            TkImage,Unlink(@ToUnlink)
            */
            ToUnlink <- nil
         end
         meth tk(...) = M
            {TkSendTuple Session self M}
         end
         meth tkImage(...) = M
            {TkSendTagTuple Session image self M}
         end
         meth !TkReturnMethod(M Cast)
            {TkReturnMess Session self M unit Cast}
         end
         meth tkImageReturn(...) = M
            {TkReturnMess Session image M self TkStringToString}
         end
         meth tkImageReturnString(...) = M
            {TkReturnMess Session image M self TkStringToString}
         end
         meth tkImageReturnAtom(...) = M
            {TkReturnMess Session image M self TkStringToAtom}
         end
         meth tkImageReturnInt(...) = M
            {TkReturnMess Session image M self TkStringToInt}
         end
         meth tkImageReturnFloat(...) = M
            {TkReturnMess Session image M self TkStringToFloat}
         end
         meth tkImageReturnList(...) = M
            {TkReturnMess Session image M self TkStringToListString}
         end
         meth tkImageReturnListString(...) = M
            {TkReturnMess Session image M self TkStringToListString}
         end
         meth tkImageReturnListAtom(...) = M
            {TkReturnMess Session image M self TkStringToListAtom}
         end
         meth tkImageReturnListInt(...) = M
            {TkReturnMess Session image M self TkStringToListInt}
         end
         meth tkImageReturnListFloat(...) = M
            {TkReturnMess Session image M self TkStringToListFloat}
         end
         meth tkClose
            {ForAll @ToUnlink OS.unlink}
         end
      end
   end

   proc {AddYScrollbar T S}
      {TkBatch Session
       [o(T configure yscrollcommand: s(S set))
        o(S configure command:        s(T yview))]}
   end

   proc {AddXScrollbar T S}
      {TkBatch Session
       [o(T configure xscrollcommand: s(S set))
        o(S configure command:        s(T xview))]}
   end

   IsColor = case SGI.browser then true else
                thread
                   {TkReturnInt winfo(depth '.')}>1
                end
             end

   fun {DefineUserCmd TclCmd Action Args}
      Casts    = {GetCasts Args}
      ActionId = {ActionIdServer get($)}
   in
      {Dictionary.put TkDict ActionId case Action of O#M then O#M#Casts
                                      else Action#Casts
                                      end}
      {TkSend Session v('proc '#TclCmd#' args {\n' #
                        '   eval ozp '#ActionId#' '#'$args\n' #
                        '}')}
      proc {$}
         {TkSend Session v('rename '#TclCmd#' ""')}
         {Dictionary.remove TkDict ActionId}
      end
   end

in

   tk(send:          proc {$ Tcl} {TkSend Session Tcl}  end
      batch:         proc {$ Tcl} {TkBatch Session Tcl} end

      return:           TkReturnString
      returnString:     TkReturnString
      returnAtom:       TkReturnAtom
      returnInt:        TkReturnInt
      returnFloat:      TkReturnFloat
      returnList:       TkReturnListString
      returnListString: TkReturnListString
      returnListAtom:   TkReturnListAtom
      returnListInt:    TkReturnListInt
      returnListFloat:  TkReturnListFloat

      getPrefix:     TkGetPrefix
      getId:         TkGetId
      getTclName:    TkGetTclName

      invoke:        InvokeAction

      button:        TkButton
      canvas:        TkCanvas
      checkbutton:   TkCheckbutton
      entry:         TkEntry
      frame:         TkFrame
      label:         TkLabel
      listbox:       TkListbox
      menu:          TkMenu
      menubutton:    TkMenubutton
      message:       TkMessage
      radiobutton:   TkRadiobutton
      scale:         TkScale
      scrollbar:     TkScrollbar
      text:          TkText
      toplevel:      TkToplevel

      menuentry:     TkMenuentries

      image:         TkImage

      textTag:       TkTextTag
      textMark:      TkTextMark
      canvasTag:     TkCanvasTag

      action:        TkAction
      variable:      TkVariable
      string:        string(toInt:        TkStringToInt
                            toFloat:      TkStringToFloat
                            toListString: TkStringToListString
                            toListAtom:   TkStringToListAtom
                            toListInt:    TkStringToListInt
                            toListFloat:  TkStringToListFloat)

      isColor:       IsColor

      addYScrollbar: AddYScrollbar
      addXScrollbar: AddXScrollbar

      defineUserCmd: DefineUserCmd
      applet:        Applet)

end
