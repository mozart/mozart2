%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% BaseDrawObject
%%%

local
   class MenuObject
      from
         BaseObject

      attr
         parent     %% Window Parent
         callObj    %% Server Reference
         mesgObj    %% Message Receiving Node
         type       %% Menu Type
         status     %% Menu Status
         menu : nil %% TK Menu Ptr

      meth create(Parent CallObj MesgObj Type)
         @parent  = Parent
         @callObj = CallObj
         @mesgObj = MesgObj
         @type    = Type
         @status  = normal
      end

      meth get($)
         Menu = @menu
      in
         case Menu
         of nil then
            MenuData = MenuObject, getMenuData(@type @status $)
            Font     = {OpMan get(menuFont $)}
            Color    = {OpMan get(menuActiveBackground $)}
         in
            menu <- {New Tk.menu
                     tkInit(parent:  @parent
                            tearoff: false)}
            MenuObject, buildEntries(MenuData Font Color)
            @menu
         else Menu
         end
      end

      meth update(Type Status)
         type   <- Type
         status <- Status
         menu   <- nil
      end

      meth setMenuStatus(Status)
         status <- Status
         menu   <- nil
      end

      meth getMenuStatus($)
         @status
      end

      meth getMenuData(MenuType Status $)
         Auto Fun MenuData
      in
         try
            Auto#Fun#MenuData = {OpMan get(MenuType $)}
         catch _ then
            MenuData = title(@type)|nil
         end

         case Status
         of normal   then MenuData
         [] expanded then
            Entry|MDr = MenuData
         in
            Entry|'Undo Expand'(callShrink)|separator|MDr
         end
      end

      meth buildEntries(MDs Font Color)
         case MDs
         of Entry|MDr then
            case Entry
            of title(Name)    then
               _ = {New Tk.menuentry.command
                    tkInit(parent: @menu
                           label:  Name
                           font:   Font
                           state:  disabled)}
               _  = {New Tk.menuentry.separator
                     tkInit(parent: @menu)}
            [] separator     then
               _ = {New Tk.menuentry.separator
                    tkInit(parent: @menu)}
            else
               Name = {Label Entry}
               Mesg = Entry.1
            in
               _ = {New Tk.menuentry.command
                    tkInit(parent:           @menu
                           label:            Name
                           font:             Font
                           activebackground: Color
                           action:           @callObj # call(@mesgObj Mesg))}
            end
            MenuObject, buildEntries(MDr Font Color)
         [] nil      then skip
         end
      end
   end
in
   class DrawObject
      from
         BaseObject

      attr
         tag             %% Canvas Tag
         haveTag : false %% Tag Freshness Flag
         dirty   : true  %% Draw Flag
         xAnchor         %% X Anchor
         yAnchor         %% Y Anchor
         menu    : nil   %% Menu Object Ptr

      meth draw(X Y)
         if @dirty
         then
            xAnchor <- X
            yAnchor <- Y
            dirty   <- false
            if @haveTag
            then {@tag tkClose}
            else haveTag <- true
            end
            tag <- {New Tk.canvasTag
                    tkInit(parent: @canvas)}
            {@visual printXY(X Y @string @tag @color)}
         end
      end

      meth undraw
         if @haveTag
         then
            {@tag tkClose}
            dirty   <- true
            haveTag <- false
         end
      end

      meth moveNodeXY(X XF Y YF)
         if @dirty
         then skip
         else
            xAnchor <- (@xAnchor + X)
            yAnchor <- (@yAnchor + Y)
            {@tag tk(move XF YF)}
         end
      end

      meth reDraw(X Y)
         if @dirty
         then
            xAnchor <- X
            yAnchor <- Y
            dirty   <- false
            if @haveTag
            then {@tag tkClose}
            else haveTag <- true
            end
            tag <- {New Tk.canvasTag
                    tkInit(parent: @canvas)}
            {@visual printXY(X Y @string @tag @color)}
         else
            DeltaX = (X - @xAnchor)
            DeltaY = (Y - @yAnchor)
         in
            case DeltaX
            of 0 then
               case DeltaY
               of 0 then skip
               else
                  DrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                         DeltaY (DeltaY * @yf))
               end
            else
               DrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                      DeltaY (DeltaY * @yf))
            end
         end
      end

      meth searchNode(Coord $)
         coord(X Y) = Coord
      in
         if X =< @xDim andthen Y =< @yDim
         then self
         else nil
         end
      end

      meth initMenu(Type)
         case @menu
         of nil then
            Visual = @visual
            Server = {Visual getServer($)}
         in
            menu <- {New MenuObject create(@canvas Server self Type)}
         else skip
         end
      end

      meth updateMenu(Type Status)
         {@menu update(Type Status)}
      end

      meth getMenu($)
         {@menu get($)}
      end

      meth setMenuStatus(Status)
         {@menu setMenuStatus(Status)}
      end

      meth getMenuStatus($)
         {@menu getMenuStatus($)}
      end

      meth handleLeftButton(X FX Y FY)
         skip
      end

      meth handleMiddleButton(X FX Y FY)
         skip
      end

      meth handleRightButton(X FX Y FY)
         case @menu
         of nil then skip
         else
            Menu = DrawObject, getMenu($)
         in
            {@visual popup(X Y Menu)}
         end
      end

      meth expand(F)
         NewValue = {F @value}
      in
         {@parent link(@index NewValue)}
      end

      meth callShrink
         {@parent shrink(@index)}
      end
   end
end
