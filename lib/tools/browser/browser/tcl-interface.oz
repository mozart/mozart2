%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%% Tcl/tk (somewhat) interface to Oz Browser;
%%%
%%% The idea behind these objects is not only to encapsulate the state
%%% of windows etc. (though it's also a goal), but rather to provide
%%% for an only place where things from Tk.oz are used;
%%%
%%%

%%%
%%%   Local auxiliary functions;
%%%
local
   %%
   MyToplevel

   %%
   ProcessEntries
   DerefEntry
   %%
   MakeEvent

   %%
   GetRepMarks
   GetStrs

   %%
   CanvasFeat   = {NewName}     %
   TagFeat      = {NewName}     %

   %%
in

   %%
   class MyToplevel from Tk.toplevel end

   %%
   %% Apply a command 'W' to elements of the list 'Es' augmented with
   %% the menubar's widget name 'M'. It looks like
   %%
   %% {Process
   %%  Menu
   %%  [browser([show close]) buffer(clear)]
   %%   tk(entryconf state:disabled)}
   %%
   %% This code has been stolen from the Explorer. Thanks to Christian!
   %%
   proc {ProcessEntries M Es W}
      case Es of nil then true
      [] E|Er then {ProcessEntries M E W} {ProcessEntries M Er W}
      elsecase {IsAtom Es} then {M.Es W}
      else {ProcessEntries M.{Label Es} Es.1 W}
      end
   end
   fun {DerefEntry M E}
      case {IsAtom E} then M.E
      else {DerefEntry M.{Label E} E.1}
      end
   end

   %%
   %%
   local MakeEventPattern in
      fun {MakeEventPattern E}
         case E
         of ctrl(R)    then 'Control-' # {MakeEventPattern R}
         [] shift(R)   then 'Shift-' # {MakeEventPattern R}
         [] lock(R)    then 'Lock-' # {MakeEventPattern R}
         [] mod1(R)    then 'Mod1-' # {MakeEventPattern R}
         [] mod2(R)    then 'Mod2-' # {MakeEventPattern R}
         [] mod3(R)    then 'Mod3-' # {MakeEventPattern R}
         [] mod4(R)    then 'Mod4-' # {MakeEventPattern R}
         [] mod5(R)    then 'Mod5-' # {MakeEventPattern R}
         [] alt(R)     then 'Alt-' #  {MakeEventPattern R}
         [] button1(R) then 'Button1-' # {MakeEventPattern R}
         [] button2(R) then 'Button2-' # {MakeEventPattern R}
         [] button3(R) then 'Button3-' # {MakeEventPattern R}
         [] button4(R) then 'Button4-' # {MakeEventPattern R}
         [] button5(R) then 'Button5-' # {MakeEventPattern R}
         [] double(R)  then 'Double-' # {MakeEventPattern R}
         [] triple(R)  then 'Triple-' # {MakeEventPattern R}
         else E
         end
      end

      %%
      fun {MakeEvent R}
         '<' # {MakeEventPattern R} # '>'
      end
   end

   %%
   %% It gets a previous mark to 'Index' until it escapes 'RefIndex';
   fun {GetRepMarks BW Index RefIndex}
      local M in
         M = {Tk.return o(BW mark prev Index)}

         %%
         case M == "" orelse {Tk.return o(BW index M)} \= RefIndex
         then nil
         else M|{GetRepMarks BW M RefIndex}
         end
      end
   end

   %%
   %% 'GetsStrs' extracts substrings delimited by 'Delim' out of 'Str';
   local FindChar FindChar1 in
      fun {FindChar S C} {FindChar1 S C 1} end
      fun {FindChar1 S C N}
         case S of H|R then
            case H of !C then N
            else {FindChar1 R C N+1}
            end
         else ~1
         end
      end

      %%
      %% Its input argument 'Str' may not be the empty list (because
      %% of 'List.take');
      fun {GetStrs Str Delim ParRes}
         local Ind in
            Ind = {FindChar Str Delim}
            %%
            case Ind == ~1 then {Append ParRes [Str]}
            else HeadOf TailOf in
               HeadOf = {List.take Str Ind-1}
               TailOf = {List.drop Str Ind}

               %%
               {GetStrs TailOf Delim {Append ParRes [HeadOf]}}
            end
         end
      end

      %%
   end

%%%
%%%
%%%  Prototype of browser's window;
%%%
   %%
   %%
   class BrowserWindowClass from UrObject
      %%

      %%
      feat
      %% given by creation;
         browserObj             %
         store                  % cache it directly;
         standAlone             % 'True'/'False';

      %%
      %% widgets;
      %%
      %% static, i.e. a 'BrowserWindowClass' cannot re-create
      %% it's widget;
         Window
         BrowseWidget
      %% We don't need the 'FrameHS' except for specifying the
      %% placement order in the 'exposeMenuBar';
         FrameHS
      %%
      %% The only mark where something can be inserted;
         Cursor

      %%
      %% Tcl"s (low-level), and a map from Tcl"s to pairs
      %% (<type>,<term object>).
         TclBase
         TclsMap                % a map mentioned above;

      %%
      attr
      %% these widgets can be triggered;
         menuBar:      InitValue
      %% Cursor's column #.
         cursorCol:    InitValue
      %%
         TclCN:        InitValue        % current tcl number;
         TclsCache:    InitValue        % just a list of reusable Tcl"s;
         TclsTail:     InitValue        % a tail of tcl"s cache;
      %%
         HighlightTag: InitValue
      %%
      %% optimized 'unsetMark': first, collect some of them into
      %% 'o'-tuple, and, after that - unset them in one shot:
         UnsetMarks

%%%
%%%
%%%  Controlling a browser window, etc.
%%%

      %%
      %%  ... store the given Window as a browser's "root" window or
      %% make a new one if none is given;
      meth init(window:        WindowIn
                browserObj:    BObj
                store:         Store
                screen:        Screen)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::init!'}
\endif
         %%
         self.browserObj = BObj
         self.store = Store

         %%
         case WindowIn == InitValue then
            WindowLocal XSize YSize CloseAction RootXSize RootYSize
         in
            self.standAlone = True
            XSize = {self.store read(StoreXSize $)}
            YSize = {self.store read(StoreYSize $)}

            %%
            WindowLocal =
            {New MyToplevel case Screen == InitValue
                            then tkInit(withdraw:True)
                            else tkInit(withdraw:True screen:Screen)
                            end}

            %%
            CloseAction = {New Tk.action tkInit(parent: WindowLocal
                                                action: BObj#close)}

            %%
            {Tk.send update(idletasks)}
            {Tk.returnInt winfo(screenheight WindowLocal) RootYSize}
            {Tk.returnInt winfo(screenwidth WindowLocal) RootXSize}

            %%
            {Wait RootYSize}
            {Wait RootXSize}

            %%
            {Tk.batch
             [wm(maxsize WindowLocal (RootXSize) (RootYSize))
              wm(iconname WindowLocal IITitle)
              wm(iconbitmap WindowLocal '@'#IIBitmap)
              %% wm(iconmask WindowLocal '@'#IIBMask)
              wm(geometry WindowLocal XSize#x#YSize)
              wm(protocol WindowLocal 'WM_DELETE_WINDOW' CloseAction)]}

            %%
            {Tk.send wm(title WindowLocal
                        case self.browserObj.IsView then IVTitle
                        else ITitle
                        end)}

            %%
            self.Window = WindowLocal
         else
            self.standAlone = False
            self.Window = WindowIn
            %%  Note that there is no control for this window;
            %%  It means in particular, that the application
            %% giving this window shouldn't do any *nonsese".
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::init: toplevel complete;'}
\endif

         %%
         %% Initialize Tcl"s generator, and create a tcl"s map;
         self.TclBase = {String.toAtom {Tk.getPrefix}}
         self.TclsMap = {Dictionary.new}
         TclCN <- 1             % '0' is used (for the cursor);
         TclsCache <- _
         TclsTail <- @TclsCache
         UnsetMarks <- nil

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::init: internals complete;'}
\endif

         %%
         %% Now, we have a toplevel widget or its replacement in the
         %% case of embedded browsers;
         local
            W              %  top level;
            FHS            %  frame for horizontal scrollbar and glue;
            FHS_F          %  this frame servers as a glue
                           % (see previous line);
            FHS_HS         %  horizontal scrollbar;
            BW             %
            VS             %  vertical scrollbar bound with the BW directly;

            %%
            ButtonClickAction
            DButtonClickAction
         in
            %%
            W = self.Window

            %%
            FHS = {New Tk.frame tkInit(parent: W
                                       bd: 0
                                       highlightthickness: 0)}
            FHS_HS = {New Tk.scrollbar tkInit(parent: FHS
                                              relief: IFrameRelief
                                              bd: IBigBorder
                                              width: ISWidth
                                              orient: horizontal
                                              highlightthickness: 0)}
            FHS_F = {New Tk.frame
                     tkInit(parent: FHS
                            width: (ISWidth + IBigBorder + IBigBorder)
                            height: (ISWidth + IBigBorder + IBigBorder)
                            highlightthickness: 0)}
            BW = {New Tk.text tkInit(parent: W
                                     %% width: ITWWidth
                                     %% height: ITWHeight
                                     bd: IBigBorder
                                     relief: ITextRelief
                                     padx: ITWPad
                                     pady: ITWPad
                                     wrap: none
                                     insertontime: 0
                                     background: IBackGround
                                     foreground: IForeGround
                                     highlightthickness: 0)}

            %%
            %%  ... let's try to change the cursor shape
            %% (asynchronously);
            thread
               {Tk.return 'catch'(q(BW conf(cursor: ICursorName))) _}
            end

            %%
            self.BrowseWidget = BW
            self.FrameHS = FHS

            %%
            %% Select a font from ITWFont?, and store it;
            {Wait
             (self , FoldL_Obj([ITWFont1 ITWFont2 ITWFont3] TryFont True $))}

            %%
            %% scrollbars;
            VS = {New Tk.scrollbar tkInit(parent: W
                                          relief: IFrameRelief
                                          bd: IBigBorder
                                          width: ISWidth
                                          highlightthickness: 0)}
            {Tk.addYScrollbar BW VS}
            {Tk.addXScrollbar BW FHS_HS}

            %%
\ifdef DEBUG_TI
            {Show 'BrowserWindowClass::init: widgets complete;'}
\endif

            %%
            %%  pack them;
            {Tk.batch
             [pack(FHS side: bottom fill: x padx: 0 pady: 0)
              pack(VS side: right fill: y padx: IPad pady: IPad)
              pack(FHS_HS side: left fill: x expand: yes
                   padx: IPad pady: IPad)
              pack(FHS_F side: right fill: none padx: IPad pady: IPad)
              pack(BW fill: both expand: yes side: top
                   padx: IPad pady: IPad)

              %%
              %%  Only bindings by the BrowseWidget itself are allowed;
              bindtags(BW q(BW))

              %%
              bind(BW '<Shift-1>'
                   q(v(
                        'myTkTextButton1 %W %x %y; %W tag remove sel 0.0 end'
                      )))
              bind(BW '<Shift-B1-Motion>'
                   q(v(
                      'tkTextSelectTo %W %x %y'
                    )))
              bind(BW '<Shift-3>'
                   q(v(
                      'tkTextResetAnchor %W @%x,%y; tkTextSelectTo %W %x %y'
                    )))
              bind(BW '<Shift-B3-Motion>'
                   q(v(
                        'tkTextResetAnchor %W @%x,%y; tkTextSelectTo %W %x %y'
                    )))

              %%
              %% X11 selection - shift-buttons[move];
              %% actually, they are not Motif-like, but something like
              %% 'xterm';
              %%
              %%  exclude '$w mark set insert @$x,$y';
              o(pr#oc myTkTextButton1 q(w x y)
                q(
                   v('global tkPriv;')
                   v('set tkPriv(selectMode) char;')
                   v('set tkPriv(mouseMoved) 0;')
                   v('set tkPriv(pressX) $x;')
                   v('$w mark set anchor @$x,$y;')
                   v('if {[$w cget -state] == "normal"} {focus $w};')
                 )
                )

              %%
              focus(BW)
              %%
             ]}

            %%
\ifdef DEBUG_TI
            {Show 'BrowserWindowClass::init: widgets packed;'}
\endif

            %%
            %% 'ButtonPress' and 'Double-ButtonPress' actions;
            local StreamObj Act in
               StreamObj = {self.store read(StoreStreamObj $)}
               %%
               proc {Act Handler Arg X Y}
                  local NewMark Pairs TargetObj in
                     NewMark = {Tk.server tkGet($)}
                     %% the default gravity is right...
                     {BW tk(m s NewMark '@'#X#','#Y)}

                     %%
                     %% Now, figure out the target object.
                     %%
                     %% Note that this should be done now because later
                     %% otherwise a wrong object must be pointed by
                     %% the 'NewMark'. Note also that 'mapMark'
                     %% should be atomic (therefore, it's implemented
                     %% as a method);
                     Pairs = {self mapMark(NewMark $)}
                     TargetObj = {GetTargetObj Pairs}

                     %%
                     {StreamObj enq(processEvent(TargetObj Handler Arg))}
                  end
               end

               %%
               proc {ButtonClickAction B X Y}
                  %% middle button is still free;
                  case B of '3' then {self.browserObj UnsetSelected}
                  else {Act ButtonsHandler B X Y}
                  end
               end
               proc {DButtonClickAction B X Y}
                  {Act DButtonsHandler B X Y}
               end
            end

            %%
            %%
            {BW [tkBind(event:  '<ButtonPress>'
                        action: ButtonClickAction
                        args:   [atom('b') int('x') int('y')])
                 tkBind(event:  '<Double-ButtonPress>'
                        action: DButtonClickAction
                        args:   [atom('b') int('x') int('y')])
                 %%
                 %%  some special bindings for browse text widget;
                 tkBind(event:  '<Configure>'
                        action: self#resetTW)]}

            %%
            %%  toplevel-widget;
            {W [tkBind(event: '<FocusIn>'
                       action: proc {$}
                                  {self focusIn}
                                  {BrowserMessagesFocus self.Window}
                               end)
                tkBind(event: '<FocusOut>'
                       action: proc {$}
                                  %%  no special action;
                                  {BrowserMessagesNoFocus}
                               end)]}

            %%
\ifdef DEBUG_TI
            {Show 'BrowserWindowClass::init: bindings done;'}
\endif

            %%
            %% Bind 'Cursor' to the Tk's 'insert' mark;
            local IM in
               IM = self.Cursor = self.TclBase # 0
               {BW tk(m s IM insert)}
            end
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::init: complete!'}
\endif
      end

      %%
      %% Loop over list ('FoldL' fashion) with method applications;
      meth FoldL_Obj(Xs P Z $)
         case Xs
         of X|Xr then self , FoldL_Obj(Xr P (self , P(Z X $)) $)
         [] nil  then Z
         end
      end

      %%
      meth TryFont(Proceed IFont $)
         case Proceed then
            %%
            case BrowserWindowClass , setTWFont(IFont $) then
               %%
               %% Browser object will also send a request to select an
               %% appropriate radio button;
               thread   % job
                  {self.browserObj
                   setParameter(BrowserFont IFont.name)}
               end
               %%
               False
            else True
            end
         else Proceed
         end
      end

      %%
      %% close the top level widnow;
      %%
      meth close
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::close'}
\endif
         %%
         %% external window must be closed by provider;
         case self.standAlone then {self.Window close}
         else true
         end

         %% reject all future messages;
         Object.base , close
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::close is finished'}
\endif
      end

      %%
      %%
      meth expose
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::expose'}
\endif
         case self.standAlone then {Tk.send wm(deiconify self.Window)}
         else true
         end
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::expose is finished'}
\endif
      end

      %%
      %%
      meth focusIn
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::focusIn'}
\endif
         true
         %%
         %%  Tk 4.0 does not require any special action;
         %% {Tk.send focus(self.BrowseWidget)}
         %%
      end

      %%
      %% Yields 'True' if the font exists;
      meth tryFont(Font $)
         {X11ResourceCache tryFont(Font.font $)}
      end

      %%
      %% Yields height and width of the font given (or zeros if it
      %% doesn't exist at all);
      meth getFontRes(Font ?XRes ?YRes)
         {X11ResourceCache getFontRes(Font.font XRes YRes)}
      end

      %%
      %% Yields 'True' if a try was successful;
      meth setTWFont(NewFont $)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setTWFont'#NewFont}
\endif
         %%
         local Font in
            Font = {self.store read(StoreTWFont $)}

            %%
            case NewFont
            of !Font then True  %  have it already;
            elsecase BrowserWindowClass , tryFont(NewFont $) then
               %%
               {self.BrowseWidget tk(conf font:NewFont.font)}
               {self.store store(StoreTWFont NewFont)}
               BrowserWindowClass , resetTW

               %%
               True
            else False
            end
         end
      end

      %%
      %% A 'feedback' for browser providing for an actual tw width;
      meth resetTW
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::resetTW'}
\endif
         %%
         local Font TWWidthS TWWidth XRes in
            {self.store read(StoreTWFont Font)}

            %%
            {Tk.send update(idletasks)}

            %%
            {Tk.return winfo(width self.BrowseWidget) TWWidthS}
            TWWidth = {String.toInt TWWidthS}   % implicit sync;

            %%
            XRes = case Font.xRes == 0 then
                      BrowserWindowClass , getFontRes(Font $ _)
                   else Font.xRes
                   end

            %%
            case XRes \= 0 then
               thread           % job
                  {self.browserObj
                   SetTWWidth({`div`
                               (TWWidth - 2*ITWPad - 2*IBigBorder)
                               XRes})}
               end
            else true           % we cannot do anything anyway;
            end
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::resetTW is finished'}
\endif
         touch
      end

      %%
      %% Set the geometry of a browser's window, provided it is
      %% not smaller than a minimal possible one
      %% (and, of course, this is a 'stand alone' browser);
      %%
      meth setXYSize(X Y)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setXYSize' # X # Y}
\endif
         %%
         case self.standAlone then MinXSize MinYSize in
            {self.store [read(StoreXMinSize MinXSize)
                         read(StoreYMinSize MinYSize)]}

            %%
            case MinXSize =< X andthen MinYSize =< Y then
               %%
               {Tk.send wm(geometry self.Window X#'x'#Y)}

               %%
               %% synchronization;
               {Tk.send update(idletasks)}
               {Wait {Tk.returnInt winfo(exists self.BrowseWidget)}}

               %%
               touch
            else {BrowserWarning 'Impossible window size wrt limits'}
            end
         else true
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setXYSize is finished'}
\endif
      end

      %%
      %% create a menubar (i.e. a frame with menu buttons etc.)
      meth createMenuBar(EL ER)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::createMenuBar'}
\endif
         menuBar <- {TkTools.menubar self.Window self.BrowseWidget EL ER}
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::createMenuBar is finished'}
\endif
      end

      %%
      %% Pack the menubar;
      meth exposeMenuBar
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::exposeMenuBar'}
\endif
         %%
         case @menuBar \= InitValue then
            {Tk.send pack(@menuBar
                          side: top
                          fill: x
                          padx: IPad
                          pady: IPad
                          before: self.FrameHS)}

            %%
            touch
         else true              %  may happen?
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::exposeMenuBar is finished'}
\endif
      end

      %%
      %% Remove the menubar;
      meth closeMenuBar
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::closeMenuBar'}
\endif
         %%
         case @menuBar \= InitValue then
            %%
            {@menuBar close}

            %%
            menuBar <- InitValue
         else true
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::closeMenuBar is finished'}
\endif
      end

      %%
      %% Set the minimal possible size of the window;
      %%
      meth setMinSize
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setMinSize'}
\endif
         %%
         case self.standAlone then XMinSize YMinSize in
            %%
            case @menuBar == InitValue then
               %%
               {Tk.send update(idletasks)}

               %%
               XMinSize = {self.store read(StoreXMinSize $)}
               YMinSize = {self.store read(StoreYMinSize $)}
               %% don't use gridded text widget;
            else MFWidth in
               %% regular (standard) configuration;
               %%
               {Tk.send update(idletasks)}

               %%
               MFWidth = {Tk.returnInt winfo(reqwidth @menuBar)}

               %%
               XMinSize = 2*IPad + 2*ISmallBorder + MFWidth
               YMinSize = {self.store read(StoreYMinSize $)}
            end

            %% force the minsize of the window;
            local XSize YSize in
               YSize = {Tk.returnInt winfo(height self.Window)}
               XSize = {Tk.returnInt winfo(width self.Window)}

               %%
               {Tk.send wm(minsize self.Window XMinSize YMinSize)}

               %%
               case XMinSize =< XSize andthen YMinSize =< YSize then true
               elsecase XSize < XMinSize andthen YMinSize =< YSize then
                  {Tk.send wm(geometry self.Window XMinSize#'x'#YSize)}

                  %%
                  BrowserWindowClass , BrowserWindowClass , resetTW
               elsecase YSize < YMinSize andthen XMinSize =< XSize then
                  {Tk.send wm(geometry self.Window XSize#'x'#YMinSize)}

                  %%
                  BrowserWindowClass , resetTW
               else
                  {Tk.send wm(geometry self.Window XMinSize#'x'#YMinSize)}

                  %%
                  BrowserWindowClass , resetTW
               end
            end
         else true
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setMinSize is finished'}
\endif
      end

      %%
      %% 'Key' is a key description of the form 'ctrl(alt(m))', and
      %% 'Action' is a procedure without arguments or a description
      %% of the form 'Object#Method', where, in turn, 'Method' is a
      %% method without arguments;
      meth bindKey(key:Key action:Action)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::bindKey' # Key}
\endif
         %%
         {self.BrowseWidget tkBind(event:  {MakeEvent Key}
                                   action: Action)}
      end

%%%
%%%
%%% Actual "interface" methods;
%%%
%%%

      %%
      %% 'Gravity' must be either 'left' or 'right';
      %%
      %% 'ToMapOn' should be (and could be, of course) a chunk.
      %% De'facto it contains a mark type ('Type') and and object
      %% 'Obj':
      %%    Type#Obj
      %%
      %% 'Type' is either 'left' or 'right', stating whether the mark
      %% is a "leading" or a "tail" one respectively. Note that this
      %% mark attribute is permanent and cannot be changed.  'Obj' is
      %% an object stored under 'NewMark' index in the internal
      %% "TclsMap".
      %%
      meth putMark(Gravity ToMapOn ?NewMark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::putMark' # Gravity}
\endif
         %%
         local BW MarkName in
            BW = self.BrowseWidget
            NewMark = BrowserWindowClass , GenTcl($)
            MarkName = self.TclBase # NewMark

            %%
            {BW tk(m s MarkName self.Cursor)}

            %%
            %% use the default: right gravity;
            case Gravity \= right then {BW tk(m g MarkName Gravity)}
            else true
            end

            %%
            %% That's so simple ...
\ifdef DEBUG_TI
            local NN in
               NN = {NewName}

               %%
               case {Dictionary.condGet self.TclsMap NewMark NN} \= NN
               then {BrowserError 'BrowserWindowClass::putMark: error!'}
               else true
               end
            end
\endif
            %%
            {Dictionary.put self.TclsMap NewMark ToMapOn}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::putMark is finished:' # NewMark}
\endif
         touch
      end

      %%
      %% a special version - put the mark somewhere before;
      meth putMarkBefore(Offset ToMapOn ?NewMark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::putMarkBefore' # Offset}
\endif
         %%
         local BW MarkName in
            BW = self.BrowseWidget
            NewMark = BrowserWindowClass , GenTcl($)
            MarkName = self.TclBase # NewMark

            %%
            {BW tk(m s MarkName self.Cursor#'-'#Offset#'c')}

            %%
\ifdef DEBUG_TI
            local NN in
               NN = {NewName}

               %%
               case {Dictionary.condGet self.TclsMap NewMark NN} \= NN
               then {BrowserError 'BrowserWindowClass::putMark: error!'}
               else true
               end
            end
\endif
            %%
            {Dictionary.put self.TclsMap NewMark ToMapOn}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::putMarkBefore is finished:' # NewMark}
\endif
         touch
      end

      %%
      %% ... in addition, the mapping from the mark to an object is
      %% removed (this serves also as a strong consistency check:
      %% once a mark is removed, it cannot be removed again);
      meth unsetMark(Mark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::unsetMark' # Mark}
\endif
         %%
         UnsetMarks <- Mark|@UnsetMarks

         %%
\ifdef DEBUG_TI
         local NN in
            NN = {NewName}

            %%
            case {Dictionary.condGet self.TclsMap Mark NN} == NN
            then {BrowserError 'BrowserWindowClass::unsetMark: error!'}
            else true
            end
         end
\endif

         %%
         %% Actually, it's freed when it's removed from the
         %% dictionary;
         {Dictionary.remove self.TclsMap Mark}
         touch
      end

      %%
      meth flushUnsetMarks
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::flushUnsetMarks'}
\endif
         local ListOf OT Base in
            ListOf = @UnsetMarks
            UnsetMarks <- nil

            %%
            %% free the object state;
            OT = {Tuple.make 'o' {Length ListOf}}
            Base = self.TclBase
            {List.forAllInd ListOf
             proc{$ N Mark}
                OT.N = Base#Mark
             end}

            %%
            {self.BrowseWidget tk(m u OT)}
            BrowserWindowClass , FreeTcls(ListOf)
         end
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::flushUnsetMarks is finished'}
\endif
      end

      %%
      %% 'Mark' is a full mark set by '*Action'. After execution of
      %% the method it dissapears;
      meth mapMark(Mark $)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::mapMark is applied' # Mark}
\endif
         %%
         local BW BaseLen DropBase TakeBase BaseStr FirstIndex AMark in
            BW = self.BrowseWidget
            BaseLen = {VirtualString.length self.TclBase}
            fun {DropBase In} {List.drop In BaseLen} end
            fun {TakeBase In} {List.take In BaseLen} end
            BaseStr = {VirtualString.toString self.TclBase}

            %%
            %% if a previous mark is obtained like
            %%    '.t mark prev 1.5'
            %% then search starts just after the character to the left
            %% of '1.5' - excluding all marks sitting between '1.5'
            %% and '1.6'. But we want to get them, if any. So, as a
            %% first location we take now an absolute index of a
            %% next character:
            FirstIndex = {Tk.return o(BW index q(Mark '+1c'))}
            %% Note that the mark itself must be removed NOW;
            {BW tk(m u Mark)}

            %% 'AMark' is a mark among searched ones: we'll use its
            %% index as a reference;
            AMark = {Tk.return o(BW mark prev FirstIndex)}

            %%
            case AMark == "" then nil   % there are no marks;
            else RefIndex Pairs in
               %% 'RefIndex' is an index (not an empty string);
               RefIndex = {Tk.return o(BW index AMark)}

               %%
               %% oooh... but it's basically simple: first, get all
               %% the necessary marks, and map them to 'map values'
               %% stored in 'TclsMap'. Note that some marks may absent
               %% there: first, it's not said that all the marks must
               %% be stored in there, and, second, there are auxiliary
               %% marks of the argument category;
               Pairs =
               {Filter          % auxiliary marks, like the cursor;
                {Map            % numbers(int)  -> pairs;
                 {Map           % numbers(str)  -> numbers(int);
                  {Map          % marks(str)    -> numbers(str);
                   {Filter      % other marks (not 'self.TclBase#N');
                    {GetRepMarks BW FirstIndex RefIndex}
                    fun {$ E} {TakeBase E} == BaseStr end}
                   DropBase}
                  String.toInt}
                 fun {$ M} {Dictionary.condGet self.TclsMap M InitValue} end}
                fun {$ E} E \= InitValue end}

               %%
               case Pairs == nil then
                  %%
                  case RefIndex \= "1.0" then
                     %%
                     %% so, all the marks we have found were auxiliary -
                     %% just repeat the procedure from a previous
                     %% position:
                     {BW tk(m s Mark q(RefIndex '-1c'))}

                     %%
                     BrowserWindowClass , mapMark(Mark $)
                  else nil
                  end
               else Pairs
               end
            end
         end
      end

      %%
      %%
      meth deleteRegion(M1 M2)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::deleteRegion' # M1 # M2}
\endif
         %%
         local Base in
            Base = self.TclBase

            %%
            {self.BrowseWidget tk(del Base#M1 Base#M2)}
            touch
         end
      end

      %%
\ifdef DEBUG_RM
      meth debugShowIndices(M1 M2)
         local BW Base I1 I2 in
            BW = self.BrowseWidget
            Base = self.TclBase

            %%
            thread I1 = {Tk.return o(BW index Base#M1)} end
            thread I2 = {Tk.return o(BW index Base#M2)} end

            %%
            {Show 'DEBUG: Indices: ' # {Map [I1 I2] String.toAtom}}
         end
      end
\endif

      %%
      %%
      meth deleteForward(N)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::deleteForward' # N}
\endif
         %%
         case N > 0 then C in
            C = self.Cursor

            %%
            {self.BrowseWidget tk(del C C#'+'#N#'c')}
            touch
         else true
         end
      end

      %%
      meth deleteBackward(N)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::deleteBackward' # N}
\endif
         %%
         case N > 0 then C in
            C = self.Cursor

            %%
            {self.BrowseWidget tk(del C#'-'#N#'c' C)}
            touch
         else true
         end
      end

      %%
      %%
      meth setMarkGravity(Mark Gravity)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setMarkGravity' # Mark # Gravity}
\endif
         %%
         {self.BrowseWidget tk(m g self.TclBase#Mark Gravity)}
         touch
      end

      %%
      %% Moves the cursor to 'Mark'
      meth setCursor(Mark Column)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setCursor' # Mark}
\endif
         %%
         {self.BrowseWidget tk(m s self.Cursor self.TclBase#Mark)}
         cursorCol <- Column    % trust a given value;
      end

      %%
      %% Moves the cursor to 'Mark'
      meth setCursorOffset(Mark Offset Column)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setCursorOffset' # Mark # Offset}
\endif
         %%
         {self.BrowseWidget
          tk(m s self.Cursor self.TclBase#Mark#'+'#Offset#'c')}
         cursorCol <- Column    % trust a given value;
      end

      %%
      %%
      meth advanceCursor(N)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::advanceCursor' # N}
\endif
         %%
         case N \= 0 then
            {self.BrowseWidget tk(m s self.Cursor self.Cursor#'+'#N#'c')}
            cursorCol <- @cursorCol + N
         else true
         end
      end

      %%
      meth getCursorCol($)
         @cursorCol
      end

      %%
      meth jumpEnd
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::jumpEnd'}
\endif
         %%
         local BW EndIndex in
            BW = self.BrowseWidget

            %%
            EndIndex = {Tk.return o(BW index 'end -1lines')}
            {Wait {String.is EndIndex}}

            %%
            {BW tk(m s self.Cursor EndIndex)}
            cursorCol <- 0              % per convention:
         end
      end

      %%
      %% Insert the 'VS' into the text widget at a cursor position;
      %%
      %% Note that 'VS' may not contain 'new line' characters.
      %% Otherwise, the 'cursorCol' counter will contain a wrong
      %% value;
      %%
      meth insert(VS ?Size)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::insert'
          # {String.toAtom {VirtualString.toString VS}}}
\endif
         %%
         {self.BrowseWidget tk(ins self.Cursor VS)}
         Size = {VirtualString.length VS}
         cursorCol <- @cursorCol + Size

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::insert is finished:' # Size}
\endif
      end

      %%
      %% Insert a new line character at a cursor position, and scroll
      %% if needed;
      meth insertNL
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::insertNL'}
\endif
         %%
         {self.BrowseWidget tk(ins self.Cursor '\n')}
         cursorCol <- 0

         %%
%        case {self.store read(StoreSmoothScrolling $)} then
%           {self.BrowseWidget tk(see self.Cursor)}
%           {Tk.send update(idletasks)}
%        else true
%        end
      end

      %%
      meth removeNL
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeNL'}
\endif
         {self.BrowseWidget tk(del self.Cursor)}
      end

      %%
      %% Scroll a line the mark given + 'x' scroll to a first char;
      meth pickMark(Mark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::pickMark' # Mark}
\endif
         %%
         local M in
            M = self.TclBase#Mark

            %%
            {self.BrowseWidget tk(see M)}
                             % tk(yview scroll ~1 units)
         end
      end

      %%
      %% It *must* yield a value (and not a variable);
      %%
      %% Note: theoretically, an opaque object (that is, a chunk)
      %% should be produced here which can be packed/unpacked only
      %% within this Tcl/Tk interface (i.e. those methods are known
      %% to this Tcl/Tk interface only).
      %%
      %% But: (a) efficiency! and (b) i'm "tet-a-tet" with the
      %% Browser, i feel i may do such things;
      %%
      %% Note that a value returned is NOT a valid mark, but its's
      %% suffix, and it must an integer;
      %%
      meth GenTcl($)
\ifdef DEBUG_TI
         local Out in Out =
\endif
            %%
            %% if there is a freed tcl, then reuse it ...
            case {IsVar @TclsCache} then N in
               N = @TclCN
               TclCN <- N + 1
               N
            else N R in
               @TclsCache = N|R
               TclsCache <- R
               N
            end

            %%
\ifdef DEBUG_TI
            {Show 'BrowserWindowClass::GenTcl' # Out}
            Out
         end
\endif
      end

      %%
      meth FreeTcl(Tcl)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::FreeTcl' # Tcl}
\endif
         local NewTclsTail in
            @TclsTail = Tcl|NewTclsTail
            TclsTail <- NewTclsTail
         end
      end

      %%
      meth FreeTcls(Tcls)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::FreeTcl' # Tcls}
\endif
         local NewTclsTail in
            @TclsTail = {Append Tcls NewTclsTail}
            TclsTail <- NewTclsTail
         end
      end

      %%
      %% Highlight a region;
      %%
      meth highlightRegion(M1 M2)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::highlightRegion' # M1 # M2}
\endif
         %%
         local TB Tag in
            TB = self.TclBase
            Tag = BrowserWindowClass , GenTcl($)

            %%
            BrowserWindowClass , unHighlightRegion
            %%
            {self.BrowseWidget
             [tk(tag add TB#Tag TB#M1 TB#M2)
              tk(tag conf TB#Tag o(background:black foreground:white))]}

            %%
            HighlightTag <- Tag
         end
      end

      %%
      %%
      meth unHighlightRegion
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::unHighlightRegion'}
\endif
         %%
         case @HighlightTag == InitValue then true
         else Tag in
            Tag = @HighlightTag

            %%
            {self.BrowseWidget tk(tag del self.TclBase#Tag)}
            BrowserWindowClass , FreeTcl(Tag)

            %%
            HighlightTag <- InitValue
         end
      end

      %%
      %% Produce a graphical delimiter between lines at the cursor.
      %% After that, the cursor stays at a new line;
      meth makeUnderline(?Underline)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::makeUnderline'}
\endif
         %%
         local
            BW Mark SFont YRes TWWidth F1 F2 CWidth LineBase Canvas Tag T
         in
            BW = self.BrowseWidget
            Mark = self.Cursor

            %%
            thread              % job
               {X11ResourceCache getSmallestFont(SFont YRes)}
            end

            %%
            %% we have to do this because text widget may be even not
            %% yet mapped on the screen - and in this case 'winfo
            %% width' will yield just 0;
            {Tk.send update(idletasks)}

            %%
            %%  The 'highlightthickness' should be set to zero (while
            %% these three components constitute the width 'overhead');
            thread              % job
               TWWidth =
               {Tk.returnInt winfo(width BW)} - 2*ITWPad - 2*IBigBorder
            end

            %%
            thread S1 S2 in     % job
               [S1 S2] = {GetStrs {Tk.return o(BW xview)} CharSpace nil}

               %%
               F1 = case S1 of "0" then 0. else {String.toFloat S1} end
               F2 = case S2 of "1" then 1. else {String.toFloat S2} end
            end

            %%
            %%  In fact, this is not the same as we could want (?):
            %% we should lookup lengths of all lines which can be visible
            %% simultaneously with the underline produced here (given
            %% a current window configuration).
            CWidth = {Float.toInt ({Int.toFloat TWWidth} / (F2 - F1))}
            LineBase = {`div` YRes 2}

            %%
            Canvas = {New Tk.canvas tkInit(parent: BW
                                           width:  CWidth
                                           height: YRes
                                           highlightthickness: 0)}
            {Canvas tk('create' line 0 LineBase (CWidth - 1) LineBase
                           width: YRes stipple: gray25)}

            %%
            {BW tk(window 'create' Mark window: Canvas)}
            {BW tk(ins Mark '\n')}

            %%
            Tag = BrowserWindowClass , GenTcl($)
            T = self.TclBase # Tag
            {BW tk(tag add T Canvas q(Canvas '+1lines'))}
            {BW tk(tag conf T font:SFont)}

            %%
            Underline = {Chunk.new r(CanvasFeat:Canvas TagFeat:Tag)}
\ifdef DEBUG_TI
            {Show 'BrowserWindowClass::makeUnderline is finisehd'}
\endif
            touch
         end
      end

      %%
      %%   ... after that, a 'Underline' cannot be used anymore;
      meth removeUnderline(Underline)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeUnderline'}
\endif
         %%
         local Tag T in
            Tag = Underline.TagFeat
            T = self.TclBase # Tag

            %%
            %% it removes '\n' too;
            {self.BrowseWidget
             [tk(del p(T first) p(T last))
              tk(tag delete T)]}
            BrowserWindowClass , FreeTcl(Tag)

            %%
            touch
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeUnderline is finished'}
\endif
         end
      end

      %%
      %% Create a tcl/tk variable - for check&radio buttons/menu entries;
      %% UpdateProc is called every time when the cariable changes
      %% its value, i.e. when user clicks a button that controls it;
      %% UpdateProc is an unary procedure that gets the (actual) value
      %% of the variable as the string;
      %%
      meth createTkVar(FValue UpdateProc ?TkVar)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::createTkVar'#FValue}
\endif
         %%
         local A in
            TkVar = {New Tk.variable tkInit(FValue)}

            %%
            A = {New Tk.action tkInit(parent: self.Window
                                      action: proc{$ _ _ _}
                                                 %% is not interesting;
                                                 local A in
                                                    A = {TkVar tkReturn($)}
                                                    {UpdateProc A}
                                                 end
                                              end)}

            %%
            {Tk.send trace(variable TkVar w A)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::createTkVar is finished'}
\endif
         touch
      end

      %%
      meth setTkVar(Var Value)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setTkVar'}
\endif
         {Var tkSet(Value)}
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setTkVar is finished'}
\endif
         touch
      end

      %%
      %% Define a "postcommand" for a menu, which can be used in order
      %% o change entries labels.
      %%  'PProc' is an unary procedure which argument should be expected
      %% o be a binary procedure provided by the interface.
      %% Its first argument is a pattern ('*' is added at the end
      %% automatically), and the second one is the new label;
      %%  'Menu' is a menu path in the style 'menuA(subMenuB(subMenuC))';
      meth setPostCommand(MenuDesc UserProc)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setPostCommand'}
\endif
         %%
         case @menuBar \= InitValue then Menu SuppProc Action ActionProc in
            Menu = {DerefEntry @menuBar MenuDesc}

            %%
            proc {SuppProc Pattern Label}
               {Menu tk(entryconf Pattern#'*' label:Label)}
            end
            %%  Provide for an internal procedure since
            %% there can be no arguments;
            proc {ActionProc}
               {UserProc SuppProc}
            end

            %%
            Action = {New Tk.action tkInit(parent: Menu
                                           action: ActionProc)}
            {Menu tk(conf postcommand:Action)}
         else true              % no menus;
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setPostCommand is finished'}
\endif
         touch
      end

      %%
      %% Create a 'radio' entry in the 'Menu'
      %% (which is described in the style 'view(font(misc(menu)))');
      %% Value is the 'active' value of this (particular) radio button;
      %%
      meth addRadioEntry(MenuDesc Label TkVar Value ?EntryProc)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::addRadioEntry'#
          {String.toAtom {VirtualString.toString Label}}}
\endif
         %%
         case @menuBar == InitValue then
            EntryProc = proc {$ _ _} true end
         else Menu in
            %%
            %%  This can be also done by 'Tk.menuentry.radiobutton',
            %% but i do it so (as an example, if you want);

            %%
            Menu = {DerefEntry @menuBar MenuDesc}

            %%
            {Menu tk(add radio label:Label value:Value variable:TkVar)}

            %%
            EntryProc =
            proc {$ Action Arg}
               case Action
               of state  then {Menu tk(entryconf Label#'*' state: Arg)}
               [] label  then {Menu tk(entryconf Label#'*' label: Arg)}
               [] delete then {Menu tk(del Label#'*')}
               else {BrowserError 'Undefined action for a menu entry'}
               end
            end

            %%
            touch
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::addRadioEntry is finished'}
\endif
      end

      %%
      meth commandEntriesEnable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesEnable'}
\endif
         {ProcessEntries @menuBar Arg tk(entryconf state:normal)}

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesEnable is finished'}
\endif
         touch
      end

      %%
      meth commandEntriesDisable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesDisable'}
\endif
         {ProcessEntries @menuBar Arg tk(entryconf state:disabled)}

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesDisable is finished'}
\endif
         touch
      end

      %%
      meth buttonsEnable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsEnable'}
\endif
         {ProcessEntries @menuBar Arg tk(conf state:normal)}

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsEnable is finished'}
\endif
         touch
      end

      %%
      meth buttonsDisable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsDisable'}
\endif
         {ProcessEntries @menuBar Arg tk(conf state:disabled)}

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsDisable is finished'}
\endif
         touch
      end

      %%
      meth checkButtonOn(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOn'}
\endif
         {ProcessEntries @menuBar Arg tk(entryconf state:nornal)}

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOn is finished'}
\endif
         touch
      end

      %%
      meth checkButtonOff(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOff'}
\endif
         {ProcessEntries @menuBar Arg tk(entryconf state:disabled)}

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOff is finished'}
\endif
         touch
      end

      %%
   end

   %%
   %%
   %% Window(s) for messages (warnings, errors);
   %%
   class MessageWindowClass from UrObject
      %%
      attr
         window:            InitValue
         messageWidget:     InitValue
         fb:                InitValue

      %%
      %%
      meth createMessageWindow
\ifdef DEBUG_TI
         {Show 'MessageWindowClass::createMessageWindow'}
\endif
         %%
         local
            Window         %
            MessageWidget  %  text widget for messages;
            VS             %
            FB             %  buttons' frame;
            CloseAction    %
         in
            %%
            window <- Window
            messageWidget <- MessageWidget
            fb <- FB

            %%
            Window = {New MyToplevel tkInit(withdraw: True)}

            %%
            CloseAction = {New Tk.action
                           tkInit(parent: Window
                                  action: self # closeWindow)}

            {Tk.batch
             [wm(title(Window IMTitle))
              wm(iconname(Window IMITitle))
              wm(iconbitmap(Window '@'#IMIBitmap))
              %%  {Tk.wm iconmask(Window '@'#IMIBMask)}
              wm(minsize Window IMXMinSize IMYMinSize)
              wm(protocol(Window 'WM_DELETE_WINDOW' CloseAction))]}

            %%
            MessageWidget = {New Tk.text tkInit(parent: Window
                                                setgrid: 'true'
                                                bd: IBigBorder
                                                relief: ITextRelief
                                                padx: ITWPad
                                                pady: ITWPad
                                                height: IMHeight
                                                width: IMWidth
                                                insertontime: 0
                                                background: IBackGround
                                                foreground: IForeGround
                                                highlightthickness: 0)}

            %%  choose a font;
            {FoldL [ITWFont1 ITWFont2 ITWFont3]
             fun {$ Proceed IFont}
                case
                   Proceed andthen
                   {X11ResourceCache tryFont(IFont.font $)}
                then
                   {MessageWidget tk(conf font:IFont.font)}
                   False
                else Proceed
                end
             end
             True _}

            %%
            VS = {New Tk.scrollbar tkInit(parent: Window
                                          relief: IFrameRelief
                                          bd: IBigBorder
                                          width: ISWidth
                                          highlightthickness: 0)}
            FB = {New Tk.frame tkInit(parent: Window
                                      relief: IFrameRelief
                                      bd: ISmallBorder
                                      highlightthickness: 0)}
            {Tk.addYScrollbar MessageWidget VS}

            %%
            {Tk.batch
             [pack(VS fill: y padx: IPad pady: IPad side: right)
              pack(FB fill: y padx: IPad pady: IPad side: left)
              pack(MessageWidget fill: both padx: IPad pady: IPad
                   side: bottom expand: yes)
              bindtags(MessageWidget q(MessageWidget))
             ]}

            %%
\ifdef DEBUG_TI
            {Show 'MessageWindowClass::createMessageWindow is finished'}
\endif
            touch
         end
      end

      %%
      %% Put a new button on the buttons frame;
      %% Note that a calling procedure should treat the 'Button'
      %% as an atomic value and use it only for 'confButton' messages;
      %%
      meth pushButton(Text Action ?Button)
         case @window == InitValue then Button = InitValue
         else MessageWidget ResStr in
            MessageWidget = @messageWidget

            %%
            Button = {New Tk.button tkInit(parent: @fb
                                           text: Text
                                           action: Action
                                           width: IButtonWidth
                                           relief: IButtonRelief
                                           highlightthickness: 0
                                           padx: IButtonPad
                                           pady: IButtonPad
                                           bd: ISmallBorder)}

            %%  choose a font;
            {FoldL [IBFont1 IBFont2 IBFont3 IReservedFont]
             fun {$ Proceed IFont}
                case
                   Proceed andthen
                   {X11ResourceCache tryFont(IFont $)}
                then
                   {MessageWidget tk(conf font:IFont)}
                   False
                else Proceed
                end
             end
             True _}

            %%
            {Tk.send pack(Button side: top fill: x padx: IPad pady: IPad)}
         end
      end

      %%
      %%
      meth showIn(VS)
         case @window == InitValue then true
         else MyScreen LWScreen LeaderWindow RealLWindow in
            {@messageWidget [tk(ins insert VS)
                             tk(ins insert '\n')
                             tk(yview 'insert-2lines')]}

            %%
            %%  Now, let's try to move it to a (current) leader window;
            LeaderWindow = @leaderWindow
            case LeaderWindow == InitValue then
               %%  leader is gone?
               {Tk.batch [update wm(deiconify @window)]}
            else
               MyScreen = {Tk.return winfo(screen @window)}
               LWScreen = {Tk.return winfo(screen LeaderWindow)}

               %%
               case MyScreen == LWScreen then
                  %%  leave it where it is - we cannot move it anyway;
                  {Tk.batch [update wm(deiconify @window)]}
               else
                  %%  the same screen;
                  RealLWindow = {Tk.return winfo(toplevel LeaderWindow)}

                  %%
                  case {String.is RealLWindow} then Geom X Y in
                     Geom = {Tk.return wm(geometry RealLWindow)}
                     [_ X Y] = {GetStrs Geom &+ nil}

                     %%
                     {Tk.batch [update
                                wm(geometry @window
                                   '+'#(X + IMWXOffset)#
                                   '+'#(Y + IMWYOffset))
                                wm(deiconify @window)]}
                  end
               end
            end
         end
      end

      %%
      %%
      meth clear
         case @window == InitValue then true
         else {@messageWidget tk(del p(1 0) insert)}
         end
      end

      %%
      %% close the top level widnow;
      %%
      meth closeWindow
         case @window == InitValue then true
         else
            {@window close}

            %%
            window <- InitValue
            messageWidget <- InitValue
            fb <- InitValue
         end
      end
   end

   %%
   %% Help Window;
   %%
   class HelpWindowClass from UrObject
      %%
      attr
         window:            InitValue
         messageWidget:     InitValue
         fb:                InitValue

      %%
      %%
      meth createHelpWindow(screen: Screen)
\ifdef DEBUG_TI
         {Show 'HelpWindowClass::createHelpWindow'}
\endif
         %%
         local
            Window         %
            MessageWidget  %  text widget;
            VS             %
            CloseAction    %
         in
            %%
            window <- Window
            messageWidget <- MessageWidget

            %%
            Window =
            {New MyToplevel case Screen == InitValue
                            then tkInit(withdraw:True)
                            else tkInit(withdraw:True screen:Screen)
                            end}

            %%
            CloseAction = {New Tk.action tkInit(parent: Window
                                                action: self#close)}

            %%
            {Tk.batch
             [wm(title(Window IHTitle))
              wm(iconname(Window IHITitle))
              wm(iconbitmap(Window '@'#IIBitmap))
              %%  {Tk.wm iconmask(Window '@'#IMIBMask)}
              wm(geometry Window IHXSize#x#IHYSize)
              wm(protocol(Window 'WM_DELETE_WINDOW' CloseAction))]}

            %%
            MessageWidget = {New Tk.text tkInit(parent: Window
                                % setgrid: 'true'
                                                bd: IBigBorder
                                % height: IMHeight
                                % width: IMWidth
                                                relief: ITextRelief
                                                padx: ITWPad
                                                pady: ITWPad
                                                insertontime: 0
                                                background: IBackGround
                                                foreground: IForeGround
                                                highlightthickness: 0)}

            %%  choose a font;
            {FoldL [ITWFont1 ITWFont2 ITWFont3]
             fun {$ Proceed IFont}
                case
                   Proceed andthen
                   {X11ResourceCache tryFont(IFont.font $)}
                then
                   {MessageWidget tk(conf font:IFont.font)}
                   False
                else Proceed
                end
             end
             True _}

            %%
            VS = {New Tk.scrollbar tkInit(parent: Window
                                          relief: IFrameRelief
                                          bd: IBigBorder
                                          width: ISWidth
                                          highlightthickness: 0)}
            {Tk.addYScrollbar MessageWidget VS}

            %%
            {Tk.batch
             [pack(VS fill: y padx: IPad pady: IPad side: right)
              pack(MessageWidget fill: both padx: IPad pady: IPad
                   side: bottom expand: yes)
              bindtags(MessageWidget q(MessageWidget))
             ]}

            %%
            %% sync;
            {Wait Window}
            {Wait MessageWidget}

            %%
            {Tk.send wm(deiconify Window)}

            %%
\ifdef DEBUG_TI
            {Show 'HelpWindowClass::createHelpWindow is finished'}
\endif
            touch
         end
      end

      %%
      %%
      meth showIn(VS)
         case @window == InitValue then true
         else {@messageWidget [tk(ins insert VS) tk(ins insert '\n')]}
                             % tk(yview 'insert-2lines')
         end
      end

      %%
      %%
      meth close
         case @window == InitValue then true
         else
            {@window close}

            %%
            Object.base , close
         end
      end

      %%
   end
   %%
   %%

   %%
end
