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

proc {NewCompilerInterfaceTk Tk TkTools Open Browse ?CompilerInterfaceTk}
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

   InstallNewColors = {NewName}
   DoLoadVariable = {NewName}

   class VSEntryDialog from TkTools.dialog
      prop final
      meth init(Master Port VS)
         proc {DoFeed} VS in
            {Entry tkReturn(get p(1 0) 'end' ?VS)}
            TkTools.dialog, tkClose()
            {Send Port feedVirtualString(VS)}
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
         proc {DoSetColors} NewColors in
            TkTools.dialog, tkClose()
            NewColors#_ = {FoldL Colors
                           fun {$ NewColors#I T#_} C in
                              C = {Dictionary.get self.ColorDict I}
                              (T#C|NewColors)#(I + 1)
                           end nil#0}
            {Send Port InstallNewColors(NewColors
                                        {EnableVariable tkReturnInt($)} == 1)}
         end
         TkTools.dialog, tkInit(master: Master
                                root: pointer
                                title: 'Oz Compiler: Environment Colors'
                                buttons: ['Ok'#DoSetColors
                                          'Cancel'#tkClose()]
                                default: 1
                                focus: 1
                                pack: false)
         TypeFrame = {New TkTools.textframe tkInit(parent: self
                                                   text: 'Type')}
         ListFrame = {New Tk.frame tkInit(parent: TypeFrame.inner
                                          highlightthickness: 0)}
         TypeListHeight = {Options get(compilerTypeListHeight $)}
         self.TypeList = {New Tk.listbox tkInit(parent: ListFrame
                                                selectmode: single
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
      case N == 0 then ""
      else & |{MakeSpaces N - 1}
      end
   end
in
   class CompilerInterfaceTk
      prop locking final
      attr
         ErrorTagCounter: 0
         TaskQueueHd TaskQueueTl
         ColoringIsEnabled
         LastFeededVS LastURL EnvSelection ActionCount ValueDict TagDict
      feat
         isClosed
         TopLevel
         EventPort Compiler ToGray InterruptButton
         SystemVariables ColorDict
         Actions ActionVariable ActionDict NColsInEnv
         Book Messages Text ScrollToBottom
         EnvDisplay EditedVariable
         SwitchRec HasMaxErrorsEnabled MaxNumberOfErrors

      %%
      %% Method-provided User Functionality
      %%

      meth init(ExistingCompiler <= unit)
         lock
            case {IsFree self.EventPort} then Q Xs in   % only init once
               TaskQueueHd <- Q
               TaskQueueTl <- Q
               thread CompilerInterfaceTk, RunTaskQueue() end
               self.EventPort = {NewPort Xs}
               CompilerInterfaceTk, DoInit()
               case ExistingCompiler == unit then
                  self.Compiler = {New CompilerClass init(self)}
               else
                  self.Compiler = ExistingCompiler
               end
               thread CompilerInterfaceTk, Serve(Xs) end
            else skip
            end
         end
      end
      meth Serve(Messages)
         case {IsDet self.isClosed} then skip
         elsecase Messages of M|Mr then
            lock {self M} end
            CompilerInterfaceTk, Serve(Mr)
         end
      end

      meth feedFile(FileName ?RequiredInterfaces <= _)
         lock
            case {IsDet self.isClosed} then skip
            else DoFeedFile in
               proc {DoFeedFile}
                  {self.Compiler feedFile(FileName ?RequiredInterfaces)}
               end
               CompilerInterfaceTk, EnqueueTask(DoFeedFile true)
            end
         end
      end
      meth feedVirtualString(VS ?RequiredInterfaces <= _)
         lock
            case {IsDet self.isClosed} then skip
            else DoFeedVirtualString in
               proc {DoFeedVirtualString}
                  LastFeededVS <- VS
                  {self.Compiler feedVirtualString(VS ?RequiredInterfaces)}
               end
               CompilerInterfaceTk, EnqueueTask(DoFeedVirtualString true)
            end
         end
      end
      meth putEnv(Env)
         lock
            case {IsDet self.isClosed} then skip
            else DoPutEnv in
               proc {DoPutEnv}
                  {self.Compiler putEnv(Env)}
               end
               CompilerInterfaceTk, EnqueueTask(DoPutEnv false)
            end
         end
      end
      meth mergeEnv(Env)
         lock
            case {IsDet self.isClosed} then skip
            else DoMergeEnv in
               proc {DoMergeEnv}
                  {self.Compiler mergeEnv(Env)}
               end
               CompilerInterfaceTk, EnqueueTask(DoMergeEnv false)
            end
         end
      end
      meth getEnv(?Env)
         lock
            case {IsDet self.isClosed} then skip
            else DoGetEnv in
               proc {DoGetEnv}
                  {self.Compiler getEnv(?Env)}
               end
               CompilerInterfaceTk, EnqueueTask(DoGetEnv false)
            end
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
            self.EventPort#M
         end

         self.TopLevel = {New Tk.toplevel
                          tkInit(title: 'Oz Compiler'
                                 'class': 'OzTools'
                                 delete: {MkAction Close()}
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
                                            action: {MkAction Close()})])
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
                               action: {MkAction SetMaxErrors(_)})}
         self.MaxNumberOfErrors = {New TkTools.numberentry
                                   tkInit(parent: ErrorsFrame
                                          min: 1
                                          max: 100
                                          val: 17
                                          font: SwitchFont
                                          width: 3
                                          action: {MkAction SetMaxErrors()})}
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
      in
         {Tk.batch [pack(Menu fill: x)
                    pack(self.Book padx: 4 pady: 4)
                    pack(MessageOptionsFrame side: bottom fill: x)
                    pack(ScrollToBottomButton side: left)
                    pack(Clear side: right)
                    pack(self.Text TextYScrollbar side: left fill: y)
                    pack(EnvOptionsFrame side: bottom fill: x)
                    pack(Save Load Remove side: right)
                    pack(self.EditedVariable side: left fill: x expand: true)
                    pack(self.EnvDisplay EnvYScrollbar side: left fill: y)
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
                    pack(ParsingLabel SystemSw CatchAllSw anchor: w)
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
                        WarnRedeclSw WarnUnusedSw WarnForwardSw SystemSw
                        CatchAllSw StaticAnalysisSw CoreSw RealCoreSw
                        DebugValueSw DebugTypeSw CodeGenSw OutputCodeSw
                        FeedToEmulatorSw ThreadedQueriesSw ProfileSw
                        RunWithDebuggerSw DebugInfoControlSw
                        DebugInfoVarnamesSw]
         self.InterruptButton = Menu.compiler.interrupt
         ValueDict <- {NewDictionary}
         TagDict <- {NewDictionary}
         CompilerInterfaceTk, addAction('Show' Show)
         CompilerInterfaceTk, addAction('Browse' Browse)
      end

      meth FeedFile() FileName in
         FileName =
         {Tk.return tk_getOpenFile(parent: self.TopLevel
                                   title: 'Oz Compiler: Feed File'
                                   filetypes: q(q('Oz Source Files' q('.oz'))
                                                q('All Files' '*')))}
         case FileName == "" then skip
         else
            CompilerInterfaceTk, feedFile(FileName)
         end
      end
      meth FeedVirtualString()
         {New VSEntryDialog init(self.TopLevel self.EventPort @LastFeededVS) _}
      end
      meth Interrupt()
         CompilerInterfaceTk, ClearTaskQueue()
      end
      meth Reset()
         CompilerInterfaceTk, ClearTaskQueue()
         CompilerInterfaceTk, ClearInfo()
         {self.Compiler init()}
      end
      meth Close()
         lock
            self.isClosed = unit
            CompilerInterfaceTk, ClearTaskQueue()   %--** suboptimal!
            {self.TopLevel tkClose()}
         end
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
                               action: self.EventPort#SelectEnv(PrintName))}
             Action2 = {New Tk.action
                        tkInit(parent: self.EnvDisplay
                               action: self.EventPort#ExecuteEnv(PrintName))}
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
          init(self.TopLevel self.EventPort
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
      meth RemoveVariable() PrintName DoRemoveVariable in
         {self.EditedVariable tkReturnAtom(get ?PrintName)}
         proc {DoRemoveVariable}
            case {self.Compiler isDeclared(PrintName $)} then
               {self.Compiler undeclare(PrintName)}
               CompilerInterfaceTk, RedisplayEnv()
            else
               {New TkTools.error
                tkInit(master: self.TopLevel
                       text: 'Non-existing variable "'#PrintName#'"') _}
            end
         end
         CompilerInterfaceTk, EnqueueTask(DoRemoveVariable false)
      end
      meth LoadVariable() S in
         {self.EditedVariable tkReturnString(get ?S)}
         try PrintName in
            PrintName = {StringToPrintName S}
            _ = {New URLEntryDialog
                 init(self.TopLevel self.EventPort PrintName @LastURL)}
         catch notAPrintName then
            {New TkTools.error
             tkInit(master: self.TopLevel
                    text: 'Illegal variable name syntax "'#S#'"') _}
         end
      end
      meth !DoLoadVariable(PrintName URL) DoLoadVariable in
         proc {DoLoadVariable}
            LastURL <- URL
            try Value in
               Value = {Load URL}
               {self.Compiler mergeEnv(env(PrintName: Value))}
            catch error(...) then
               {New TkTools.error
                tkInit(master: self.TopLevel
                       text: 'Load failed for URL "'#URL#'"') _}
            end
         end
         CompilerInterfaceTk, EnqueueTask(DoLoadVariable false)
      end
      meth SaveVariable() PrintName in
         {self.EditedVariable tkReturnAtom(get ?PrintName)}
         case {self.Compiler isDeclared(PrintName $)} then Value in
            Value = {Dictionary.get @ValueDict PrintName}
            {Send self.EventPort DoSaveVariable(Value)}
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
         else {Save Value FileName 'file:/'#FileName}
         end
      end

      meth Switch(SwitchName)
         case {self.SwitchRec.SwitchName tkReturnInt($)} == 1 then
            {self.Compiler setSwitch(on(SwitchName unit))}
         else
            {self.Compiler setSwitch(off(SwitchName unit))}
         end
      end
      meth SetMaxErrors(_)
         case {self.HasMaxErrorsEnabled tkReturnInt($)} == 1 then
            {self.Compiler setMaxNumberOfErrors(~1)}
         else N in
            {self.MaxNumberOfErrors tkReturnInt(?N)}
            {self.Compiler setMaxNumberOfErrors(N)}
         end
      end

      %%
      %% Methods Called by the Compiler Object
      %%

      meth !SetSwitches(Switches)
         lock
            {Record.forAllInd self.SwitchRec
             proc {$ SwitchName Variable}
                {Variable tkSet({Switches get(SwitchName $)})}
             end}
         end
      end
      meth !SetMaxNumberOfErrors(N)
         lock
            case N =< 0 then
               {self.HasMaxErrorsEnabled tkSet(false)}
            else
               {self.HasMaxErrorsEnabled tkSet(true)}
               {self.MaxNumberOfErrors tkSet(N)}
            end
         end
      end
      meth !ShowInfo(VS Coord <= unit)
         lock
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
                                   action: self.EventPort#Goto(File Line
                                                               Column))}
                  {self.Text tk(tag bind Tag '<1>' Action)}
               end
            end
            {self.Text tk(configure state: disabled)}
            case {self.ScrollToBottom tkReturnInt($)} == 1 then
               {self.Text tk(see 'end')}
            else skip
            end
         end
      end
      meth !DisplaySource(Title Ext VS)
         {New SourceWindow init(self.TopLevel Title VS) _}
      end
      meth !ToTop()
         {self.Book toTop(self.Messages)}
      end
      meth !DisplayEnv(TheValueDict)
         lock
            ValueDict <- TheValueDict
            CompilerInterfaceTk, RedisplayEnv()
         end
      end
      meth !AskAbort(?Result)
         proc {DoIgnore}
            Result = false
            {Dialog tkClose()}
         end
         proc {DoAbort}
            Result = true
            {Dialog tkClose()}
         end
         Dialog = {New TkTools.dialog
                   tkInit(master: self.TopLevel
                          root: pointer
                          title: 'Oz Compiler: Exception'
                          buttons: ['Ignore'#DoIgnore
                                    'Abort'#DoAbort]
                          focus: 2
                          default: 2
                          pack: false)}
         Bitmap = {New Tk.label tkInit(parent: Dialog
                                       bitmap: question)}
         Message = {New Tk.message
                    tkInit(parent: Dialog
                           text: '#'('Execution of the query threw an '
                                     'uncaught exception.  Should this be '
                                     'ignored?')
                           aspect: 250)}
      in
         {Tk.send pack(Bitmap Message side: left padx: 4 pady: 4 expand: true)}
         {Dialog tkPack()}
      end

      %%
      %% Handle Task Queue
      %%

      meth EnqueueTask(P OwnThread) NewTaskQueueTl in
         @TaskQueueTl = P#OwnThread|NewTaskQueueTl
         TaskQueueTl <- NewTaskQueueTl
      end
      meth RunTaskQueue() OldTaskQueueHd NewTaskQueueHd in
         OldTaskQueueHd = (TaskQueueHd <- NewTaskQueueHd)
         case OldTaskQueueHd of P#OwnThread|Rest then
            NewTaskQueueHd = Rest
            case OwnThread then Done in
               CompilerInterfaceTk, SetWidgetsState(self.ToGray disabled)
               {self.InterruptButton tk(entryconfigure state: normal)}
               thread
                  try
                     {P}
                  finally
                     Done = unit
                  end
               end
               {Wait Done}
               lock
                  case {IsFree self.isClosed} then
                     CompilerInterfaceTk, SetWidgetsState(self.ToGray normal)
                     {self.InterruptButton tk(entryconfigure state: disabled)}
                  else skip
                  end
               end
            else
               {P}
            end
            CompilerInterfaceTk, RunTaskQueue()
         end
      end
      meth ClearTaskQueue()
         {self.InterruptButton tk(entryconfigure state: disabled)}
         TaskQueueHd <- @TaskQueueTl
         {self.Compiler interrupt()}
      end
      meth SetWidgetsState(Widgets State)
         case Widgets of Widget|Rest then
            {Widget tk(configure state: State)}
            CompilerInterfaceTk, SetWidgetsState(Rest State)
         [] nil then skip
         end
      end
   end
end
