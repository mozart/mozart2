%%%
%%% Authors:
%%%   Konstantin Popov
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Konstantin Popov, 1997
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
   Window       = {NewName}     %

   %%
   ProcessEntries
   DerefEntry
   %%
   MakeEvent

   %%
   GetRepMarks

   %%
   CanvasFeat   = {NewName}     %
   TagFeat      = {NewName}     %

   %%
   FoldL_Obj

   %%
   Oz2Tcl
   Tcl2Oz

   %%
   MakeDistFrame

   %%
   HelperTransient
   TransientManager

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
      case Es of nil then skip
      [] E|Er then {ProcessEntries M E W} {ProcessEntries M Er W}
      else
         if {IsAtom Es} then {M.Es W}
         else {ProcessEntries M.{Label Es} Es.1 W}
         end
      end
   end
   fun {DerefEntry M E}
      if {IsAtom E} then M.E
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
         [] 'lock'(R)    then 'Lock-' # {MakeEventPattern R}
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
         if M == "" orelse {Tk.return o(BW index M)} \= RefIndex
         then nil
         else M|{GetRepMarks BW M RefIndex}
         end
      end
   end

   %%
   %% Loop over list ('FoldL' fashion) with method applications;
   fun {FoldL_Obj Self Xs M Z}
      case Xs
      of X|Xr then {FoldL_Obj Self Xr M {Self M(Z X $)}}
      [] nil  then Z
      end
   end

   %%
   %%  (Oz) Names cannot be passed around with tcl/tk;
   fun {Oz2Tcl OzValue}
      case OzValue
      of true              then 'tcl_True'
      [] false             then 'tcl_False'
      [] !TreeRep          then 'tcl_treeRep'
      [] !GraphRep         then 'tcl_graphRep'
      [] !MinGraphRep      then 'tcl_minGraphRep'
      [] !Expanded         then 'tcl_Expanded'
      [] !Filled           then 'tcl_Filled'
      [] !NoArity          then 'tcl_NoArity'
      [] !TrueArity        then 'tcl_TrueArity'
      else
         {BrowserError 'Oz2Tcl: unknown value!'}
         'tcl_False'
      end
   end
   %%
   fun {Tcl2Oz TclValue}
      case TclValue
      of 'tcl_True'        then true
      [] 'tcl_False'       then false
      [] 'tcl_treeRep'     then TreeRep
      [] 'tcl_graphRep'    then GraphRep
      [] 'tcl_minGraphRep' then MinGraphRep
      [] 'tcl_Expanded'    then Expanded
      [] 'tcl_Filled'      then Filled
      [] 'tcl_NoArity'     then NoArity
      [] 'tcl_TrueArity'   then TrueArity
      else
         {BrowserError 'Tcl2Oz: unknown value!'}
         false
      end
   end

   %%
   fun {MakeDistFrame P}
      {New Tk.frame tkInit(parent:P width:30)}
   end

   %%
   class HelperTransient
      from Tk.toplevel

      %%
      %% don't use argument's (i.e. original) coordinates;
      meth make(master:Master text:Text)
         local TF X Y SW SH W H in
            %%
            Tk.toplevel , tkInit(parent:Master bd:1 withdraw:true)
            {Tk.send wm(transient self Master)}
            {Tk.send wm(overrideredirect self true)}
            TF = {New Tk.label tkInit(parent:self text:Text)}
            {Tk.send pack(TF)}

            %%
            {Tk.send update(idletasks)}
            X = {Tk.returnInt winfo(pointerx Master)}
            Y = {Tk.returnInt winfo(pointery Master)}
            SW = {Tk.returnInt winfo(screenwidth Master)}
            SH = {Tk.returnInt winfo(screenheight Master)}
            W = {Tk.returnInt winfo(reqwidth self)}
            H = {Tk.returnInt winfo(reqheight self)}

            %%
            if X > 0 andthen Y > 0 then XLoc YLoc in
               XLoc = if X + IXTransDist + W > SW then X - W - IXTransDist
                      else X + IXTransDist
                      end
               YLoc = if Y + IYTransDist + H > SH then Y - H - IYTransDist
                      else Y + IYTransDist
                      end
               {Tk.send wm(geometry self '+'#XLoc#'+'#YLoc)}
            else skip   % no geometry - let WM to decide;
            end

            %%
            {Tk.send wm(deiconify self)}
         end
      end

      %%
      meth close
         Tk.toplevel ,  tkClose
      end
   end

   %%
   class TransientManager
      from Object.base
      prop locking
      feat
         Text                   % text to be shown;
         Master                 % master window;
      attr
         Helper                 % helper object;
         Req
         SeqNum

      %%
      meth init(master:IMaster text:IText follow:IObj)
         self.Text = IText
         self.Master = IMaster
         Helper <- unit
         Req <- false
         SeqNum <- 0

         %%
         %% ... what's more essential is that it cancels started
         %% transaction;
         thread
            {Wait IObj.closed}
            {self remove}
         end
      end

      %%
      meth make
         if
            lock
               if @Req then false
               else Req <- true true
               end
            end
         then N = @SeqNum + 1 in
            %%
            SeqNum <- N
            {Delay 500}

            %%
            lock
               if @Req andthen @SeqNum == N then
                  Helper <- {New HelperTransient
                             make(master:self.Master text:self.Text)}
               end
            end
         end
      end

      %%
      meth remove
         lock
            if @Helper \= unit then
               {@Helper close}
            end

            %%
            Helper <- unit
            Req <- false
            SeqNum <- @SeqNum + 1
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
   class BrowserWindowClass
      from Object.base BatchObject MyClosableObject
      %%

      %%
      feat
      %% given by creation;
         browserObj             %
         store                  % cache it directly;
         standAlone             % 'true'/'false';

      %%
      %% widgets;
      %%
      %% static, i.e. a 'BrowserWindowClass' cannot re-create
      %% it's widget;
         !Window                % that's a leader for dialogs;
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
         buttons:      buttons          % record with buttons;
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
      %%
         ScrollingOn:  true             % a boolean saying either
                                        % scrolling is enabled or not;

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
         if WindowIn == InitValue then
            WindowLocal XSize YSize RootXSize RootYSize
         in
            self.standAlone = true
            XSize = {self.store read(StoreXSize $)}
            YSize = {self.store read(StoreYSize $)}

            %%
            WindowLocal =
            {New MyToplevel if Screen == InitValue
                            then tkInit('class': 'OzTools'
                                        withdraw: true
                                        delete: BObj#close)
                            else tkInit('class': 'OzTools'
                                        withdraw: true
                                        delete: BObj#close
                                        screen: Screen)
                            end}

            %%
            {Tk.send update(idletasks)}
            {Tk.returnInt winfo(screenheight WindowLocal) RootYSize}
            {Tk.returnInt winfo(screenwidth WindowLocal) RootXSize}

            %%
            {Tk.batch
             [wm(maxsize WindowLocal (RootXSize) (RootYSize))
              wm(iconname WindowLocal IITitle)
              wm(iconbitmap WindowLocal '@'#IIBitmap)
              %% wm(iconmask WindowLocal '@'#IIBMask)
              wm(geometry WindowLocal XSize#x#YSize)]}

            %%
            {Tk.send wm(title WindowLocal ITitle)}

            %%
            self.Window = WindowLocal
         else
            self.standAlone = false
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

            %%
            MyHandler
            MyTkTextButton1
            SelfBWO
         in
            %%
            W = self.Window

            %%
            %%
            FHS = {New Tk.frame tkInit(parent: W
                                       bd: 0
                                       highlightthickness: 0)}
            FHS_HS = {New Tk.scrollbar tkInit(parent: FHS
                                              relief: IFrameRelief
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
                                     relief: ITextRelief
                                     wrap: none
                                     % insertontime: 0
                                     background: IBackGround
                                     foreground: IForeGround
                                     highlightthickness: 0)}

            %%
            self.BrowseWidget = BW
            self.FrameHS = FHS

            %%
            %% Select a font from ITWFont?, and store it;
            {Wait {FoldL_Obj self
                   [{Store read(StoreTWFont $)} ITWFont1 ITWFont2 ITWFont3]
                   TryFont
                   true}}

            %%
            %% scrollbars;
            SelfBWO = self
            MyHandler=
            {New
             class from Object.base
               meth m(...) = Mess
                  case Mess of m("moveto" F) then
                      %% "moveto Fraction" - just feed it further;
                     {BW tk(yview 'moveto' F)}
                  elseof       m("scroll" N Units) andthen case Units
                                                           of "page"  then true
                                                           [] "pages" then true
                                                           else false end
                  then
                     Last FT FB Current Kind NewMark Pairs
                  in
                     %% "scroll N Type" - filter the 'pages' case;
                     %%
                     Kind =
                     case N of &-|_ then 'backward' else 'forward' end

                     %%
                     Last    = {Tk.returnInt o(BW index 'end')}
                     [FT FB] = {Tk.returnListFloat o(BW yview)}

                     %%
                     %% that's the line just before the top one in
                     %% the view;
                     Current =
                     {Float.toInt
                      {Float.floor
                       case Kind of 'forward' then FB else FT end
                       * {Int.toFloat Last}}}

                     %%
                     NewMark = {Tk.getId}
                     {BW tk(m s NewMark p(Current 0))}
                     Pairs = {SelfBWO mapMark(NewMark $)}

                     %%
                     local TO = {GetTargetObj Pairs} in
                        if TO \= InitValue then
                           {SelfBWO.browserObj ScrollTo(TO Kind)}
                        end
                     end
                  elseof       m("scroll" N "units") then
                     %% basically, there is only 'units' type left;
                     {BW tk(yview 'scroll' N 'units')}
                  else {BrowserError 'Unknown type of scrollbar operation!'}
                  end
               end
             end
             noop}

            %%
            VS = {New Tk.scrollbar tkInit(parent: W
                                          relief: IFrameRelief
                                          width: ISWidth
                                          highlightthickness: 0
                                          action: MyHandler # m)}
            %%
            %% The following will not work because we 'addYScrollbar'
            %% redefines 'command' for the scrollbar;
            %% {Tk.addYScrollbar BW VS}
            {BW tk(conf yscrollcommand: s(VS set))}

            %%
            %% An "interesting" thing: b2-motion does not work since
            %% it handler expects immediate (forced through "update
            %% idletasks") reaction from widget, which is impossible
            %% in our case. So, i just disable it;
            {Tk.batch [bindtags(VS q(VS 'Scrollbar'))
                       bind(VS '<B2-Motion>' 'break')]}

            %%
            {Tk.addXScrollbar BW FHS_HS}

            %%
\ifdef DEBUG_TI
            {Show 'BrowserWindowClass::init: widgets complete;'}
\endif

            %%
            MyTkTextButton1 = {Tk.getId}

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
                   q(MyTkTextButton1
                     v(
                        '%W %x %y; %W tag remove sel 0.0 end'
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
              bind(BW '<<Copy>>'
                   q(v(
                        'tk_textCopy %W'
                    )))

              %%
              %% X11 selection - shift-buttons[move];
              %% actually, they are not Motif-like, but something like
              %% 'xterm';
              %%
              %%  exclude '$w mark set insert @$x,$y';
              o('proc' MyTkTextButton1 q(w x y)
                    /*
                 end            % sh$t!!!
              */
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
                  local NewMark Pairs in
                     NewMark = {Tk.getId}
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

                     %%
                     local TO = {GetTargetObj Pairs} in
                        if TO \= InitValue then
                           {StreamObj enq(processEvent(TO Handler Arg))}
                        end
                     end
                  end
               end

               %%
               proc {ButtonClickAction B X Y}
                  %%
                  case B of '1' then {self setScrolling(X Y)}
                  else skip
                  end

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
            {BW tkBind(event:  '<ButtonPress>'
                       action: ButtonClickAction
                       args:   [atom('b') int('x') int('y')])}
            {BW tkBind(event:  '<Double-ButtonPress>'
                       action: DButtonClickAction
                       args:   [atom('b') int('x') int('y')])}
                 %%
                 %%  some special bindings for browse text widget;
            {BW tkBind(event:  '<Configure>'
                       action: self#resetTW)}

            %%
            %%  toplevel-widget;
            {W tkBind(event: '<FocusIn>'
                      action: proc {$}
                                 {self focusIn}
                                 {BrowserMessagesFocus self.Window}
                              end)}
            {W tkBind(event: '<FocusOut>'
                      action: proc {$}
                                 %%  no special action;
                                 {BrowserMessagesNoFocus}
                              end)}

            %%
            %% Windows: need an explicit "copy" key stroke:
            local
               PN =
               {List.take {Atom.toString {Property.get 'platform'}.name} 3}
            in
               if PN == "win" then
                  {Tk.send event(add '<<Copy>>' '<Control-q>')}
               else skip
               end
            end

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
      meth TryFont(Proceed IFont $)
         if Proceed then
            if BrowserWindowClass , setTWFont(IFont $) then false
            else true
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
         if self.standAlone then {self.Window tkClose}
         end

         %%
         % Object.closable , close
         MyClosableObject , close
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
         if self.standAlone then {Tk.send wm(deiconify self.Window)}
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
         skip
         %%
         %%  Tk 4.0 does not require any special action;
         %% {Tk.send focus(self.BrowseWidget)}
         %%
      end

      %%
      %% Yields 'true' if the font exists;
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
      %% Yields 'true' if a try was successful;
      meth setTWFont(NewFont $)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setTWFont'#NewFont}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if BrowserWindowClass , tryFont(NewFont $) then
            %%
            {self.BrowseWidget tk(conf font:NewFont.font)}
            {self.store store(StoreTWFont NewFont)}
            BrowserWindowClass , resetTW

            %%
            true
         else false
         end
      end

      %%
      %% A 'feedback' for browser providing for an actual tw width;
      meth resetTW
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::resetTW'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local Font TWWidth WWidth WHeight XRes in
            {self.store read(StoreTWFont Font)}

            %%
            {Tk.send update(idletasks)}

            %%
            TWWidth = {Tk.returnInt winfo(width self.BrowseWidget)}
            WWidth = {Tk.returnInt winfo(width self.Window)}
            WHeight = {Tk.returnInt winfo(height self.Window)}

            %%
            {Wait TWWidth} {Wait WWidth} {Wait WHeight}
            {self.store store(StoreXSize WWidth)}
            {self.store store(StoreYSize WHeight)}

            %%
            XRes = if Font.xRes == 0 then
                      BrowserWindowClass , getFontRes(Font $ _)
                   else Font.xRes
                   end

            %%
            if XRes \= 0 then
               thread           % job
                  {self.browserObj
                   SetTWWidth((TWWidth - 2*ITWPad - 2*IBigBorder) div XRes)}
               end
            else skip           % we cannot do anything anyway;
            end
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::resetTW is finished'}
\endif
      end

      %%
      %% Set the geometry of a browser's window, provided it is
      %% not smaller than a minimal possible one
      %% (and, of course, this is a 'stand alone' browser);
      %%
      meth setXYSize
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setXYSize'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if self.standAlone then X Y MinXSize MinYSize in
            {self.store [read(StoreXMinSize MinXSize)
                         read(StoreYMinSize MinYSize)
                         read(StoreXSize X)
                         read(StoreYSize Y)]}

            %%
            if MinXSize =< X andthen MinYSize =< Y then
               %%
               {Tk.send wm(geometry self.Window X#'x'#Y)}

               %%
               %% synchronization;
               {Tk.send update(idletasks)}
               {Wait {Tk.returnInt winfo(exists self.BrowseWidget)}}
            else {BrowserWarning 'Impossible window size wrt limits'}
            end
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setXYSize is finished'}
\endif
      end

      %%
      %% create a menubar (i.e. a frame with menu buttons etc.)
      meth createMenuBar(EL)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::createMenuBar'}
\endif
         menuBar <- {TkTools.menubar self.Window self.BrowseWidget EL nil}
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
         if @menuBar \= InitValue then
            {Tk.send pack(@menuBar
                          side: top
                          fill: x
                          padx: IPad
                          pady: IPad
                          before: self.FrameHS)}
         else skip              %  may happen?
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
         if @menuBar \= InitValue then
            %%
            {@menuBar tkClose}

            %%
            menuBar <- InitValue
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if self.standAlone then XMinSize YMinSize in
            %%
            if @menuBar == InitValue then
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
               XMinSize = {Max
                           (2*IPad + 2*ISmallBorder + MFWidth)
                           {self.store read(StoreXMinSize $)}}
               YMinSize = {self.store read(StoreYMinSize $)}
            end

            %% force the minsize of the window;
            local XSize YSize in
               YSize = {Tk.returnInt winfo(height self.Window)}
               XSize = {Tk.returnInt winfo(width self.Window)}
               {Wait XSize} {Wait YSize}

               %%
               {Tk.send wm(minsize self.Window XMinSize YMinSize)}

               %%
               if XMinSize =< XSize andthen YMinSize =< YSize then skip
               elseif XSize < XMinSize andthen YMinSize =< YSize then
                  {Tk.send wm(geometry self.Window XMinSize#'x'#YSize)}

                  %%
                  BrowserWindowClass , resetTW
               elseif YSize < YMinSize andthen XMinSize =< XSize then
                  {Tk.send wm(geometry self.Window XSize#'x'#YMinSize)}

                  %%
                  BrowserWindowClass , resetTW
               else
                  {Tk.send wm(geometry self.Window XMinSize#'x'#YMinSize)}

                  %%
                  BrowserWindowClass , resetTW
               end
            end
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
            if Gravity \= right then {BW tk(m g MarkName Gravity)}
            end

            %%
            %% That's so simple ...
\ifdef DEBUG_TI
            local NN in
               NN = {NewName}

               %%
               if {Dictionary.condGet self.TclsMap NewMark NN} \= NN
               then {BrowserError 'BrowserWindowClass::putMark: error!'}
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
      end

      %%
      %% a special version - put the mark somewhere before;
      meth putMarkBefore(Offset ToMapOn ?NewMark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::putMarkBefore' # Offset}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
               if {Dictionary.condGet self.TclsMap NewMark NN} \= NN
               then {BrowserError 'BrowserWindowClass::putMark: error!'}
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
      end

      %%
      %% ... in addition, the mapping from the mark to an object is
      %% removed (this serves also as a strong consistency check:
      %% once a mark is removed, it cannot be removed again);
      meth unsetMark(Mark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::unsetMark' # Mark}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         UnsetMarks <- Mark|@UnsetMarks

         %%
\ifdef DEBUG_TI
         local NN in
            NN = {NewName}

            %%
            if {Dictionary.condGet self.TclsMap Mark NN} == NN
            then {BrowserError 'BrowserWindowClass::unsetMark: error!'}
            end
         end
\endif

         %%
         %% Actually, it's freed when it's removed from the
         %% dictionary;
         {Dictionary.remove self.TclsMap Mark}
      end

      %%
      meth flushUnsetMarks
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::flushUnsetMarks'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
            if AMark == "" then nil   % there are no marks;
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
               if Pairs == nil then
                  %%
                  if RefIndex \= "1.0" then
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local Base in
            Base = self.TclBase

            %%
            {self.BrowseWidget tk(del Base#M1 Base#M2)}
         end
      end

      %%
\ifdef DEBUG_RM
      meth debugShowIndices(M1 M2)
         local BW Base I1 I2 in
            BW = self.BrowseWidget
            Base = self.TclBase

            %%
            I1 = {Tk.return o(BW index Base#M1)}
            I2 = {Tk.return o(BW index Base#M2)}

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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if N > 0 then C in
            C = self.Cursor

            %%
            {self.BrowseWidget tk(del C C#'+'#N#'c')}
         end
      end

      %%
      meth deleteBackward(N)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::deleteBackward' # N}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if N > 0 then C in
            C = self.Cursor

            %%
            {self.BrowseWidget tk(del C#'-'#N#'c' C)}
         end
      end

      %%
      %%
      meth setMarkGravity(Mark Gravity)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setMarkGravity' # Mark # Gravity}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         {self.BrowseWidget tk(m g self.TclBase#Mark Gravity)}
      end

      %%
      %% Moves the cursor to 'Mark'
      meth setCursor(Mark Column)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setCursor' # Mark}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if N \= 0 then
            {self.BrowseWidget tk(m s self.Cursor self.Cursor#'+'#N#'c')}
            cursorCol <- @cursorCol + N
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local BW EndIndex in
            BW = self.BrowseWidget

            %%
            EndIndex = {Tk.return o(BW index 'end -1lines')}

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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         {self.BrowseWidget tk(ins self.Cursor '\n')}
         cursorCol <- 0
      end

      %%
      meth removeNL
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeNL'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         {self.BrowseWidget tk(del self.Cursor)}
      end

      %%
      meth setScrolling(X Y)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setScrolling' # X # Y}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local V in
            ScrollingOn <- V

            %%
            %% either we stay at the end of the text;
            {self.BrowseWidget tk(m s insert '@'#X#','#Y)}
            V = {Tk.returnInt
                 o(self.BrowseWidget comp 'insert+1li' '==' 'end')} == 1
         end
      end

      %%
      %% Scroll to a the containing 'Mark';
      meth pickMark(Mark How)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::pickMark' # Mark # How}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         {self.BrowseWidget
          case How of 'top' then tk(yview self.TclBase#Mark)
          else tk(yview '-pickplace' self.TclBase#Mark)
          end}
      end

      %%
      %% ... but only if scrolling is enabled;
      meth scrollToMark(Mark)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::scrollToMark' # Mark}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @ScrollingOn then {self pickMark(Mark 'any')}
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
            if {IsFree @TclsCache} then N in
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local TB Tag in
            TB = self.TclBase
            Tag = BrowserWindowClass , GenTcl($)

            %%
            BrowserWindowClass , unHighlightRegion
            %%
            {self.BrowseWidget tk(tag add TB#Tag TB#M1 TB#M2)}
            {self.BrowseWidget tk(tag conf TB#Tag
                                  background:IEntryColor foreground:black)}

            %%
            HighlightTag <- Tag
         end
      end

      %%
      %%
      meth unHighlightRegion
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::unHighlightRegion'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @HighlightTag \= InitValue then Tag in
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local
            BW Mark SFont YRes TWWidthS TWWidth
            F1 F2 CWidth LineBase Canvas Tag T
         in
            BW = self.BrowseWidget
            Mark = self.Cursor

            %%
            YRes =
            {Max {X11ResourceCache getSmallestFont(SFont $)}
             local
                PN =
                {List.take {Atom.toString {Property.get 'platform'}.name} 3}
             in
                if PN == "win"
                then TkWindowsMinCanvasWidth
                else TkX11MinCanvasWidth
                end
             end}

            %%
            %% we have to do this because text widget may be even not
            %% yet mapped on the screen - and in this case 'winfo
            %% width' will yield just 0;
            {Tk.send update(idletasks)}

            %%
            %%  The 'highlightthickness' should be set to zero (while
            %% these three components constitute the width
            %% 'overhead');
            TWWidthS = {Tk.return winfo(width BW)}
            if {String.isInt TWWidthS} then
               TWWidth = {String.toInt TWWidthS} - 2*ITWPad - 2*IBigBorder
            elseif MyClosableObject , isClosed($) then
               {Exception.raiseError
                browser('Closed window object is applied!')}
            else
               {Exception.raiseError browser('Invalid "width" string:'
                                             {String.toAtom TWWidthS})}
            end

            [F1 F2] = {Tk.returnListFloat o(BW xview)}

            %%
            %%  In fact, this is not the same as we could want (?):
            %% we should lookup lengths of all lines which can be visible
            %% simultaneously with the underline produced here (given
            %% a current window configuration).
            CWidth = {Float.toInt ({Int.toFloat TWWidth} / (F2 - F1))}
            LineBase = YRes div 2

            %%
            Canvas = {New Tk.canvas tkInit(parent: BW
                                           width:  CWidth
                                           bg:     IBackGround
                                           height: YRes-1
                                           highlightthickness: 0)}
            {Canvas tk('create' line 0 LineBase (CWidth - 1) LineBase
                           width: YRes-1 stipple: gray25)}

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
         end
      end

      %%
      %%   ... after that, a 'Underline' cannot be used anymore;
      meth removeUnderline(Underline)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeUnderline'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         local Tag T in
            Tag = Underline.TagFeat
            T = self.TclBase # Tag

            %%
            %% it removes '\n' too;
            {self.BrowseWidget tk(del p(T first) p(T last))}
            {self.BrowseWidget tk(tag delete T)}
            BrowserWindowClass , FreeTcl(Tag)

            %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeUnderline is finished'}
\endif
         end
      end

      %%
      meth setTkVarUpdateProc(TkVar UpdateProc)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setTkVarUpdateProc is applied'}
\endif
         local
            A = {New Tk.action tkInit(parent: self.Window
                                      action: proc{$ _ _ _}
                                                 %% is not interesting;
                                                 local A in
                                                    A = {TkVar tkReturn($)}
                                                    {UpdateProc A}
                                                 end
                                              end)}
         in
            %%
            {Tk.send trace(variable TkVar w A)}
         end
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setTkVarUpdateProc is finished'}
\endif
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         TkVar = {New Tk.variable tkInit(FValue)}
         BrowserWindowClass , setTkVarUpdateProc(TkVar UpdateProc)

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::createTkVar is finished'}
\endif
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
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @menuBar \= InitValue then Menu SuppProc Action ActionProc in
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
         else skip              % no menus;
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::setPostCommand is finished'}
\endif
      end

      %%
      %% Create a 'radio' entry in the 'Menu'
      %% (which is described in the style 'view(font(misc(menu)))');
      %% Value is the 'active' value of this (particular) radio button;
      %%
      meth addRadioEntry(MenuDesc Label TkVar Value)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::addRadioEntry'#
          {String.toAtom {VirtualString.toString Label}}}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @menuBar \= InitValue then Menu in
            %%
            %%  This can be also done by 'Tk.menuentry.radiobutton',
            %% but i do it so (as an example, if you want);

            %%
            Menu = {DerefEntry @menuBar MenuDesc}

            %%
            {Menu tk(add radio label:Label value:Value variable:TkVar)}

            %%
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::addRadioEntry is finished'}
\endif
      end

      %%
      meth removeRadioEntry(MenuDesc N)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeRadioEntry'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @menuBar \= InitValue then Menu in
            %%
            %%  This can be also done by 'Tk.menuentry.radiobutton',
            %% but i do it so (as an example, if you want);

            %%
            Menu = {DerefEntry @menuBar MenuDesc}

            %%
            {Menu tk(delete N)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::removeRadioEntry is finished'}
\endif
      end

      %%
      meth commandEntriesEnable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesEnable'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @menuBar Arg tk(entryconf state:normal)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesEnable is finished'}
\endif
      end

      %%
      meth commandEntriesDisable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesDisable'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @menuBar Arg tk(entryconf state:disabled)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::commandEntriesDisable is finished'}
\endif
      end

      %%
      %% Put a new button on the buttons frame;
      %% 'ButtonProc' is an binary procedure, that can perform certain
      %% action on this button;
      meth pushButton(BD TText)
\ifdef DEBUG_TI
         {Show 'tcl/tk: pushButton:' # BD}
         if MyClosableObject , isClosed($)
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @menuBar \= InitValue then Action NewBD Button TM in
            proc {Action}
               case BD.action
               of O#M then {O M}
               else {BD.action}
               end

               %%
               {TM remove}
            end
            NewBD = {AdjoinAt BD action Action}

            %%
            Button = {New Tk.button {Adjoin NewBD tkInit(parent: @menuBar)}}

            %%
            {Tk.send pack(Button side:right)}

            %%
            buttons <- {AdjoinAt @buttons {Label BD} Button}

            %%
            TM = {New TransientManager
                  init(master: self.Window
                       follow: self
                       text:   TText)}
            {Button tkBind(event:  '<Enter>'
                           action: proc {$} {TM make} end)}
            {Button tkBind(event:  '<Leave>'
                           action: proc {$} {TM remove} end)}
         end
      end

      %%
      %% Put a new button on the buttons frame;
      %% 'ButtonProc' is an binary procedure, that can perform certain
      %% action on this button;
      meth pushEmptyFrame(FD)
\ifdef DEBUG_TI
         {Show 'tcl/tk: pushEmptyFrame:' # FD}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         %%
         if @menuBar \= InitValue then Frame in
            Frame = {New Tk.frame {Adjoin FD tkInit(parent: @menuBar)}}
            {Tk.send pack(Frame side:right)}
         end
      end

      %%
      meth setWaitCursor
         if {X11ResourceCache tryCursor(ICursorClock $)}
         then {self.BrowseWidget tk(conf cursor: ICursorClock)}
         end
      end

      %%
      meth setDefaultCursor
         if {X11ResourceCache tryCursor(ICursorName $)}
         then {self.BrowseWidget tk(conf cursor: ICursorName)}
         end
      end

      %%
      meth buttonsEnable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsEnable'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @buttons Arg tk(conf state:normal)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsEnable is finished'}
\endif
      end

      %%
      meth buttonsDisable(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsDisable'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @buttons Arg tk(conf state:disabled)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::buttonsDisable is finished'}
\endif
      end

      %%
      meth checkButtonOn(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOn'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @menuBar Arg tk(entryconf state:nornal)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOn is finished'}
\endif
      end

      %%
      meth checkButtonOff(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOff'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @menuBar Arg tk(entryconf state:disabled)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::checkButtonOff is finished'}
\endif
      end

      %%
      meth noTearOff(Arg)
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::noTearOff'}
         if MyClosableObject , isClosed($) then
            {Exception.raiseError browser('Closed window object is applied!')}
         end
\endif
         if @menuBar \= InitValue then
            {ProcessEntries @menuBar Arg tk(conf tearoff:false)}
         end

         %%
\ifdef DEBUG_TI
         {Show 'BrowserWindowClass::noTearOff is finished'}
\endif
      end

      %%
   end

   %%
   %%
   %% Window(s) for messages (warnings, errors);
   %%
   class MessageWindowClass
      from TkTools.error

      %%
      %% If 'Leader' is the 'InitValue', then it's ignored;
      meth make(leader:Leader message:Message)
\ifdef DEBUG_TI
         {Show 'MessageWindowClass::make' # Message}
\endif
         %%
         {New TkTools.error
          if Leader == InitValue then
             tkInit(title: IMTitle text:Message)
          else
             tkInit(title: IMTitle master: Leader text: Message)
          end _}

         %%
\ifdef DEBUG_TI
         {Show 'MessageWindowClass::make is finished'}
\endif
      end

      %%
   end

%%%
%%%  Dialog windows for options etc. are due to Christian (Schulte),
%%%  and adapted and integrated into Browser by me (kost@, i.e.
%%%  Konstantin Popov). Thanks to Christian!
%%%
%%%

   %%
   %%
   class AboutDialogClass
      from MyClosableObject TkTools.dialog
      feat TitleW

      %%
      meth init(windowObj: WO)
         TkTools.dialog , tkInit(master:  WO.Window
                                 title:   IATitle
                                 buttons: ['Okay'#tkClose(self#close)]
                                 focus:   1
                                 pack:    false
                                 default: 1)
         Title = {New Tk.label tkInit(parent:     self
                                      text:       'Oz Browser'
                                      foreground: IAboutColor)}
         self.TitleW = Title
         {Wait {FoldL_Obj self [IAFont1 IAFont2 IAFont3] SetTitleFont true}}

         %%
         Author = {New Tk.label tkInit(parent: self
                                       text: ('Konstantin Popov\n' #
                                              '(popov@ps.uni-sb.de)\n'))}
      in
         {Tk.send pack(Title Author side:top expand:1
                       padx:IBigPad pady:IBigPad)}
         AboutDialogClass , tkPack
      end

      %%
      meth SetTitleFont(Proceed IFont $)
         if Proceed then
            %%
            if {X11ResourceCache tryFont(IFont $)} then
               {self.TitleW tk(conf font:IFont)}
               %%
               false
            else true
            end
         else Proceed
         end
      end

      %%
   end

   %%
   %%
   %%
   class BufferDialog
      from MyClosableObject TkTools.dialog

      %%
      meth init(windowObj: WO)
         proc {Okay} S in
            {Size enter}
            S = {Size tkGet($)}
            if {IsInt S} then
               {WO.browserObj SetBufferSize(S)}
               {WO.store store(StoreAreSeparators
                               {Tcl2Oz {SepVar tkReturnAtom($)}})}
               {self tkClose}
               {self close}
            end
         end

         %%
         proc {Enter S} {Size tkSet(S)} end

         %%
         TkTools.dialog , tkInit(master:  WO.Window
                                 title:   IBOTitle
                                 default: 1
                                 pack:    false
                                 buttons: ['Okay'#Okay
                                           'Cancel'#tkClose(self#close)])
         SizeFrame = {New TkTools.textframe tkInit(parent: self
                                                   text:   'Size')}
         Left = {New Tk.frame tkInit(parent: SizeFrame.inner)}
         Size = {New TkTools.numberentry
                 tkInit(parent: Left
                        min: 1
                        max: DInfinite
                        val: {WO.store read(StoreBufferSize $)}
                        % back: IEntryColor
                        width: ISEntryWidth)}
         Right = {New Tk.frame tkInit(parent: SizeFrame.inner)}
         SepFrame  = {New TkTools.textframe tkInit(parent: self
                                                   text:   'Separator')}
         SepVar = {New Tk.variable
                   tkInit({Oz2Tcl {WO.store read(StoreAreSeparators $)}})}
      in

         %%
         {Tk.batch [grid({New Tk.label tkInit(parent:Left
                                              text:  'Buffer Size:'
                                              anchor:w)}
                         row:0 column:0 sticky:we)
                    grid(Size row:0 column:1 sticky:we)
                    pack({New Tk.button tkInit(parent: Right
                                               text:   'Small'
                                               action: Enter # IBSSmall)}
                         {New Tk.button tkInit(parent: Right
                                               text:   'Medium'
                                               action: Enter # IBSMedium)}
                         {New Tk.button tkInit(parent: Right
                                               text:   'Large'
                                               action: Enter # IBSLarge)}
                         fill:x)
                    pack(Left  side:left anchor:n)
                    pack(Right {MakeDistFrame SizeFrame.inner}
                         side:right anchor:n)
                    pack({New Tk.checkbutton
                          tkInit(parent:SepFrame.inner var:SepVar
                                 onvalue:{Oz2Tcl true}
                                 offvalue:{Oz2Tcl false}
                                 text:'Separate Buffer Entries')}
                         side:left anchor:n)
                    pack(SizeFrame SepFrame fill:x)]}
         BufferDialog , tkPack
      end

      %%
   end

   %%
   %%
   %%
   class RepresentationDialog
      from MyClosableObject TkTools.dialog

      %%
      meth init(windowObj: WO)
         %%
         proc {Okay}
            {WO.store store(StoreRepMode
                            {Tcl2Oz {ModeVar tkReturnAtom($)}})}
            {WO.store store(StoreArityType
                            {Tcl2Oz {ChunkVar tkReturnAtom($)}})}
            {WO.store store(StoreSmallNames
                            {Tcl2Oz {NameVar tkReturnAtom($)}})}
            {WO.store store(StoreAreStrings
                            {Tcl2Oz {StringsVar tkReturnAtom($)}})}
            {WO.store store(StoreAreVSs
                            {Tcl2Oz {VSsVar tkReturnAtom($)}})}
            {self tkClose}
            {self close}
         end

         %%
         TkTools.dialog , tkInit(master:  WO.Window
                                 title:   IROTitle
                                 default: 1
                                 pack:    false
                                 buttons: ['Okay'#Okay
                                           'Cancel'#tkClose(self#close)])
         ModeFrame = {New TkTools.textframe tkInit(parent: self
                                                   text:   'Mode')}
         ModeVar = {New Tk.variable
                    tkInit({Oz2Tcl {WO.store read(StoreRepMode $)}})}
         DetailFrame = {New TkTools.textframe tkInit(parent: self
                                                     text:   'Detail')}
         ChunkVar = {New Tk.variable
                     tkInit({Oz2Tcl {WO.store read(StoreArityType $)}})}
         NameVar = {New Tk.variable
                    tkInit({Oz2Tcl {WO.store read(StoreSmallNames $)}})}
         VSsFrame = {New TkTools.textframe tkInit(parent: self
                                                  text:   'Type')}
         StringsVar = {New Tk.variable
                       tkInit({Oz2Tcl {WO.store read(StoreAreStrings $)}})}
         VSsVar = {New Tk.variable
                   tkInit({Oz2Tcl {WO.store read(StoreAreVSs $)}})}
      in

         %%
         {Tk.batch [pack({New Tk.radiobutton tkInit(parent: ModeFrame.inner
                                                    text:   'Tree'
                                                    var: ModeVar
                                                    val: {Oz2Tcl TreeRep}
                                                    anchor: w)}
                         {New Tk.radiobutton tkInit(parent: ModeFrame.inner
                                                    text:   'Graph'
                                                    var: ModeVar
                                                    val: {Oz2Tcl GraphRep}
                                                    anchor: w)}
                         {New Tk.radiobutton tkInit(parent: ModeFrame.inner
                                                    text:   'Minimal Graph'
                                                    var: ModeVar
                                                    val: {Oz2Tcl MinGraphRep}
                                                    anchor: w)}
                         fill:x)

                    pack({New Tk.checkbutton
                          tkInit(parent:DetailFrame.inner var:ChunkVar
                                 text:'Chunks'
                                 onvalue:{Oz2Tcl TrueArity}
                                 offvalue:{Oz2Tcl NoArity}
                                 anchor:w)}
                         {New Tk.checkbutton
                          tkInit(parent:DetailFrame.inner var:NameVar
                                 text: 'Names And Procedures'
                                 onvalue:{Oz2Tcl false}
                                 offvalue:{Oz2Tcl true}
                                 anchor:w)}
                         fill:x)
                    pack(ModeFrame DetailFrame fill:x)
                    pack({New Tk.checkbutton
                          tkInit(parent:VSsFrame.inner var:StringsVar
                                 text:'Strings'
                                 onvalue:{Oz2Tcl true}
                                 offvalue:{Oz2Tcl false}
                                 anchor:w)}
                         fill:x)
                    pack({New Tk.checkbutton
                          tkInit(parent:VSsFrame.inner var:VSsVar
                                 text:'Virtual Strings'
                                 onvalue:{Oz2Tcl true}
                                 offvalue:{Oz2Tcl false}
                                 anchor:w)}
                         fill:x)
                    pack(ModeFrame VSsFrame fill:x)]}
         RepresentationDialog , tkPack
      end

      %%
   end

   %%
   class DisplayDialog
      from MyClosableObject TkTools.dialog

      %%
      meth init(windowObj: WO)
         %%
         proc {Okay} D W DI WI in
            {Depth enter}
            {Width enter}
            {DepthInc enter}
            {WidthInc enter}
            D  = {Depth tkGet($)}
            W  = {Width tkGet($)}
            DI = {DepthInc tkGet($)}
            WI = {WidthInc tkGet($)}
            if {All [D W DI WI] IsInt} then
               {WO.browserObj SetDepth(D)}
               {WO.browserObj SetWidth(W)}
               {WO.browserObj SetDInc(DI)}
               {WO.browserObj SetWInc(WI)}
               {WO.browserObj UpdateSizes}
               {self tkClose}
               {self close}
            end
         end

         %%
         proc {EnterLimits D#W}
            {Depth tkSet(D)} {Width tkSet(W)}
         end
         proc {EnterInc D#W}
            {DepthInc tkSet(D)} {WidthInc tkSet(W)}
         end

         %%
         TkTools.dialog , tkInit(master:  WO.Window
                                 title:   IDOTitle
                                 default: 1
                                 pack:    false
                                 buttons: ['Okay'#Okay
                                           'Cancel'#tkClose(self#close)])
         LimitsFrame = {New TkTools.textframe
                        tkInit(parent:self text:'Browse Limit')}
         LimitsLeft  = {New Tk.frame tkInit(parent:LimitsFrame.inner)}
         Depth       = {New TkTools.numberentry
                        tkInit(parent: LimitsLeft
                               min: 1
                               max: DInfinite
                               val: {WO.store read(StoreDepth $)}
                               % back:  IEntryColor
                               width: ISEntryWidth)}
         Width       = {New TkTools.numberentry
                        tkInit(parent: LimitsLeft
                               min: 1
                               max: DInfinite
                               val: {WO.store read(StoreWidth $)}
                               % back: IEntryColor
                               width: ISEntryWidth)}
         LimitsRight = {New Tk.frame tkInit(parent:LimitsFrame.inner)}

         IncFrame = {New TkTools.textframe
                     tkInit(parent:self text:'Expansion Increment')}
         IncLeft  = {New Tk.frame tkInit(parent:IncFrame.inner)}
         DepthInc = {New TkTools.numberentry
                     tkInit(parent: IncLeft
                            min: 1
                            max: DInfinite
                            val: {WO.store read(StoreDepthInc $)}
                            % back: IEntryColor
                            width: ISEntryWidth)}
         WidthInc = {New TkTools.numberentry
                     tkInit(parent: IncLeft
                            min: 1
                            max: DInfinite
                            val: {WO.store read(StoreWidthInc $)}
                            % back: IEntryColor
                            width: ISEntryWidth)}
         IncRight = {New Tk.frame tkInit(parent:IncFrame.inner)}
      in
         {Tk.batch [grid({New Tk.label tkInit(parent: LimitsLeft
                                              text:   'Depth:')}
                         row:0 column:0 sticky:w)
                    grid(Depth row:0 column:1)
                    grid({New Tk.label tkInit(parent: LimitsLeft
                                              text:   'Width:')}
                         row:1 column:0 sticky:w)
                    grid(Width row:1 column:1)
                    pack({New Tk.button tkInit(parent:LimitsRight
                                               text:  'Small'
                                               action: EnterLimits #
                                               (IDSmall # IWSmall))}
                         {New Tk.button tkInit(parent:LimitsRight
                                               text:  'Middle'
                                               action: EnterLimits #
                                               (IDMedium # IWMedium))}
                         {New Tk.button tkInit(parent:LimitsRight
                                               text:  'Large'
                                               action: EnterLimits #
                                               (IDLarge # IWLarge))}
                         fill:x)
                    pack(LimitsLeft  side:left anchor:n)
                    pack(LimitsRight {MakeDistFrame LimitsFrame.inner}
                         side:right anchor:n)
                    grid({New Tk.label tkInit(parent: IncLeft
                                              text:   'Depth:')}
                         row:0 column:0 sticky:w)
                    grid(DepthInc row:0 column:1)
                    grid({New Tk.label tkInit(parent: IncLeft
                                              text:   'Width:')}
                         row:1 column:0 sticky:w)
                    grid(WidthInc row:1 column:1)
                    pack({New Tk.button tkInit(parent:IncRight
                                               text:  'Small'
                                               action: EnterInc #
                                               (IDISmall # IWISmall))}
                         {New Tk.button tkInit(parent:IncRight
                                               text:  'Middle'
                                               action: EnterInc #
                                               (IDIMedium # IWIMedium))}
                         {New Tk.button tkInit(parent:IncRight
                                               text:  'Large'
                                               action: EnterInc #
                                               (IDILarge # IWILarge))}
                         fill:x)
                    pack(IncLeft  side:left anchor:n)
                    pack(IncRight {MakeDistFrame IncFrame.inner}
                         side:right anchor:n)

                    pack(LimitsFrame IncFrame fill:x)]}
         DisplayDialog , tkPack
      end

      %%
   end

   %%
   %%
   %%
   class LayoutDialog
      from MyClosableObject TkTools.dialog

      %%
      meth init(windowObj: WO)
         %%
         proc {Okay} Size Wght StoredFN in
            Size = {PointVar tkReturnInt($)}
            Wght = {WghtVar tkReturnAtom($)}
            StoredFN = {WO.store read(StoreTWFont $)}
            %%
            {ForAll IKnownCourFonts
             proc {$ Font}
                if
                   Font.size == Size andthen
                   Font.wght == Wght andthen
                   Font \= StoredFN
                then {WO setTWFont(Font _)}
                end
             end}

            %%
            {WO.store store(StoreFillStyle
                            {Tcl2Oz {RecordVar tkReturnAtom($)}})}
            {self tkClose}
            {self close}
         end

         %%
         TkTools.dialog , tkInit(master:  WO.Window
                                 title:   ILOTitle
                                 default: 1
                                 pack:    false
                                 buttons: ['Okay'#Okay
                                           'Cancel'#tkClose(self#close)])
         FontFrame = {New TkTools.textframe tkInit(parent: self
                                                   text:   'Font')}
         PointVar  = {New Tk.variable
                      tkInit({WO.store read(StoreTWFont $)}.size)}
         Point     = {New Tk.menubutton tkInit(parent:FontFrame.inner)}
         {Tk.send destroy(Point)}
         WghtVar   = {New Tk.variable
                      tkInit({WO.store read(StoreTWFont $)}.wght)}
         MiscFrame = {New TkTools.textframe tkInit(parent: self
                                                   text:   'Alignment')}
         RecordVar = {New Tk.variable
                      tkInit({Oz2Tcl {WO.store read(StoreFillStyle $)}})}
      in
         {Tk.batch [tk_optionMenu(Point PointVar 10 12 14 18 24)
                    grid({New Tk.label tkInit(parent:FontFrame.inner
                                              text:'Font Size')}
                         row:0 column:0)
                    grid(Point row:0 column:1)
                    grid({New Tk.checkbutton tkInit(parent:FontFrame.inner
                                                    text:'Bold' anchor:w
                                                    onvalue:bold
                                                    offvalue:medium
                                                    var:WghtVar)}
                         row:1 column:0 columnspan:2 sticky:we)
                    grid(columnconfigure FontFrame.inner 2 weight:1)
                    pack({New Tk.checkbutton tkInit(parent:MiscFrame.inner
                                                    text:'Align Record Fields'
                                                    onvalue:{Oz2Tcl Expanded}
                                                    offvalue:{Oz2Tcl Filled}
                                                    var:RecordVar)}
                         side:left fill:x)

                    pack(FontFrame MiscFrame fill:x)]}
         LayoutDialog , tkPack
      end

   end

%%
end
