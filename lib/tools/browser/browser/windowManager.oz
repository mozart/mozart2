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
class WindowManagerClass from MyClosableObject BatchObject
   %%
   feat
   %% There is a number of object-depended procedures:
      Entry2Path                %  (see beneath;)
      Button2Path               %
      CleanUp                   %

   %%
   attr
      window:      InitValue    %  the window object itself;
   %%
      actionVar:   InitValue    %  tcl's variable;
      actions:     InitValue    %  dictionary of actions;
      nextANumber: InitValue    %  ... and a next free index in it;

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
         [] about             then browser(about)
         [] checkLayout       then browser(checkLayout)
         [] close             then browser(close)
         [] clear             then browser(clear)
         [] clearAllButLast   then browser(clearAllButLast)
         [] expand            then selection(expand)
         [] shrink            then selection(shrink)
         [] deref             then selection(deref)
         [] rebrowse          then selection(rebrowse)
         [] process           then selection(process)
         else InitValue
         end
      end

      %%
      self.Button2Path =
      fun {$ Button}
         case Button
         of break             then break
         else InitValue
         end
      end

      %%
      self.CleanUp = fun {$ A} A \= InitValue end
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
         {self.store store(StoreIsWindow true)}
      else skip
      end

      %%
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createWindow is finished'}
\endif
   end

   %%
   %%
   meth createMenus
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createMenus is applied'}
\endif
      %%
      case {self.store read(StoreAreMenus $)} then skip
      else Store BO Window Menus ActionVar Actions in
         %%
         Store = self.store
         BO = self.browserObj
         Window = @window
         Actions = {Dictionary.new}
         actions <- Actions

         %%
         %%  All the elements of the menubar
         %%  (The 'TkTools.menubar' is used);
         Menus =
         [menubutton(text: 'Browser'
                     menu: [%%
                            command(label:   'About...'
                                    action:  BO#About
                                    feature: about)
                            separator

                            %%
                            command(label:   'Break'
                                    % key:     ctrl(c)
                                    acc:     '     C-c'
                                    action:  BO#break
                                    feature: break)
                            command(label:   'Deselect'
                                    action:  BO#UnsetSelected
                                    feature: unselect)
                            separator

                            %%
%                           command(label:   'Toggle Menus'
%                                   % key:     ctrl(alt(m))
%                                   acc:     '   C-A-m'
%                                   action:  BO#toggleMenus
%                                   feature: toggleMenus)
%                           separator

                            %%
                            command(label:   'Clear'
                                 % key:     ctrl(u)
                                    acc:     '     C-u'
                                    action:  BO#reset
                                    feature: clear)
                            command(label:   'Clear All But Last'
                                    acc:     '     C-w'
                                    action:  BO#clearAllButLast
                                    feature: clearAllButLast)
                            separator

                            %%
                            command(label:   'Refine Layout'
                                    % key:     ctrl(l)
                                    acc:     '     C-l'
                                    action:  BO#checkLayout
                                    feature: checkLayout)
                            separator

                            %%
                            command(label:   'Close'
                                    % key:     ctrl(x)
                                    acc:     '     C-x'
                                    action:  BO#close
                                    feature: close)]
                     feature: browser)

          %% 'Selection' menu;
          menubutton(text: 'Selection'
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
                            separator

                            %%
                            cascade(label:   'Set Action'
                                    menu:    nil
                                    feature: action)
                            command(label:   'Apply Action'
                                    % key:     ctrl(p)
                                    acc:     '     C-p'
                                    action:  BO#Process
                                    feature: process)]
                     feature: selection)

          %% 'Buffer' menu;
          menubutton(text: 'Options'
                     menu:
                        [%%
                         command(label:'Buffer...'
                                 action: self #
                                 guiOptions(buffer))
                         command(label:'Representation...'
                                 action: self #
                                 guiOptions(representation))
                         command(label:'Display Parameters...'
                                 action: self #
                                 guiOptions(display))
                         command(label:'Layout...'
                                 action: self #
                                 guiOptions(layout))]
                     feature: options)

          %%
         ]

         %%
         %%  create & pack it;
         {Window [createMenuBar(Menus)
                  pushButton(break(%%
                                   % text:   'Break'
                                   action: BO#break
                                   bitmap: IStopBitmap
                                   bd: 0
                                   anchor: center
                                   width: IStopWidth
                                   fg:    IStopFG
                                   activeforeground:IStopAFG)
                             "Break")
                  createTkVar(1 % must be 0;
                              proc {$ V}
                                 Action = {Dictionary.get Actions
                                           {String.toInt V}}.action
                              in
                                 %%
                                 {Store store(StoreProcessAction Action)}
                              end
                              ActionVar)
                  exposeMenuBar]}
         actionVar <- ActionVar
         nextANumber <- 2       % two pre-defined actions;

         %%
         %%  everything else is done asynchronously;
         thread
            %%
            %% no "tear-off" menus;
            {Window noTearOff([browser(menu)
                               selection(menu)
                               selection(action(menu))
                               options(menu)])}

            %%
            %% Key bindings;
            {Window [bindKey(key: ctrl(c)      action: BO#break)
                     bindKey(key: ctrl(b)      action: BO#rebrowse)
                     bindKey(key: ctrl(p)      action: BO#Process)
                     bindKey(key: ctrl(l)      action: BO#checkLayout)
                     bindKey(key: ctrl(alt(m)) action: BO#toggleMenus)
                     bindKey(key: ctrl(h)      action: BO#About)
                     bindKey(key: ctrl(x)      action: BO#close)
                     bindKey(key: ctrl(u)      action: BO#reset)
                     bindKey(key: ctrl(w)      action: BO#clearAllButLast)
                     bindKey(key: d            action: BO#SelDeref)
                     bindKey(key: e            action: BO#SelExpand)
                     bindKey(key: s            action: BO#SelShrink)]}

            %%
            {Window addRadioEntry(selection(action(menu))
                                  'Show' ActionVar 0)}
            {Window addRadioEntry(selection(action(menu))
                                  'Browse' ActionVar 1)}
            {Dictionary.put Actions 0 r(action:Show number:0)} % must be 0;
            {Dictionary.put Actions 1 r(action:Browse number:1)} % must be 1;
            {Store store(StoreProcessAction Browse)}

            %%
         end

         %%
         case @window.standAlone then {@window setMinSize}
         else WindowManagerClass , entriesDisable([close])
         end

         %%
         {self.store store(StoreAreMenus true)}
      end

      %%
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::createMenus is finished'}
\endif
   end

   %%
   %%
   meth guiOptions(What)
      {Wait {New case What
                 of buffer then BufferDialog
                 [] representation then RepresentationDialog
                 [] display then DisplayDialog
                 [] layout then LayoutDialog
                 end
             init(windowObj: @window)}.closed}
   end

   %%
   %%
   meth resetWindowSize
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::resetWindowSize is applied'}
\endif
      %%
      case @window == InitValue then skip
      else {@window [setMinSize setXYSize resetTW]}
      end

      %%
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::resetWindowSize is finished'}
\endif
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
      case
         @window \= InitValue andthen
         {self.store read(StoreAreMenus $)}
      then
         {@window [closeMenuBar setMinSize]}
         actions <- InitValue
         actionVar <- InitValue
         nextANumber <- InitValue
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
         actions <- InitValue
         actionVar <- InitValue
         nextANumber <- InitValue
         {self.store store(StoreIsWindow false)}
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::closeWindow is finished'}
\endif
   end

   %%
   %%
   meth makeAbout
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::makeAbout is applied'}
\endif
      {New AboutDialogClass init(windowObj:@window) _}
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::makeAbout is finished'}
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
         case {Filter Arg fun {$ E} E == break end} of [break] then
            WindowManagerClass , WrapWindow(setDefaultCursor)
         else skip
         end
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::entriesDisable is finished'}
\endif
   end

   %%
   %%
   meth addAction(Action Label)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::addProcessAction is applied'}
\endif
      %%
      case @window \= InitValue andthen {self.store read(StoreAreMenus $)}
      then Actions N PA in
         Actions = @actions
         N = @nextANumber
         PA = {Dictionary.get Actions (N-1)}      % cannot be empty;
         {@window addRadioEntry(selection(action(menu)) Label @actionVar N)}
         {Dictionary.put @actions N r(action:Action number:(PA.number+1))}
         nextANumber <- N + 1
      else skip
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::addProcessAction is finished'}
\endif
   end

   %%
   %%
   meth removeAction(Action)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::removeProcessAction is applied'}
\endif
      %%
      case @window \= InitValue andthen {self.store read(StoreAreMenus $)}
      then Window Actions in
         Window = @window
         Actions = @actions
         {ForAll
          {List.filter {Dictionary.keys Actions}
           fun {$ K}
              case {Value.status Action}
              of free      then false
              [] kinded(_) then false
              else
                 {Dictionary.get Actions K}.action == Action orelse
                 (Action == 'all' andthen K \= 0 andthen K\= 1)
              end
           end}
          proc {$ N}
             {Window removeRadioEntry(selection(action(menu)) N)}
             {Dictionary.remove Actions N}
          end}

         %%
         %% Slide numbers - since menu entries could get new
         %% indexes (after executing the code above);
         nextANumber <-
         {List.foldL
          {Sort {Dictionary.keys Actions} `<`}
          fun {$ I K}
             {Dictionary.put Actions K
              {AdjoinAt {Dictionary.get Actions K} number I}}
             I + 1
          end
          0}                    % must be 0;
      else skip
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::removeProcessAction is finished'}
\endif
   end

   %%
   %%
   meth setAction(Action)
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setAction is applied'}
\endif
      %%
      local Actions AVar in
         Actions = @actions
         AVar = @actionVar

         %%
         {ForAll {Dictionary.keys Actions}
          proc {$ K}
             A = {Dictionary.get Actions K}
          in
             case A.action == Action then
                {AVar tkSet(K)}
                {self.store store(StoreProcessAction Action)}
             else skip
             end
          end}
      end
\ifdef DEBUG_WM
      {Show 'WindowManagerClass::setAction is finished'}
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
      case @window \= InitValue andthen {self.store read(StoreAreMenus $)}
      then {@window Meth}
      else skip
      end
   end

   %%
end
