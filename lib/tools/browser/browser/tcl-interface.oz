%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  tcl/tk (somewhat) interface to Oz (Modern) Browser;
%%%
%%%
%%%

%%
%%  Prototype of browser's window;
%%
local
   %%  synchronizing?
   TkNewName
   %%
   %%
   TagsListLoop
   RemovePosition
   %%
   %%  Parse a string of the form '<number><delim><number>...<number>'
   %% and get numbers in the list
   GetNums
   %%
   class MyToplevel from Tk.toplevel end
   %%
in
   %%
   class ProtoBrowserWindow from UrObject
      %%
      feat
         browserObj
         store
         standAlone
      %%
      attr
         window: InitValue
         browseWidget: InitValue
         menusFrame: InitValue
         buttonsFrame: InitValue
         highlightTag: InitValue
         HScrollbar: InitValue
      %%
         FrameHS: InitValue
         FrameButtons: InitValue
         FrameMenus: InitValue
      %%  we don't need the last three normally,
      %% but it's essential for the packing order and for close methods;
      %%
         TestTW: InitValue
      %%  this is used by 'tryFont';
      %%
      %%  ... store the given Window as a browser's "root" window or
      %% make the new one if none is given;
      meth init(window:        W
                browserObj:    BObj
                store:         Store
                standAlone:    StandAlone
                screen:        Screen)
\ifdef DEBUG_TI
         {Show 'tcl/tk::init'}
\endif
         %%
         %%
         self.browserObj = BObj
         self.store = Store
         self.standAlone = StandAlone
         %%
         case StandAlone then
            local Window XSize YSize CloseAction RootXSize RootYSize in
               XSize = {self.store read(StoreXSize $)}
               YSize = {self.store read(StoreYSize $)}
               %%
               %%
               CloseAction = {New Tk.action
                              tkInit(proc {$}
                                        case self.standAlone then
                                           {self.browserObj close}
                                        else true
                                        end
                                     end)}

               %%
               case Screen == InitValue then
                  Window = {New MyToplevel tkInit}
               else
                  Window = {New MyToplevel tkInit(screen: Screen)}
               end
               %%
               {Tk update(idletasks)}
               {Tk.returnInt winfo(screenheight Window) RootYSize}
               {Tk.returnInt winfo(screenwidth Window) RootXSize}
               %%
               %%
               {Tk.batch
                [wm(maxsize Window (RootXSize) (RootYSize))
                 %% wm(title Window ITitle)
                 wm(iconname Window IITitle)
                 wm(iconbitmap Window '@'#IIBitmap)
                 %% wm(iconmask Window '@'#IIBMask)
                 wm(geometry Window XSize#x#YSize)
                 wm(protocol Window "WM_DELETE_WINDOW" CloseAction)]}
               %%
               %%
               case self.browserObj.IsView then
                  {Tk wm(title Window IVTitle)}
               else
                  {Tk wm(title Window ITitle)}
               end
               %%
               %%
               %% {Window tkBind(event:'<Destroy>'
               %% action: proc {$} {self destroyClose} end)}
               %%
               %% isn't needed any more (we have redefined the window-delete
               %% protocol);
               %%
               %%  sync;
               case {Det Window} then
                  window <- Window
               end
            end
         else
            window <- W
            %%  Note that there is no control for this window;
            %%  It means in particular, that the application giving this window
            %% shouldn't do any *nonsese".
         end
         %%
         %%
         TestTW <- {New Tk.text tkInit(parent: @window
                                       width: 1
                                       height: 1
                                       bd: 0
                                       exportselection: 0
                                       highlightthickness: 0
                                       padx: 0
                                       pady: 0
                                       selectborderwidth: 0
                                       spacing1: 0
                                       spacing2: 0
                                       spacing3: 0)}
         %%
         %% Added by Christian:
         <<CreateBrowseWidget>>
      end
      %%
      %%
      %%  close the top level widnow;
      %%
      meth close
\ifdef DEBUG_TI
         {Show 'tcl/tk::close'}
\endif
         {@window close}
         %% if the window was given from aside, 'close' method should be provided too;
         <<UrObject close>>
         %% reject all future messages;
      end
      %%
      %%
      %%  ... but as the <Destroy> event handler;
      %%
      %% meth destroyClose
      %% if BObj in self.browserObj = BObj then
      %% {BObj closeWindows}
      %% else true
      %% fi
      %% end
      %%
      %%
      %%  Create the text widget and all auxiliaries (such as scrollbars);
      %%
      meth CreateBrowseWidget()
\ifdef DEBUG_TI
         {Show 'tcl/tk: CreateBrowseWidget'}
\endif
         local
            Window         %  top level;
            FHS            %  frame for horizontal scrollbar and glue;
            FHS_F          %  this frame servers as a glue (see previous line);
            FHS_HS         %  horizontal scrollbar;
            BrowseWidget   %
            VS             %  vertical scrollbar bound with BrowseWidget directly;
            FSSync
         in
            %%
            %%
            Window = @window
            %%
            %%
            FHS = {New Tk.frame tkInit(parent: Window
                                       bd: 0
                                       highlightthickness: 0)}
            FHS_HS = {New Tk.scrollbar tkInit(parent: FHS
                                              relief: IFrameRelief
                                              bd: IBigBorder
                                              width: ISWidth
                                              orient: horizontal
                                              highlightthickness: 0)}
            FHS_F = {New Tk.frame tkInit(parent: FHS
                                         width: (ISWidth + IBigBorder + IBigBorder)
                                         height: (ISWidth + IBigBorder + IBigBorder)
                                         highlightthickness: 0)}
            BrowseWidget = {New Tk.text tkInit(parent: Window
                                               % width: ITWWidth
                                               % height: ITWHeight
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
            %%  ... just ignore the result;
            {Tk.returnInt
             catch(q(BrowseWidget conf(cursor: ICursorName)))
             _}
            %%
            %% Select the font from ITWFont?, and store it;
            %%
            {FoldL [ITWFont1 ITWFont2 ITWFont3]
             fun {$ Proceed IFont}
                case Proceed then
                   %%
                   case
                      {Tk.returnInt
                       catch(q(BrowseWidget conf(font: IFont.font)))} \= 0
                   then True
                   else
                      %%
                      %%  This doesn't work 'cause we have to update the
                      %% radio button too;
                      %% {self.store store(StoreTWFont IFont)}
                      job
                         {self.browserObj
                          setParameter(BrowserFont IFont.font)}
                      end
                      False
                   end
                else Proceed
                end
             end
             True FSSync}
            %%
            case {IsValue FSSync} then <<nil>> end
            %%
            VS = {New Tk.scrollbar tkInit(parent: Window
                                          relief: IFrameRelief
                                          bd: IBigBorder
                                          width: ISWidth
                                          highlightthickness: 0)}
            {Tk.addYScrollbar BrowseWidget VS}
            {Tk.addXScrollbar BrowseWidget FHS_HS}
            %%
            %%
            %%  pack them;
            {Tk.batch
             [pack(FHS o(side: bottom fill: x padx: 0 pady: 0))
              pack(VS o(side: right fill: y padx: IPad pady: IPad))
              pack(FHS_HS o(side: left fill: x expand: yes
                            padx: IPad pady: IPad))
              pack(FHS_F o(side: right fill: none padx: IPad pady: IPad))
              pack(BrowseWidget o(fill: both expand: yes side: top
                                  padx: IPad pady: IPad))
              %%
              o(pr#oc myNullProc '' '')
              %%
              %%
              /*
              %%
              %%  Actually, not necessary any more - since all class bindigns
              %% can be discarded with 'bindtags';
              %%
              %%  ... and now, discard ~all bindings from text widget,
              %% as they are specified in 'lib/tk/text.tcl';
              %%
              %%  '<Enter>' and '<FocusIn>' are kept;
              bind('Text' '<1>' myNullProc)
              bind('Text' '<B1-Motion>' myNullProc)
              bind('Text' '<Double-1>' myNullProc)
              bind('Text' '<Triple-1>' myNullProc)
              bind('Text' '<Shift-1>' myNullProc)
              bind('Text' '<Double-Shift-1>' myNullProc)
              bind('Text' '<Triple-Shift-1>' myNullProc)
              bind('Text' '<B1-Leave>' myNullProc)
              bind('Text' '<B1-Enter>' myNullProc)
              bind('Text' '<ButtonRelease-1>' myNullProc)
              bind('Text' '<Control-1>' myNullProc)
              bind('Text' '<Left>' myNullProc)
              bind('Text' '<Right>' myNullProc)
              bind('Text' '<Up>' myNullProc)
              bind('Text' '<Down>' myNullProc)
              bind('Text' '<Shift-Left>' myNullProc)
              bind('Text' '<Shift-Right>' myNullProc)
              bind('Text' '<Shift-Up>' myNullProc)
              bind('Text' '<Shift-Down>' myNullProc)
              bind('Text' '<Control-Left>' myNullProc)
              bind('Text' '<Control-Right>' myNullProc)
              bind('Text' '<Control-Up>' myNullProc)
              bind('Text' '<Control-Down>' myNullProc)
              bind('Text' '<Shift-Control-Left>' myNullProc)
              bind('Text' '<Shift-Control-Right>' myNullProc)
              bind('Text' '<Shift-Control-Up>' myNullProc)
              bind('Text' '<Shift-Control-Down>' myNullProc)
              bind('Text' '<Prior>' myNullProc)
              bind('Text' '<Shift-Prior>' myNullProc)
              bind('Text' '<Control-Prior>' myNullProc)
              bind('Text' '<Next>' myNullProc)
              bind('Text' '<Shift-Next>' myNullProc)
              bind('Text' '<Control-Next>' myNullProc)
              bind('Text' '<Home>' myNullProc)
              bind('Text' '<Shift-Home>' myNullProc)
              bind('Text' '<Control-Home>' myNullProc)
              bind('Text' '<Control-Shift-Home>' myNullProc)
              bind('Text' '<End>' myNullProc)
              bind('Text' '<Shift-End>' myNullProc)
              bind('Text' '<Control-End>' myNullProc)
              bind('Text' '<Control-Shift-End>' myNullProc)
              bind('Text' '<Tab>' myNullProc)
              bind('Text' '<Shift-Tab>' myNullProc)
              bind('Text' '<Control-Tab>' myNullProc)
              bind('Text' '<Control-Shift-Tab>' myNullProc)
              bind('Text' '<Control-i>' myNullProc)
              bind('Text' '<Return>' myNullProc)
              bind('Text' '<Delete>' myNullProc)
              bind('Text' '<BackSpace>' myNullProc)
              bind('Text' '<Control-space>' myNullProc)
              bind('Text' '<Select>' myNullProc)
              bind('Text' '<Control-Shift-space>' myNullProc)
              bind('Text' '<Shift-Select>' myNullProc)
              bind('Text' '<Control-slash>' myNullProc)
              bind('Text' '<Control-backslash>' myNullProc)
              bind('Text' '<Insert>' myNullProc)
              bind('Text' '<KeyPress>' myNullProc)
              bind('Text' '<Alt-KeyPress>' myNullProc)
              bind('Text' '<Meta-KeyPress>' myNullProc)
              bind('Text' '<Control-KeyPress>' myNullProc)
              bind('Text' '<Escape>' myNullProc)
              bind('Text' '<>' myNullProc)
              %%  some of emacs-like bindings;
              %%  other fall in the 'KeyPress' cases;
              bind('Text' '<2>' myNullProc)
              bind('Text' '<B2-Motion>' myNullProc)
              bind('Text' '<ButtonReleas-2>' myNullProc)
              %%
              */
              %%
              %%
              bindtags(BrowseWidget q(BrowseWidget))
              %%
              %%  remove all 'KeyPress' bindings
              %% (some of them will be reinstalled soon);
              bind(BrowseWidget '<KeyPress>' myNullProc)
              /*
              %%
              %%  exclude all key presses but without any modifiers;
              %%  Modifiers
              %% Control Shift Lock Button[1-5] Mod[1-5] Meta Alt
              %% Double Triple
              %%
              */
              %%
              %%
              %%  x11 selection - shift-buttons[move];
              %% actually, they are not Motif-like, but somethings like
              %% to the 'xterm';
              %%
              %%  exclude '$w mark set insert @$x,$y';
              o(pr#oc
                myTkTextButton1
                q(w x y)
                q('global' 'tkPriv;'
                  'set' 'tkPriv(selectMode)' 'char;'
                  'set' 'tkPriv(mouseMoved)' '0;'
                  'set' 'tkPriv(pressX)' '$x;'
                  '$w' 'mark' 'set' 'anchor' '@$x,$y;'
                  'if' '{[$w' 'cget' '-state]' '==' '"normal"}' '{focus' '$w};'))
              %%
              bind(BrowseWidget '<Shift-ButtonPress-1>'
                   "myTkTextButton1 %W %x %y; %W tag remove sel 0.0 end"
                  )
              bind(BrowseWidget '<Shift-Button1-Motion>'
                   "tkTextSelectTo %W %x %y"
                  )
              bind(BrowseWidget '<Shift-ButtonPress-3>'
                   "tkTextResetAnchor %W @%x,%y; tkTextSelectTo %W %x %y"
                  )
              bind(BrowseWidget '<Shift-Button3-Motion>'
                   "tkTextResetAnchor %W @%x,%y; tkTextSelectTo %W %x %y"
                  )
              %%
              %%
              %%
              focus(BrowseWidget)
              %%
             ]}
            %%
            %%
            %% some special bindings;
            {BrowseWidget tkBind(event:'<Configure>'
                                 action: proc {$}
                                            {self resetTW}
                                         end)}
            {Window tkBind(event:'<FocusIn>'
                           action: proc {$}
                                      {self focusIn}
                                      {BrowserMessagesFocus Window}
                                   end)}
            {Window tkBind(event:'<FocusOut>'
                           action: proc {$}
                                      %%  no special action;
                                      {BrowserMessagesNoFocus}
                                   end)}
            {BrowseWidget tkBind(event:'<Control-x>'
                                 action: proc {$}
                                            case self.standAlone then
                                               {self.browserObj close}
                                            else true
                                            end
                                         end)}
            {BrowseWidget tkBind(event:'<Control-h>'
                                 action: proc {$}
                                            {self.browserObj Help}
                                         end)}
            {BrowseWidget tkBind(event:'<Control-z>'
                                 action: proc {$}
                                            {self.browserObj Iconify}
                                         end)}
            {BrowseWidget tkBind(event:'<Control-n>'
                                 action: proc {$}
                                            {self.browserObj createNewView}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-u>'
                                 action: proc {$}
                                            {self.browserObj Unzoom}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-t>'
                                 action: proc {$}
                                            {self.browserObj Top}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-f>'
                                 action: proc {$}
                                            {self.browserObj first}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-l>'
                                 action: proc {$}
                                            {self.browserObj last}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-p>'
                                 action: proc {$}
                                            {self.browserObj previous}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-n>'
                                 action: proc {$}
                                            {self.browserObj next}
                                         end)}
            {BrowseWidget tkBind(event:'<Key-a>'
                                 action: proc {$}
                                            {self.browserObj all}
                                         end)}
            {BrowseWidget tkBind(event:'<Control-b>'
                                 action: proc {$}
                                            {self.browserObj rebrowse}
                                         end)}
            {BrowseWidget tkBind(event:'<Control-l>'
                                 action: proc {$}
                                            {self.browserObj redraw}
                                         end)}
            {BrowseWidget tkBind(event:'<Control-s>'
                                 action: proc {$}
                                            {self.store store(StoreNodeNumber 0)}
                                         end)}
            {BrowseWidget tkBind(event:'<Control-u>'
                                 action: proc {$}
                                            {self.browserObj undraw}
                                         end)}
            {BrowseWidget tkBind(event:'<Mod1-Control-m>'
                                 action: proc {$}
                                            {self.browserObj toggleMenus}
                                         end)}
            {BrowseWidget tkBind(event:'<Mod2-Control-m>'
                                 action: proc {$}
                                            {self.browserObj toggleMenus}
                                         end)}
            {BrowseWidget tkBind(event:'<Mod1-Control-b>'
                                 action: proc {$}
                                            {self.browserObj toggleButtons}
                                         end)}
            {BrowseWidget tkBind(event:'<Mod2-Control-b>'
                                 action: proc {$}
                                            {self.browserObj toggleButtons}
                                         end)}
            {BrowseWidget tkBind(event:'<3>'
                                 action: proc {$}
                                            {self tagUnHighlight}
                                            {self.browserObj UnsetSelected}
                                         end)}
            %%
            %%
            %%
            %% sync;
            case {Det BrowseWidget} then
               browseWidget <- BrowseWidget
               HScrollbar <- FHS_HS
               FrameHS <- FHS
               <<setTWFont>>  % scrollincrement + resetTW;
            end
         end
      end
      %%
      %%
      %%
      %%
      meth iconify
\ifdef DEBUG_TI
         {Show 'tcl/tk: iconify'}
\endif
         case self.standAlone then {Tk wm(iconify @window)}
         else true
         end
      end
      %%
      %%
      meth focusIn
\ifdef DEBUG_TI
         {Show 'tcl/tk: focusIn'}
\endif
         true
         %%
         %%  Tk 4.0 does not require any special action;
         %% {Tk focus(@browseWidget)}
         %%
      end
      %%
      %%  Yields 'True' if the font exists;
      %%
      meth tryFont(Font ?R)
         R = {Tk.returnInt catch(q(@TestTW conf(font: Font)))} == 0
      end
      %%
      %%  Yields height and width of the font given (or zeros if it
      %% doesn't exist at all);
      %%
      meth getFontRes(Font ?XRes ?YRes)
         %%
         case <<tryFont(Font $)>> then
            %%
            YRes = {Tk.returnInt winfo(reqheight @TestTW)}
            XRes = {Tk.returnInt winfo(reqwidth @TestTW)}
            %%
            case {IsValue XRes} then <<nil>> end
         else
            %%
            YRes = XRes = 0
         end
      end
      %%
      %%
      %%
      meth setTWFont
\ifdef DEBUG_TI
         {Show 'tcl/tk: setTWFont'}
\endif
         local Font in
            Font = {self.store read(StoreTWFont $)}
            %%
            %%
            case Font.name == '*startup*' then true   % skip it;
            else
               {@browseWidget tk(configure(font: Font.font))}
            end
            %%
            <<resetTW>>
            %%
         end
      end
      %%
      %%
      %%
      %%
      meth resetTW
\ifdef DEBUG_TI
         {Show 'tcl/tk: resetTWFont'}
\endif
         local Font TWWidthS TWWidth XRes in
            {self.store read(StoreTWFont Font)}
            %%
            %%
            {Tk update(idletasks)}
            %%
            {Tk.return winfo(width @browseWidget) TWWidthS}
            TWWidth = {String.toInt TWWidthS}
            %%
            %%
            case Font.xRes == 0 then
               XRes = <<getFontRes(Font.font $ _)>>
            else
               XRes = Font.xRes
            end
            %%
            %%
            case XRes \= 0 then
               job
                  {self.browserObj
                   SetTWWidth({`div`
                               (TWWidth - 2*ITWPad - 2*IBigBorder)
                               XRes})}
               end
            else true           % we cannot do anything anyway;
            end
            %%
            %%
         end
      end
      %%
      %%
      %%  Set the geometry of a browser's window, provided it is not smaller
      %% than minimal possible (and, of coarse, this is a 'stand alone' browser);
      %%
      meth setXYSize(X Y)
         case self.standAlone then
            local MinXSize MinYSize Sync in
               {self.store [read(StoreXMinSize MinXSize)
                            read(StoreYMinSize MinYSize)]}
               %%
               %%
               case MinXSize =< X andthen MinYSize =< Y then
                  %%
                  {Tk wm(geometry @window X#'x'#Y)}
                  %%
                  %% synchronization;
                  {Tk update(idletasks)}
                  %%
                  {Tk.return winfo(exists @browseWidget) Sync}
                  %%
                  case {IsValue {String.toAtom Sync}} then
                     <<nil>>
                  end
               else
                  {BrowserWarning ['Impossible window size wrt limits']}
               end
            end
         else true
         end
      end
      %%
      %%
      %%  Create the menus frame;
      %%
      meth createMenusFrame
\ifdef DEBUG_TI
         {Show 'tcl/tk: createMenusFrame'}
\endif
         case @menusFrame == InitValue then
            local
               MFT            %  template, y-fill
               MenusFrame     %
            in
               %%
               MFT = {New Tk.frame tkInit(parent: @window
                                           bd: ISmallBorder
                                           relief: IFrameRelief)}
               %% height: IMFHeight#c  % but: who cares? :))
               MenusFrame = {New Tk.frame tkInit(parent: MFT bd: 0)}
               %%
               %%  the packing order ('-before' option for packer) is essential;
               case @FrameButtons == InitValue then
                  {Tk pack(MFT o(side: top
                                 fill: x
                                 padx: IPad
                                 pady: IPad
                                 before: @FrameHS))}
               else
                  {Tk pack(MFT o(side: top
                                 fill: x
                                 padx: IPad
                                 pady: IPad
                                 before: @FrameButtons))}
               end
               %%
               %%
               case {Det MenusFrame} then
                  menusFrame <- MenusFrame
                  FrameMenus <- MFT
               end
            end
         else
            {BrowserWarning ['can not create another menus frame']}
         end
      end
      %%
      %%  ... pack it;
      meth exposeMenusFrame
\ifdef DEBUG_TI
         {Show 'tcl/tk: exposeMenusFrame'}
\endif
         local MenusFrame in
            MenusFrame = @menusFrame
            %%
            case MenusFrame == InitValue then true
            else
               {Tk pack(MenusFrame o(side: left))}
            end
         end
      end
      %%
      %%
      %%
      meth createButtonsFrame
\ifdef DEBUG_TI
         {Show 'tcl/tk: CreateButtonsFrame'}
\endif
         case @buttonsFrame == InitValue then
            local
               BFT            %  template, x-fill
               ButtonsFrame   %
            in
               %%
               BFT = {New Tk.frame tkInit(parent: @window
                                          bd: ISmallBorder
                                          relief: IFrameRelief)}
               %% width: IBFWidth#c
               ButtonsFrame = {New Tk.frame tkInit(parent: BFT bd: 0)}
               %%
               %%  always before horizontal scrollbar;
               {Tk pack(BFT o(side: left
                              fill: y
                              padx: IPad
                              pady: IPad
                              before: @FrameHS))}
               %%
               %%
               case {Det ButtonsFrame} then
                  buttonsFrame <- ButtonsFrame
                  FrameButtons <- BFT
               end
            end
         else
            {BrowserWarning ['can not create another buttons frame']}
         end
      end
      %%
      %%
      meth exposeButtonsFrame
\ifdef DEBUG_TI
         {Show 'tcl/tk: exposeMenusFrame'}
\endif
         local ButtonsFrame in
            ButtonsFrame = @buttonsFrame
            %%
            case ButtonsFrame == InitValue then true
            else
               {Tk pack(ButtonsFrame o(side: top))}
            end
         end
      end
      %%
      %%
      %%  Remove the menus frame;
      %%
      meth closeMenusFrame
\ifdef DEBUG_TI
         {Show 'tcl/tk: closeMenusFrame'}
\endif
         case @FrameMenus == InitValue then true
         else
            {@FrameMenus close}
            %%  and therefore @buttonsFrame and all menus too;
            %%
            %%
            menusFrame <- InitValue
            FrameMenus <- InitValue
         end
      end
      %%
      %%
      %%  Remove the buttons frame;
      %%
      meth closeButtonsFrame
\ifdef DEBUG_TI
         {Show 'tcl/tk: closeButtonsFrame'}
\endif
         case @FrameButtons == InitValue then true
         else
            {@FrameButtons close}
            %%
            %%
            buttonsFrame <- InitValue
            FrameButtons <- InitValue
         end
      end
      %%
      %%
      %%  Set the minimal possible size of the window;
      %%
      meth setMinSize
\ifdef DEBUG_TI
         {Show 'tcl/tk: setMinSize'}
\endif
         case self.standAlone then
            local XMinSize YMinSize in
               %%
               case
                  @FrameButtons == InitValue andthen
                  @FrameMenus == InitValue
               then
                  %%
                  {Tk update(idletasks)}
                  %%
                  %%
                  XMinSize = {self.store read(StoreXMinSize $)}
                  YMinSize = {self.store read(StoreYMinSize $)}
                  %% don't use gridded text widget;
               elsecase @FrameButtons == InitValue then
                  local MFWidthS in
                     %%
                     {Tk update(idletasks)}
                     %%
                     %%
                     {Tk.return winfo(reqwidth @menusFrame) MFWidthS}
                     %%
                     %%
                     YMinSize = IYMinSize
                     XMinSize = {String.toInt MFWidthS} + 2*IPad + 2*ISmallBorder
                  end
               elsecase @FrameMenus == InitValue then
                  local BFHeightS in
                     %%
                     {Tk update(idletasks)}
                     %%
                     %%
                     {Tk.return winfo(reqheight @buttonsFrame) BFHeightS}
                     %%
                     %%
                     XMinSize = IXMinSize
                     YMinSize = {String.toInt BFHeightS} + 2*IPad + 2*ISmallBorder
                  end
               else
                  local MFHeightS MFWidthS BFHeightS MFHeight MFWidth BFHeight in
                     %%
                     {Tk update(idletasks)}
                     %%
                     %%
                     {Tk.return winfo(reqheight @menusFrame) MFHeightS}
                     {Tk.return winfo(reqheight @buttonsFrame) BFHeightS}
                     {Tk.return winfo(reqwidth @menusFrame) MFWidthS}
                     %%
                     %%
                     MFHeight = {String.toInt MFHeightS}
                     BFHeight = {String.toInt BFHeightS}
                     MFWidth = {String.toInt MFWidthS}
                     %%
                     %%
                     YMinSize = 4*IPad + 4*ISmallBorder + MFHeight + BFHeight
                     XMinSize = 2*IPad + 2*ISmallBorder + MFWidth
                  end
               end
               %%
               %%
               case {IsValue XMinSize} andthen {IsValue YMinSize} then
                  %%
                  %% force the minsize of the window;
                  local XSizeS YSizeS XSize YSize in
                     {Tk.return winfo(height @window) YSizeS}
                     {Tk.return winfo(width @window) XSizeS}
                     {Tk wm(minsize @window XMinSize YMinSize)}
                     %%
                     %%
                     XSize = {String.toInt XSizeS}
                     YSize = {String.toInt YSizeS}
                     %%
                     %%
                     %% relational;
                     case XMinSize =< XSize andthen YMinSize =< YSize
                     then true
                     elsecase XSize < XMinSize andthen YMinSize =< YSize then
                        {Tk wm(geometry @window XMinSize#'x'#YSizeS)}
                        %%
                        %%
                        <<resetTW>>
                     elsecase YSize < YMinSize andthen XMinSize =< XSize then
                        {Tk wm(geometry @window XSizeS#'x'#YMinSize)}
                        %%
                        <<resetTW>>
                     else
                        {Tk wm(geometry @window XMinSize#'x'#YMinSize)}
                        %%
                        %%
                        <<resetTW>>
                     end
                  end
               end
            end
         else true
         end
      end

      /*
      %%
      %%  Set a font for the tag based on the mapping from the current one
      %% (IFontMap);
      %%
      meth setRefFont(Tag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: setRefFont:'#Tag}
\endif
         local BrowseWidget Font RefFont in
            BrowseWidget = @browseWidget
            Font = {self.store read(StoreTWFont $)}
            RefFont = IFontMap.(Font.font)
            %%
            %%
            case {Det Tag} then
               {BrowseWidget tk(tag(configure Tag o(font: RefFont)))}
            end
         end
      end
      */

      %%
      %%
      meth genTkName(?Mark)
\ifdef DEBUG_TI
         {Show 'tcl/tk: genTkName:'}
\endif
         Mark = {TkNewName}
      end
      %%
      %%  Insert the 'VS' into the text widget at the given mark;
      %%
      meth insert(Mark VS)
\ifdef DEBUG_TI
         {Show 'tcl/tk: insert:'#Mark}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %% suspensions don't works: the sequence of corresponding wakeup's
            %% isn't defined!
            %% if {IsValue Mark} {IsValue Atom} then
            %%
            {BrowseWidget tk(insert(Mark VS))}
            <<nil>>
            %% fi
         end
      end
      %%
      %%
      %%  Insert the 'Atom' just before the Tag,
      %% and extend 'Tags' over inserted atom;
      %%
      meth insertBeforeTag(Tag Tags VS)
\ifdef DEBUG_TI
         {Show  'tcl/tk: insertBeforeTag:'#Tag#VS}
\endif
         local BrowseWidget StrT in
            BrowseWidget = @browseWidget
            %%
            StrT = {Tuple s {Length Tags}}
            {List.forAllInd Tags proc {$ I T} StrT.I = T end}
            %%
            {BrowseWidget tk(insert(p(Tag first) VS StrT))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Insert after the 'Mark' with the offset 'Offset';
      meth insertAfterMark(Mark Offset VS)
\ifdef DEBUG_TI
         {Show  'tcl/tk: insertAfterMark:'#Mark#Offset#VS}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(insert(q(Mark '+' Offset 'chars') VS))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Insert after the Tag.last;
      meth insertAfterTag(Tag Tags VS)
\ifdef DEBUG_TI
         {Show 'tcl/tk: insertJustAfterTag:'#Tag#VS}
\endif
         local BrowseWidget StrT in
            BrowseWidget = @browseWidget
            %%
            StrT = {Tuple s {Length Tags}}
            {List.forAllInd Tags proc {$ I T} StrT.I = T end}
            %%
            {BrowseWidget tk(insert(p(Tag last) VS StrT))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Insert the 'VS' into the text widget at the given mark, and
      %% create a new mark before this atom;
      %%
      meth insertWithMark(Mark VS ?NewMark)
\ifdef DEBUG_TI
         {Show  'tcl/tk: insertWithMark:'#Mark#VS}
\endif
         local BrowseWidget SLength IS in
            BrowseWidget = @browseWidget
            %%
            SLength = {VSLength VS}
            %%
            {BrowseWidget [tk(insert(Mark VS))
                           tk(mark(set NewMark q(Mark '-' SLength 'chars')))]}
            %%
            <<nil>>
         end
      end
      %%
      %%  Insert the 'VS' into text widget at given mark, and
      %% stretch 'PTag' over the just inserted atom;
      %% 'PTag' (pseudo tag) is a list of tags;
      %% - if it contains exactly one element, it (tag) is stretched over 'VS';
      %% - otherwise 'VS' gets *only* tags from 'PTag';
      %%
      meth insertWithTag(Mark VS PTag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: insertWithTag:'#Mark#VS}
\endif
         local BrowseWidget NumOf StrT in
            NumOf = {Length PTag}
            BrowseWidget = @browseWidget
            %%
            case NumOf == 1 then
               %%
               {BrowseWidget
                [tk(insert(Mark VS))
                 tk(tag(add PTag.1 q(Mark '-' {VSLength VS}
                                         'chars') Mark))]}
            else
               %%
               StrT = {Tuple s NumOf}
               {List.forAllInd PTag proc {$ I T} StrT.I = T end}
               %%
               {BrowseWidget tk(insert(Mark VS StrT))}
            end
            %%
            <<nil>>
            %%
         end
      end
      %%
      %%
      %%  ... with both (i.e. mark before atom and tag over it);
      %%
      meth insertWithBoth(Mark VS NewMark PTag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: insertWithBoth:'#Mark#VS}
\endif
         local BrowseWidget LengthVS NumOf StrT in
            LengthVS = {VSLength VS}
            BrowseWidget = @browseWidget
            NumOf = {Length PTag}
            %%
            case NumOf == 1 then
               StrT = q(Mark '-' LengthVS 'chars')
               %%
               {BrowseWidget
                [tk(insert(Mark VS))
                 tk(mark(set NewMark StrT))
                 tk(tag(add PTag.1 StrT Mark))]}
            else
               %%
               StrT = {Tuple s NumOf}
               {List.forAllInd PTag proc {$ I T} StrT.I = T end}
               %%
               {BrowseWidget
                [tk(insert(Mark VS StrT))
                 tk(mark(set NewMark q(Mark '-' LengthVS 'chars')))]}
            end
            %%
            <<nil>>
            %%
         end
      end
      %%
      %%
      /*
      %%  Get the absolute position of the mark;
      %%  Actually not used;
      %%
      meth getMarkPosition(Mark ?Row ?Col)
\ifdef DEBUG_TI
         {Show 'tcl/tk: getMarkPosition:'#Mark}
\endif
         local L Ind BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            L = {BrowseWidget tkReturn(index(Mark) $)}
            %%
            <<nil>>
            %%
            %% to recall: L is a list of ascii-codes of the characters composing
            %% a string of the form [1-9][0-9]*\.[1-9][0-9]*
            Ind = {FindChar L CharDot}
            Row = {String.toInt {Head L Ind-1}}
            Col = {String.toInt {Tail L Ind+1}}
            %%
         end
      end
      %%
      %%
      meth getMarkCol(Mark ?Col)
\ifdef DEBUG_TI
         {Show 'tcl/tk: getMarkCol:'#Mark}
\endif
         local L BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            L = {BrowseWidget tkReturn(index(Mark) $)}
            %%
            <<nil>>
            %%
            Col = {String.toInt {Tail L {FindChar L CharDot}+1}}
            %%
         end
      end
      %%
      */
      %%
      %%
      meth getTagFirst(Tag ?Col)
\ifdef DEBUG_TI
         {Show 'tcl/tk: getTagFirst:'#Tag}
\endif
         local L BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            L = {BrowseWidget tkReturn(index(p(Tag first)) $)}
            %%
            <<nil>>
            %%
            Col = {String.toInt {Tail L {FindChar L CharDot}+1}}
            %%
         end
      end
      %%
      %%
      %%  Delete all characters in range tag.first - tag.last
      %%
      meth delete(Tag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: delete:'#Tag}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(delete(p(Tag first) p(Tag last)))}
            %%
            <<nil>>
            %%
         end
      end
      %%
      %%
      %%  Delete 'N' characters with offset 'Offset' after the 'Mark';
      %%
      meth deleteAfterMark(Mark Offset N)
\ifdef DEBUG_TI
         {Show 'tcl/tk: deleteAfterMark:'#Mark#Offset#N}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(delete(q(Mark '+' Offset 'chars')
                                        q(Mark '+' (Offset + N) 'chars')))}
            %%
            <<nil>>
            %%
         end
      end
      %%
      %%
      %%  Delete 'N' characters before the 'Mark';
      %%
      meth deleteBeforeMark(Mark N)
\ifdef DEBUG_TI
         {Show 'tcl/tk: deleteBeforeMark:'#Mark#N}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(delete(q(Mark '-' N 'chars') Mark))}
            %%
            <<nil>>
            %%
         end
      end
      %%
      %%
      /*
      %%  Delete 'N' characters with offset 'Offset' after the first character
      %% of the 'Tag';
      %%  Actually not used;
      %%
      meth deleteAfterTag(Tag Offset N)
\ifdef DEBUG_TI
         {Show 'tcl/tk: deleteAfterTag:'#Tag#Offset#N}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget
             tk(delete(p(Tag first '+' Offset 'chars')
                           p(Tag first '+' (Offset + N) 'chars')))}
            %%
            <<nil>>
            %%
         end
      end
      %%
      */
      %%
      %%
      %%  Delete tag;
      %%
      meth deleteTag(Tag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: deleteTag:'#Tag}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(tag(delete Tag))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Unsert mark;
      %%
      meth unsetMark(Mark)
\ifdef DEBUG_TI
         {Show 'tcl/tk: unsetMark:'#Mark}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(mark(unset Mark))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Duplicate mark;
      %%
      meth duplicateMark(Mark NewMark)
\ifdef DEBUG_TI
         {Show 'tcl/tk: duplicateMark:'#Mark}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(mark(set NewMark Mark))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Duplicate mark, but with left gravity;
      %%
      meth duplicateMarkLG(Mark NewMark)
\ifdef DEBUG_TI
         {Show 'tcl/tk: duplicateMarkLG:'#Mark}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget [tk(mark(set NewMark Mark))
                           tk(mark(gravity NewMark left))]}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%
      meth setMarksGravity(Marks Gravity)
\ifdef DEBUG_TI
         {Show 'tcl/tk: setMarksGravity:'#Marks#Gravity}
\endif
         case Marks
         of Mark|RestMarks then
            local BrowseWidget in
               BrowseWidget = @browseWidget
               %%
               {BrowseWidget tk(mark(gravity Mark Gravity))}
               %%
               <<setMarksGravity(RestMarks Gravity)>>
            end
         else true
         end
      end
      %%
      %%
      /*
      %%
      %%  Move mark;
      %%  Actually not used;
      %%
      meth moveMark(Mark Dir N)
\ifdef DEBUG_TI
         {Show 'tcl/tk: moveMark:'#Mark}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            case Dir == forward then
               %%
               {BrowseWidget
                tk(mark(set Mark q(Mark '+' N 'chars')))}
            else
               %%
               {BrowseWidget
                tk(mark(set Mark q(Mark '-' N 'chars')))}
            end
            %%
            <<nil>>
         end
      end
      %%
      */
      %%
      %%  Duplicate tag;
      %%  Note that the 'Tag' is not actually duplicated, but a new tag
      %% from 'Tag.first' to 'Tag.last' is created. In other words, it's
      %% assumed that 'Tag' covers a permanent area in text widget;
      %%
      meth duplicateTag(Tag NewTag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: duplicateTag:'#Tag}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(tag(add NewTag p(Tag first) p(Tag last)))}
            %%
            <<nil>>
         end
      end
      %%
      %%
      /*
      %%
      %%  Free the _last_ position covered by tag from all tags with bigger
      %% priority (used for inserting of braces, but can be generally useful;>)
      %%  Actually not used;
      %%
      meth freeLastPosition(Tag ?Sync)
\ifdef DEBUG_TI
         {Show 'tcl/tk: freeLastPosition:'#Tag}
\endif
         local STag Tags Pos in
            STag = {VirtualString.toString Tag}
            Pos = p(Tag last '-' 1 chars)
            <<GetTagsList(Pos Tags)>>
            %%
            {RemovePosition @browseWidget Pos STag Tags Sync}
            %%  Note:
            %%  This operation must be performed in *single transaction*,
            %% since otherwise tags can be modified between their determining
            %% and modification in 'RemovePosition';
            case {Det Sync} then <<nil>> end
            %%
         end
      end
      %%
      %%
      %%  set Mark after the 'Tag';
      %%
      meth setMarkAfterTag(Tag Mark)
\ifdef DEBUG_TI
         {Show 'tcl/tk: setMarkAfterTag:'#Tag}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(mark(set Mark p(Tag last)))}
            %%
            <<nil>>
         end
      end
      %%
      */
      %%
      %%  Yields names of tags at 'X,Y' in text widget;
      %%  ('X' and 'Y' are strings);
      meth getTagsOnXY(X Y ?Tags)
\ifdef DEEBUG_TI
         {Show 'tcl/tk: getTagsOnXY: ...'}
\endif
         local RS in
            RS = {Tk.return o(@browseWidget tag names "@"#X#","#Y)}
            %%
            Tags = {GetStrs RS CharSpace nil}
         end
      end
      %%
      %%  ... on first tagged char;
      meth getTagsOnTag(Tag ?Tags)
         local RS in
            RS = {Tk.return o(@browseWidget tag names p(Tag first))}
            %%
            Tags = {GetStrs RS CharSpace nil}
         end
      end
      %%
      %%
      %%  Yields 'False' if tags are the equal (i.e. the same);
      meth diffTags(T1 T2 ?Result)
         %%
         %% depends on 'TkNewName' (see at the bottom of this file);
         Result = {DiffStrs
                   {VirtualString.toString T1}
                   {VirtualString.toString T2}}
      end
      %%
      %%  Get the id for the tag for calling object;
      %%
      meth initBindings(Obj ?Id)
\ifdef DEBUG_TI
         {Show 'tcl/tk: initBindings: ...'}
\endif
         %%
         Id = {`TkIdServer` new(Obj $)}
      end
      %%
      %%
      %%  Destroy the id for the object;
      %%
      meth exitBindings(Id)
\ifdef DEBUG_TI
         {Show 'tcl/tk: exitBindings'#Id}
\endif
         %%
         {`TkIdServer` delete(Id)}
      end
      %%
      %%
      %%  Bind any-key-press with the message 'Mess' wrt the Id;
      %%
      meth keysBind(Tag TagId KeysHandler)
\ifdef DEBUG_TI
         {Show 'tcl/tk: keysBind:'#Tag#TagId}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            %%  Note: it takes now ASCII-characters, not keysums;
            %% (i.e. ',' instead of 'comma' for %K);
            {BrowseWidget
             tk(tag bind Tag '<KeyPress>'
                {`TkTranslateMessage` TagId KeysHandler q('%A' '%x' '%y')})}
            %%
         end
      end
      %%
      %%
      %%  Bind the buttons events;
      %%
      meth buttonsBind(Tag TagId ButtonsHandler)
\ifdef DEBUG_TI
         {Show 'tcl/tk: buttonsBind:'#Tag#TagId}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            %% discard effects of window-specific bindings (cut&paste);
            {BrowseWidget
             tk(tag bind Tag '<Shift-ButtonPress>' myNullProc)}
            %%
            {BrowseWidget
             tk(tag bind Tag '<ButtonPress>'
                {`TkTranslateMessage` TagId ButtonsHandler '%b %x %y'})}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Bind the buttons events;
      %%
      meth dButtonsBind(Tag TagId DButtonsHandler)
\ifdef DEBUG_TI
         {Show 'tcl/tk: dButtonsBind:'#Tag#TagId}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget
             tk(tag bind Tag '<Double-ButtonPress>'
                {`TkTranslateMessage` TagId DButtonsHandler '%b %x %y'})}
            %%
            <<nil>>
         end
      end
      %%
      %%
      %%  Highlight the tag;
      %%
      meth tagHighlight(Tag)
\ifdef DEBUG_TI
         {Show 'tcl/tk: tagHighlight:'#Tag}
\endif
         <<tagUnHighlight>>
         %%
         local BrowseWidget HighlightTag in
            <<[genTkName(HighlightTag) duplicateTag(Tag HighlightTag)]>>
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget tk(tag(config
                                     HighlightTag o(background:black
                                                    foreground:white)))}
            highlightTag <- HighlightTag
            %%
            <<nil>>
         end
      end
      %%
      %%
      meth tagUnHighlight
\ifdef DEBUG_TI
         {Show 'tcl/tk::tagUnHighlight'}
\endif
         case @highlightTag == InitValue then true
         else
            <<deleteTag(@highlightTag)>>
            highlightTag <- InitValue
         end
      end
      %%
      %%
      %%  put a new button on the buttons frame;
      %%  'ButtonProc' is an binary procedure, that can perform certain action on
      %% this button;
      %%
      meth pushButton(Text Action ?ButtonProc)
\ifdef DEBUG_TI
         {Show 'tcl/tk: pushButton:'#
          {String.toAtom {VirtualString.toString Text}}}
\endif
         %%
         case @buttonsFrame == InitValue then
            ButtonProc = proc {$ _ _} true end
         else
            local Button in
               Button = {New Tk.button tkInit(parent: @buttonsFrame
                                              text: Text
                                              action: Action
                                              width: IButtonWidth
                                              relief: IButtonRelief
                                              highlightthickness: 0
                                              padx: IButtonPad
                                              pady: IButtonPad
                                              bd: ISmallBorder)}
               %%
               {FoldL [IBFont1 IBFont2 IBFont3 IReservedFont]
                fun {$ Proceed IFont}
                   case Proceed then
                      %%
                      case
                         {Tk.returnInt
                          catch(q(Button conf(font: IFont)))} \= 0
                      then True
                      else False
                      end
                   else Proceed
                   end
                end
                True _}
               %%
               {Tk pack(Button o(side: top fill: x padx: IPad pady: IPad))}
               %%
               ButtonProc = proc {$ Action Arg}
                               case Action
                               of state then {Button tk(conf(state: Arg))}
                               [] label then {Button tk(conf(label: Arg))}
                               [] delete then {Button close}
                               else
                                  {BrowserError ['undefined action for a button']}
                               end
                            end
            end
         end
      end
      %%
      %%
      %%  Create a menu button and pack it on the menus frame;
      %%
      meth pushMenuButton(Text ?MenuButton ?MenuButtonProc)
\ifdef DEBUG_TI
         {Show 'tcl/tk: pushMenuButton:'#{String.toAtom {VirtualString.toString Text}}}
\endif
         %%
         case @menusFrame == InitValue then
            MenuButton = InitValue
            MenuButtonProc = proc {$ _ _} true end
         else
            local ResStr in
               MenuButton = {New Tk.menubutton tkInit(parent: @menusFrame
                                                      text: Text
                                                      width: IMBWidth
                                                      relief: IButtonRelief
                                                      highlightthickness: 0
                                                      padx: IButtonPad
                                                      pady: IButtonPad
                                                      bd: ISmallBorder)}
               %%
               {FoldL [IMBFont1 IMBFont2 IMBFont3 IReservedFont]
                fun {$ Proceed IFont}
                   case Proceed then
                      %%
                      case
                         {Tk.returnInt
                          catch(q(MenuButton conf(font: IFont)))} \= 0
                      then True
                      else False
                      end
                   else Proceed
                   end
                end
                True _}
               %%
            end
            %%
            {Tk pack(MenuButton o(side: left
                                   fill: none
                                   padx: IPad
                                   pady: IPad))}
            %%
            MenuButtonProc = proc {$ Action Arg}
                                case Action
                                of state then {MenuButton tk(conf(state: Arg))}
                                [] label then {MenuButton tk(conf(label: Arg))}
                                [] delete then {MenuButton close}
                                else
                                   {BrowserError ['undefined action for a menubutton']}
                                end
                             end
         end
      end
      %%
      %%
      %%  Create a menu with entries and actions;
      %%  Note that 'ParentOf' can be both the menubutton or another menu;
      %%
      meth defineMenu(MenuButton PostProc ?Menu)
\ifdef DEBUG_TI
         {Show 'tcl/tk: defineMenu:'}
\endif
         case MenuButton == InitValue then
            Menu = InitValue
         else
            % lazy (I'm);
            if ResStr in PostProc = True then
               Menu = {New Tk.menu tkInit(parent: MenuButton
                                          bd: ISmallBorder)}
               %%
               {FoldL [IMFont1 IMFont2 IMFont3 IReservedFont]
                fun {$ Proceed IFont}
                   case Proceed then
                      %%
                      case
                         {Tk.returnInt
                          catch(q(Menu conf(font: IFont)))} \= 0
                      then True
                      else False
                      end
                   else Proceed
                   end
                end
                True _}
               %%
            else
               local MA ResStr in
                  MA = {New Tk.action tkInit(PostProc)}
                  Menu = {New Tk.menu tkInit(parent: MenuButton
                                             bd: ISmallBorder
                                             postcommand: MA)}
                  %%
                  {FoldL [IMFont1 IMFont2 IMFont3 IReservedFont]
                   fun {$ Proceed IFont}
                      case Proceed then
                         %%
                         case
                            {Tk.returnInt
                             catch(q(Menu conf(font: IFont)))} \= 0
                         then True
                         else False
                         end
                      else Proceed
                      end
                   end
                   True _}
                  %%
               end
            fi
            %%
            {MenuButton tk(conf(menu: Menu))}
         end
      end
      %%
      %%
      %%
      meth defineSubMenu(ParentOf PostProc ?Menu)
\ifdef DEBUG_TI
         {Show 'tcl/tk: defineMenu:'}
\endif
         %%
         case ParentOf == InitValue then
            Menu = InitValue
         else
            % lazy (I'm);
            if ResStr in PostProc = True then
               Menu = {New Tk.menu tkInit(parent: ParentOf
                                          bd: ISmallBorder)}
               %%
               {FoldL [IMFont1 IMFont2 IMFont3 IReservedFont]
                fun {$ Proceed IFont}
                   case Proceed then
                      %%
                      case
                         {Tk.returnInt
                          catch(q(Menu conf(font: IFont)))} \= 0
                      then True
                      else False
                      end
                   else Proceed
                   end
                end
                True _}
               %%
            else
               local MA ResStr in
                  MA = {New Tk.action tkInit(PostProc)}
                  Menu = {New Tk.menu tkInit(parent: ParentOf
                                             bd: ISmallBorder
                                             postcommand: MA)}
                  %%
                  {FoldL [IMFont1 IMFont2 IMFont3 IReservedFont]
                   fun {$ Proceed IFont}
                      case Proceed then
                         %%
                         case
                            {Tk.returnInt
                             catch(q(Menu conf(font: IFont)))} \= 0
                         then True
                         else False
                         end
                      else Proceed
                      end
                   end
                   True _}
                  %%
               end
            fi
         end
      end
      %%
      %%
      %%  Create a 'command' entry in the 'Menu';
      %%  Note that the new label is given via 'EntryProc' must be matchable
      %% with the old label and '*' (for instance, " Depth " --> " Depth(1) ");
      %%
      meth addCommandEntry(Menu Label Proc ?EntryProc)
\ifdef DEBUG_TI
         {Show 'tcl/tk: addCommandEntry:'#
          {String.toAtom {VirtualString.toString Label}}}
\endif
         case Menu == InitValue then
            EntryProc = proc {$ _ _} true end
         else
            local L in
               %%
               %% relational;
               if Label = _#_ then
                  L = {List.flatten [Label.1 "*"]}
                  {Menu tk(add(command(label: Label.1
                                           accelerator: Label.2
                                           command:{New Tk.action tkInit(Proc)})))}
               else
                  L = {List.flatten [Label "*"]}
                  {Menu tk(add(command(label: Label
                                           command:{New Tk.action tkInit(Proc)})))}

               fi
               %%
               EntryProc = proc {$ Action Arg}
                              case Action
                              of state then
                                 {Menu tk(entryconfig(L o(state: Arg)))}
                              [] label then
                                 {Menu tk(entryconfig(L o(label: Arg)))}
                              [] delete then {Menu tk(delete(L))}
                              else
                                 {BrowserError ['undefined action for a menu entry']}
                              end
                           end
            end
         end
      end
      %%
      %%
      %%  Create a 'menu' entry in the 'Menu';
      %%
      meth addMenuEntry(Menu Label SubMenu ?EntryProc)
\ifdef DEBUG_TI
         {Show 'tcl/tk: addMenuEntry:'#
          {String.toAtom {VirtualString.toString Label}}}
\endif
         %%
         case Menu == InitValue then true
         else
            local L in
               {Menu tk(add(cascade(label: Label menu: SubMenu)))}
               L = {List.flatten [Label "*"]}
               %%
               EntryProc =
               proc {$ Action Arg}
                  case Action
                  of state then {Menu tk(entryconfig(L o(state: Arg)))}
                  [] label then {Menu tk(entryconfig(L o(label: Arg)))}
                  [] delete then {Menu tk(delete(L))}
                  else
                     {BrowserError ['undefined action for a menu entry']}
                  end
               end
            end
         end
      end
      %%
      %%
      %%  Create a tcl/tk variable - for check&radio buttons/menu entries;
      %%  UpdateProc is called every time when the value of the variable changes,
      %% i.e. when user clicks the button;
      %%  UpdateProc is an unary procedure that gets the (actual) value
      %% of the variable as the string;
      %%
      meth createTkVar(FValue UpdateProc ?TkVar)
\ifdef DEBUG_TI
         {Show 'tck/tk: createTkVar (init):'#FValue}
\endif
         local A in
            TkVar = {New Tk.variable tkInit(FValue)}
            %%
            A = {New Tk.action tkInit(proc{$ _ _ _}   % is not interesting;
                                         local A in
                                            A = {TkVar tkReturn($)}
                                            {UpdateProc A}
                                         end
                                      end)}
            %%
            {Tk trace(variable TkVar w A)}
         end
      end
      %%
      %%
      %%  Create a 'check' entry in the 'Menu';
      %%  OnValue and OffValue are the corresponding values;
      %%
      meth addCheckEntry(Menu Label TkVar OnValue OffValue ?EntryProc)
\ifdef DEBUG_TI
         {Show 'tcl/tk: addCheckEntry:'#
          {String.toAtom {VirtualString.toString Label}}}
\endif
         %%
         case Menu == InitValue then
            EntryProc = proc {$ _ _} true end
         else
            local L in
               %%
               {Menu tk(add(check(label: Label
                                      onvalue: OnValue
                                      offvalue: OffValue
                                      variable: TkVar)))}
               L = {List.flatten [Label "*"]}
               %%
               EntryProc =
               proc {$ Action Arg}
                  case Action
                  of state then {Menu tk(entryconfig(L o(state: Arg)))}
                  [] label then {Menu tk(entryconfig(L o(label: Arg)))}
                  [] delete then {Menu tk(delete(Label))}
                  else
                     {BrowserError ['undefined action for a menu entry']}
                  end
               end
            end
         end
      end
      %%
      %%
      %%  Create a 'radio' entry in the 'Menu';
      %%  Value is the 'active' value of this (particular) radio button;
      %%
      meth addRadioEntry(Menu Label TkVar Value ?EntryProc)
\ifdef DEBUG_TI
         {Show 'tcl/tk: addRadioEntry:'#
          {String.toAtom {VirtualString.toString Label}}}
\endif
         %%
         case Menu == InitValue then
            EntryProc = proc {$ _ _} true end
         else
            local L in
               %%
               {Menu tk(add(radio(label: Label
                                      value: Value
                                      variable: TkVar)))}
               L = {List.flatten [Label "*"]}
               %%
               EntryProc =
               proc {$ Action Arg}
                  case Action
                  of state then {Menu tk(entryconfig(L o(state: Arg)))}
                  [] label then {Menu tk(entryconfig(L o(label: Arg)))}
                  [] delete then {Menu tk(delete(Label))}
                  else
                     {BrowserError ['undefined action for a menu entry']}
                  end
               end
            end
         end
      end
      %%
      %%
      %%  Insert the 'separator' entry in the Menu;
      %%
      meth addSeparatorEntry(Menu)
\ifdef DEBUG_TI
         {Show 'tck/tk: addSeparatorEntry:'}
\endif
         case Menu == InitValue then true
         else
            {Menu tk(add(separator))}
         end
      end
      %%
      %%
      %%  Scroll to the first line of the tag + 'x' scroll to the first char;
      %%
      meth pickTagFirst(Tag)
\ifdef DEBUG_TI
         {Show 'tck/tk: pickTagFirst:'#Tag}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget [tk(see(p(Tag last)))
                           tk(see(p(Tag first)))
                           tk(see(p(Tag first '-' 1 'lines')))
                           tk(see(p(Tag first '+' 1 'lines')))]}
            %% tk(yview(scroll ~1 units))
         end
      end
      %%
      %%
      %%  Scroll to the last line of the tag;
      %%
      meth pickTagLast(Tag)
\ifdef DEBUG_TI
         {Show 'tck/tk: pickTagLast:'#Tag}
\endif
         local BrowseWidget in
            BrowseWidget = @browseWidget
            %%
            {BrowseWidget [tk(see(p(Tag first)))
                           tk(see(p(Tag last)))
                           tk(see(p(Tag last '+' 1 'lines')))
                           tk(see(p(Tag last '-' 1 'lines')))]}
            %% tk(yview(scroll 1 units))
            %%
         end
      end
      %%
      %%
      /*
      %%  Special: get the list of tags covering the character at given
      %%  *text widget* position;
      %%  Actually not used too;
      %%
      meth GetTagsList(Pos ?List)
\ifdef DEBUG_TI
         {Show 'tck/tk: GetTagsList'#Pos}
\endif
         %%
         local L in
            {@browseWidget tkReturn(tag(names Pos) L)}
            {TagsListLoop {Reverse L} List nil}
         end
      end
      %%
      */
      %%
      %%  DEBUG:
      %%  Get the text widget object;
      %%
      meth getTW(?TW)
         TW = @browseWidget
      end
      %%
   end
   %%
   %%
   %%
   %%  Window(s) for messages (warnings, errors);
   %%
   class ProtoMessageWindow from UrObject
      %%
      attr
         window:            InitValue
         messageWidget:     InitValue
         fb:                InitValue
      %%
      %%
      meth createMessageWindow
\ifdef DEBUG_TI
         {Show 'tck/tk: createMessageWindow'}
\endif
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
            CloseAction = {New Tk.action tkInit(proc {$} {self closeWindow} end)}
            %%
            Window = {New MyToplevel tkInit}
            {Tk.batch
             [wm(iconify Window)
              wm(title(Window IMTitle))
              wm(iconname(Window IMITitle))
              wm(iconbitmap(Window '@'#IMIBitmap))
              %%  {Tk.wm iconmask(Window '@'#IMIBMask)}
              wm(minsize Window IMXMinSize IMYMinSize)
              wm(protocol(Window "WM_DELETE_WINDOW" CloseAction))]}
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
            %%
            {FoldL [ITWFont1 ITWFont2 ITWFont3]
             fun {$ Proceed IFont}
                case Proceed then
                   %%
                   case
                      {Tk.returnInt
                       catch(q(MessageWidget conf(font: IFont.font)))} \= 0
                   then True
                   else False
                   end
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
            %%
            {Tk.batch
             [pack(VS o(fill: y padx: IPad pady: IPad side: right))
              pack(FB o(fill: y padx: IPad pady: IPad side: left))
              pack(MessageWidget o(fill: both padx: IPad pady: IPad
                                   side: bottom expand: yes))
              o(pr#oc myNullProc '' '')
              %%
              bindtags(MessageWidget q(MessageWidget))
              %%  i.e. nothing;
              ]}
            %%
            %%
            %% {Window tkBind(event:'<Destroy>'
            %%                action: proc {$} {self destroyClose} end)}
            %%
            %% sync;
            case {All [Window MessageWidget FB] IsValue} then
               <<nil>>
            end
         end
      end
      %%
      %%
      %%   Put a new button on the buttons frame;
      %%  Note that a calling procedure should treat 'Button' as an atomic value
      %%  and use it only for 'confButton' messages;
      %%
      meth pushButton(Text Action ?Button)
         case @window == InitValue then true
         else
            local ResStr in
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
               %%
               {FoldL [IBFont1 IBFont2 IBFont3 IReservedFont]
                fun {$ Proceed IFont}
                   case Proceed then
                      %%
                      case
                         {Tk.returnInt
                          catch(q(Button conf(font: IFont)))} \= 0
                      then True
                      else False
                      end
                   else Proceed
                   end
                end
                True _}
               %%
            end
            %%
            {Tk pack(Button o(side: top fill: x padx: IPad pady: IPad))}
         end
      end
      %%
      %%
      %%
      meth showIn(VS)
         case @window == InitValue then true
         else
            local G P X Y MyScreen LWScreen in
               {@messageWidget [tk(insert(insert VS))
                                tk(insert(insert "\n"))
                                tk(yview("insert - 2 lines"))]}
               %%
               %%
               %% lazy (I'm);
               if LeaderWindow RealLWindow in
                  @leaderWindow = LeaderWindow
               then
                  case LeaderWindow == InitValue then
                     {Tk.batch [update wm(deiconify @window)]}
                  else
                     MyScreen = {VirtualString.toString
                                 {Tk.return
                                  winfo(screen @window)}}
                     LWScreen = {VirtualString.toString
                                 {Tk.return
                                  winfo(screen LeaderWindow)}}
                     %%
                     case {DiffStrs MyScreen LWScreen} then
                        {Tk.batch [update wm(deiconify @window)]}
                     else
                        %%
                        %%  the same screen;
                        RealLWindow = {VirtualString.toString
                                       {Tk.return
                                        winfo(toplevel LeaderWindow)}}
                        %%
                        case {All RealLWindow IsValue} then
                           {Tk.return wm(geometry RealLWindow) G}
                           P = {Tail G {FindChar G "+".1}}
                           X = {String.toInt {Head P.2 ({FindChar P.2 "+".1} - 1)}}
                           Y = {String.toInt {Tail P.2 ({FindChar P.2 "+".1} + 1)}}
                           %%
                           case {All [X Y] IsValue} then
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
               else
                  {Tk.batch [update wm(deiconify @window)]}
               fi
            end
         end
      end
      %%
      %%
      %%
      meth clear
         case @window == InitValue then true
         else
            {@messageWidget tk(delete(p(1 0) insert))}
         end
      end
      %%
      %%
      %%
      meth iconify
         case @window == InitValue then true
         else
            {Tk wm(iconify @window)}
         end
      end
      %%
      %%  close the top level widnow;
      %%
      meth closeWindow
         case @window == InitValue then true
         else
            {@window close}
            window <- InitValue
            messageWidget <- InitValue
            fb <- InitValue
         end
      end
   end
   %%
   %%
   %%  Help Window;
   %%
   class ProtoHelpWindow from UrObject
      %%
      attr
         window:            InitValue
         messageWidget:     InitValue
         fb:                InitValue
      %%
      %%
      meth createHelpWindow(screen: Screen)
\ifdef DEBUG_TI
         {Show 'tck/tk: createHelpWindow'}
\endif
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
            %%
            CloseAction = {New Tk.action tkInit(proc {$} {self close} end)}
            %%
            case Screen == InitValue then
               Window = {New MyToplevel tkInit}
            else
               Window = {New MyToplevel tkInit(screen: Screen)}
            end
            %%
            {Tk.batch
             [wm(title(Window IHTitle))
              wm(iconname(Window IHITitle))
              wm(iconbitmap(Window '@'#IIBitmap))
              %%  {Tk.wm iconmask(Window '@'#IMIBMask)}
              wm(geometry Window IHXSize#x#IHYSize)
              wm(protocol(Window "WM_DELETE_WINDOW" CloseAction))]}
            %%
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
            %%
            {FoldL [ITWFont1 ITWFont2 ITWFont3]
             fun {$ Proceed IFont}
                case Proceed then
                   %%
                   case
                      {Tk.returnInt
                       catch(q(MessageWidget conf(font: IFont.font)))} \= 0
                   then True
                   else False
                   end
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
            %%
            {Tk.batch
             [pack(VS o(fill: y padx: IPad pady: IPad side: right))
              pack(MessageWidget o(fill: both padx: IPad pady: IPad
                                   side: bottom expand: yes))
              %%
              o(pr#oc myNullProc '' '')
              %%
              bindtags(MessageWidget q(MessageWidget))
              %%  i.e. nothing;
              ]}
            %%
            %%
            %% {Window tkBind(event:'<Destroy>'
            %%             action: proc {$} {self destroyClose} end)}
            %%
            %% sync;
            case {IsValue Window} andthen {IsValue MessageWidget} then
               <<nil>>
            end
         end
      end
      %%
      %%
      %%
      meth showIn(VS)
         case @window == InitValue then true
         else
            {@messageWidget [tk(insert(insert VS))
                             tk(insert(insert "\n"))]}
                                % tk(yview("insert - 2 lines"))
            %%
         end
      end
      %%
      %%
      %%
      meth close
         case @window == InitValue then true
         else
            {@window close}
            %%
            window <- InitValue
            messageWidget <- InitValue
            %%
            <<UrObject close>>
         end
      end
   end
   %%
   %%
%%%
%%%
%%%   Local auxiliary functions;
%%%
   %%
   %%  optimized: create Tags and Marks
   %%
   local C = {Cell.new 1} in
      fun {TkNewName}
         Val NewVal
      in
         Val = {Cell.exchange C $ NewVal}
         NewVal = Val + 1
         browser#Val
      end
   end
   %%
   %%
   proc {TagsListLoop In OutList Tmp}
      %% relational;
      if E R NT in In = E|R then
         case E == CharSpace then
            OutList = Tmp|NT
            {TagsListLoop R NT nil}
         else
            {TagsListLoop R OutList E|Tmp}
         end
      else OutList = [Tmp]
      fi
   end
   %%
   %%
   proc {RemovePosition Widget Pos STag Tags Sync}
      %% relational;
      if T R in Tags = T|R then
         case STag == T then Sync = ok
         else
            {Widget tk(tag(remove T Pos))}
            {RemovePosition Widget Pos STag R Sync}
         end
      else
         {BrowserError [' RemovePosition: have not found itself']}
         %%  since otherwise something has gone wrong;
      fi
   end
   %%
   %%
   fun {GetNums Str Delim ParRes}
      local Ind in
         Ind = {FindChar Str Delim}
         %%
         case Ind == ~1 then {Append ParRes [{String.toInt Str}]}
         else
            local HeadOf TailOf in
               HeadOf = {String.toInt {Head Str Ind-1}}
               TailOf = {Tail Str Ind+1}
               %%
               {GetNums TailOf Delim {Append ParRes [HeadOf]}}
            end
         end
      end
   end
   %%
   %%
end
