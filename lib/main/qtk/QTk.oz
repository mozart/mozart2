%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                      %%
%% QTk                                                                  %%
%%                                                                      %%
%%  (c) 2000 Université catholique de Louvain. All Rights Reserved.     %%
%%  The development of QTk is supported by the PIRATES project at       %%
%%  the Université catholique de Louvain.  This file is subject to the  %%
%%  general Mozart license.                                             %%
%%                                                                      %%
%%  Author: Donatien Grolaux                                            %%
%%                                                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%\define FULLLOAD

functor

import
%   System(show:Show)
   Tk
   Module
   Property
   Error
   QTkDevel
   QTkImage(newImage:           NewImage
            newImageLibrary:    NewImageLibrary
            loadImageLibrary:   LoadImageLibrary
            saveImageLibrary:   SaveImageLibrary
            buildImageLibrary:  BuildImageLibrary)
   QTkMenu(newMenu:NewMenu)
   QTkSpace
   QTkLabel
   QTkButton
   QTkCheckbutton
   QTkRadiobutton
   QTkScale
   QTkScrollbar
   QTkEntry
   QTkCanvas
   QTkListbox
   QTkText
\ifdef FULLLOAD
   QTkDropdownlistbox
   QTkNumberentry
   QTkPlaceholder
   QTkPanel
   QTkRubberframe
   QTkScrollframe
   QTkToolbar
\endif

export

   build:DialogBuilder
   dialogbox:DialogBox
   Bell
   Clipboard
   NewFont
   NewImage
   NewImageLibrary
   LoadImageLibrary
   SaveImageLibrary
   BuildImageLibrary
   buildmenu:NewMenu
   registerWidget:QTkRegisterWidget
   newLook:NewLook
   LoadTk
   LoadTkPI
   WInfo

define

%   {Show 'QTk'}

   LoadTk=QTkDevel.loadTk
   LoadTkPI=QTkDevel.loadTkPI

   QTkAction
   NewLook
   Split
   SplitGeometry
   SplitParams
   CondFeat
   TkInit
   ExecTk
   ReturnTk
   MakeClass
   CheckType
   Assert
   SetGet
   QTkClass
   Subtracts
   TkToolTips
   GlobalInitType
   GlobalUnsetType
   GlobalUngetType
   RegisterWidget
   MapLabelToObject

   {List.map [qTkAction newLook split splitGeometry splitParams condFeat tkInit
              execTk returnTk makeClass checkType assert
              setGet qTkClass subtracts qTkTooltips
              globalInitType globalUnsetType globalUngetType
              registerWidget mapLabelToObject] fun{$ I} QTkDevel.I end}=[QTkAction
                                                                         NewLook
                                                                         Split
                                                                         SplitGeometry
                                                                         SplitParams
                                                                         CondFeat
                                                                         TkInit
                                                                         ExecTk
                                                                         ReturnTk
                                                                         MakeClass
                                                                         CheckType
                                                                         Assert
                                                                         SetGet
                                                                         QTkClass
                                                                         Subtracts
                                                                         TkToolTips
                                                                         GlobalInitType
                                                                         GlobalUnsetType
                                                                         GlobalUngetType
                                                                         RegisterWidget
                                                                         MapLabelToObject]

   NoArgs={NewName}

   ModMan={New Module.manager init}
   {ModMan enter(name:"QTkDevel" QTkDevel)} %% this prevents QTkDevel from being loaded again in this module manager
   {ModMan enter(name:"QTk" QTkDevel.qTk)}
   fun{Majus Str}
      case {VirtualString.toString Str}
      of C|Cs then C-32|Cs
      [] X then X
      end
   end

   %% Registers a widget, raising correctly the error if any
   %% special thanks to Andreas Franke for his contribution
%   local
%      ModHandlers = {NewDictionary}
%      %% save old handler, create default handler for module errors
%      local
%        OldHandler = {Property.get 'errors.handler'}
%      in
%        {Property.put 'errors.other' OldHandler}
%        if {Property.condGet 'errors.module' unit}==unit then
%           {Property.put 'errors.module' OldHandler}
%        end
%      end
%      %% create new handler
%      fun {MkAbsUrl Url}
%        if {URL.isAbsolute Url} then Url
%        else
%           {URL.toAtom {URL.resolve {Property.get 'application.url'} Url}}
%        end
%      end
%      local
%        local
%           local
%              proc {DefaultModHandler Exc}
%                 Handler = {Property.get 'errors.module'} in
%                 {Handler Exc}
%              end
%           in
%              proc {ModHandler Exc}
%                 case Exc
%                 of system(module(notFound load Url)...) then
%                    case {Dictionary.condGet ModHandlers {MkAbsUrl Url} unit}
%                    of unit    then {DefaultModHandler Exc}
%                    [] Handler then {Handler Exc}
%                    end
%                 [] qtk(...) then
%                    case {Dictionary.condGet ModHandlers {MkAbsUrl Url} unit}
%                    of unit    then {DefaultModHandler Exc}
%                    [] Handler then {Handler Exc}
%                    end
%                 else {DefaultModHandler Exc}
%                 end
%              end
%           end
%        in
%           local
%              proc {OtherHandler Exc}
%                 Handler = {Property.get 'errors.other'} in
%                 {Handler Exc}
%              end
%           in
%              proc {NewHandler Exc}
%                 case Exc of system(module(...)...) then {ModHandler Exc}
%                 else {OtherHandler Exc}
%                 end
%              end
%           end
%        end
%      in
%        {Property.put 'errors.handler' NewHandler}
%      end
%      proc {SetDefaultHandler Proc1}
%        {Type.ask.'procedure/1' Proc1}
%        {Property.put 'errors.module' Proc1}
%      end
%      proc {SetHandler Url Proc1}
%        {Type.ask.'procedure/1' Proc1}
%        {Dictionary.put ModHandlers {MkAbsUrl Url} Proc1}
%      end
%      proc {Redirect Url Thr}
%        {Type.ask.'thread' Thr}
%        {SetHandler Url proc {$ Exc} {Thread.injectException Thr Exc} end}
%      end
%   in
%      fun{QTkRegisterWidget GName}
%        FName=case {VirtualString.toString GName}
%              of 116|100|X then {VirtualString.toString "QTk"#{Majus X}#".ozf"}
%              [] 108|114|X then {VirtualString.toString "QTk"#{Majus X}#".ozf"}
%              else {VirtualString.toString "QTk"#{Majus GName}#".ozf"}
%              end
%        M
%      in
%        {Redirect FName {Thread.this}}
%        {ModMan link(url:FName M)}
%        {Wait M} %% force M to load and register itself
%        M
%      end
%   end

   fun{QTkRegisterWidget GName}
      %%
      %% Warning this function has a bad behaviour
      %% however it is the best behaviour I succeeded to obtain
      %%
      FName=case {VirtualString.toString GName}
            of 116|100|X then {VirtualString.toString "QTk"#{Majus X}#".ozf"}
            [] 108|114|X then {VirtualString.toString "QTk"#{Majus X}#".ozf"}
            else {VirtualString.toString "QTk"#{Majus GName}#".ozf"}
            end
      M
      OldHandler={Property.get 'errors.handler'}
      Except
      proc{NewHandler Exc}
         Except=Exc
      end
   in
      {Property.put 'errors.handler' NewHandler}
      {ModMan link(url:FName M)}
      {WaitOr M Except} %% force M to load and register itself
      {Property.put 'errors.handler' OldHandler}
      if {IsDet Except} then {Error.raiseException Except} end
      M
   end

   {Wait NewMenu}
%   {Show 'Menu'}
   {Wait QTkSpace}
%   {Show 'Space'}
   {Wait QTkLabel}
%   {Show 'Label'}
   {Wait QTkButton}
%   {Show 'Button'}
   {Wait QTkCheckbutton}
%   {Show 'Checkbutton'}
   {Wait QTkRadiobutton}
%   {Show 'Radiobutton'}
   {Wait QTkScale}
%   {Show 'Scale'}
   {Wait QTkScrollbar}
%   {Show 'Scrollbar'}
   {Wait QTkEntry}
%   {Show 'Entry'}
   {Wait QTkCanvas}
%   {Show 'Canvas'}
   {Wait QTkListbox}
%   {Show 'Listbox'}
   {Wait QTkText} % makes sure these functors are loaded
%   {Show 'Text'}
\ifdef FULLLOAD
   {Wait QTkPlaceholder}
%   {Show 'Placeholder'}
   {Wait QTkPanel}
%   {Show 'Panel'}
   {Wait QTkRubberframe}
%   {Show 'Rubberframe'}
   {Wait QTkScrollframe}
%   {Show 'Scrollframe'}
   {Wait QTkToolbar}
%   {Show 'Toolbar'}
   {Wait QTkDropdownlistbox}
%   {Show 'Dropdownlistbox'}
   {Wait QTkNumberentry}
%   {Show 'Numberentry'}
\endif

   \insert QTkClipboard.oz
   \insert Frame.oz
   \insert QTkFont.oz
   \insert QTkFrame.oz
   \insert QTkDialogbox.oz

   class QTkTopLevel

      from Frame Tk.toplevel QTkClass

      feat
         Init
         Return
         port
         Closed
         Radiobuttons
         Destroyed
         RadiobuttonsNotify
         widgetType:toplevel
         WM:[title aspect client focusmodel geometry grid group iconbitmap iconmask iconname iconposition iconwindow maxsize minsize overrideredirect resizable transient]
         typeInfo:r(all:r(look:no
                          borderwidth:pixel
                          cursor:cursor
                          highlightbackground:color
                          highlightcolor:color
                          highlightthickness:pixel
                          relief:relief
                          takefocus:boolean
                          background:color bg:color
                          'class':atom
                          colormap:no
                          container:boolean
                          height:pixel
                          %% menu:no commented as special support has to be furnished for this
                          screen:vs
                          use:vs
                          visual:no
                          width:pixel
                          %% parameters taken into account here
                          action:action  % action is called when the user tries to close the window
                          parent:no
                          return:free    % same return as for buttons
                          %% wm parameters
                          title:vs
                          aspect:no
                          client:vs
                          focusmodel:[active passive]
                          geometry:no
                          grid:no
                          group:no
                          iconbitmap:bitmap
                          iconmask:bitmap
                          iconname:vs
                          iconposition:no
                          iconwindow:no
                          maxsize:no
                          minsize:no
                          overrideredirect:boolean
                          resizable:no
                          transient:no)
                    uninit:r
                    unset:r(return:unit visual:unit use:unit screen:unit container:unit
                            colormap:unit 'class':unit)
                    unget:r(return:unit group:unit iconbitmap:unit iconmask:unit
                            iconwindow:unit transient:unit))
         action

      attr Destroyer


      prop locking

      meth init(M1)
         lock
            M={QTkDevel.propagateLook M1}
            if {IsFree self.Init} then self.Init=unit else
               {Exception.raiseError qtk(custom "Can't build a window" "The window has already been initialized" M)}
            end
            Out
            proc{Listen L}
               case L of X|Xs then
                  case X
                  of destroy then
                     % save datas
                     {ForAll {self getChildren($)}
                      proc{$ C} try {C destroy} catch _ then skip end end}
                     {self destroy}
                     % close window
                     self.Closed=unit
                     _={New TkToolTips hide}
                     {self tkClose}
                  else
                     % apply action
                     if {IsFree self.Destroyed} then
                        Rec={List.toRecord
                             X.2
                             {List.filter
                              {List.map
                               {Record.toListInd X}
                               fun{$ R}
                                  I J
                               in
                                  I#J=R
                                  if I>2 then I-2#J else nil end
                               end}
                              fun{$ R} R\=nil end}}
                     in
                        try
                           {X.1 Rec}
                        catch E then
                           {Error.printException E}
                        end
                     else skip end % waiting for the destroy instruction => skip pending commands
                     {Listen Xs}
                  end
               else skip end
            end
            A B
            Title={CondFeat M title "Oz/QTk Window"}
         in
            self.toplevel=self
            self.Radiobuttons={NewDictionary}
            self.RadiobuttonsNotify={NewDictionary}
            Destroyer<-nil
            self.port={NewPort Out}
            QTkClass,{Record.adjoin {Record.filterInd M
                                     fun{$ I _}
                                        {Int.is I}==false
                                     end} init(parent:self
                                               action:{CondFeat M action toplevel#close})}
            self.Return={CondFeat M return _}
            {SplitParams M self.WM A B}
            Tk.toplevel,{Record.adjoin {TkInit A} tkInit(delete:self.port#r(self Execute)
                                                         withdraw:true)}
            {self {Record.adjoin B WM(title:Title
                                      iconname:{CondFeat M iconname Title})}}
            Frame,init({Subtracts {Record.adjoinAt M parent self} [action return]})
            thread
               {Listen Out}
            end
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M self.WM A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {self {Record.adjoin B WM}}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M self.WM A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {self {Record.adjoin B WMGet}}
         end
      end

      meth WM(...)=M
         lock
            {Record.forAllInd M
             proc{$ I V}
                proc{Check Type}
                   Err={CheckType Type V}
                in
                   if Err==unit then skip
                   else
                      {Exception.raiseError qtk(typeError I self.widgetType Err M)}
                   end
                end
             in
                case I
                of title then
                   {Check vs}
                   {Tk.send wm(title self V)}
                [] aspect then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V} andthen {Label V}==aspect then
                      if {Record.arity V}==nil then
                         {Tk.send wm(aspect self '""' '""' '""' '""')}
                      elseif {Record.arity V}==[maxDenom maxNumer minDenom minNumer]
                         andthen {Record.all V fun{$ I} {IsDet I} andthen {Int.is I} end} then
                         {Tk.send wm(aspect self V.minNumer V.minDenom V.maxNumer V.maxDenom)}
                      else
                         Err=unit
                      end
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record aspect or aspect(minNumer:int minDenom:int maxNumer:int maxDenom:int) where int is an integer value"
                                                M)}
                   end
                [] client then
                   {Check vs}
                   {Tk.send wm(client self V)}
                [] focusmodel then
                   {Check [active passive]}
                   {Tk.send wm(focusmodel self V)}
                [] geometry then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V} andthen {Label V}==geometry
                      andthen {Record.all V fun{$ I} {IsDet I} andthen {Int.is I} end} then
                      if {Record.arity V}==[height width x y] then
                         {Tk.send wm(geometry self V.width#"x"#V.height#"+"#V.x#"+"#V.y)}
                      elseif {Record.arity V}==[height width] then
                         {Tk.send wm(geometry self V.width#"x"#V.height)}
                      elseif {Record.arity V}==[x y] then
                         {Tk.send wm(geometry self "+"#V.x#"+"#V.y)}
                      else
                         Err=unit
                      end
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record geometry(x:int y:int width:int height:int) where int is an integer value"
                                                M)}
                   end
                [] grid then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V} andthen {Label V}==grid then
                      if {Record.arity V}==nil then
                         {Tk.send wm(grid self '""' '""' '""' '""')}
                      elseif {Record.arity V}==[baseHeight baseWidth heightInc widthInc]
                         andthen {Record.all V fun{$ I} {IsDet I} andthen {Int.is I} end} then
                         {Tk.send wm(grid self V.baseHeight V.baseWidth V.widthInc V.heightInc)}
                      else
                         Err=unit
                      end
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record grid or grid(minNumer:int minDenom:int maxNumer:int maxDenom:int) where int is an integer value"
                                                M)}
                   end
                [] group then
                   if {IsDet V}==false orelse
                      {Tk.returnInt 'catch'(v("{wm group ") self V v("}"))}==1 then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A window"
                                                M)}
                   end
                [] iconbitmap then
                   {Check bitmap}
                   {Tk.send wm(iconbitmap self V)}
                [] iconmask then
                   {Check bitmap}
                   {Tk.send wm(iconmask self V)}
                [] iconname then
                   {Check vs}
                   {Tk.send wm(iconname self V)}
                [] iconposition then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V}
                      andthen {Record.arity V}==[x y]
                      andthen {Record.all V fun{$ I} {IsDet I} andthen {Int.is I} end} then
                      {Tk.send wm(iconposition self V.x V.y)}
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record coord(x:int y:int) where int is an integer value"
                                                M)}
                   end
                [] iconwindow then
                   if {IsDet V}==false orelse
                      {Tk.returnInt 'catch'(v("{wm iconwindow ") self V v("}"))}==1 then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A window"
                                                M)}
                   end
                [] maxsize then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V}
                      andthen {Record.arity V}==[height width]
                      andthen {Record.all V fun{$ I} {IsDet I} andthen {Int.is I} end} then
                      {Tk.send wm(maxsize self V.width V.height)}
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record maxsize(width:int height:int) where int is an integer value"
                                                M)}
                   end
                [] minsize then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V}
                      andthen {Record.arity V}==[height width]
                      andthen {Record.all V fun{$ I} {IsDet I} andthen {Int.is I} end} then
                      {Tk.send wm(minsize self V.width V.height)}
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record minsize(width:int height:int) where int is an integer value"
                                                M)}
                   end
                [] overrideredirect then
                   {Check boolean}
                   {Tk.send wm(overrideredirect self V)}
                [] resizable then
                   Err
                in
                   if {IsDet V} andthen {IsRecord V}
                      andthen {Record.arity V}==[height width]
                      andthen {Record.all V fun{$ I} {IsDet I} andthen I==true orelse I==false end} then
                      {Tk.send wm(resizable self V.width V.height)}
                   else
                      Err=unit
                   end
                   if {IsDet Err} then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A record resizable(width:bool height:bool) where bool is either true or false"
                                                M)}
                   end
                [] transient then
                   if {IsDet V}==false orelse
                      {Tk.returnInt 'catch'(v("{wm transient ") self V v("}"))}==1 then
                      {Exception.raiseError qtk(typeError I self.widgetType
                                                "A window"
                                                M)}
                   end
                else
                   {Exception.raiseError qtk(badParameter I toplevel M)}
                end
             end}
         end
      end

      meth WMGet(...)=M
         lock
            {Record.forAllInd M
             proc{$ I V}
                Str={Tk.return wm(I self)}
             in
                V=case I
                  of title then Str
                  [] aspect then {List.toRecord aspect {List.mapInd {Split Str}
                                                        fun{$ I V}
                                                           case I
                                                           of 1 then minNumer
                                                           [] 2 then minDenom
                                                           [] 3 then maxNumer
                                                           [] 4 then maxDenom
                                                           end#{String.toInt V}
                                                        end}}
                  [] client then Str
                  [] focusmodel then {String.toAtom Str}
                  [] geometry then {List.toRecord geometry
                                    {List.mapInd
                                     {SplitGeometry Str}
                                     fun{$ I V}
                                        case I
                                        of 1 then width
                                        [] 2 then height
                                        [] 3 then x
                                        [] 4 then y
                                        end#V
                                     end}}
                  [] grid then {List.toRecord grid {List.mapInd {Split Str}
                                                    fun{$ I V}
                                                       case I
                                                       of 1 then baseWidth
                                                       [] 2 then baseHeight
                                                       [] 3 then widthInc
                                                       [] 4 then heightInc
                                                       end#{String.toInt V}
                                                    end}}
                  [] iconname then Str
                  [] iconposition then {List.toRecord iconposition {List.mapInd {Split Str}
                                                    fun{$ I V}
                                                       case I
                                                       of 1 then x
                                                       [] 2 then y
                                                       end#{String.toInt V}
                                                    end}}
                  [] maxsize then {List.toRecord maxsize {List.mapInd {Split Str}
                                                          fun{$ I V}
                                                             case I
                                                             of 1 then width
                                                             [] 2 then height
                                                             end#{String.toInt V}
                                                          end}}
                  [] minsize then {List.toRecord minsize {List.mapInd {Split Str}
                                                          fun{$ I V}
                                                             case I
                                                             of 1 then width
                                                             [] 2 then height
                                                             end#{String.toInt V}
                                                          end}}
                  [] overrideredirect then Str=="1"
                  [] resizable then {List.toRecord resizable {List.mapInd {Split Str}
                                                              fun{$ I V}
                                                                 case I
                                                                 of 1 then width
                                                                 [] 2 then height
                                                                 end#V=="1"
                                                              end}}
                  end
                {Wait V}
             end}
         end
      end

      meth show(wait:W<=false modal:M<=false)
         lock
            {Tk.send wm(deiconify self)}
            if M then
               {Tk.send grab(self)}
            end
         end
         if W then
            {Wait self.Closed}
         end
      end

      meth wait
         {Wait self.Closed}
      end

      meth hide
         lock
            {Tk.send wm(withdraw self)}
         end
      end

      meth close
         lock
            self.Destroyed=unit
            {Send self.port destroy}
         end
      end

      meth iconify
         lock
            {Tk.send wm(iconify self)}
         end
      end

      meth deiconify
         lock
            {Tk.send wm(deiconify self)}
         end
      end

      % internal methods for the good behaviour of buttons and radiobuttons

      meth Execute
         lock
            Destroyer<-self
            {self.action execute}
         end
      end

      meth setDestroyer(Obj)
         lock
            Destroyer<-Obj
         end
      end

      meth getDestroyer(Obj)
         lock
            Obj=@Destroyer
         end
      end

      meth askNotifyRadioButton(Key Obj)
         lock
            {Dictionary.put self.RadiobuttonsNotify Key
             {Append [Obj] {Dictionary.condGet self.RadiobuttonsNotify Key nil}}
            }
         end
      end

      meth notifyRadioButton(Key)
         lock
            {ForAll
             {Dictionary.condGet self.RadiobuttonsNotify Key nil}
             proc{$ O}
                try {O notify} catch _ then skip end
             end}
         end
      end

      meth putRadioDict(Key Value)
         lock
            {Dictionary.put self.Radiobuttons Key Value}
         end
      end

      meth getRadioDict(Key Value)
         lock
            V={Dictionary.condGet self.Radiobuttons Key nil}
         in
            if V==nil then
               {self putRadioDict(Key r({New Tk.variable tkInit(1)} 0))}
               {self getRadioDict(Key Value)}
            else
               Value=V
            end
            {self putRadioDict(Key r(Value.1 Value.2+1))}
         end
      end

      meth destroy
         lock
            self.Return=@Destroyer==self
         end
      end

      meth newAction(Act Ret)
         lock
            {{New QTkAction init(parent:self action:Act)} action(Ret)}
         end
      end

   end

   fun{DialogBuilder Description}
      MyClass={MakeClass QTkTopLevel Description}
   in
      {New MyClass Description}
   end

   proc{Bell}
      {Tk.send bell}
   end

   fun{WInfo I}
      R
      What=winfo(I)
   in
      R=case {Label I}
        of cells then {Tk.returnInt What}
        [] colormapfull then {Tk.return What}=="1"
        [] depth then {Tk.returnInt What}
        [] exist then {Tk.return What}=="1"
        [] fpixels then {Tk.returnFloat What}
        [] height then {Tk.returnInt What}
        [] ismapped then {Tk.return What}=="1"
        [] pixels then {Tk.returnInt What}
        [] pointerx then {Tk.returnInt What}
        [] pointery then {Tk.returnInt What}
        [] reqheight then {Tk.returnInt What}
        [] reqwidth then {Tk.returnInt What}
        [] rootx then {Tk.returnInt What}
        [] rooty then {Tk.returnInt What}
        [] screen then {Tk.return What}
        [] screencells then {Tk.returnInt What}
        [] screendepth then {Tk.returnInt What}
        [] screenheight then {Tk.returnInt What}
        [] screenmmheight then {Tk.returnInt What}
        [] screenmmwidth then {Tk.returnInt What}
        [] screenvisual then {Tk.returnAtom What}
        [] screenwidth then {Tk.returnInt What}
        [] server then {Tk.return What}
        [] viewable then {Tk.return What}=="1"
        [] visual then {Tk.returnAtom What}
        [] visualid then {Tk.return What}
        [] vrootwidth then {Tk.returnInt What}
        [] vrootheight then {Tk.returnInt What}
        [] vrootx then {Tk.returnInt What}
        [] vrooty then {Tk.returnInt What}
        [] width then {Tk.returnInt What}
        [] x then {Tk.returnInt What}
        [] y then {Tk.returnInt What}
      end
      {Wait R}
      R
   end

   {Tk.send tk_setPalette(grey)} % to force all qtk users to have the same default palette

end
