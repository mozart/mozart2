%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

import
   TkBoot at 'x-oz://boot/Tk'

   Property(get)

   System(showError)

   Error(registerFormatter)

   Open(pipe
        text
        socket)

   OS(getEnv
      putEnv
      close
      exec
      pipe
      stat)

   Resolve(makeResolver pickle handler)

export
   send:          TkSend
   batch:         TkBatch

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

   getPrefix:        TkGetPrefix
   getId:            TkGetId
   getTclName:       TkGetTclName

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
   font:          TkFont

   listener:      TkListener

   textTag:       TkTextTag
   textMark:      TkTextMark
   canvasTag:     TkCanvasTag

   action:        TkAction
   variable:      TkVariable
   string:        TkString

   isColor:       IsColor

   addYScrollbar:   AddYScrollbar
   addXScrollbar:   AddXScrollbar

   defineUserCmd:   DefineUserCmd
   localize:        TkFixedLocalize

   optionsManager:  OptionsManager

   newWidgetClass:  NewWidgetClass

prepare

   class Counter
      prop locking final
      attr n:0
      meth get(?N)
         lock N=@n n <- N+1 end
      end
   end

   Stok  = String.token
   Stoks = String.tokens
   S2F   = String.toFloat
   S2I   = String.toInt
   SIF   = String.isFloat
   SII   = String.isInt

   V2S   = VirtualString.toString

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
         if IsAFloat andthen {SIF OS} then
            {FloatToInt {S2F OS}}
         elseif {Not IsAFloat} andthen {SII OS} then
            {S2I OS}
         else false
         end
      end

      fun {TkStringToFloat S}
         %% Read a number and convert it to a float
         OS IsAFloat in OS={TkNum S false ?IsAFloat}
         if IsAFloat andthen {SIF OS} then
            {S2F OS}
         elseif {Not IsAFloat} andthen {SII OS} then
            {IntToFloat {S2I OS}}
         else false
         end
      end

      fun {TkStringToListString S}
         {Stoks S & }
      end

      fun {TkStringToListAtom S}
         {Map {Stoks S & } TkStringToAtom}
      end

      fun {TkStringToListInt S}
         {Map {Stoks S & } TkStringToInt}
      end

      fun {TkStringToListFloat S}
         {Map {Stoks S & } TkStringToFloat}
      end
   end


   %% expand a quoted Tcl/Tk string
   %%  \n     -> newline
   %%  \<any> -> <any>
   fun {Expand Is}
      case Is of nil then nil
      [] I|Ir then
         if I==&\\ then
            case Ir of nil then nil
            [] II|Irr then
               if II==&n then &\n else II end|{Expand Irr}
            end
         else I|{Expand Ir}
         end
      end
   end

   local
      IsTkListener = {NewName}
      ListenToThat = {NewName}

      proc {EnterMessageArgs As I T}
         case As of nil then skip
         [] A|Ar then T.I=A {EnterMessageArgs Ar I+1 T}
         end
      end

      proc {EnterPrefixArgs I MP M}
         if I>0 then  M.I=MP.I {EnterPrefixArgs I-1 MP M} end
      end

      fun {MaxInt As M}
         case As of nil then M
         [] A|Ar then
            {MaxInt Ar if {IsInt A} then {Max M A} else M end}
         end
      end

      fun {NumberArgs As I}
         case As of nil then nil
         [] A|Ar then J=I+1 in J#A|{NumberArgs Ar J}
         end
      end

      proc {Hear L Ms}
         case Ms of nil then skip
         [] M|Mr then {L M} {Hear L Mr}
         end
      end

   in
      class TkListener
         feat !IsTkListener:unit
         attr Tail
         meth tkInit
            Stream = @Tail
         in
            thread {Hear self Stream} end
         end
         meth !ListenToThat(M)
            NewTail
         in
            M|NewTail = (Tail <- NewTail)
         end
         meth tkServe(M)
            TkListener,ListenToThat(M)
         end
         meth tkClose
            Tail <- nil
         end
      end

      proc {InvokeAction Action Args NoArgs Thread}
         case Action
         of OP # M then SM in
            if NoArgs==0 then SM=M
            elseif {IsTuple M} then W={Width M} in
               SM = {MakeTuple {Label M} NoArgs + W}
               {EnterPrefixArgs W M SM}
               {EnterMessageArgs Args {Width M}+1 SM}
            else
               SM={AdjoinList M {NumberArgs Args {MaxInt {Arity M} 0}}}
            end
            if {IsPort OP} then
               {Send OP SM}
            elseif {IsObject OP} andthen {HasFeature OP IsTkListener} then
               {OP ListenToThat(SM)}
            elseif Thread then
               thread {OP SM} end
            else
               {OP SM}
            end
         else
            if NoArgs==0 then
               if Thread then
                  thread {Action} end
               else {Action}
               end
            else
               if Thread then
                  thread {Procedure.apply Action Args} end
               else {Procedure.apply Action Args}
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
      if N>=IdNumber then
         IdCharacters.((N mod IdNumber) + 1)|{GenString N div IdNumber}
      else [IdCharacters.N]
      end
   end

   TkString = string(toInt:        TkStringToInt
                     toFloat:      TkStringToFloat
                     toListString: TkStringToListString
                     toListAtom:   TkStringToListAtom
                     toListInt:    TkStringToListInt
                     toListFloat:  TkStringToListFloat)


define

   %%
   %% Error formatter
   %%

   {Error.registerFormatter tk
    fun {$ E}
       T = 'Error: Tk module'
    in
       case E
       of tk(wrongParent O M) then
          error(kind: T
                msg: 'Wrong Parent'
                items: [hint(l:'Object application'
                             m:'{' # oz(O) # ' ' # oz(M) # '}')])
       [] tk(alreadyInitialized O M) then
          error(kind: T
                msg: 'Object already initialized'
                items: [hint(l:'Object application'
                             m:'{' # oz(O) # ' ' # oz(M) # '}')])
       [] tk(alreadyClosed O M) then
          error(kind: T
                msg: 'Window already closed'
                items: [hint(l:'Object application'
                             m:'{' # oz(O) # ' ' # oz(M) # '}')])
       [] tk(alreadyClosed O) then
          error(kind: T
                msg: 'Window already closed'
                items: [hint(l:'Object' m:oz(O))])
       [] tk(engineCrashed) then
          error(kind: T
                msg: ('Graphics engine (tk.exe) crashed '#
                      'or could not be started'))
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

   %%
   %% Sending tickles
   %%
   TkInit         = TkBoot.init
   TkGetNames     = TkBoot.getNames

   TkSend         = TkBoot.send
   TkBatch        = TkBoot.batch
   TkReturn       = TkBoot.return
   TkReturnMess   = TkBoot.returnMess
   TkSendTuple    = TkBoot.sendTuple
   TkSendTagTuple = TkBoot.sendTagTuple
   TkSendFilter   = TkBoot.sendFilter

   TkClose        = TkBoot.close

   %%
   %% Generation of Identifiers
   %%
   GenTopName    = TkBoot.genTopName
   GenWidgetName = TkBoot.genWidgetName
   GenTagName    = TkBoot.genTagName
   GenVarName    = TkBoot.genVarName
   GenImageName  = TkBoot.genImageName
   GenFontName   = TkBoot.genFontName


   %%
   %% Master slave mechanism for widgets
   %%
   AddSlave  = TkBoot.addGroup
   DelSlave  = TkBoot.delGroup

   %%
   %% Printing error messages
   %%
   proc {TkError S Tcl}
      P={Property.get errors}
   in
      {System.showError 'Tk Module: '#S#
       if Tcl==unit then '' else '\n'#
          {Value.toVirtualString Tcl P.depth P.width}
       end}
   end


   Stream = local
               Platform = {Property.get 'platform.name'}
               PLTFRM = ({Property.get 'oz.home'} #
                         '/platform/'#Platform#'/')
               TKEXE = case {Property.get 'platform.arch'}
                       of 'darwin' then 'OzWish.app/Contents/MacOS/OzWish'
                       else 'tk.exe' end
            in
               {OS.putEnv 'TCL_LIBRARY' PLTFRM#'wish/tcl'}
               {OS.putEnv 'TK_LIBRARY'  PLTFRM#'wish/tk'}

               % RS: on MS Windows we use a socket: before we used
               % pipes, but on NT this made problems when certain background
               % tasks where running: Tk could get stuck here
               if Platform == 'win32-i486'
               then Stream Port in
                  thread
                     Stream = {New class $ from Open.socket Open.text
                                      prop final
                                   end
                               server(port: ?Port)}
                  end
                  {Wait Port}
                  _ = {OS.exec PLTFRM#TKEXE [Port] true}
                  {Wait Stream}
                  Stream
               else
                  {New class $ from Open.pipe Open.text
                          prop final
                       end
                   init(cmd:PLTFRM#TKEXE)}
               end
            end

   ActionIdServer = {New Counter get(_)}

   TkDict         = {Dictionary.new}

   local
      TkInitStr =
      \insert TkInit.oz
   in
      {Stream write(vs:TkInitStr)}
      {Stream flush(how:[send])}
   end

   local
      RealRetStream = {TkInit {Stream getDesc(_ $)} TkDict}
   in
      RetStream = {Cell.new RealRetStream}
   end

   local
      fun {GetArgs N Ps}
         %% Get the next N line lines expanded
         if N>0 then E={Expand {Stream getS($)}} in
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

      proc {TkReadLoop RS}
         Is={Stream getS($)}
      in
         case Is
         of I|Ir then Irr=Ir.2 in
            case I
            of &r then Rs Car Cdr in
               {Cell.exchange RS Rs Cdr}
               Car = Rs.1
               Cdr = Rs.2
               Car.1 = {Car.2 {Expand Irr}} {TkReadLoop RS}
            [] &p then
               Irr1
               Id     = {S2I {Stok Irr  & $ ?Irr1}}
               NoArgs = {S2I {Stok Irr1 & $ _}}
            in
               case {Dictionary.condGet TkDict Id unit}
               of O # M # Ps then
                  {InvokeAction O#M {GetArgs NoArgs Ps} NoArgs true}
               [] P # Ps then
                  {InvokeAction P {GetArgs NoArgs Ps} NoArgs true}
               else
                  _={GetArgs NoArgs nil}
               end
               {TkReadLoop RS}
            [] &s then
               {TkSend
                v('puts stdout {s end}; flush stdout; destroy .')}
               {Stream close}
            [] &w then
               {TkError Irr#'\n'#{ReadUntilDot} unit}
               {TkReadLoop RS}
            else {TkReadLoop RS}
            end
         [] false then
            {Stream close}
         end
      end

      %% Start reading wish's output
      thread
         try
            {Thread.setThisPriority high}
            {TkReadLoop RetStream}
         catch _ then
            raise system(tk(engineCrashed)) end
         end
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
      IdBase   = {StringToAtom {TkGetPrefix}}
      IdServer = {New Counter get(_)}
   in
      fun {TkGetId}
         IdBase#{IdServer get($)}
      end
   end

   fun {TkGetTclName W}
      {V2S W.TclName}
   end

   TkReturnMethod = {NewName}
   TkClass        = {NewName}
   TkWidget       = {NewName}

   TclSlaves TclSlaveEntry TclName
   {TkGetNames ?TclSlaves ?TclSlaveEntry ?TclName}

   proc {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
      Fields = {GetFields Args}
      Casts  = {GetCasts Args}
   in
      ActionId = {ActionIdServer get($)}
      {Dictionary.put TkDict ActionId case Action
                                      of O#M then O#M#Casts
                                      elseof P then P # Casts
                                      end}
      Command = '{'#if AddIt then '+' else '' end#'ozp '#ActionId#
      Fields #
      if BreakIt then '; break' else '' end#'}'
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
      prop
         sited
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
         if ParentSlaves==unit then
            {Exception.raiseError tk(wrongParent self M)}
         elseif {IsDet ThisTclName} then
            {Exception.raiseError tk(alreadyInitialized self M)}
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
      {TkReturn M TkStringToString}
   end

   fun {TkReturnAtom M}
      {TkReturn M TkStringToAtom}
   end

   fun {TkReturnInt M}
      {TkReturn M TkStringToInt}
   end

   fun {TkReturnFloat M}
      {TkReturn M TkStringToFloat}
   end

   fun {TkReturnListString M}
      {TkReturn M TkStringToListString}
   end

   fun {TkReturnListAtom M}
      {TkReturn M TkStringToListAtom}
   end

   fun {TkReturnListInt M}
      {TkReturn M TkStringToListInt}
   end

   fun {TkReturnListFloat M}
      {TkReturn M TkStringToListFloat}
   end

   class ReturnClass
      prop sited
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
                  action: Action  <= unit
                  args:   Args    <= nil
                  append: AddIt   <= false
                  break:  BreakIt <= false) = Message
         if {HasFeature Message action} then
            ActionId Command
         in
            {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
            {AddSlave self.TclSlaves ActionId _}
            {TkSend bind(self Event v(Command))}
         else
            {TkSend bind(self Event '')}
         end
      end

      meth !TkReturnMethod(M Cast)
         {TkReturnMess self M unit Cast}
      end

      meth tk(...) = M
         {TkSendTuple self M}
      end

      meth tkClose
         {TkClose destroy(self) self}
      end

   end


   class CommandWidget
      from Widget

      meth tkInit(parent:Parent ...) = Message
         ThisTclName = self.TclName
         if {IsDet ThisTclName} then
            {Exception.raiseError tk(alreadyInitialized self Message)}
         end
         NewTkName  =
         if {IsObject Parent} then
            ParentSlaves = {CondSelect Parent TclSlaves unit}
         in
            if ParentSlaves==unit then
               {Exception.raiseError tk(wrongParent self Message)} _
            else
               self.TclSlaveEntry = {AddSlave ParentSlaves self}
               {GenWidgetName Parent.TclName}
            end
         elseif {IsVirtualString Parent} then
            self.TclSlaveEntry = nil
            {GenWidgetName Parent}
         else
            {Exception.raiseError tk(wrongParent self Message)} _
         end
      in
         if {HasFeature Message action} then
            ActionId Command
         in
            {DefineCommand Message.action {CondSelect Message args nil}
             ?ActionId ?Command}
            self.TclSlaves = [nil ActionId]
            {TkSendFilter self.TkClass NewTkName Message
             [action args parent] v('-command '#Command)}
         else
            self.TclSlaves = [nil]
            {TkSendFilter self.TkClass NewTkName Message [parent] unit}
         end
         ThisTclName = NewTkName
      end

      meth tkAction(action:Action<=unit args:Args <= nil) = Message
         if {HasFeature Message action} then ActionId Command in
            {DefineCommand Action Args ?ActionId ?Command}
            {AddSlave self.TclSlaves ActionId _}
            {TkSend o(self configure command: v(Command))}
         else
            {TkSend o(self configure command:'')}
         end
      end

   end

   class NoCommandWidget
      from Widget

      meth tkInit(parent:Parent ...) = Message
         ThisTclName = self.TclName
         if {IsDet ThisTclName} then
            {Exception.raiseError tk(alreadyInitialized self Message)}
         end
         NewTkName =
         if {IsObject Parent} then
            ParentSlaves = {CondSelect Parent TclSlaves unit}
         in
            if ParentSlaves==unit then
               {Exception.raiseError tk(wrongParent self Message)} _
            else
               self.TclSlaveEntry = {AddSlave ParentSlaves self}
               {GenWidgetName Parent.TclName}
            end
         elseif {IsVirtualString Parent} then
            self.TclSlaveEntry = nil
            {GenWidgetName Parent}
         else
            {Exception.raiseError tk(wrongParent self Message)} _
         end
      in
         self.TclSlaves = [nil]
         {TkSendFilter self.TkClass NewTkName Message [parent] unit}
         ThisTclName = NewTkName
      end

   end


   class TkToplevel from Widget

      meth tkInit(...) = Message
         ThisTclName = self.TclName
         if {IsDet ThisTclName} then
            {Exception.raiseError tk(alreadyInitialized self Message)}
         end
         MyTitle  = {CondSelect Message title 'Oz Window'}
         MyTkName =
         if {HasFeature Message parent} then
            Parent = Message.parent
         in
            if {IsObject Parent} then
               ParentSlaves = {CondSelect Parent TclSlaves unit}
            in
               if ParentSlaves==unit then
                  {Exception.raiseError tk(wrongParent self Message)} _
               else
                  self.TclSlaveEntry = {AddSlave ParentSlaves self}
                  {GenWidgetName Parent.TclName}
               end
            elseif {IsVirtualString Parent} then
               self.TclSlaveEntry = nil
               {GenWidgetName Parent}
            else
               {Exception.raiseError tk(wrongParent self Message)} _
            end
         else
            self.TclSlaveEntry = nil
            {GenTopName}
         end
         CloseId  CloseCommand
      in
         {DefineCommand {CondSelect Message delete self#tkClose} nil
          ?CloseId ?CloseCommand}
         self.TclSlaves = [nil CloseId]
         {TkSendFilter toplevel MyTkName Message
          [delete parent title withdraw]
          o(if {CondSelect Message withdraw false} then
               v('; wm withdraw '#MyTkName)
            else unit
            end
            v('; wm title '#MyTkName) MyTitle
            v('; wm protocol '#MyTkName#' WM_DELETE_WINDOW '# CloseCommand))}
         ThisTclName = MyTkName
      end

      meth tkWM(...) = M
         {TkSendTagTuple wm self M}
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
            if E==EB then Tcl={MkMove EA|Es I} EA|Es
            else E|{Insert Er EA EB I+1 ?Tcl}
            end
         end
      end

      fun {Remove Es EA I ?Tcl}
         case Es of nil then Tcl=[unit] nil
         [] E|Er then
            if E==EA then Tcl={MkMove Er I} Er
            else E|{Remove Er EA I+1 ?Tcl}
            end
         end
      end


      class TkMenuentry
         from ReturnClass
         prop
            sited
         feat
            !TclSlaves
            !TclSlaveEntry
            !TclName        % widget name
            !EntryVar
            !TkWidget

         meth tkInit(parent: Parent
                     before: Before <= unit
                     action: Action <= unit
                     args:   Args   <= nil ...) = Message
            ThisTclName = self.TclName
            if {IsDet ThisTclName} then
               {Exception.raiseError tk(alreadyInitialized self Message)}
            end
            ParentLock  = {CondSelect Parent EntryLock unit}
            if ParentLock==unit then
               {Exception.raiseError tk(wrongParent self Message)}
            end
         in
            lock ParentLock then
               IsInsert = {HasFeature Message before}
               MoveTcl  = if IsInsert then
                             {Parent InsertEntry(self Before $)}
                          else {Parent AddEntry(self $)}
                          end
               VarName  = {GenVarName}
            in
               case MoveTcl of unit then skip else
                  self.TkWidget      = Parent
                  self.TclSlaveEntry = {AddSlave Parent.TclSlaves self}
                  self.EntryVar      = VarName
                  if {HasFeature Message action} then
                     ActionId Command
                  in
                     {DefineCommand Action Args ?ActionId ?Command}
                     self.TclSlaves = [nil ActionId]
                     {TkSendFilter
                      o(Parent if IsInsert then insert(Before)
                               else add
                               end)
                      self.TkType Message [action args before parent]
                      o(v('-command '#Command) b(MoveTcl))}
                  else
                     self.TclSlaves = [nil]
                     {TkSendFilter
                      o(Parent if IsInsert then insert(Before)
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
               {TkSendTagTuple Parent self M}
            end
         end

         meth !TkReturnMethod(M Cast)
            Parent = self.TkWidget
         in
            lock Parent.EntryLock then
               {TkReturnMess Parent M self Cast}
            end
         end

         meth tkClose
            Parent = self.TkWidget
         in
            lock Parent.EntryLock then
               case {Parent RemoveEntry(self $)} of unit then skip
               elseof MoveTcl then
                  {TkClose o(Parent delete self v(';')
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
   class TkVariable from ReturnClass
      prop sited
      feat !TclName

      meth tkInit(InitValue <= unit)
         MyTclName   = {GenVarName}
         ThisTclName = self.TclName
      in
         if {IsDet ThisTclName} then
            {Exception.raiseError tk(alreadyInitialized self tkInit)}
         end
         if InitValue\=unit then
            {TkSend set(v(MyTclName) InitValue)}
         end
         ThisTclName = MyTclName
      end
      meth tkSet(X)
         {TkSend set(self X)}
      end
      meth !TkReturnMethod(M C)
         M.1={TkReturn set(self) C}
      end
   end


   %%
   %% Tags and Marks
   %%

   local
      TkQualify = {NewName}

      class TkTagAndMark from ReturnClass
         feat
            !TkWidget
            !TclSlaves
            !TclSlaveEntry
            !TclName

         meth tkInit(parent:Parent)
            ThisTclName  = self.TclName
            ParentSlaves = {CondSelect Parent TclSlaves unit}
         in
            if ParentSlaves==unit then
               {Exception.raiseError tk(wrongParent self tkInit(parent:Parent))}
            end
            if {IsDet ThisTclName} then
               {Exception.raiseError tk(alreadyInitialized self tkInit(parent:Parent))}
            end
            self.TclSlaves     = [nil]
            self.TclSlaveEntry = {AddSlave ParentSlaves self}
            self.TkWidget      = Parent
            ThisTclName        = {GenTagName}
         end

         meth tk(...) = M
            {TkSendTagTuple o(self.TkWidget self.TkQualify) self M}
         end

         meth !TkReturnMethod(M Cast)
            {TkReturnMess o(self.TkWidget self.TkQualify) M self Cast}
         end

         meth tkClose
            {TkClose o(self.TkWidget self.TkQualify delete self) self}
         end
      end

      class TkTag from TkTagAndMark
         meth tkBind(event:  Event
                     action: Action  <= unit
                     args:   Args    <= nil
                     append: AddIt   <= false
                     break:  BreakIt <= false) = Message
            if {HasFeature Message action} then
               ActionId Command
            in
               {DefineEvent Action Args AddIt BreakIt ?ActionId ?Command}
               {AddSlave self.TclSlaves ActionId _}
               {TkSend o(self.TkWidget self.TkQualify bind self Event
                         v(Command))}
            else
               {TkSend o(self.TkWidget self.TkQualify bind self Event '')}
            end
         end
      end

   in

      class TkTextMark from TkTagAndMark
         feat !TkQualify: mark
      end


      class TkCanvasTag from TkTag
         feat !TkQualify: unit
      end

      class TkTextTag from TkTag
         feat !TkQualify: tag

         meth tkInit(parent:Parent ...) = M
            ParentSlaves = {CondSelect Parent TclSlaves unit}
            ThisTclName  = {GenTagName}
         in
            if ParentSlaves==unit then
               {Exception.raiseError tk(wrongParent self M)}
            end
            if {IsDet self.TclName} then
               {Exception.raiseError tk(alreadyInitialized self M)}
            end
            self.TclSlaves     = [nil]
            self.TclSlaveEntry = {AddSlave ParentSlaves self}
            self.TkWidget      = Parent
            if {Width M}>1 then
               {TkSendFilter
                o(Parent tag configure) ThisTclName M [parent]
                unit}
            end
            self.TclName       = ThisTclName
         end
      end
   end

   %%
   %% Images
   %%

   local
      %% use essentially the same resolver as for pickles
      %% this used to be all=.:root=$OZHOME which was completely
      %% bogus and could not be parametrized using env vars.  I
      %% don't really see why we need a different resolver.
      ImRes = {Resolve.makeResolver image
               init({Resolve.pickle.getHandlers})}
      {ImRes.addHandler front({Resolve.handler.root '.'})}

      PathStore = {New class $
                          prop final locking
                          attr ps:nil
                          meth init
                             ps <- nil
                          end
                          meth add(P)
                             lock
                                ps <- P|@ps
                             end
                          end
                          meth get($)
                             lock
                                @ps
                             end
                          end
                       end init}


   in

      fun {TkLocalize Res Url}
         case {Res.localize Url}
         of old(F) then F
         [] new(F) then {PathStore add(F)} F
         end
      end

      fun {TkFixedLocalize Url}
         {TkLocalize ImRes Url}
      end

      class TkImage
         from ReturnClass
         feat
            !TclName

         meth tkInit(type:Type resolver:Resolver<=!ImRes ...) = Message
            ThisTclName = self.TclName
            if {IsDet ThisTclName} then
               {Exception.raiseError tk(alreadyInitialized self Message)}
            end
            NewTkName = {GenImageName}
            MessUrl   = if {HasFeature Message url} then
                           {AdjoinAt Message file
                            {TkLocalize Resolver Message.url}}
                        else Message
                        end
            MessAll   = if {HasFeature MessUrl maskurl} then
                           {AdjoinAt MessUrl maskfile
                            {TkLocalize Resolver MessUrl.maskurl}}
                        else MessUrl
                        end
         in
            {TkSendFilter v('image create '#Type) NewTkName
             MessAll [maskurl type url] unit}
            ThisTclName = NewTkName
         end
         meth tk(...) = M
            {TkSendTuple self M}
         end
         meth !TkReturnMethod(M Cast)
            {TkReturnMess image M self Cast}
         end
         meth tkClose
            skip
         end
      end
   end

   %%
   %% Fonts
   %%

   class TkFont
      from ReturnClass
      feat !TclName

      meth tkInit(...) = Message
         ThisTclName = self.TclName
         if {IsDet ThisTclName} then
            {Exception.raiseError tk(alreadyInitialized self Message)}
         end
         NewTkName   = {GenFontName}
      in
         {TkSendFilter v('font create') NewTkName Message nil unit}
         ThisTclName = NewTkName
      end
      meth tk(...) = M
         {TkSendTagTuple font self M}
      end
      meth !TkReturnMethod(M Cast)
         {TkReturnMess font M self Cast}
      end
      meth tkClose
         {TkSend o('font delete' self)}
      end
   end

   proc {AddYScrollbar T S}
      {TkBatch
       [o(T configure yscrollcommand: s(S set))
        o(S configure command:        s(T yview))]}
   end

   proc {AddXScrollbar T S}
      {TkBatch
       [o(T configure xscrollcommand: s(S set))
        o(S configure command:        s(T xview))]}
   end

   IsColor = thread
                {TkReturnInt winfo(depth '.')}>1
             end

   fun {DefineUserCmd TclCmd Action Args}
      Casts    = {GetCasts Args}
      ActionId = {ActionIdServer get($)}
   in
      {Dictionary.put TkDict ActionId case Action of O#M then O#M#Casts
                                      else Action#Casts
                                      end}
      {TkSend v('proc '#TclCmd#' args {\n' #
                '   eval ozp '#ActionId#' '#'$args\n' #
                '}')}
      proc {$}
         {TkSend v('rename '#TclCmd#' ""')}
         {Dictionary.remove TkDict ActionId}
      end
   end

   %%
   %% Define additional options
   %%

   \insert 'TkOptions.oz'


   fun {NewWidgetClass Mode Name}
      From = case Mode
             of widget    then Widget
             [] command   then CommandWidget
             [] noCommand then NoCommandWidget
             end
   in
      class $ from From
         feat !TkClass:Name
      end
   end

end
