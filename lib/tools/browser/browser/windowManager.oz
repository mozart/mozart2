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
      window:  InitValue        %  the window object itself;
      menu:    InitValue        %  menubar;

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
         [] reset             then browser(reset)
         [] close             then browser(close)
         [] clear             then browser(clear)
         [] clearAllButLast   then browser(clearAllButLast)
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
      else Store BO Window Menus in
         %%
         Store = self.store
         BO = self.browserObj
         Window = @window

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
                            command(label:   'About'
                                    action:  BO#About
                                    feature: about)
                            separator

                            %%
                            command(label:   'Close'
                                    % key:     ctrl(x)
                                    acc:     '     C-x'
                                    action:  BO#close
                                    feature: close)]
                     feature: browser)

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

          %% 'Buffer' menu;
          menubutton(text: 'Options'
                     menu:
                        [%%
                         command(label:'Buffer'
                                 action: self #
                                 guiOptions(buffer))
                         command(label:'Representation'
                                 action: self #
                                 guiOptions(representation))
                         command(label:'Display Parameters'
                                 action: self #
                                 guiOptions(display))
                         command(label:'Layout'
                                 action: self #
                                 guiOptions(layout))]
                     feature: options)

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
            {Window noTearOff([browser(menu) navigate(menu) options(menu)])}

            %%
            %% Key bindings;
            {Window [bindKey(key: ctrl(c)      action: BO#break)
                     bindKey(key: ctrl(b)      action: BO#rebrowse)
                     bindKey(key: ctrl(s)      action: BO#SelShow)
                     bindKey(key: ctrl(n)      action: BO#createNewView)
                     bindKey(key: ctrl(l)      action: BO#checkLayout)
                     bindKey(key: ctrl(alt(m)) action: BO#toggleMenus)
                     bindKey(key: ctrl(h)      action: BO#About)
                     bindKey(key: ctrl(x)      action: BO#close)
                     bindKey(key: ctrl(u)      action: BO#clear)
                     bindKey(key: z            action: BO#SelZoom)
                     bindKey(key: d            action: BO#SelDeref)
                     bindKey(key: e            action: BO#SelExpand)
                     bindKey(key: s            action: BO#SelShrink)]}

            %%
         end

         %%
         case @window.standAlone then skip
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
      else X Y in
         {@store [read(StoreXSize X) read(StoreYSize Y)]}

         %%
         {@window [setXYSize(X Y) resetTW]}
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
         {@window closeMenuBar}
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
