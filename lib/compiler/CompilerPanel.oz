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

local
   IsBuiltin = {`Builtin` 'isBuiltin' 2}

   local
      proc {EscapeVariableChar Hd C|Cr Tl}
         case Cr of nil then Hd = C|Tl   % terminating quote
         elsecase C == &` orelse C == &\\ then Hd = &\\|C|Tl
         elsecase C < 10 then Hd = &\\|&x|&0|(&0 + C)|Tl
         elsecase C < 16 then Hd = &\\|&x|&0|(&A + C - 10)|Tl
         elsecase C < 26 then Hd = &\\|&x|&1|(&0 + C - 16)|Tl
         elsecase C < 32 then Hd = &\\|&x|&1|(&A + C - 26)|Tl
         else Hd = C|Tl
         end
      end
   in
      fun {PrintNameToVirtualString PrintName}
         case {Atom.toString PrintName} of &`|Sr then
            &`|{FoldLTail Sr EscapeVariableChar $ nil}
         else PrintName
         end
      end
   end

   local
      Resources =
      resources(compilerTextFont:
                   return#'Font'#'9x15'
                compilerTextForeground:
                   return#'Foreground'#black
                compilerTextBackground:
                   (return#'Background'#
                    case Tk.isColor then c(239 239 239) else white end)
                compilerVSEntryWidth:
                   returnInt#'Width'#40
                compilerVSEntryHeight:
                   returnInt#'Height'#5
                compilerMessagesWidth:
                   returnInt#'Width'#80
                compilerMessagesHeight:
                   returnInt#'Height'#17
                compilerMessagesWrap:
                   return#'Wrap'#none
                compilerTypeListHeight:
                   returnInt#'Height'#10
                compilerColorDisplayBorder:
                   returnInt#'BorderWidth'#2
                compilerURLEntryWidth:
                   returnInt#'Width'#60
                compilerSwitchGroupFont:
                   (return#'Font'#
                    '-*-helvetica-bold-r-normal--*-120-*-*-*-*-*-*')
                compilerSwitchFont:
                   (return#'Font'#
                    '-*-helvetica-medium-r-normal--*-120-*-*-*-*-*-*')
                compilerEnvCols:
                   returnInt#'EnvCols'#4
                compilerSourceWidth:
                   returnInt#'Width'#80
                compilerSourceHeight:
                   returnInt#'Height'#25
                compilerSourceWrap:
                   return#'Wrap'#none)

      class OptionsClass
         attr Window
         meth init()
            Window <- {New Tk.toplevel tkInit(withdraw: true)}
         end
         meth get(Name $)
            Return#Class#Default = Resources.Name
         in
            case {Tk.Return option(get @Window Name Class)} of nil then Default
            elseof false then Default
            elseof Value then Value
            end
         end
      end
   in
      Options = {New OptionsClass init()}
   end

   BitmapPath = '@'#{System.get home}#'/lib/bitmaps/'

   Black = c(0 0 0)
   Gray = c(127 127 127)
   Red = c(191 0 0)
   Orange = c(191 127 0)
   Magenta = c(191 0 127)
   Blue = c(0 0 191)
   Cyan = c(0 127 191)
   Green = c(0 191 0)

   Colors = ['Undetermined'#Gray
             'Int'#Red 'Float'#Red 'Atom'#Red 'Name'#Red
             'Record'#Magenta 'Tuple'#Magenta
             'Procedure'#Black 'Builtin'#Black
             'Cell'#Orange
             'Chunk'#Green
             'Class'#Blue
             'Object'#Cyan
             'Array'#Green 'Dictionary'#Green 'Port'#Green 'Lock'#Green
             'Thread'#Orange 'Space'#Orange]

   proc {SetColor TextWidget PrintName Value ColorDict}
      case {IsDet Value} then Type C in
         case {IsInt Value} then 'Int'
         elsecase {IsFloat Value} then 'Float'
         elsecase {IsAtom Value} then 'Atom'
         elsecase {IsName Value} then 'Name'
         elsecase {IsTuple Value} then 'Tuple'
         elsecase {IsRecord Value} then 'Record'
         elsecase {IsBuiltin Value} then 'Builtin'
         elsecase {IsProcedure Value} then 'Procedure'
         elsecase {IsCell Value} then 'Cell'
         elsecase {IsArray Value} then 'Array'
         elsecase {IsDictionary Value} then 'Dictionary'
         elsecase {IsClass Value} then 'Class'
         elsecase {IsObject Value} then 'Object'
         elsecase {IsPort Value} then 'Port'
         elsecase {IsLock Value} then 'Lock'
         elsecase {IsChunk Value} then 'Chunk'
         elsecase {IsThread Value} then 'Thread'
         elsecase {IsSpace Value} then 'Space'
         end = Type
         C = {Dictionary.get ColorDict Type}
         {TextWidget tk(tag configure q(PrintName) foreground: C)}
      else C in
         C = {Dictionary.get ColorDict 'Undetermined'}
         {TextWidget tk(tag configure q(PrintName) foreground: C)}
         thread
            {Wait Value}
            {SetColor TextWidget PrintName Value ColorDict}
         end
      end
   end

   InstallNewColors    = {NewName}
   DoLoadVariable      = {NewName}
   DoFeedVirtualString = {NewName}

   class VSEntryDialog from TkTools.dialog
      prop final
      meth init(Master Port VS)
         proc {DoFeed} VS in
            {Entry tkReturn(get p(1 0) 'end' ?VS)}
            TkTools.dialog, tkClose()
            {Wait VS}
            {Send Port DoFeedVirtualString(VS)}
         end
         proc {DoClear}
            {Entry tk(delete p(1 0) 'end')}
         end
         proc {DoClose}
            {self tkClose()}
         end
         TkTools.dialog, tkInit(master: Master
                                root: pointer
                                title: 'Oz Compiler: Feed Virtual String'
                                buttons: ['Ok'#DoFeed
                                          'Clear'#DoClear
                                          'Cancel'#DoClose]
                                pack: false)
         Frame = {New Tk.frame tkInit(parent: self
                                      highlightthickness: 0)}
         Title = {New Tk.label tkInit(parent: Frame
                                      text: 'Feed virtual string:')}
         TextFont = {Options get(compilerTextFont $)}
         TextForeground = {Options get(compilerTextForeground $)}
         TextBackground = {Options get(compilerTextBackground $)}
         Width = {Options get(compilerVSEntryWidth $)}
         Height = {Options get(compilerVSEntryHeight $)}
         Entry = {New Tk.text tkInit(parent: Frame
                                     font: TextFont
                                     foreground: TextForeground
                                     background: TextBackground
                                     width: Width
                                     height: Height)}
         {Entry tk(insert p(1 0) VS)}
         {Entry tkBind(event: '<Meta-Return>' action: DoFeed)}
         {Entry tkBind(event: '<Escape>' action: DoClose)}
         {Entry tkBind(event: '<Control-x>' action: DoClose)}
         {Entry tkBind(event: '<Control-r>' action: DoClear)}
      in
         {Tk.batch [pack(Title Entry anchor: w)
                    pack(Frame pady: 4)
                    focus(Entry)]}
         TkTools.dialog, tkPack()
      end
   end

   class ColorConfigurationDialog from TkTools.dialog
      prop final
      feat
         ColorDict TypeList ColorDisplay
         RedVariable GreenVariable BlueVariable
      meth init(Master Port Colors IsEnabled)
         proc {DoApply} NewColors in
            NewColors#_ = {FoldL Colors
                           fun {$ NewColors#I T#_} C in
                              C = {Dictionary.get self.ColorDict I}
                              (T#C|NewColors)#(I + 1)
                           end nil#0}
            {Send Port InstallNewColors(NewColors
                                        {EnableVariable tkReturnInt($)} == 1)}
         end
         proc {DoOk}
            TkTools.dialog, tkClose()
            {DoApply}
         end
         TkTools.dialog, tkInit(master: Master
                                root: pointer
                                title: 'Oz Compiler: Environment Colors'
                                buttons: ['Ok'#DoOk
                                          'Apply'#DoApply
                                          'Close'#tkClose()]
                                default: 1
                                focus: 1
                                pack: false)
         TypeFrame = {New TkTools.textframe tkInit(parent: self
                                                   text: 'Type')}
         ListFrame = {New Tk.frame tkInit(parent: TypeFrame.inner
                                          highlightthickness: 0)}
         TextForeground = {Options get(compilerTextForeground $)}
         TextBackground = {Options get(compilerTextBackground $)}
         TypeListHeight = {Options get(compilerTypeListHeight $)}
         self.TypeList = {New Tk.listbox tkInit(parent: ListFrame
                                                selectmode: single
                                                foreground: TextForeground
                                                background: TextBackground
                                                height: TypeListHeight)}
         Scrollbar = {New Tk.scrollbar tkInit(parent: ListFrame)}
         {Tk.addYScrollbar self.TypeList Scrollbar}
         ColorFrame = {New TkTools.textframe tkInit(parent: self
                                                    text: 'Color')}
         RedLabel = {New Tk.label tkInit(parent: ColorFrame.inner
                                         text: 'Red'
                                         foreground: Red)}
         self.RedVariable = {New Tk.variable tkInit(0)}
         RedScale = {New Tk.scale tkInit(parent: ColorFrame.inner
                                         orient: horizontal
                                         to: 255
                                         variable: self.RedVariable
                                         action: self#setColor(1)
                                         args: [int])}
         GreenLabel = {New Tk.label tkInit(parent: ColorFrame.inner
                                           text: 'Green'
                                           foreground: Green)}
         self.GreenVariable = {New Tk.variable tkInit(0)}
         GreenScale = {New Tk.scale tkInit(parent: ColorFrame.inner
                                           orient: horizontal
                                           to: 255
                                           variable: self.GreenVariable
                                           action: self#setColor(2)
                                           args: [int])}
         BlueLabel = {New Tk.label tkInit(parent: ColorFrame.inner
                                          text: 'Blue'
                                          foreground: Blue)}
         self.BlueVariable = {New Tk.variable tkInit(0)}
         BlueScale = {New Tk.scale tkInit(parent: ColorFrame.inner
                                          orient: horizontal
                                          to: 255
                                          variable: self.BlueVariable
                                          action: self#setColor(3)
                                          args: [int])}
         ColorDisplayBorder = {Options get(compilerColorDisplayBorder $)}
         ColorDisplayFrame = {New Tk.frame tkInit(parent: ColorFrame.inner
                                                  relief: ridge
                                                  borderwidth:
                                                     ColorDisplayBorder)}
         self.ColorDisplay = {New Tk.frame tkInit(parent: ColorDisplayFrame
                                                  background: Black
                                                  highlightthickness: 0)}
         EnableVariable = {New Tk.variable tkInit(IsEnabled)}
         EnableButton = {New Tk.checkbutton tkInit(parent: self
                                                   text: 'Enable Coloring'
                                                   variable: EnableVariable)}
      in
         {Tk.batch [pack(self.TypeList Scrollbar
                         side: left fill: both expand: true)
                    pack(ListFrame fill: both expand: true padx: 4 pady: 4)
                    grid(rowconfigure ColorFrame.inner 4 weight: 1)
                    grid(columnconfigure ColorFrame.inner 2 weight: 1)
                    grid(RedLabel row: 1 column: 1 sticky: sw)
                    grid(RedScale row: 1 column: 2 sticky: sew)
                    grid(GreenLabel row: 2 column: 1 sticky: sw)
                    grid(GreenScale row: 2 column: 2 sticky: sew)
                    grid(BlueLabel row: 3 column: 1 sticky: sw)
                    grid(BlueScale row: 3 column: 2 sticky: sew)
                    pack(self.ColorDisplay fill: both expand: true)
                    grid(ColorDisplayFrame row: 4 column: 1 columnspan: 2
                         sticky: nesw padx: 8 pady: 8)
                    grid(rowconfigure self 1 weight: 1)
                    grid(columnconfigure self 2 weight: 1)
                    grid(TypeFrame row: 1 column: 1 sticky: nsew
                         padx: 4 pady: 4)
                    grid(ColorFrame row: 1 column: 2 sticky: nsew
                         padx: 4 pady: 4)
                    grid(EnableButton row: 2 column: 1 columnspan: 2
                         sticky: w)]}
         self.ColorDict = {NewDictionary}
         {FoldL Colors
          fun {$ I T#C}
             {self.TypeList tk(insert 'end' T)}
             {Dictionary.put self.ColorDict I C}
             I + 1
          end 0 _}
         {self.TypeList
          tkBind(event: '<1>'
                 action: proc {$} Is T C in
                            {self.TypeList tkReturnListInt(curselection ?Is)}
                            T = Is.1
                            C = {Dictionary.get self.ColorDict T}
                            {self.ColorDisplay tk(configure(background: C))}
                            {self.RedVariable tkSet(C.1)}
                            {self.GreenVariable tkSet(C.2)}
                            {self.BlueVariable tkSet(C.3)}
                         end)}
         TkTools.dialog, tkPack()
      end
      meth setColor(F V) Is in
         {self.TypeList tkReturnListInt(curselection ?Is)}
         case Is of nil then R G B NewC in
            {self.RedVariable tkReturnInt(?R)}
            {self.GreenVariable tkReturnInt(?G)}
            {self.BlueVariable tkReturnInt(?B)}
            NewC = {AdjoinAt c(R G B) F V}
            {self.ColorDisplay tk(configure(background: NewC))}
         else T NewC in
            T = Is.1
            NewC = {AdjoinAt {Dictionary.get self.ColorDict T} F V}
            {Dictionary.put self.ColorDict T NewC}
            {self.ColorDisplay tk(configure(background: NewC))}
         end
      end
   end

   class URLEntryDialog from TkTools.dialog
      prop final
      meth init(Master Port PrintName URL)
         proc {DoLoad} URL in
            {Entry tkReturnString(get ?URL)}
            TkTools.dialog, tkClose()
            {Send Port DoLoadVariable(PrintName URL)}
         end
         proc {DoClear}
            {Entry tk(delete '0' 'end')}
         end
         TkTools.dialog, tkInit(master: Master
                                root: pointer
                                title: 'Oz Compiler: Load variable from URL'
                                buttons: ['Ok'#DoLoad
                                          'Clear'#DoClear
                                          'Cancel'#tkClose()]
                                default: 1
                                pack: false)
         Frame = {New Tk.frame tkInit(parent: self
                                      highlightthickness: 0)}
         Title = {New Tk.label tkInit(parent: Frame
                                      text: 'URL to load into variable '#
                                            PrintName#':')}
         TextFont = {Options get(compilerTextFont $)}
         TextForeground = {Options get(compilerTextForeground $)}
         TextBackground = {Options get(compilerTextBackground $)}
         URLEntryWidth = {Options get(compilerURLEntryWidth $)}
         Entry = {New Tk.entry tkInit(parent: Frame
                                      font: TextFont
                                      foreground: TextForeground
                                      background: TextBackground
                                      width: URLEntryWidth)}
         {Entry tk(insert '0' URL)}
      in
         {Tk.batch [pack(Title Entry anchor: w)
                    pack(Frame pady: 4)
                    focus(Entry)]}
         TkTools.dialog, tkPack()
      end
   end

   class SourceWindow from Tk.toplevel
      prop final
      feat Source TheVS
      meth init(Parent Title VS)
         Menu SourceFrame TextFont TextForeground TextBackground
         SourceWidth SourceHeight SourceWrap Scrollbar
      in
         Tk.toplevel, tkInit(parent: Parent
                             title: Title
                             'class': 'OzTools'
                             highlightthickness: 0
                             withdraw: true)
         {Tk.send wm(iconname self Title)}
         Menu = {TkTools.menubar self self
                 [menubutton(text: 'File'
                             feature: file
                             menu: [command(label: 'Save as ...'
                                            action: self#SaveAs())
                                    separator
                                    command(label: 'Close window'
                                            key: ctrl(x)
                                            action: self#tkClose())])
                  menubutton(text: 'Edit'
                             feature: edit
                             menu: [command(label: 'Select all'
                                            action: self#SelectAll())])]
                 nil}
         SourceFrame = {New Tk.frame tkInit(parent: self
                                            highlightthickness: 0)}
         TextFont = {Options get(compilerTextFont $)}
         TextForeground = {Options get(compilerTextForeground $)}
         TextBackground = {Options get(compilerTextBackground $)}
         SourceWidth = {Options get(compilerSourceWidth $)}
         SourceHeight = {Options get(compilerSourceHeight $)}
         SourceWrap = {Options get(compilerSourceWrap $)}
         self.Source = {New Tk.text tkInit(parent: SourceFrame
                                           font: TextFont
                                           foreground: TextForeground
                                           background: TextBackground
                                           width: SourceWidth
                                           height: SourceHeight
                                           wrap: SourceWrap)}
         {self.Source tk(insert p(1 0) VS)}
         {self.Source tk(configure state: disabled)}
         Scrollbar = {New Tk.scrollbar tkInit(parent: SourceFrame)}
         {Tk.addYScrollbar self.Source Scrollbar}
         self.TheVS = VS
         {Tk.batch [pack(Menu fill: x)
                    pack(Scrollbar side: right fill: y)
                    pack(self.Source side: right fill: both expand: true)
                    pack(SourceFrame padx: 4 pady: 4 fill: both expand: true)
                    update(idletasks)
                    wm(deiconify self)]}
      end
      meth SelectAll()
         {self.Source tk(tag add 'sel' p(1 0) 'end')}
      end
      meth SaveAs() FileName in
         FileName =
         {Tk.return tk_getSaveFile(parent: self
                                   title: 'Oz Compiler: Save Source Text'
                                   filetypes: q(q('All Files' '*')))}
         case FileName == "" then skip
         else File in
            File = {New Open.file init(name: FileName
                                       flags: [write create truncate])}
            {File write(vs: self.TheVS)}
            {File close()}
         end
      end
   end

   local
      Escapes = escapes(&a: &\a &b: &\b f: &\f n: &\n r: &\r t: &\t v: &\v
                        &\\: &\\ &': &' &": &" &`: &`)
      Hex = hex(&0: 0x0 &1: 0x1 &2: 0x2 &3: 0x3 &4: 0x4
                &5: 0x5 &6: 0x6 &7: 0x7 &8: 0x8 &9: 0x9
                &a: 0xA &b: 0xB &c: 0xC &d: 0xD &e: 0xE &f: 0xF
                &A: 0xA &B: 0xB &C: 0xC &D: 0xD &E: 0xE &F: 0xF)
      Oct = oct(&0: 0 &1: 1 &2: 2 &3: 3 &4: 4 &5: 5 &6: 6 &7: 7)

      fun {QuotedToPrintName Ss}
         case Ss of S1|Sr then
            case S1 of &` then
               case Sr of nil then "`"
               else raise notAPrintName end
               end
            [] &\\ then
               case Sr of S1|Sr then
                  case {HasFeature Oct S1} then
                     case Sr of S2|S3|Sr then
                        case {HasFeature Oct S2} andthen {HasFeature Oct S3}
                        then C in
                           C = Oct.S1 * 0100 + Oct.S2 * 010 + Oct.S3
                           case {IsChar C} then C|{QuotedToPrintName Sr}
                           else raise notAPrintName end
                           end
                        else raise notAPrintName end
                        end
                     else raise notAPrintName end
                     end
                  elsecase S1 == &x orelse S1 == &X then
                     case Sr of S2|S3|Sr then
                        case {HasFeature Hex S2} andthen {HasFeature Hex S3}
                        then (Hex.S2 * 0x10 + Hex.S3)|{QuotedToPrintName Sr}
                        else raise notAPrintName end
                        end
                     else raise notAPrintName end
                     end
                  elsecase {HasFeature Escapes S1} then
                     Escapes.S1|{QuotedToPrintName Sr}
                  else raise notAPrintName end
                  end
               else raise notAPrintName end
               end
            [] 0 then raise notAPrintName end
            else S1|{QuotedToPrintName Sr}
            end
         else raise notAPrintName end
         end
      end
   in
      fun {StringToPrintName S}
         case S of S1|Sr then
            case S1 of &` then {String.toAtom &`|{QuotedToPrintName Sr}}
            elsecase {Char.isUpper S1}
               andthen {All Sr fun {$ C} {Char.isAlNum C} orelse C == &_ end}
            then {String.toAtom S}
            else raise notAPrintName end
            end
         else raise notAPrintName end
         end
      end
   end

   fun {MakeSpaces N}
      case N =< 0 then ""
      else & |{MakeSpaces N - 1}
      end
   end

   fun {FormatQuery Id M} S in
      S = {Int.toString Id}
      {MakeSpaces 5 - {Length S}}#S#' '#
      case M of macroDefine(X) then
         'define macro '#{PrintNameToVirtualString X}
      [] macroUndef(X) then
         'undefine macro '#{PrintNameToVirtualString X}
      [] getDefines(?Xs) then
         'get defines'
      [] getSwitch(SwitchName ?B) then
         'get switch '#{System.valueToVirtualString SwitchName 0 0}
      [] setSwitch(SwitchName B) then
         'set switch '#{System.valueToVirtualString SwitchName 0 0}#
         ' to '#{System.valueToVirtualString B 0 0}
      [] pushSwitches() then
         'push switches'
      [] popSwitches() then
         'pop switches'
      [] getMaxNumberOfErrors(?N) then
         'get maximal number of errors'
      [] setMaxNumberOfErrors(N) then
         'set maximal number of errors to '#{System.valueToVirtualString N 0 0}
      [] addToEnv(PrintName Value) then
         'add variable '#{PrintNameToVirtualString PrintName}#
         ' to environment'
      [] lookupInEnv(PrintName ?Value) then
         'look up variable '#{PrintNameToVirtualString PrintName}#
         ' in environment'
      [] removeFromEnv(PrintName) then
         'remove variable '#{PrintNameToVirtualString PrintName}#
         ' from environment'
      [] putEnv(Env) then
         'set new environment'
      [] mergeEnv(Env) then
         'add bindings to environment'
      [] getEnv(?Env) then
         'get environment'
      [] feedVirtualString(VS) then
         'feed virtual string'
      [] feedVirtualString(VS ?RequiredInterfaces) then
         'feed virtual string'
      [] feedFile(VS) then
         'feed file "'#VS#'"'
      [] feedFile(VS ?RequiredInterfaces) then
         'feed file "'#VS#'"'
      [] ping(?HereIAm) then
         'ping'
      else
         'unknown query ('#{System.valueToVirtualString {Label M} 0 0}#')'
      end
   end

   fun {RemoveQuery Hd Id I ?Pos}
      case {IsDet Hd} then
         case Hd.1 == Id then
            Pos = I
            Hd.2
         else
            Hd.1|{RemoveQuery Hd.2 Id I + 1 ?Pos}
         end
      else
         Pos = ~1
         Hd
      end
   end
in
   class CompilerPanel from Compiler.genericInterface
      prop locking final
      attr
         ErrorTagCounter: 0
         ColoringIsEnabled
         LastFeededVS LastURL EnvSelection ActionCount ValueDict TagDict
         QueryIdsHd QueryIdsTl
      feat
         isClosed
         TopLevel ToGray InterruptMenuItem InterruptButton
         %--** SuspendButton
         DequeueQueryButton ClearQueueButton
         SystemVariables ColorDict
         Actions ActionVariable ActionDict NColsInEnv
         Book Messages Text ScrollToBottom
         EnvDisplay EditedVariable
         SwitchRec HasMaxErrorsEnabled MaxNumberOfErrors
         CurrentQuery QueryList

      %%
      %% Method-provided User Functionality
      %%

      meth init(CompilerObject)
         Compiler.genericInterface, init(CompilerObject Serve)
         CompilerPanel, DoInit()
      end
      meth exit()
         thread   % so that we don't kill ourselves ;-)
            lock
               self.isClosed = unit
               Compiler.genericInterface, exit()
               {self.TopLevel tkClose()}
            end
         end
      end
      meth Serve(Ms)
         case {IsDet self.isClosed} then skip
         elsecase Ms of M|Mr then
            lock
               case M of newQuery(Id M) then X in
                  {self.QueryList tk(insert 'end' {FormatQuery Id M})}
                  @QueryIdsTl = Id|X
                  QueryIdsTl <- X
                  {self.ClearQueueButton tk(configure state: normal)}
               [] runQuery(Id M) then Pos in
                  QueryIdsHd <- {RemoveQuery @QueryIdsHd Id 0 ?Pos}
                  case {IsFree @QueryIdsHd} then
                     {self.ClearQueueButton tk(configure state: disabled)}
                  else skip
                  end
                  {self.QueryList tk(delete Pos)}
                  case {self.QueryList tkReturnListInt(curselection $)}
                  of nil then
                     {self.DequeueQueryButton tk(configure state: disabled)}
                  else skip
                  end
                  {self.CurrentQuery tk(configure state: normal)}
                  {self.CurrentQuery tk(insert '0' {FormatQuery Id M})}
                  {self.CurrentQuery tk(configure state: disabled)}
               [] removeQuery(Id) then Pos in
                  QueryIdsHd <- {RemoveQuery @QueryIdsHd Id 0 ?Pos}
                  case Pos == ~1 then
                     {self.CurrentQuery tk(configure state: normal)}
                     {self.CurrentQuery tk(delete '0' 'end')}
                     {self.CurrentQuery tk(configure state: disabled)}
                  else
                     {self.QueryList tk(delete Pos)}
                     case {self.QueryList tkReturnListInt(curselection $)}
                     of nil then
                        {self.DequeueQueryButton tk(configure state: disabled)}
                     else skip
                     end
                     case {IsFree @QueryIdsHd} then
                        {self.ClearQueueButton tk(configure state: disabled)}
                     else skip
                     end
                  end
               [] busy() then
                  CompilerPanel, SetWidgetsState(self.ToGray disabled)
                  {self.InterruptButton tk(configure state: normal)}
                  %--** {self.SuspendButton tk(configure state: normal)}
                  {self.InterruptMenuItem tk(entryconfigure state: normal)}
               [] idle() then
                  CompilerPanel, SetWidgetsState(self.ToGray normal)
                  {self.InterruptButton tk(configure state: disabled)}
                  %--** {self.SuspendButton tk(configure state: disabled)}
                  {self.InterruptMenuItem tk(entryconfigure state: disabled)}
               [] switch(SwitchName B) then
                  {self.SwitchRec.SwitchName tkSet(B)}
               [] switches(Rec) then
                  {Record.forAllInd self.SwitchRec
                   proc {$ SwitchName Variable}
                      {Variable tkSet(Rec.SwitchName)}
                   end}
               [] maxNumberOfErrors(N) then
                  case N =< 0 then
                     {self.HasMaxErrorsEnabled tkSet(false)}
                  else
                     {self.HasMaxErrorsEnabled tkSet(true)}
                     {self.MaxNumberOfErrors tkSet(N)}
                  end
               [] env(Env) then
                  ValueDict <- Env
                  CompilerPanel, RedisplayEnv()
               [] info(VS) then
                  CompilerPanel, ShowInfo(VS)
               [] info(VS Coord) then
                  CompilerPanel, ShowInfo(VS Coord)
               [] displaySource(Title _ VS) then
                  {New SourceWindow init(self.TopLevel Title VS) _}
               [] toTop() then
                  {self.Book toTop(self.Messages)}
               [] pong() then skip
               else {self M}
               end
            end
            CompilerPanel, Serve(Mr)
         end
      end
      meth SetWidgetsState(Widgets State)
         case Widgets of Widget|Rest then
            {Widget tk(configure state: State)}
            CompilerPanel, SetWidgetsState(Rest State)
         [] nil then skip
         end
      end
      meth ShowInfo(VS Coord <= unit)
         {self.Text tk(configure state: normal)}
         case Coord == unit then
            {self.Text tk(insert 'end' VS)}
         else File Line Column in
            case Coord of pos(F L C) then File = F Line = L Column = C
            [] pos(F L C _ _ _) then File = F Line = L Column = C
            [] posNoDebug(F L C) then File = F Line = L Column = C
            end
            case File of 'nofile' then
               {self.Text tk(insert 'end' VS)}
            else Tag Action in
               Tag = @ErrorTagCounter
               ErrorTagCounter <- Tag + 1
               {self.Text tk(insert 'end' VS Tag)}
               Action = {New Tk.action
                         tkInit(parent: self.Text
                                action: (Compiler.genericInterface, getPort($)#
                                         Goto(File Line Column)))}
               {self.Text tk(tag bind Tag '<1>' Action)}
            end
         end
         {self.Text tk(configure state: disabled)}
         case {self.ScrollToBottom tkReturnInt($)} == 1 then
            {self.Text tk(see 'end')}
         else skip
         end
      end

      meth addAction(ActionName Proc)
         lock
            case {IsDet self.isClosed} then skip
            else
               ActionCount <- @ActionCount + 1
               {New Tk.menuentry.radiobutton
                tkInit(parent: self.Actions
                       label: ActionName
                       variable: self.ActionVariable
                       value: @ActionCount) _}
               {Dictionary.put self.ActionDict @ActionCount Proc}
               {self.ActionVariable tkSet(@ActionCount)}
            end
         end
      end

      %%
      %% GUI-Provided User Functionality
      %%

      meth DoInit()
         fun {MkAction M}
            Compiler.genericInterface, getPort($)#M
         end

         self.TopLevel = {New Tk.toplevel
                          tkInit(title: 'Oz Compiler'
                                 'class': 'OzTools'
                                 delete: {MkAction exit()}
                                 highlightthickness: 0
                                 withdraw: true)}
         TextFont        = {Options get(compilerTextFont $)}
         TextForeground  = {Options get(compilerTextForeground $)}
         TextBackground  = {Options get(compilerTextBackground $)}
         MessagesWidth   = {Options get(compilerMessagesWidth $)}
         MessagesHeight  = {Options get(compilerMessagesHeight $)}
         MessagesWrap    = {Options get(compilerMessagesWrap $)}
         SwitchGroupFont = {Options get(compilerSwitchGroupFont $)}
         SwitchFont      = {Options get(compilerSwitchFont $)}
         NCols           = {Options get(compilerEnvCols $)}

         {Tk.batch [wm(iconname self.TopLevel 'Oz Compiler')
                    wm(iconbitmap self.TopLevel BitmapPath#'compiler.xbm')
                    wm(iconmask self.TopLevel BitmapPath#'compilermask.xbm')
                    wm(resizable self.TopLevel 0 0)]}
         self.SystemVariables = {New Tk.variable tkInit(false)}
         self.NColsInEnv = {New Tk.variable tkInit(NCols)}
         ColumnMenu = {ForThread 7 1 ~1
                       fun {$ In I}
                          radiobutton(label: I
                                      variable: self.NColsInEnv
                                      value: I
                                      action: {MkAction RedisplayEnv()})|In
                       end nil}
         Menu = {TkTools.menubar self.TopLevel self.TopLevel
                 [menubutton(text: 'Compiler'
                             feature: compiler
                             menu: [command(label: 'Feed file ...'
                                            action: {MkAction FeedFile()})
                                    command(label: 'Feed virtual string ...'
                                            action: {MkAction
                                                     FeedVirtualString()})
                                    separator
                                    command(label: 'Clear message window'
                                            key: ctrl(u)
                                            action: {MkAction ClearInfo()})
                                    command(label: 'Interrupt'
                                            feature: interrupt
                                            key: ctrl(c)
                                            state: disabled
                                            action: {MkAction Interrupt()})
                                    command(label: 'Reset'
                                            key: ctrl(r)
                                            action: {MkAction Reset()})
                                    separator
                                    command(label: 'Close window'
                                            key: ctrl(x)
                                            action: {MkAction exit()})])
                  menubutton(text: 'Options'
                             feature: options
                             menu: [checkbutton(label: 'Show system variables'
                                                variable: self.SystemVariables
                                                action: {MkAction
                                                         RedisplayEnv()})
                                    command(label: 'Configure colors ...'
                                            feature: colors
                                            action: {MkAction
                                                     ConfigureColors()})
                                    cascade(label: 'Number of columns'
                                            feature: columns
                                            menu: ColumnMenu)
                                    cascade(label: 'Set action'
                                            feature: action
                                            menu: nil)])]
                 [menubutton(text: 'Help'
                             feature: help
                             menu: [command(label: 'About ...'
                                            action: {MkAction
                                                     AboutDialog()})])]}
         case Tk.isColor then skip
         else {Menu.options.colors tk(entryconfigure state: disabled)}
         end

         self.Book = {New TkTools.notebook tkInit(parent: self.TopLevel)}
         self.Messages = {New TkTools.note tkInit(parent: self.Book
                                                  text: 'Messages')}
         {self.Book add(self.Messages)}
         self.Text = {New Tk.text tkInit(parent: self.Messages
                                         font: TextFont
                                         foreground: TextForeground
                                         background: TextBackground
                                         width: MessagesWidth
                                         height: MessagesHeight
                                         wrap: MessagesWrap
                                         state: disabled)}
         TextYScrollbar = {New Tk.scrollbar tkInit(parent: self.Messages)}
         {Tk.addYScrollbar self.Text TextYScrollbar}
         MessageOptionsFrame = {New Tk.frame tkInit(parent: self.Messages
                                                    highlightthickness: 0)}
         self.ScrollToBottom = {New Tk.variable tkInit(true)}
         ScrollToBottomButton = {New Tk.checkbutton
                                 tkInit(parent: MessageOptionsFrame
                                        text: 'Scroll to bottom on output'
                                        variable: self.ScrollToBottom)}
         Clear = {New Tk.button tkInit(parent: MessageOptionsFrame
                                       text: 'Clear'
                                       action: {MkAction ClearInfo()})}

         Environment = {New TkTools.note tkInit(parent: self.Book
                                                text: 'Environment')}
         {self.Book add(Environment)}
         self.EnvDisplay = {New Tk.text tkInit(parent: Environment
                                               font: TextFont
                                               foreground: TextForeground
                                               background: TextBackground
                                               width: MessagesWidth
                                               height: MessagesHeight
                                               state: disabled
                                               cursor: left_ptr)}
         EnvYScrollbar = {New Tk.scrollbar tkInit(parent: Environment)}
         {Tk.addYScrollbar self.EnvDisplay EnvYScrollbar}
         EnvOptionsFrame = {New Tk.frame tkInit(parent: Environment
                                                highlightthickness: 0)}
         self.EditedVariable = {New Tk.entry tkInit(parent: EnvOptionsFrame
                                                    font: TextFont
                                                    foreground:
                                                       TextForeground
                                                    background:
                                                       TextBackground)}
         Remove = {New Tk.button tkInit(parent: EnvOptionsFrame
                                        text: 'Remove'
                                        action: {MkAction RemoveVariable()})}
         Load = {New Tk.button tkInit(parent: EnvOptionsFrame
                                      text: 'Load ...'
                                      action: {MkAction LoadVariable()})}
         Save = {New Tk.button tkInit(parent: EnvOptionsFrame
                                      text: 'Save ...'
                                      action: {MkAction SaveVariable()})}

         Switches = {New TkTools.note tkInit(parent: self.Book
                                             text: 'Switches')}
         {self.Book add(Switches)}
         Column1 = {New Tk.frame tkInit(parent: Switches
                                        highlightthickness: 0)}
         Column2 = {New Tk.frame tkInit(parent: Switches
                                        highlightthickness: 0)}
         Column3 = {New Tk.frame tkInit(parent: Switches
                                        highlightthickness: 0)}

         GlobalFrame = {New Tk.frame tkInit(parent: Column1
                                            highlightthickness: 0)}
         GlobalLabel = {New Tk.label tkInit(parent: GlobalFrame
                                            text: 'Global Configuration'
                                            font: SwitchGroupFont)}
         CompilerPasses = {New Tk.variable tkInit(false)}
         CompilerPassesSw = {New Tk.checkbutton
                             tkInit(parent: GlobalFrame
                                    text: 'Show compiler passes'
                                    font: SwitchFont
                                    variable: CompilerPasses
                                    action: {MkAction Switch(compilerpasses)})}
         ShowInsert = {New Tk.variable tkInit(false)}
         ShowInsertSw = {New Tk.checkbutton
                         tkInit(parent: GlobalFrame
                                text: 'Show insertions'
                                font: SwitchFont
                                variable: ShowInsert
                                action: {MkAction Switch(showinsert)})}
         EchoQueries = {New Tk.variable tkInit(false)}
         EchoQueriesSw = {New Tk.checkbutton
                          tkInit(parent: GlobalFrame
                                 text: 'Echo queries'
                                 font: SwitchFont
                                 variable: EchoQueries
                                 action: {MkAction Switch(echoqueries)})}
         ErrorsFrame = {New Tk.frame tkInit(parent: GlobalFrame
                                            highlightthickness: 0)}
         self.HasMaxErrorsEnabled = {New Tk.variable tkInit(true)}
         DoMaxErrors = {New Tk.checkbutton
                        tkInit(parent: ErrorsFrame
                               text: 'Stop after '
                               font: SwitchFont
                               variable: self.HasMaxErrorsEnabled
                               action: {MkAction SetMaxErrorsCheck()})}
         self.MaxNumberOfErrors = {New TkTools.numberentry
                                   tkInit(parent: ErrorsFrame
                                          min: 1
                                          max: 100
                                          val: 17
                                          font: SwitchFont
                                          width: 3
                                          action:
                                             {MkAction SetMaxErrorsCount()})}
         ErrorsLabel = {New Tk.label tkInit(parent: ErrorsFrame
                                            text: ' errors'
                                            font: SwitchFont)}

         WarningsFrame = {New Tk.frame tkInit(parent: Column1
                                              highlightthickness: 0)}
         WarningsLabel = {New Tk.label tkInit(parent: WarningsFrame
                                              text: 'Warnings'
                                              font: SwitchGroupFont)}
         WarnRedecl = {New Tk.variable tkInit(false)}
         WarnRedeclSw = {New Tk.checkbutton
                         tkInit(parent: WarningsFrame
                                text: 'Warn about top-level redeclarations'
                                font: SwitchFont
                                variable: WarnRedecl
                                action: {MkAction Switch(warnredecl)})}
         WarnUnused = {New Tk.variable tkInit(false)}
         WarnUnusedSw = {New Tk.checkbutton
                         tkInit(parent: WarningsFrame
                                text: 'Warn about unused variables'
                                font: SwitchFont
                                variable: WarnUnused
                                action: {MkAction Switch(warnunused)})}
         WarnForward = {New Tk.variable tkInit(false)}
         WarnForwardSw = {New Tk.checkbutton
                          tkInit(parent: WarningsFrame
                                 text: 'Warn about oo forward declarations'
                                 font: SwitchFont
                                 variable: WarnForward
                                 action: {MkAction Switch(warnforward)})}

         ParsingFrame = {New Tk.frame tkInit(parent: Column2
                                             highlightthickness: 0)}
         ParsingLabel = {New Tk.label tkInit(parent: ParsingFrame
                                             text: 'I. Parsing and Expanding'
                                             font: SwitchGroupFont)}
         Expression = {New Tk.variable tkInit(true)}
         ExpressionSw = {New Tk.checkbutton
                         tkInit(parent: ParsingFrame
                                text: 'Expect expressions, not statements'
                                font: SwitchFont
                                variable: Expression
                                action: {MkAction Switch(expression)})}
         System = {New Tk.variable tkInit(true)}
         SystemSw = {New Tk.checkbutton
                     tkInit(parent: ParsingFrame
                            text: 'Allow use of system variables'
                            font: SwitchFont
                            variable: System
                            action: {MkAction Switch(system)})}
         CatchAll = {New Tk.variable tkInit(false)}
         CatchAllSw = {New Tk.checkbutton
                       tkInit(parent: ParsingFrame
                              text: 'Allow wildcard in catch patterns'
                              font: SwitchFont
                              variable: CatchAll
                              action: {MkAction Switch(catchall)})}

         SAFrame = {New Tk.frame tkInit(parent: Column2
                                        highlightthickness: 0)}
         SALabel = {New Tk.label tkInit(parent: SAFrame
                                        text: 'II. Static Analysis'
                                        font: SwitchGroupFont)}
         StaticAnalysis = {New Tk.variable tkInit(true)}
         StaticAnalysisSw = {New Tk.checkbutton
                             tkInit(parent: SAFrame
                                    text: 'Run static analysis'
                                    font: SwitchFont
                                    variable: StaticAnalysis
                                    action: {MkAction Switch(staticanalysis)})}

         CoreFrame = {New Tk.frame tkInit(parent: Column2
                                          highlightthickness: 0)}
         CoreLabel = {New Tk.label tkInit(parent: CoreFrame
                                          text: 'III. Core Output'
                                          font: SwitchGroupFont)}
         Core = {New Tk.variable tkInit(false)}
         CoreSw = {New Tk.checkbutton
                   tkInit(parent: CoreFrame
                          text: 'Output core syntax'
                          font: SwitchFont
                          variable: Core
                          action: {MkAction Switch(core)})}
         RealCore = {New Tk.variable tkInit(false)}
         RealCoreSw = {New Tk.checkbutton
                       tkInit(parent: CoreFrame
                              text: 'Real core'
                              font: SwitchFont
                              variable: RealCore
                              action: {MkAction Switch(realcore)})}
         DebugValue = {New Tk.variable tkInit(false)}
         DebugValueSw = {New Tk.checkbutton
                         tkInit(parent: CoreFrame
                                text: 'Include annotations about values'
                                font: SwitchFont
                                variable: DebugValue
                                action: {MkAction Switch(debugvalue)})}
         DebugType = {New Tk.variable tkInit(false)}
         DebugTypeSw = {New Tk.checkbutton
                        tkInit(parent: CoreFrame
                               text: 'Include annotations about types'
                               font: SwitchFont
                               variable: DebugType
                               action: {MkAction Switch(debugtype)})}

         CodeGenFrame = {New Tk.frame tkInit(parent: Column3
                                             highlightthickness: 0)}
         CodeGenLabel = {New Tk.label tkInit(parent: CodeGenFrame
                                             text: 'IV. Code Generation'
                                             font: SwitchGroupFont)}
         CodeGen = {New Tk.variable tkInit(true)}
         CodeGenSw = {New Tk.checkbutton
                      tkInit(parent: CodeGenFrame
                             text: 'Run code generator'
                             font: SwitchFont
                             variable: CodeGen
                             action: {MkAction Switch(codegen)})}
         OutputCode = {New Tk.variable tkInit(false)}
         OutputCodeSw = {New Tk.checkbutton
                         tkInit(parent: CodeGenFrame
                                text: 'Output assembler code textually'
                                font: SwitchFont
                                variable: OutputCode
                                action: {MkAction Switch(outputcode)})}

         EmulatorFrame = {New Tk.frame tkInit(parent: Column3
                                              highlightthickness: 0)}
         EmulatorLabel = {New Tk.label tkInit(parent: EmulatorFrame
                                              text:
                                                 'V. Feeding to the Emulator'
                                              font: SwitchGroupFont)}
         FeedToEmulator = {New Tk.variable tkInit(true)}
         FeedToEmulatorSw = {New Tk.checkbutton
                             tkInit(parent: EmulatorFrame
                                    text: 'Feed code to emulator'
                                    font: SwitchFont
                                    variable: FeedToEmulator
                                    action: {MkAction Switch(feedtoemulator)})}
         ThreadedQueries = {New Tk.variable tkInit(true)}
         ThreadedQueriesSw = {New Tk.checkbutton
                              tkInit(parent: EmulatorFrame
                                     text: 'Threaded queries'
                                     font: SwitchFont
                                     variable: ThreadedQueries
                                     action: {MkAction
                                              Switch(threadedqueries)})}
         Profile = {New Tk.variable tkInit(false)}
         ProfileSw = {New Tk.checkbutton
                      tkInit(parent: EmulatorFrame
                             text: 'Include profiling information'
                             font: SwitchFont
                             variable: Profile
                             action: {MkAction Switch(profile)})}

         DebuggerFrame = {New Tk.frame tkInit(parent: Column3
                                              highlightthickness: 0)}
         DebuggerLabel = {New Tk.label tkInit(parent: DebuggerFrame
                                              text: 'VI. Debugging'
                                              font: SwitchGroupFont)}
         RunWithDebugger = {New Tk.variable tkInit(false)}
         RunWithDebuggerSw = {New Tk.checkbutton
                              tkInit(parent: DebuggerFrame
                                     text: 'Execute queries under debugger'
                                     font: SwitchFont
                                     variable: RunWithDebugger
                                     action: {MkAction
                                              Switch(runwithdebugger)})}
         DebugInfoControl = {New Tk.variable tkInit(false)}
         DebugInfoControlSw = {New Tk.checkbutton
                               tkInit(parent: DebuggerFrame
                                      text: 'Include control flow information'
                                      font: SwitchFont
                                      variable: DebugInfoControl
                                      action: {MkAction
                                               Switch(debuginfocontrol)})}
         DebugInfoVarnames = {New Tk.variable tkInit(false)}
         DebugInfoVarnamesSw = {New Tk.checkbutton
                                tkInit(parent: DebuggerFrame
                                       text: 'Include variable information'
                                       font: SwitchFont
                                       variable: DebugInfoVarnames
                                       action: {MkAction
                                                Switch(debuginfovarnames)})}

         Queue = {New TkTools.note tkInit(parent: self.Book
                                          text: 'Query Queue')}
         {self.Book add(Queue)}
         self.CurrentQuery = {New Tk.entry tkInit(parent: Queue
                                                  font: TextFont
                                                  foreground: TextForeground
                                                  background: TextBackground
                                                  state: disabled)}
         self.InterruptButton = {New Tk.button
                                 tkInit(parent: Queue
                                        text: 'Interrupt'
                                        action: {MkAction Interrupt()})}
         QueueFrame = {New Tk.frame tkInit(parent: Queue
                                           highlightthickness: 0)}
         self.QueryList = {New Tk.listbox tkInit(parent: QueueFrame
                                                 selectmode: single
                                                 font: TextFont
                                                 foreground: TextForeground
                                                 background: TextBackground
                                                 width: MessagesWidth
                                                 height: MessagesHeight - 4)}
         {self.QueryList tkBind(event: '<1>'
                                action: proc {$}
                                           {self.DequeueQueryButton
                                            tk(configure state: normal)}
                                        end)}
         QueueYScrollbar = {New Tk.scrollbar tkInit(parent: QueueFrame)}
         {Tk.addYScrollbar self.QueryList QueueYScrollbar}
         QueueControlFrame = {New Tk.frame tkInit(parent: Queue
                                                  highlightthickness: 0)}
         self.DequeueQueryButton = {New Tk.button
                                    tkInit(parent: QueueControlFrame
                                           text: 'Dequeue query'
                                           state: disabled
                                           action: {MkAction DequeueQuery()})}
%--**    self.SuspendButton = {New Tk.checkbutton
%--**                          tkInit(parent: QueueControlFrame
%--**                                 text: 'Suspend')}
         self.ClearQueueButton = {New Tk.button
                                  tkInit(parent: QueueControlFrame
                                         text: 'Clear queue'
                                         state: disabled
                                         action: {MkAction ClearTaskQueue()})}
      in
         {Tk.batch [pack(Menu fill: x)
                    pack(self.Book padx: 4 pady: 4)
                    %% "Messages" note:
                    pack(MessageOptionsFrame side: bottom fill: x)
                    pack(ScrollToBottomButton side: left)
                    pack(Clear side: right)
                    pack(self.Text TextYScrollbar side: left fill: y)
                    %% "Environment" note:
                    pack(EnvOptionsFrame side: bottom fill: x)
                    pack(Save Load Remove side: right)
                    pack(self.EditedVariable side: left fill: x expand: true)
                    pack(self.EnvDisplay EnvYScrollbar side: left fill: y)
                    %% "Switches" note:
                    pack(Column1 Column2 Column3 side: left fill: y)
                    pack(GlobalFrame WarningsFrame padx: 8 pady: 8 anchor: w)
                    pack(WarningsLabel WarnRedeclSw WarnUnusedSw WarnForwardSw
                         anchor: w)
                    pack(GlobalLabel CompilerPassesSw ShowInsertSw
                         EchoQueriesSw ErrorsFrame anchor: w)
                    pack(DoMaxErrors self.MaxNumberOfErrors ErrorsLabel
                         side: left anchor: w)
                    pack(ParsingFrame SAFrame CoreFrame
                         padx: 24 pady: 8 anchor: w)
                    pack(ParsingLabel ExpressionSw SystemSw CatchAllSw
                         anchor: w)
                    pack(SALabel StaticAnalysisSw anchor: w)
                    pack(CoreLabel CoreSw RealCoreSw DebugValueSw DebugTypeSw
                         anchor: w)
                    pack(CodeGenFrame EmulatorFrame DebuggerFrame
                         padx: 8 pady: 8 anchor: w)
                    pack(CodeGenLabel CodeGenSw OutputCodeSw anchor: w)
                    pack(EmulatorLabel FeedToEmulatorSw ThreadedQueriesSw
                         ProfileSw anchor: w)
                    pack(DebuggerLabel RunWithDebuggerSw DebugInfoControlSw
                         DebugInfoVarnamesSw anchor: w)
                    %% "Query Queue" note:
                    grid(self.CurrentQuery row: 1 column: 1 sticky: nsew)
                    grid(columnconfigure Queue 1 weight: 1)
                    grid(self.InterruptButton row: 1 column: 2 sticky: nsew)
                    grid(QueueFrame row: 2 column: 1 columnspan: 2
                         sticky: nsew)
                    pack(self.QueryList QueueYScrollbar
                         side: left fill: both expand: true)
                    grid(QueueControlFrame row: 3 column: 1 columnspan: 2
                         sticky: nsew)
                    pack(%--** self.SuspendButton
                         self.DequeueQueryButton self.ClearQueueButton
                         side: left fill: x expand: true)
                    update(idletasks)
                    wm(deiconify self.TopLevel)]}
         ColoringIsEnabled <- Tk.isColor
         LastFeededVS <- ""
         LastURL <- ""
         ActionCount <- 0
         self.ColorDict = {NewDictionary}
         {ForAll Colors proc {$ T#C} {Dictionary.put self.ColorDict T C} end}
         self.Actions = Menu.options.action.menu
         self.ActionVariable = {New Tk.variable tkInit(none)}
         self.ActionDict = {NewDictionary}
         EnvSelection <- ''
         self.SwitchRec = switches(compilerpasses: CompilerPasses
                                   showinsert: ShowInsert
                                   echoqueries: EchoQueries
                                   warnredecl: WarnRedecl
                                   warnunused: WarnUnused
                                   warnforward: WarnForward
                                   expression: Expression
                                   system: System
                                   catchall: CatchAll
                                   staticanalysis: StaticAnalysis
                                   core: Core
                                   realcore: RealCore
                                   debugvalue: DebugValue
                                   debugtype: DebugType
                                   codegen: CodeGen
                                   outputcode: OutputCode
                                   feedtoemulator: FeedToEmulator
                                   threadedqueries: ThreadedQueries
                                   profile: Profile
                                   runwithdebugger: RunWithDebugger
                                   debuginfocontrol: DebugInfoControl
                                   debuginfovarnames: DebugInfoVarnames)
         self.ToGray = [Remove Load Save
                        self.MaxNumberOfErrors.inc self.MaxNumberOfErrors.dec
                        self.MaxNumberOfErrors.entry DoMaxErrors
                        CompilerPassesSw ShowInsertSw EchoQueriesSw
                        WarnRedeclSw WarnUnusedSw WarnForwardSw ExpressionSw
                        SystemSw CatchAllSw StaticAnalysisSw CoreSw RealCoreSw
                        DebugValueSw DebugTypeSw CodeGenSw OutputCodeSw
                        FeedToEmulatorSw ThreadedQueriesSw ProfileSw
                        RunWithDebuggerSw DebugInfoControlSw
                        DebugInfoVarnamesSw]
         self.InterruptMenuItem = Menu.compiler.interrupt
         ValueDict <- {NewDictionary}
         TagDict <- {NewDictionary}
         local X in
            QueryIdsHd <- X
            QueryIdsTl <- X
         end
         CompilerPanel, addAction('Show' Show)
         CompilerPanel, addAction('Browse' Browse)
      end

      meth FeedFile() FileName in
         FileName =
         {Tk.return tk_getOpenFile(parent: self.TopLevel
                                   title: 'Oz Compiler: Feed File'
                                   filetypes: q(q('Oz Source Files' q('.oz'))
                                                q('All Files' '*')))}
         case FileName == "" then skip
         else
            Compiler.genericInterface, enqueue(feedFile(FileName))
         end
      end
      meth FeedVirtualString()
         {New VSEntryDialog
          init(self.TopLevel Compiler.genericInterface, getPort($)
               @LastFeededVS) _}
      end
      meth !DoFeedVirtualString(VS)
         case {IsDet self.isClosed} then skip
         else
            LastFeededVS <- VS
            Compiler.genericInterface, enqueue(feedVirtualString(VS))
         end
      end
      meth DequeueQuery()
         case {self.QueryList tkReturnListInt(curselection $)}
         of [N] then
            {Compiler.genericInterface, getCompiler($)
             dequeue({Nth @QueryIdsHd N + 1})}
         else skip
         end
      end
      meth Interrupt()
         {Compiler.genericInterface, getCompiler($) interrupt()}
      end
      meth Reset()
         CompilerPanel, ClearTaskQueue()
         CompilerPanel, Interrupt()
         %--** CompilerPanel, ClearInfo()
         %--** {self.Compiler init()}
      end
      meth ClearTaskQueue()
         {Compiler.genericInterface, getCompiler($) clearQueue()}
      end
      meth AboutDialog()
         Dialog = {New TkTools.dialog tkInit(master: self.TopLevel
                                             root: pointer
                                             title: 'Oz Compiler: About'
                                             buttons: ['Ok'#tkClose]
                                             default: 1
                                             focus: 1
                                             pack: false)}
         Title = {New Tk.label tkInit(parent: Dialog
                                      text: 'Oz Compiler')}
         Author = {New Tk.label tkInit(parent: Dialog
                                       text: 'Programming Systems Lab\n'#
                                             'Contact: Leif Kornstaedt\n'#
                                             '<kornstae@ps.uni-sb.de>')}
      in
         {Tk.send pack(Title Author padx: 4 pady: 4 expand: true)}
         {Dialog tkPack()}
      end

      meth Goto(File Line Column) VS in
         VS = 'oz-bar '#File#' '#Line#' '#Column#' runnable'
         {Print {String.toAtom {VirtualString.toString VS}}}
      end
      meth ClearInfo()
         {self.Text tk(configure state: normal)}
         {self.Text tk(delete p(1 0) 'end')}
         {self.Text tk(configure state: disabled)}
         {self.Text tk(see 'end')}
         {For 0 @ErrorTagCounter - 1 1
          proc {$ I} {self.Text tk(tag delete I)} end}
         ErrorTagCounter <- 0
      end

      meth RedisplayEnv()
         PrintNames Count NCols Rows RowArray MessagesWidth NCharsInCol
         NewEnvDisplay
      in
         case {self.SystemVariables tkReturnInt($)} == 1 then
            PrintNames = {Sort {Dictionary.keys @ValueDict} Value.'<'}
         else
            PrintNames = {Sort
                          {Filter {Dictionary.keys @ValueDict}
                           fun {$ PrintName}
                              {Atom.toString PrintName}.1 \= &`
                           end} Value.'<'}
         end
         Count = {Length PrintNames}
         {self.NColsInEnv tkReturnInt(?NCols)}
         Rows = {Max (Count + NCols - 1) div NCols 1}
         RowArray = {NewArray 1 Rows ''}
         MessagesWidth = {Options get(compilerMessagesWidth $)}
         NCharsInCol = (MessagesWidth - (NCols - 1)) div NCols
         {FoldL
          {Map
           {Append PrintNames
            {ForThread 1 (Rows * NCols) - Count 1
             fun {$ In _} ''|In end nil}}
           fun {$ PrintName} S Len in
              S = {VirtualString.toString
                   {PrintNameToVirtualString PrintName}}
              Len = {Length S}
              case Len > NCharsInCol then
                 {List.take S NCharsInCol - 3}#"..."
              else
                 S#{MakeSpaces NCharsInCol - Len}
              end
           end}
          fun {$ Sp#N S}
             {Put RowArray N {Get RowArray N}#Sp#S}
             case N < Rows then Sp#(N + 1)
             else ' '#1
             end
          end ''#1 _#_}
         NewEnvDisplay =
         {ForThread Rows - 1 1 ~1 fun {$ In I} {Get RowArray I}#'\n'#In end
         {Get RowArray Rows}}
         {self.EnvDisplay tk(configure state: normal)}
         {self.EnvDisplay tk(delete p(1 0) 'end')}
         {self.EnvDisplay tk(insert p(1 0) NewEnvDisplay)}
         {self.EnvDisplay tk(configure state: disabled)}
         {ForAll {Dictionary.keys @TagDict}
          proc {$ Tag} {self.EnvDisplay tk(tag delete Tag)} end}
         TagDict <- {NewDictionary}
         {FoldL PrintNames
          fun {$ N#C PrintName} Ind1 Ind2 Action1 Action2 in
             Ind1 = p(N C)
             Ind2 = p(N C + NCharsInCol)
             {self.EnvDisplay tk(tag add q(PrintName) Ind1 Ind2)}
             Action1 = {New Tk.action
                        tkInit(parent: self.EnvDisplay
                               action: (Compiler.genericInterface, getPort($)#
                                        SelectEnv(PrintName)))}
             Action2 = {New Tk.action
                        tkInit(parent: self.EnvDisplay
                               action: (Compiler.genericInterface, getPort($)#
                                        ExecuteEnv(PrintName)))}
             {self.EnvDisplay tk(tag bind q(PrintName) '<1>' Action1)}
             {self.EnvDisplay tk(tag bind q(PrintName) '<Double-1>' Action2)}
             case @ColoringIsEnabled then
                {SetColor self.EnvDisplay PrintName
                 {Dictionary.get @ValueDict PrintName} self.ColorDict}
             else skip
             end
             {Dictionary.put @TagDict PrintName Ind1#Ind2#Action1#Action2}
             case N < Rows then (N + 1)#C
             else 1#(C + NCharsInCol + 1)
             end
          end 1#0 _#_}
         case {Dictionary.member @ValueDict @EnvSelection} then
            case Tk.isColor then
               {self.EnvDisplay tk(tag configure q(@EnvSelection)
                                   background: wheat)}
            else
               {self.EnvDisplay tk(tag configure q(@EnvSelection)
                                   foreground: white background: black)}
            end
         else
            EnvSelection <- ''
         end
      end
      meth ConfigureColors()
         {New ColorConfigurationDialog
          init(self.TopLevel Compiler.genericInterface, getPort($)
               {Map Colors fun {$ T#_} T#{Dictionary.get self.ColorDict T} end}
               @ColoringIsEnabled) _}
      end
      meth !InstallNewColors(Colors IsEnabled)
         {ForAll Colors proc {$ T#C} {Dictionary.put self.ColorDict T C} end}
         ColoringIsEnabled <- IsEnabled
         case IsEnabled then
            {ForAll {Dictionary.entries @ValueDict}
             proc {$ PrintName#Value}
                {SetColor self.EnvDisplay PrintName Value self.ColorDict}
             end}
         else
            {ForAll {Dictionary.entries @ValueDict}
             proc {$ PrintName#_}
                {self.EnvDisplay
                 tk(tag configure q(PrintName) foreground: black)}
             end}
         end
      end
      meth SelectEnv(PrintName)
         case @EnvSelection of '' then skip
         elseof PrintName then Ind1 Ind2 Action1 Action2 in
            {self.EnvDisplay tk(tag delete q(PrintName))}
            {Dictionary.get @TagDict PrintName Ind1#Ind2#Action1#Action2}
            {self.EnvDisplay tk(tag add q(PrintName) Ind1 Ind2)}
            {self.EnvDisplay tk(tag bind q(PrintName) '<1>' Action1)}
            {self.EnvDisplay tk(tag bind q(PrintName) '<Double-1>' Action2)}
            case @ColoringIsEnabled then
               {SetColor self.EnvDisplay PrintName
                {Dictionary.get @ValueDict PrintName} self.ColorDict}
            else skip
            end
         end
         case Tk.isColor then
            {self.EnvDisplay tk(tag configure q(PrintName) background: wheat)}
         else
            {self.EnvDisplay tk(tag configure q(PrintName)
                                foreground: white background: black)}
         end
         {self.EditedVariable tk(delete '0' 'end')}
         {self.EditedVariable tk(insert '0' q(PrintName))}
         EnvSelection <- PrintName
      end
      meth ExecuteEnv(PrintName)
         case {self.ActionVariable tkReturnInt($)} of 0 then skip
         elseof N then
            {{Dictionary.get self.ActionDict N}
             {Dictionary.get @ValueDict PrintName}}
         end
      end
      meth RemoveVariable() PrintName in
         {self.EditedVariable tkReturnAtom(get ?PrintName)}
         case {Dictionary.member @ValueDict PrintName} then
            %--** the above is an insufficient test, but workable for now
            Compiler.genericInterface, enqueue(removeFromEnv(PrintName))
         else
            {New TkTools.error
             tkInit(master: self.TopLevel
                    text: 'Non-existing variable "'#PrintName#'"') _}
         end
      end
      meth LoadVariable() S in
         {self.EditedVariable tkReturnString(get ?S)}
         try PrintName in
            PrintName = {StringToPrintName S}
            {New URLEntryDialog
             init(self.TopLevel Compiler.genericInterface, getPort($)
                  PrintName @LastURL) _}
         catch notAPrintName then
            {New TkTools.error
             tkInit(master: self.TopLevel
                    text: 'Illegal variable name syntax "'#S#'"') _}
         end
      end
      meth !DoLoadVariable(PrintName URL) Value in
         LastURL <- URL
         try
            Value = {Load URL}
         catch error(...) then
            {New TkTools.error
             tkInit(master: self.TopLevel
                    text: 'Load failed for URL "'#URL#'"') _}
         end
         Compiler.genericInterface,
         enqueue(mergeEnv(env(PrintName: Value)))
      end
      meth SaveVariable() PrintName in
         {self.EditedVariable tkReturnAtom(get ?PrintName)}
         case {Dictionary.member @ValueDict PrintName} then Value in
            Value = {Dictionary.get @ValueDict PrintName}
            {Send Compiler.genericInterface, getPort($) DoSaveVariable(Value)}
         else
            {New TkTools.error
             tkInit(master: self.TopLevel
                    text: 'Non-existing variable "'#PrintName#'"') _}
         end
      end
      meth DoSaveVariable(Value) FileName in
         FileName =
         {Tk.return tk_getSaveFile(parent: self.TopLevel
                                   title: 'Oz Compiler: Save Variable'
                                   filetypes: q(q('Oz Cluster Files' q('.ozc'))
                                                q('All Files' '*')))}
         case FileName == "" then skip
         else {Component.smartSave Value FileName _}
         end
      end

      meth Switch(SwitchName)
         case {self.SwitchRec.SwitchName tkReturnInt($)} == 1 then
            {self.SwitchRec.SwitchName tkSet(false)}
            Compiler.genericInterface, enqueue(setSwitch(SwitchName true))
         else
            {self.SwitchRec.SwitchName tkSet(true)}
            Compiler.genericInterface, enqueue(setSwitch(SwitchName false))
         end
      end
      meth SetMaxErrorsCheck()
         case {self.HasMaxErrorsEnabled tkReturnInt($)} == 1 then N in
            {self.MaxNumberOfErrors tkReturnInt(?N)}
            Compiler.genericInterface, enqueue(setMaxNumberOfErrors(N))
         else
            Compiler.genericInterface, enqueue(setMaxNumberOfErrors(~1))
         end
      end
      meth SetMaxErrorsCount(N)
         case {self.HasMaxErrorsEnabled tkReturnInt($)} == 1 then
            Compiler.genericInterface, enqueue(setMaxNumberOfErrors(N))
         else
            Compiler.genericInterface, enqueue(setMaxNumberOfErrors(~1))
         end
      end
   end
end
