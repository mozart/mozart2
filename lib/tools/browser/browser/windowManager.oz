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
%%%   Core window manager;
%%%
%%%
%%%
%%%

%%
class WindowManagerClass from UrObject
   %%
   feat
   %% There is a number of object-depended procedures:
      Entry2Path                %  (see beneath;)
      Button2Path               %
      CleanUp                   %
      Oz2Tcl                    %
      Tcl2Oz                    %

   %%
   attr
      window:  InitValue        %  the window object itself;
      menu:    InitValue        %  menubar;
   %%  'varDict' is here when there is the menubar;
      varDict: InitValue        %  a dictionary where a mapping
                                %  "atoms" --> "tcl vars" is stored in
                                %  ("tcl vars" are 'Tk.variable' objects);

   %%
   %%
   meth initWindow
      %%
      %% This procedure maps (abstract) entries to "full-qualified"
      %% paths to corresponding 'menubar' entries;
      self.Entry2Path =
      fun {$ Entry}
         case Entry
         of break             then browser(break)
         [] unselect          then browser(unselect)
         [] toggleMenus       then browser(toggleMenus)
         [] help              then browser(help)
         [] checkLayout       then browser(checkLayout)
         [] reset             then browser(reset)
         [] close             then browser(close)
         [] clear             then buffer(clear)
         [] clearAllButLast   then buffer(clearAllButLast)
         [] expand            then navigate(expand)
         [] shrink            then navigate(shrink)
         [] deref             then navigate(deref)
         [] rebrowse          then navigate(rebrowse)
         [] zoom              then navigate(zoom)
         [] showOPI           then navigate(showOPI)
         [] newView           then navigate(newView)
%        [] smoothScrolling   then view(smoothScrolling)
         [] showGraph         then view(showGraph)
         [] showMinGraph      then view(showMinGraph)
         [] arityType         then view(arityType)
         [] areVSs            then view(areVSs)
         [] smallNames        then view(smallnames)
         [] fillStyle         then view(fillStyle)
         else InitValue
         end
      end

      %%
      self.Button2Path =
      fun {$ Button}
         case Button
         of break             then break
         [] unselect          then unselect
         else InitValue
         end
      end

      %%
      self.CleanUp = fun {$ A} A \= InitValue end

      %%
      %%  (Oz) Names cannot be passed around with tcl/tk;
      self.Oz2Tcl =
      fun {$ OzValue}
         case OzValue
         of true             then 'tcl_True'
         [] false            then 'tcl_False'
         [] !Expanded         then 'tcl_Expanded'
         [] !Filled           then 'tcl_Filled'
         [] !AtomicArity      then 'tcl_AtomicArity'
         [] !TrueArity        then 'tcl_TrueArity'
         else
            {BrowserError 'WindowManagerClass.Oz2Tcl: unknown value!'}
            'tcl_False'
         end
      end

      %%
      self.Tcl2Oz =
      fun {$ TclValue}
         case TclValue
         of 'tcl_True'        then true
         [] 'tcl_False'       then false
         [] 'tcl_Expanded'    then Expanded
         [] 'tcl_Filled'      then Filled
         [] 'tcl_AtomicArity' then AtomicArity
         [] 'tcl_TrueArity'   then TrueArity
         else
            {BrowserError 'WindowManagerClass.Tcl2Oz: unknown value!'}
            false
         end
      end
   end

   %%
   %%
   meth createWindow
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createWindow is applied'}
\endif
      %%
      case @window == InitValue then
         %%
         %%  This guy produces a top-level window without a menubar;
         window <- {New BrowserWindowClass
                    init(window: {self.store read(StoreOrigWindow $)}
                         screen: {self.store read(StoreScreen $)}
                         browserObj: self.browserObj
                         store: self.store)}

         %%
         {@window [setMinSize expose setWaitCursor]}

         %%
         {BrowserMessagesInit @window}

         %%
         {self.store store(StoreIsWindow true)}
      else skip
      end

      %%
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createWindow is finished'}
\endif
      touch
   end

   %%
   %%
   meth createMenus
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createMenus is applied'}
\endif
      %%
      case @varDict == InitValue then
         Store VarDict BO Window Menus
%        SmoothScrollingVar
         ShowGraphVar ShowMinGraphVar ArityTypeVar AreVSsVar
         FillStyleVar SmallNamesVar FontVar TclTrue TclFalse
      in
         %%
         Store = self.store
         BO = self.browserObj
         Window = @window
         TclTrue = {self.Oz2Tcl true}
         TclFalse = {self.Oz2Tcl false}

         %%
         VarDict = {Dictionary.new}

         %%
         %%  tcl variables for radio- and check- entries;
         {Window
          [%%
%          createTkVar({self.Oz2Tcl {Store read(StoreSmoothScrolling $)}}
%                      proc {$ V}
%                         {Store store(StoreSmoothScrolling
%                                      {self.Tcl2Oz {String.toAtom V}})}
%                      end
%                      SmoothScrollingVar)

           createTkVar({self.Oz2Tcl {Store read(StoreShowGraph $)}}
                       proc {$ V}
                          local TV in
                             TV = {self.Tcl2Oz {String.toAtom V}}

                             %%
                             {Store store(StoreShowGraph TV)}
                             case TV then
                                {ShowMinGraphVar tkSet({self.Oz2Tcl false})}
                             else skip
                             end
                          end
                       end
                       ShowGraphVar)

           %%
           createTkVar({self.Oz2Tcl {Store read(StoreShowMinGraph $)}}
                       proc {$ V}
                          local TV in
                             TV = {self.Tcl2Oz {String.toAtom V}}

                             %%
                             {Store store(StoreShowMinGraph TV)}
                             case TV then
                                {ShowGraphVar tkSet({self.Oz2Tcl false})}
                             else skip
                             end
                          end
                       end
                       ShowMinGraphVar)

           %%
           createTkVar({self.Oz2Tcl {Store read(StoreArityType $)}}
                       proc {$ V}
                          {Store store(StoreArityType
                                       {self.Tcl2Oz {String.toAtom V}})}
                       end
                       ArityTypeVar)

           %%
           createTkVar({self.Oz2Tcl {Store read(StoreAreVSs $)}}
                       proc {$ V}
                          {Store store(StoreAreVSs
                                       {self.Tcl2Oz {String.toAtom V}})}
                       end
                       AreVSsVar)

           %%
           createTkVar({self.Oz2Tcl {Store read(StoreFillStyle $)}}
                       proc {$ V}
                          {Store store(StoreFillStyle
                                       {self.Tcl2Oz {String.toAtom V}})}
                       end
                       FillStyleVar)

           %%
           createTkVar({self.Oz2Tcl {Store read(StoreSmallNames $)}}
                       proc {$ V}
                          {Store store(StoreSmallNames
                                       {self.Tcl2Oz {String.toAtom V}})}
                       end
                       SmallNamesVar)

           %%
           createTkVar({Store read(StoreTWFont $)}.font
                       proc {$ V}
                          local FN StoredFN in
                             FN = {String.toAtom V}
                             StoredFN = {Store read(StoreTWFont $)}

                             %%
                             {ForAll
                              {Append IKnownMiscFonts IKnownCourFonts}
                              proc {$ Font}
                                 case
                                    Font.font == FN andthen
                                    StoredFN \= FN
                                 then {Window setTWFont(Font _)}
                                 else skip
                                 end
                              end}
                          end
                       end
                       FontVar)

           %%
          ]}

         %%
%        {Dictionary.put VarDict smoothScrolling SmoothScrollingVar}
         {Dictionary.put VarDict showGraph ShowGraphVar}
         {Dictionary.put VarDict showMinGraph ShowMinGraphVar}
         {Dictionary.put VarDict arityType ArityTypeVar}
         {Dictionary.put VarDict areVSs AreVSsVar}
         {Dictionary.put VarDict fillStyle FillStyleVar}
         {Dictionary.put VarDict smallNames SmallNamesVar}
         {Dictionary.put VarDict font FontVar}

         %%
         varDict <- VarDict

         %%
         %%  All the elements of the menubar
         %%  (The 'TkTools.menubar' is used);
         Menus =
         [menubutton(text: 'Browser'
                     menu: [%%
                            command(label:   'Break'
                                    % key:     ctrl(c)
                                    acc:     '     C-c'
                                    action:  BO#break
                                    feature: break)
                            command(label:   'Unselect'
                                    action:  BO#UnsetSelected
                                    feature: unselect)
                            separator

                            %%
%                           command(label:   'Toggle menus'
%                                   % key:     ctrl(alt(m))
%                                   acc:     '   C-A-m'
%                                   action:  BO#toggleMenus
%                                   feature: toggleMenus)
%                           separator

                            %%
                            command(label:   'Help'
                                    % key:     ctrl(h)
                                    acc:     '     C-h'
                                    action:  BO#Help
                                    feature: help)
                            separator

                            %%
                            command(label:   'Refine layout'
                                    % key:     ctrl(l)
                                    acc:     '     C-l'
                                    action:  BO#checkLayout
                                    feature: checkLayout)
                            command(label:   'Reset'
                                    action:  BO#Reset
                                    feature: reset)
                            separator

                            %%
                            command(label:   'Close'
                                    % key:     ctrl(x)
                                    acc:     '     C-x'
                                    action:  BO#close
                                    feature: close)]
                     feature: browser)

          %% 'Buffer' menu;
          menubutton(text: 'Buffer'
                     menu:
                        [%%
                         command(label:   'Clear'
                                 % key:     ctrl(u)
                                 acc:     '     C-u'
                                 action:  BO#clear
                                 feature: clear)
                         command(label:   'Clear All But Last'
                                 action:  BO#clearAllButLast
                                 feature: clearAllButLast)
                         separator

                         %%
                         cascade(label:   'Size'
                                 menu:
                                    [command(label:  ' 1 '
                                             action: BO#SetBufferSize(1))
                                     command(label:  ' 5 '
                                             action: BO#SetBufferSize(5))
                                     command(label:  ' 25 '
                                             action: BO#SetBufferSize(25))
                                     command(label:  ' 50 '
                                             action: BO#SetBufferSize(50))
                                     command(label:  ' unbounded '
                                             action:
                                                BO#SetBufferSize(DInfinite))
                                     command(label:  ' +1 '
                                             action:
                                                BO#ChangeBufferSize(1))
                                     command(label:  ' +5 '
                                             action:
                                                BO#ChangeBufferSize(5))
                                     command(label:  ' +25 '
                                             action:
                                                BO#ChangeBufferSize(25))
                                     command(label:  ' -1 '
                                             action:
                                                BO#ChangeBufferSize(~1))
                                     command(label:  ' -5 '
                                             action:
                                                BO#ChangeBufferSize(~5))
                                     command(label:  ' -25 '
                                             action:
                                                BO#ChangeBufferSize(~25))
                                    ]
                                 feature: size)]
                     feature: buffer)

          %% 'Navigate' menu;
          menubutton(text: 'Navigate'
                     menu: [%%
                            command(label:   'Expand'
                                    % key:     e
                                    acc:     '       e'
                                    action:  BO#SelExpand
                                    feature: expand)
                            command(label:   'Shrink'
                                    % key:     s
                                    acc:     '       s'
                                    action:  BO#SelShrink
                                    feature: shrink)
                            separator

                            %%
                            command(label:   'Deref'
                                    % key:     d
                                    acc:     '       d'
                                    action:  BO#SelDeref
                                    feature: deref)
                            separator

                            %%
                            command(label:   'Rebrowse'
                                    % key:     ctrl(b)
                                    acc:     '     C-b'
                                    action:  BO#rebrowse
                                    feature: rebrowse)
                            command(label:   'Zoom'
                                    % key:     z
                                    acc:     '       z'
                                    action:  BO#SelZoom
                                    feature: zoom)
                            command(label:   'Show in OPI'
                                      % key:     ctrl(s)
                                      acc:     '     C-s'
                                      action:  BO#SelShow
                                      feature: showOPI)
                            command(label:   'New view'
                                    % key:     ctrl(n)
                                    acc:     '     C-n'
                                    action:  BO#createNewView
                                    feature: newView)]
                     feature: navigate)

          %%  'View' menu;
          menubutton(text: 'View'
                     menu:
                        [%%
%                          checkbutton(label:     'Smooth scrolling'
%                                      variable:  SmoothScrollingVar
%                                      onvalue:   TclTrue
%                                      offvalue:  TclFalse
%                                      feature:   smoothScrolling)
%                          separator

                         %%
                         checkbutton(label:     'Show Graph'
                                     variable:  ShowGraphVar
                                     onvalue:   TclTrue
                                     offvalue:  TclFalse
                                     feature:   showGraph)
                         checkbutton(label:     'Show Min Graph'
                                     variable:  ShowMinGraphVar
                                     onvalue:   TclTrue
                                     offvalue:  TclFalse
                                     feature:   showMinGraph)
                         separator

                         %%
                         checkbutton(label:     'Private Chunk fields'
                                     variable:  ArityTypeVar
                                     onvalue:   {self.Oz2Tcl TrueArity}
                                     offvalue:  {self.Oz2Tcl AtomicArity}
                                     feature:   arityType)
                         checkbutton(label:     'Virtual strings'
                                     variable:  AreVSsVar
                                     onvalue:   TclTrue
                                     offvalue:  TclFalse
                                     feature:   areVSs)
                         checkbutton(label:     'Names & Procs short'
                                     variable:  SmallNamesVar
                                     onvalue:   TclTrue
                                     offvalue:  TclFalse
                                     feature:   smallNames)
                         separator

                         %%
                         checkbutton(label:     'Record fields aligned'
                                     variable:  FillStyleVar
                                     onvalue:   {self.Oz2Tcl Expanded}
                                     offvalue:  {self.Oz2Tcl Filled}
                                     feature:   fillStyle)
                         separator

                         %%
                         cascade(label:   'Depth'
                                 menu:
                                    [command(label:  ' 1 '
                                             action: BO#SetDepth(1))
                                     command(label:  ' 2 '
                                             action: BO#SetDepth(2))
                                     command(label:  ' 5 '
                                             action: BO#SetDepth(5))
                                     command(label:  ' 10 '
                                             action: BO#SetDepth(10))
                                     command(label:  ' 25 '
                                             action: BO#SetDepth(25))
                                     command(label:  ' unbounded '
                                             action:
                                                BO#SetDepth(DInfinite))
                                     command(label:  ' +1 '
                                             action: BO#ChangeDepth(1))
                                     command(label:  ' +2 '
                                             action: BO#ChangeDepth(2))
                                     command(label:  ' +5 '
                                             action: BO#ChangeDepth(5))
                                     command(label:  ' -1 '
                                             action: BO#ChangeDepth(~1))
                                     command(label:  ' -2 '
                                             action: BO#ChangeDepth(~2))
                                     command(label:  ' -5 '
                                             action: BO#ChangeDepth(~5))
                                    ]
                                 feature: depth)
                         cascade(label:   'Width'
                                 menu:
                                    [command(label:  ' 2 '
                                             action: BO#SetWidth(2))
                                     command(label:  ' 5 '
                                             action: BO#SetWidth(5))
                                     command(label:  ' 10 '
                                             action: BO#SetWidth(10))
                                     command(label:  ' 25 '
                                             action: BO#SetWidth(25))
                                     command(label:  ' 50 '
                                             action: BO#SetWidth(50))
                                     command(label:  ' unbounded '
                                             action:
                                                BO#SetWidth(DInfinite))
                                     command(label:  ' +1 '
                                             action: BO#ChangeWidth(1))
                                     command(label:  ' +2 '
                                             action: BO#ChangeWidth(2))
                                     command(label:  ' +5 '
                                             action: BO#ChangeWidth(5))
                                     command(label:  ' +10 '
                                             action: BO#ChangeWidth(10))
                                     command(label:  ' +25 '
                                             action: BO#ChangeWidth(25))
                                     command(label:  ' -1 '
                                             action: BO#ChangeWidth(~1))
                                     command(label:  ' -2 '
                                             action: BO#ChangeWidth(~2))
                                     command(label:  ' -5 '
                                             action: BO#ChangeWidth(~5))
                                     command(label:  ' -10 '
                                             action: BO#ChangeWidth(~10))
                                     command(label:  ' -25 '
                                             action: BO#ChangeWidth(~25))
                                    ]
                                 feature: width)
                         cascade(label:   'Depth Inc'
                                 menu:
                                    [command(label:  ' 1 '
                                             action: BO#SetDInc(1))
                                     command(label:  ' 2 '
                                             action: BO#SetDInc(2))
                                     command(label:  ' 5 '
                                             action: BO#SetDInc(5))
                                     command(label:  ' 10 '
                                             action: BO#SetDInc(10))
                                     command(label:  ' +1 '
                                             action: BO#ChangeDInc(1))
                                     command(label:  ' +2 '
                                             action: BO#ChangeDInc(2))
                                     command(label:  ' +5 '
                                             action: BO#ChangeDInc(5))
                                     command(label:  ' -1 '
                                             action: BO#ChangeDInc(~1))
                                     command(label:  ' -2 '
                                             action: BO#ChangeDInc(~2))
                                     command(label:  ' -5 '
                                             action: BO#ChangeDInc(~5))
                                    ]
                                 feature: depthInc)
                         cascade(label:   'Width Inc'
                                 menu:
                                    [command(label:  ' 1 '
                                             action: BO#SetWInc(1))
                                     command(label:  ' 2 '
                                             action: BO#SetWInc(2))
                                     command(label:  ' 5 '
                                             action: BO#SetWInc(5))
                                     command(label:  ' 10 '
                                             action: BO#SetWInc(10))
                                     command(label:  ' 25 '
                                             action: BO#SetWInc(25))
                                     command(label:  ' +1 '
                                             action: BO#ChangeWInc(1))
                                     command(label:  ' +2 '
                                             action: BO#ChangeWInc(2))
                                     command(label:  ' +5 '
                                             action: BO#ChangeWInc(5))
                                     command(label:  ' +10 '
                                             action: BO#ChangeWInc(10))
                                     command(label:  ' -1 '
                                             action: BO#ChangeWInc(~1))
                                     command(label:  ' -2 '
                                             action: BO#ChangeWInc(~2))
                                     command(label:  ' -5 '
                                             action: BO#ChangeWInc(~5))
                                     command(label:  ' -10 '
                                             action: BO#ChangeWInc(~10))

                                    ]
                                 feature: widthInc)
                         separator

                         %%
                         cascade(label:   'Font'
                                 menu:
                                    %%  ... will be added later dynamically;
                                    [cascade(label:   'Misc'
                                             menu:    nil
                                             feature: misc)
                                     cascade(label:   'Courier'
                                             menu:    nil
                                             feature: courier)]
                                 feature: font)]
                     feature: view)

          %%
         ]

         %%
         %%  create & pack it;
         {Window [createMenuBar(Menus)
                  pushButton(break(text:   'Break'
                                   action: BO#break))
                  pushButton(unselect(text:   'Unselect'
                                      action: BO#UnsetSelected))
                  exposeMenuBar]}

         %%
         %%  everything else is done asynchronously;
         thread
            %%
            %% no "tear-off" menus;
            {Window
             noTearOff([browser(menu)
                        buffer(menu) buffer(size(menu))
                        navigate(menu)
                        view(menu)
                        view(depth(menu)) view(width(menu))
                        view(depthInc(menu)) view(widthInc(menu))
                        view(font(menu))
                        view(font(misc(menu))) view(font(courier(menu)))])}

            %%
            %% Key bindings;
            {Window [bindKey(key: ctrl(c)      action: BO#break)
                     bindKey(key: ctrl(b)      action: BO#rebrowse)
                     bindKey(key: ctrl(s)      action: BO#SelShow)
                     bindKey(key: ctrl(n)      action: BO#createNewView)
                     bindKey(key: ctrl(l)      action: BO#checkLayout)
                     bindKey(key: ctrl(alt(m)) action: BO#toggleMenus)
                     bindKey(key: ctrl(h)      action: BO#Help)
                     bindKey(key: ctrl(x)      action: BO#close)
                     bindKey(key: ctrl(u)      action: BO#clear)
                     bindKey(key: z            action: BO#SelZoom)
                     bindKey(key: d            action: BO#SelDeref)
                     bindKey(key: e            action: BO#SelExpand)
                     bindKey(key: s            action: BO#SelShrink)]}

            %%
            %%  'postcommand' for 'Buffer' and 'View' menu;
            {Window
             [setPostCommand(buffer(menu)
                             proc {$ MP}
                                local BS in
                                   BS = {Store read(StoreBufferSize $)}

                                   %%
                                   {MP 'Size'
                                    case BS == DInfinite
                                    then 'Size (unbounded) '
                                    else 'Size (' # BS # ') '
                                    end}
                                end
                             end)
              setPostCommand(view(menu)
                             proc {$ MP}
                                local Depth Width DepthInc WidthInc in
                                   {Store [read(StoreDepth Depth)
                                           read(StoreWidth Width)
                                           read(StoreDepthInc DepthInc)
                                           read(StoreWidthInc WidthInc)]}

                                   %%
                                   {MP 'Depth'
                                    case Depth == DInfinite
                                    then 'Depth (unbounded)'
                                    else 'Depth (' # Depth # ')'
                                    end}

                                   %%
                                   {MP 'Width'
                                    case Width == DInfinite
                                    then 'Width (unbounded)'
                                    else 'Width (' # Width # ')'
                                    end}

                                   %%
                                   {MP 'Depth Inc'
                                    'Depth Inc (' # DepthInc # ')'}
                                   {MP 'Width Inc'
                                    'Width Inc (' # WidthInc # ')'}
                                end
                             end)]}

            %%
            %%  Set up fonts;
            %%  Note that these entries are uncofigurable now
            %% (because they are dynamic (may appear later),
            %% and 'CProc' is being thrown away);
            {ForAll IKnownMiscFonts
             proc {$ Font}
                local IsThere CProc in
                   %%
                   IsThere = {Window tryFont(Font $)}

                   %%
                   {Window
                    addRadioEntry(view(font(misc(menu)))
                                  Font.name
                                  FontVar Font.font CProc)}

                   %%
                   case IsThere then skip % font exists - ok;
                   else {CProc state disabled}
                   end
                end
             end}

            %%
            {ForAll IKnownCourFonts
             proc {$ Font}
                local IsThere CProc in
                   %%
                   IsThere = {Window tryFont(Font $)}

                   %%
                   {Window
                    addRadioEntry(view(font(courier(menu)))
                                  Font.name
                                  FontVar Font.font CProc)}

                   %%
                   case IsThere then skip % font exists - ok;
                   else {CProc state disabled}
                   end
                end
             end}

            %%
         end

         %%
         case @window.standAlone then skip
         else WindowManagerClass , entriesDisable([close])
         end

         %%
         {self.store store(StoreAreMenus true)}
      else skip                 % already;
      end

      %%
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createMenus is finished'}
\endif
      touch
   end

   %%
   %%
   meth resetWindowSize
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::resetWindowSize is applied'}
\endif
      %%
      case @window == InitValue then skip
      else X Y in
         {@store [read(StoreXSize X) read(StoreYSize Y)]}

         %%
         {@window [setXYSize(X Y) resetTW]}
      end

      %%
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::resetWindowSize is finished'}
\endif
      touch
   end

   %%
   %%
   meth focusIn
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::focusIn is applied'}
\endif
      WindowManagerClass , WrapWindow(focusIn)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::focusIn is finished'}
\endif
   end

   %%
   %%
   meth closeMenus
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::closeMenus is applied'}
\endif
      case @window \= InitValue andthen @varDict \= InitValue then
         {@window closeMenuBar}

         %%
         varDict <- InitValue
         {self.store store(StoreAreMenus false)}
      else skip
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::closeMenus is finished'}
\endif
   end

   %%
   %%
   meth closeWindow
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::closeWindow is applied'}
\endif
      %%
      case @window == InitValue then skip
      else
         %%
         WindowManagerClass , closeMenus

         %%
         {@window close}
         window <- InitValue
         {self.store store(StoreIsWindow false)}
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::closeWindow is finished'}
\endif
   end

   %%
   %%  'Arg' is a list of entry names;
   meth entriesEnable(Arg)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::entriesEnable is applied'}
\endif
      %%
      local MEs Bs in
         MEs = {Filter {Map Arg self.Entry2Path} self.CleanUp}
         Bs = {Filter {Map Arg self.Button2Path} self.CleanUp}

         %%
         WindowManagerClass , WrapMenuBar(commandEntriesEnable(MEs))
         WindowManagerClass , WrapMenuBar(buttonsEnable(Bs))

         %%
         case Arg of [break] then
            WindowManagerClass , WrapWindow(setWaitCursor)
         else skip
         end
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::entriesEnable is finished'}
\endif
   end

   %%
   meth entriesDisable(Arg)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::entriesDisable is applied'}
\endif
      local MEs Bs in
         MEs = {Filter {Map Arg self.Entry2Path} self.CleanUp}
         Bs = {Filter {Map Arg self.Button2Path} self.CleanUp}

         %%
         WindowManagerClass , WrapMenuBar(commandEntriesDisable(MEs))
         WindowManagerClass , WrapMenuBar(buttonsDisable(Bs))

         %%
         case Arg of [break] then
            WindowManagerClass , WrapWindow(setDefaultCursor)
         else skip
         end
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::entriesDisable is finished'}
\endif
   end

   %%
   meth setTWFont(Font ?Res)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setTWFont is applied'}
\endif
      WindowManagerClass , WrapWindow(setTWFont(Font Res))
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setTWFont is finished'}
\endif
   end

   %%
   meth setVarValue(VarIndex Value)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setVarValue is applied'}
\endif
      case @window \= InitValue andthen @varDict \= InitValue then TclVar in
         TclVar = {Dictionary.condGet @varDict VarIndex InitValue}

         %%
         case TclVar == InitValue
         then {BrowserError 'WindowManagerClass:setVarValue: Unknown var!'}
         else {@window setTkVar(TclVar {self.Oz2Tcl Value})}
         end
      else skip
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setVarValue is finished'}
\endif
   end

   %%
   meth setFont(Font)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setFont is applied'}
\endif
      case @window \= InitValue andthen @varDict \= InitValue then
         %%
         {@window setTkVar({Dictionary.get @varDict font} Font.font)}
      else skip
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setFont is finished'}
\endif
   end

   %%
   meth unHighlightTerm
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::unHighlightTerm is applied'}
\endif
      WindowManagerClass , WrapWindow(unHighlightRegion)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::unHighlightTerm is finished'}
\endif
   end

   %%
   %%  ... Aux: checks either we have created a window already;
   %% Otherwise, the message ('Meth') is just ignored;
   meth WrapWindow(Meth)
      case @window \= InitValue then {@window Meth}
      else skip
      end
   end

   %%
   meth WrapMenuBar(Meth)
      case @window \= InitValue andthen @varDict \= InitValue
      then {@window Meth}
      else skip
      end
   end

   %%
end
