%%%
%%% Author:
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Contributor:
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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


local
   DefaultFont = local
                    T = {New Tk.toplevel
                         tkInit(withdraw:true 'class':'OzTools')}
                    L = {New Tk.label
                         tkInit(parent:T)}
                    F = {L tkReturnAtom(cget(font:unit) $)}
                 in
                    {T tkClose}
                    F
                 end

   local
      FontDict = {Dictionary.new}
      FontLock = {Lock.new}
   in
      fun {GetFontHeight F}
         lock FontLock then
            AF = case {IsAtom F} then F else
                    {String.toAtom {VirtualString.toString F}}
                 end
         in
            case {Dictionary.member FontDict AF} then skip else
               {Dictionary.put FontDict AF
                {Tk.returnInt font(metrics AF linespace:unit)}}
            end
            {Dictionary.get FontDict AF}
         end
      end
   end

   Border     = 1
   BigBorder  = 2
   Pad        = 2
   BigPad     = 4
   NoArg      = {NewName}
   EntryColor = case Tk.isColor then wheat else white end

   class Dialog
      from Tk.frame
      prop locking
      attr PackList:nil
      feat toplevel tkClosed

      meth tkInit(title:   Title
                  master:  Master <= NoArg
                  root:    Root   <= master
                  buttons: Buttons
                  pack:    Pack   <= true
                  focus:   Focus  <= 0
                  bg:      Background <= NoArg
                  default: Return <= 0)
         lock
            GeoX GeoY GeoXOffset GeoYOffset
            case Master==NoArg then skip else
               case Root
               of master then
                  GeoX = {Tk.returnInt winfo(rootx Master)}
                  GeoY = {Tk.returnInt winfo(rooty Master)}
                  GeoXOffset = 0
                  GeoYOffset = 40
               [] master # XOff # YOff then
                  GeoX = {Tk.returnInt winfo(rootx Master)}
                  GeoY = {Tk.returnInt winfo(rooty Master)}
                  GeoXOffset = XOff
                  GeoYOffset = YOff
               [] pointer then
                  GeoX = {Tk.returnInt winfo(pointerx '.')}
                  GeoY = {Tk.returnInt winfo(pointery '.')}
                  GeoXOffset = ~7
                  GeoYOffset = ~7
               [] X # Y then
                  GeoX = X
                  GeoY = Y
                  GeoXOffset = 0
                  GeoYOffset = 0
               end
            end
            Toplevel  = {New Tk.toplevel case Master==NoArg then
                                            tkInit(title:Title withdraw:true)
                                         else
                                            tkInit(parent:Master
                                                   title:Title
                                                   withdraw:true)
                                         end}
            {Toplevel tkWM(transient
                           case Master==NoArg then v('')
                           else Master
                           end)}
            Top    = {New Tk.frame tkInit(parent:             Toplevel
                                          bd:                 Border
                                          relief:             raised
                                          highlightthickness: 0)}
            case Background == NoArg then
               Tk.frame,tkInit(parent:             Top
                               bd:                 BigBorder
                               highlightthickness: 0)
            else
               Tk.frame,tkInit(parent:             Top
                               bd:                 BigBorder
                               bg:                 Background
                               highlightthickness: 0)
            end

            Bottom = {New Tk.frame tkInit(parent:             Toplevel
                                          bd:                 Border
                                          relief:             raised
                                          highlightthickness: 0)}
            ReturnButton
            ReturnAction
            FocusButton

            TkButtons = {List.mapInd Buttons
                         fun {$ Ind Text#Action}
                            ButtonAction = case Action
                                           of tkClose(Do) then
                                              proc {$}
                                                 {Tk.invoke Do nil 0 false}
                                                 {self tkClose}
                                              end
                                           [] tkClose then self # tkClose
                                           else Action
                                           end
                            Button = {New Tk.button
                                      tkInit(parent:  Bottom
                                             relief:  raised
                                             default: case Ind==Return then
                                                         active
                                                      else
                                                         normal
                                                      end
                                             text:    Text
                                             action:  ButtonAction)}
                         in
                            case Ind==Focus then
                               FocusButton = Button
                            else skip
                            end
                            case Ind==Return then
                               ReturnAction = ButtonAction
                               ReturnButton = Button
                            else skip
                            end
                            Button
                         end}
         in
            case Focus>0 then
               PackList <- [focus(FocusButton)]
            else skip
            end
            PackList <- (wm(resizable Toplevel 0 0) |
                         case Master\=NoArg andthen
                            {IsInt GeoX} andthen {IsInt GeoY}
                         then
                            wm(geometry Toplevel
                               '+' # GeoX+GeoXOffset # '+' # GeoY+GeoYOffset) |
                            update(idletasks) |
                            wm(deiconify Toplevel) | @PackList
                         else
                            update(idletasks) |
                            wm(deiconify Toplevel) | @PackList
                         end)
            PackList <- (pack(b(TkButtons)
                              padx:BigPad pady:Pad side:left expand:1) |
                         pack(Bottom side:bottom fill:both) |
                         pack(Top side:top fill:both) |
                         pack(self side:top fill:both) | @PackList)
            case Return>0 then
               {Toplevel tkBind(event:  '<Return>'
                                action: ReturnAction)}
               PackList <- pack(ReturnButton) | @PackList
            else skip
            end
            self.toplevel = Toplevel
            case Pack then Dialog,tkPack else skip end
         end
      end

      meth tkPack
         lock
            {Tk.batch @PackList}
            PackList <- nil
         end
      end

      meth tkClose
         lock
            {self.toplevel tkClose}
            self.tkClosed = unit
         end
      end
   end


   class Error from Dialog

      meth tkInit(title:  Title  <= 'Error'
                  master: Master <= NoArg
                  aspect: Aspect <= 250
                  text:   Text)
         lock
            Dialog,tkInit(title:   Title
                          master:  Master
                          buttons: ['Okay'#tkClose]
                          focus:   1
                          pack:    false
                          default: 1)
            Bitmap  = {New Tk.label   tkInit(parent: self
                                             bitmap: error)}
            Message = {New Tk.message tkInit(parent: self
                                             aspect: Aspect
                                             text:   Text)}
         in
            {Tk.send pack(Bitmap Message
                          side:left expand:1 padx:BigPad pady:BigPad)}
            Dialog,tkPack
         end
      end

   end


   local
      BarRelief = raised
      AccSpace  = ''
      AccCtrl   = 'C-'
      AccAlt    = 'A-'
      AccMeta   = 'M-'

      fun {MakeClass C Fs}
         case Fs of nil then C else
            {Class.extendFeatures C f Fs}
         end
      end

      fun {GetFeatures Ms}
         case Ms of nil then nil
         [] M|Mr then
            case {HasFeature M feature} then M.feature|{GetFeatures Mr}
            else {GetFeatures Mr}
            end
         end
      end

      local
         local
            fun {DoMakeEvent R}
               case R
               of ctrl(S) then 'Control-' # {DoMakeEvent S}
               [] alt(S)  then 'Alt-'     # {DoMakeEvent S}
               [] meta(S) then 'Meta-'    # {DoMakeEvent S}
               else R
               end
            end
         in
            fun {MakeEvent R}
               '<' # {DoMakeEvent R} # '>'
            end
         end
      in
         proc {MakeKey M Menu Item KeyBinder}
            case {HasFeature M key} then
               B={HasFeature M event}
               E={MakeEvent M.key}
            in
               {Tk.send bind(KeyBinder
                             case B
                             then M.event
                             else E
                             end
                             v('{') Menu invoke Item v('}'))}
            else skip
            end
         end
      end


      local
         fun {MakeAcc R}
            case R
            of ctrl(S) then AccCtrl # {MakeAcc S}
            [] alt(S)  then AccAlt  # {MakeAcc S}
            [] meta(S) then AccMeta # {MakeAcc S}
            [] less    then '<'
            [] greater then '>'
            else R
            end
         end

         proc {ProcessMessage As M ?AMs}
            case As of nil then AMs=nil
            [] A|Ar then AMr in
               AMs = case A
                     of key     then acc#(AccSpace#{MakeAcc M.key})|AMr
                     [] event   then AMr
                     [] feature then AMr
                     [] menu    then AMr
                     else A#M.A|AMr
                     end
               {ProcessMessage Ar M AMr}
            end
         end
      in
         fun {MakeMessage M P}
            {AdjoinList tkInit parent#P|{ProcessMessage {Arity M} M}}
         end
      end

      proc {MakeItems Ms Item Menu KeyBinder}
         case Ms of nil then skip
         [] M|Mr then
            HasMenu = {HasFeature M menu}
            BaseCl  = Tk.menuentry.{Label M}
            UseCl   = case HasMenu then
                         FS={GetFeatures M.menu}
                      in
                         {MakeClass BaseCl menu|FS}
                      else BaseCl
                      end
            M1 = {MakeMessage M Menu}
            NewItem = {New UseCl M1}
         in
            {MakeKey M Menu NewItem KeyBinder}
            case HasMenu then
               NewMenu = {New Tk.menu tkInit(parent:Menu)}
            in
               NewItem.menu = NewMenu
               {MakeItems M.menu NewItem NewMenu KeyBinder}
               {NewItem tk(entryconf menu:NewMenu)}
            else skip end
            case {HasFeature M feature} then Item.(M.feature)=NewItem
            else skip
            end
            {MakeItems Mr Item Menu KeyBinder}
         end
      end

      fun {MakeButtons Ms Bar KeyBinder}
         case Ms of nil then nil
         [] M|Mr then
            MenuButton = {New {MakeClass Tk.menubutton
                               menu|{GetFeatures M.menu}}
                          {MakeMessage M Bar}}
            Menu       = {New Tk.menu tkInit(parent:MenuButton)}
         in
            {MakeItems M.menu MenuButton Menu KeyBinder}
            {MenuButton tk(conf menu:Menu)}
            case {HasFeature M feature} then Bar.(M.feature)=MenuButton
            else skip
            end
            MenuButton.menu = Menu
            MenuButton | {MakeButtons Mr Bar KeyBinder}
         end
      end

   in

      fun {MakeMenu Parent KeyBinder L R}
         MenuBar      = {New {MakeClass Tk.frame {Append {GetFeatures L}
                                                  {GetFeatures R}}}
                         tkInit(parent:  Parent
                                'class': 'MenuFrame'
                                relief:  BarRelief)}
         LeftButtons  = {MakeButtons L MenuBar KeyBinder}
         RightButtons = {MakeButtons R MenuBar KeyBinder}
      in
         case {Append
               case LeftButtons of nil then nil
               else [pack(b(LeftButtons) side:left fill:x)]
               end
               case RightButtons of nil then nil
               else [pack(b(RightButtons) side:right fill:x)]
               end}
         of nil then skip
         elseof Tcls then {Tk.batch Tcls}
         end
         MenuBar
      end

   end

   %% Used for 3D effects
   DarkerColorBy   = 60
   BrighterColorBy = 140
   SameColorBy     = 100

   TclDarkenBg = case Tk.isColor then
                    fun {$ T P}
                       l(tkDarken l(lindex l(T conf '-bg') 4) P)
                    end
                 else
                    fun {$ _ P}
                       case P>=100 then white else black end
                    end
                 end

   local
      RidgeBorder = 2
      TextIndent  = 20
   in

      class Textframe
         from Tk.frame
         feat inner
         meth tkInit(parent:  Parent
                     'class': ThisClass <= unit
                     text:    Text
                     font:    Font   <= DefaultFont)
            case ThisClass == unit then
               Tk.frame,tkInit(parent:             Parent
                               highlightthickness: 0)
            else
               Tk.frame,tkInit(parent:             Parent
                               'class':            ThisClass
                               highlightthickness: 0)
            end
            Upper = {New Tk.frame tkInit(parent: self
                                         height: {GetFontHeight Font} div 2+1)}
            Inner = {New Tk.frame tkInit(parent: self
                                         bd:     RidgeBorder
                                         relief: ridge)}
            Lower = {New Tk.frame tkInit(parent: Inner
                                         height: {GetFontHeight Font} div 2+2)}
            Real  = {New Tk.frame tkInit(parent: Inner)}
            Label = {New Tk.label tkInit(parent: self
                                         text:   Text
                                         font:   Font)}
         in
            self.inner = Real
            {Tk.batch [pack(Lower fill:x)
                       pack(Real fill:both expand:true)
                       pack(Upper fill:both)
                       pack(Inner fill:both expand:true)
                       place(Label x:TextIndent y:0)]}
         end
      end

   end


   local
      Home               = ~10000
      FreeMarkX          = 0
      NotebookFrameWidth = 2
      NotebookOffset     = 1
      NotebookDelta      = NotebookFrameWidth + NotebookOffset

      MarkOuterOffset    = 3
      MarkInnerOffset    = 2
      MarkFrameWidth     = 2
      MarkDelta          = (MarkOuterOffset + MarkFrameWidth + MarkInnerOffset)
      MarkEdgeWidth      = 2

      NoteBorderTag      = {NewName} % horizontal part of 3D-border
      MarkBorderTag      = {NewName} % mark part of 3D-border
      HighlightTag       = {NewName} % highlightframe
      TextTag            = {NewName} % text
      MarkFont           = {NewName}
      EventTag           = {NewName} % both text and highlightframe
      NoteTag            = {NewName} % note widget
      TextWidth          = {NewName} % text width
      HorGlue            = {NewName}
      VerGlue            = {NewName}
      Reconfigure        = {NewName} % Message send from note to book
      Store              = {NewName} % Gemoentry information for note

      proc {GetBoundingBox Ns W H ?MW ?MH}
         case Ns of nil then MW=W MH=H
         [] N|Nr then NW NH in
            {N.Store get(?NW ?NH)}
            {GetBoundingBox Nr {Max W NW} {Max H NH} ?MW ?MH}
         end
      end

   in

      class Notebook
         from Tk.canvas
         prop locking
         feat
            TextHeight
            !MarkFont
            StaticTag
         attr
            Width:   0
            Height:  0
            NextX:   FreeMarkX
            TopNote: unit
            Notes:   nil

         meth tkInit(parent: Parent
                     font:   Font   <= DefaultFont)
            lock
               Tk.canvas,tkInit(parent:             Parent
                                highlightthickness: 0)
               FontHeight = {GetFontHeight DefaultFont}
               MarkHeight = FontHeight + 2 * MarkDelta
            in
               Notebook,tk(configure
                           yscrollincrement: 1
                           xscrollincrement: 1)
               Notebook,tk(yview scroll ~MarkHeight-2 units)
               Notebook,tk(xview scroll ~2 units)
               self.TextHeight = FontHeight
               self.MarkFont   = Font
               self.StaticTag  = {New Tk.canvasTag tkInit(parent:self)}
            end
         end

         meth ResizeStaticFrame(IntWidth IntHeight)
            lock
               ExtWidth    = IntWidth   + 2 * NotebookDelta
               MarkHeight  = self.TextHeight + 2 * MarkDelta
               ExtHeight   = IntHeight  + 2 * NotebookDelta
               Static      = self.StaticTag
            in
               {Static tk(delete)}
               Notebook,tk(configure
                           height:           ExtHeight + MarkHeight
                           width:            ExtWidth)
               Notebook,tk(crea polygon
                           0                        0
                           (NotebookFrameWidth - 1) 0
                           (NotebookFrameWidth - 1) (ExtHeight -
                                                     NotebookFrameWidth)
                           0                        (ExtHeight - 1)
                           0                        0
                           fill: {TclDarkenBg self BrighterColorBy}
                           tags: Static)
               Notebook,tk(crea polygon
                           1                        (ExtHeight - 1)
                           (NotebookFrameWidth - 1) (ExtHeight - 1 -
                                                     NotebookFrameWidth)
                           (ExtWidth - NotebookFrameWidth - 1)
                           (ExtHeight - NotebookFrameWidth - 1)
                           (ExtWidth - NotebookFrameWidth - 1)
                           (NotebookFrameWidth - 1)
                           ExtWidth-1                1
                           ExtWidth-1                ExtHeight-1
                           1 ExtHeight-1
                           fill: {TclDarkenBg self DarkerColorBy}
                           tags: Static)
               Width      <- IntWidth
               Height     <- IntHeight
            end
         end

         meth DrawNote(DoMark NotActive Note X W $)
            ThisNoteBorderTag = Note.NoteBorderTag
            ThisMarkBorderTag = Note.MarkBorderTag
            ThisHighlightTag  = Note.HighlightTag
            ThisTextTag       = Note.TextTag
            ThisEventTag      = Note.EventTag
            ThisTextWidth     = Note.TextWidth
            TotalMarkHeight   = 2 * MarkDelta + self.TextHeight
            TotalMarkWidth    = 2 * MarkDelta + ThisTextWidth
            %% X coordinates needed
            X0 = 0
            X1 = X
            X2 = X1 + NotebookFrameWidth - 1
            X3 = X2 + MarkEdgeWidth
            X6 = X2 + TotalMarkWidth
            X7 = X6 + NotebookFrameWidth - 1
            X4 = X6 - MarkEdgeWidth
            X8 = NotebookFrameWidth + W
            X9 = X8 + NotebookFrameWidth - 1
            %% Y coordinates needed
            Y0 = ~TotalMarkHeight - 1
            Y1 = Y0 + NotebookFrameWidth
            Y2 = Y1 + MarkEdgeWidth
            Y3 = 0
            Y4 = 0
            Y5 = NotebookFrameWidth - 1
            AO = case NotActive then Home else 0 end
            BrightColor = {TclDarkenBg self BrighterColorBy}
            DarkColor   = {TclDarkenBg self DarkerColorBy}
            SameColor   = {TclDarkenBg self SameColorBy}
         in
            {ThisNoteBorderTag tk(delete)}
            %% Draw note frame
            case X==0 then skip else
               Notebook,tk(crea polygon
                           AO+X0 AO+Y4 AO+X2 AO+Y4 AO+X2 AO+Y5
                           AO+X0 AO+Y5 AO+X0 AO+Y4
                           fill: BrightColor
                           tags: ThisNoteBorderTag)
            end
            Notebook,tk(crea polygon
                        AO+X6 AO+Y4 AO+X7 AO+Y4 AO+X6 AO+Y5 AO+X6 AO+Y4
                        fill: DarkColor
                        tags: ThisNoteBorderTag)
            Notebook,tk(crea polygon
                        AO+X6 AO+Y5 AO+X8 AO+Y5 AO+X9 AO+Y4
                        AO+X7 AO+Y4 AO+X6 AO+Y5
                        fill: BrightColor
                        tags: ThisNoteBorderTag)
            case DoMark then
               %% Make text visible
               {ThisTextTag tk(coords
                               X+MarkDelta+NotebookFrameWidth
                               2-MarkDelta)}
               %% Draw mark frame
               Notebook,tk(crea polygon
                           X1 Y3 X1 Y2 X3 Y0 X4 Y0 X4 Y1 X3 Y1
                           X2 Y2 X2 Y3 X1 Y3
                           fill: BrightColor
                           tags: ThisMarkBorderTag)
               Notebook,tk(crea polygon
                           X6 Y3 X7 Y3 X7 Y2 X4 Y0 X4 Y1 X6 Y2 X6 Y3
                           fill: DarkColor
                           tags: ThisMarkBorderTag)
               %% Draw frame around text
               Notebook,tk(crea rectangle
                           X2 + MarkOuterOffset
                           MarkFrameWidth - MarkOuterOffset
                           X6 - MarkOuterOffset
                           Y1 + MarkOuterOffset
                           fill:    SameColor
                           outline: case NotActive then SameColor
                                    else black
                                    end
                           width:   MarkFrameWidth
                           tags:    q(ThisHighlightTag ThisEventTag))
               Notebook,tk('raise' ThisTextTag ThisHighlightTag)
               {ThisEventTag tkBind(event:  '<1>'
                                    action: self # toTop(Note))}
            else skip
            end
            %% The next X coordinate
            X7 + 1
         end

         meth add(Note)
            lock
               NotFirstNote = {IsObject @TopNote}
               OldX = @NextX
               NewX = Notebook,DrawNote(true NotFirstNote Note OldX @Width $)
            in
               NextX <- NewX
               case NotFirstNote then skip else
                  {Note.NoteTag tk(move ~Home ~Home)}
                  TopNote <- Note
               end
               {Note.Store add(OldX NewX-OldX)}
               Notes <- Note|@Notes
            end
         end

         meth remove(Note)
            lock W in
               Notes <- {List.subtract @Notes Note}
               {Note.Store remove(_ ?W)}
               case @TopNote==Note then
                  case @Notes of nil then TopNote <- unit
                  elseof N|_ then
                     TopNote <- N
                     Notebook,UnhideNote(N)
                  end
               else skip
               end
               {Note.HighlightTag  tk(dtag Note.EventTag)}
               {Note.NoteBorderTag tk(delete)}
               {Note.MarkBorderTag tk(delete)}
               {Note.HighlightTag  tk(delete)}
               {Note.NoteTag       tk(coords
                                      Home + NotebookDelta - 1
                                      Home + NotebookDelta - 1)}
               {Note.TextTag       tk(coords Home Home)}
               NextX <- @NextX - W
            end
         end

         meth HideNote(Note)
            {Note.NoteTag       tk(move Home Home)}
            {Note.NoteBorderTag tk(move Home Home)}
            {Note.HighlightTag  tk(itemconf
                                   outline:{TclDarkenBg self SameColorBy})}
         end

         meth UnhideNote(Note)
            {Note.NoteTag       tk(move ~Home ~Home)}
            {Note.NoteBorderTag tk(move ~Home ~Home)}
            {Note.HighlightTag  tk(itemconf outline:black)}
         end

         meth toTop(Note)
            lock
               Top = @TopNote
            in
               case Note==Top then skip else
                  Notebook,HideNote(Top)
                  Notebook,UnhideNote(Note)
                  TopNote <- Note
               end
               {Note toTop}
            end
         end

         meth ReconfigureWidth(Ns W)
            case Ns of nil then skip
            [] N|Nr then
               Notebook,DrawNote(false N\=@TopNote
                                 N {N.Store getMarkX($)} W _)
               Notebook,ReconfigureWidth(Nr W)
            end
         end

         meth !Reconfigure
            lock
               CurNotes = @Notes
               MW MH
            in
               {GetBoundingBox CurNotes 0 0 ?MW ?MH}
               case MW==@Width then skip else
                  Notebook,ReconfigureWidth(CurNotes MW)
               end
               {ForAll CurNotes
                proc {$ N}
                   {N.VerGlue tk(conf width:MW)}
                   {N.HorGlue tk(conf height:MH)}
                end}
               Notebook,ResizeStaticFrame(MW MH)
            end
         end

         meth getTop($)
            lock
               @TopNote
            end
         end
      end

      class NoteStore
         prop final
         feat Book
         attr MarkWidth:0 MarkX:0 Width:0 Height:0 IsAdded:false
         meth init(B)
            self.Book = B
         end
         meth add(X W)
            IsAdded   <- true
            MarkX     <- X
            MarkWidth <- W
         end
         meth remove(?X ?W)
            IsAdded <- false
            X = @MarkX
            W = @MarkWidth
         end
         meth get(?W ?H)
            W=@Width H=@Height
         end
         meth getMarkX($)
            @MarkX
         end
         meth configure(W H)
            case W==@Width andthen H==@Height then skip else
               Width <- W Height <- H
               case @IsAdded then {self.Book Reconfigure} else skip end
            end
         end
      end

      class Note
         from Tk.frame
         prop locking
         feat
            !NoteBorderTag    % horizontal part of 3D-border
            !MarkBorderTag    % mark part of 3D-border
            !HighlightTag     % highlightframe
            !TextTag          % text
            !EventTag         % both text and highlightframe
            !NoteTag          % note widget
            !TextWidth        % width of text
            !VerGlue          % vertical glue to fill page
            !HorGlue          % horizontal glue to fill page
            !Store            % Store of dimension

         meth tkInit(parent:Parent text:Text)
            lock
               ThisTextTag   = {New Tk.canvasTag tkInit(parent:Parent)}
               ThisEventTag  = {New Tk.canvasTag tkInit(parent:Parent)}
               ThisNoteTag   = {New Tk.canvasTag tkInit(parent:Parent)}
               OuterFrame    = {New Tk.frame tkInit(parent:Parent
                                                    highlightthickness: 0)}
               ThisVerGlue   = {New Tk.canvas tkInit(parent:OuterFrame
                                                     highlightthickness: 0
                                                     height:0 width:0)}
               ThisHorGlue   = {New Tk.canvas tkInit(parent:OuterFrame
                                                     highlightthickness: 0
                                                     width:0 height:0)}
               ThisStore     = {New NoteStore init(Parent)}
            in
               {Parent tk(crea text Home Home
                          text:   Text
                          case Parent.MarkFont of !DefaultFont then unit
                          elseof F then o(font:F)
                          end
                          anchor: sw
                          tags:   q(ThisTextTag ThisEventTag))}
               self.TextWidth = local
                                   X1|_|X2|_ =
                                   {Parent tkReturnListInt(bbox(ThisTextTag) $)}
                                in X2 - X1
                                end
               Tk.frame,tkInit(parent:             OuterFrame
                               highlightthickness: 0)
               Note,tkBind(event:  '<Configure>'
                           args:   [int(w) int(h)]
                           action: ThisStore # configure)
               self.NoteBorderTag = {New Tk.canvasTag tkInit(parent:Parent)}
               self.MarkBorderTag = {New Tk.canvasTag tkInit(parent:Parent)}
               self.HighlightTag  = {New Tk.canvasTag tkInit(parent:Parent)}
               self.TextTag       = ThisTextTag
               self.EventTag      = ThisEventTag
               self.NoteTag       = ThisNoteTag
               self.VerGlue       = ThisVerGlue
               self.HorGlue       = ThisHorGlue
               self.Store         = ThisStore
               {Parent tk(crea window
                          Home + NotebookDelta - 1 Home + NotebookDelta - 1
                          anchor: nw
                          tags:   ThisNoteTag
                          window: OuterFrame)}
               {Tk.batch [grid(ThisVerGlue column:1 row:0)
                          grid(ThisHorGlue column:0 row:1)
                          grid(self        column:1 row:1 sticky:new)]}
            end
         end

         meth toTop
            skip
         end
      end

   end


   local
      IncStep    = 10
      IncTime    = 100
      IncWait    = 500
      Border     = 1
      BitMapDir  = '@'#{System.get home}#'/lib/bitmaps/'

      fun {CoerceAdd X Y}
         FX={IsFloat X} FY={IsFloat Y}
      in
         case FX==FY then X+Y
         elsecase FX then X + {IntToFloat Y}
         else Y + {IntToFloat X}
         end
      end

      proc {DummyAction _}
         skip
      end

   in

      class NumberEntry from Tk.frame
         prop locking
         feat entry inc dec MinVal MaxVal Parent ReturnAction
         attr Val:0 TimeStamp:0 Increment:1 Action:unit

         meth tkInit(parent:       P
                     min:          Min  <= unit
                     max:          Max  <= unit
                     val:          N    <= Min
                     font:         Font <= DefaultFont
                     width:        W    <= 6
                     action:       A    <= DummyAction
                     returnaction: RetA <= unit)
            Tk.frame, tkInit(parent:P highlightthickness:Border
                             'class':'NumberEntry'
                             bd:Border relief:sunken)
            Entry     = {New Tk.entry  tkInit(case Font==DefaultFont then unit
                                              else o(font:Font)
                                              end
                                              parent:             self
                                              width:              W
                                              highlightthickness: 0
                                              bd:                 0)}
            IncButton = {New Tk.button tkInit(parent:             self
                                              takefocus:          false
                                              highlightthickness: 0
                                              bd:                 1
                                              bitmap:BitMapDir#'mini-inc.xbm')}
            DecButton = {New Tk.button tkInit(parent:             self
                                              takefocus:          false
                                              highlightthickness: 0
                                              bd:                 1
                                              bitmap:BitMapDir#'mini-dec.xbm')}
         in
            {Tk.batch [grid(Entry     row:0 column:0 rowspan:2 sticky:ns)
                       grid(IncButton row:0 column:1           sticky:ns)
                       grid(DecButton row:1 column:1           sticky:ns)]}
            {Entry     tkBind(event:  '<Return>'
                              action: self # enter)}
            {Entry     tkBind(event:  '<FocusIn>'
                              action: Entry # tk(selection range 0 'end'))}
            {Entry     tkBind(event:  '<FocusOut>'
                              action: self # enter(true))}
            {Entry     tkBind(event:  '<KeyPress-Up>'
                              action: self # Inc(1))}
            {Entry     tkBind(event:  '<KeyPress-Down>'
                              action: self # Inc(~1))}
            {Entry     tkBind(event:  '<Shift-KeyPress-Up>'
                              action: self # Inc(10))}
            {Entry     tkBind(event:  '<Shift-KeyPress-Down>'
                              action: self # Inc(~10))}
            {Entry     tkBind(event:  '<KeyRelease-Up>'
                              action: self # IncStop)}
            {Entry     tkBind(event:  '<KeyRelease-Down>'
                              action: self # IncStop)}
            {IncButton tkBind(event:  '<ButtonPress-1>'
                              action: self # Inc(1))}
            {DecButton tkBind(event:  '<ButtonPress-1>'
                              action: self # Inc(~1))}
            {IncButton tkBind(event:  '<ButtonRelease-1>'
                              action: self # IncStop)}
            {DecButton tkBind(event:  '<ButtonRelease-1>'
                              action: self # IncStop)}
            self.entry        = Entry
            self.inc          = IncButton
            self.dec          = DecButton
            self.MinVal       = Min
            self.MaxVal       = Max
            self.Parent       = P
            self.ReturnAction = RetA
            Action           <- A
            NumberEntry, tkSet(case N==unit then 1 else N end)
         end

         meth tkAction(A <= unit)
            lock
               Action <- case A==unit then DummyAction else A end
            end
         end

         meth tkSet(I)
            lock
               E = self.entry
            in
               Val <- I
               try
                  {E tk(delete 0 'end')} {E tk(insert 0 I)}
               catch
                  system(...) %% window already closed?
               then skip end
            end
         end

         meth Update(I)
            lock
               NumberEntry, tkSet(I) {Tk.invoke @Action [I] 1 false}
            end
         end

         meth tkGet($)
            lock
               @Val
            end
         end

         meth enter(NoReturnAction<=false)
            lock
               S = {self.entry tkReturn(get $)}
            in
               case {String.isInt S} then
                  I      = {String.toInt S}
                  NewVal = case self.MinVal \= unit
                              andthen I < self.MinVal then self.MinVal
                           elsecase self.MaxVal \= unit
                              andthen I > self.MaxVal then self.MaxVal
                           else I end
               in
                  NumberEntry,Update(NewVal)
                  case NoReturnAction then skip else
                     case self.ReturnAction == unit then
                        {Tk.send focus(self.Parent)}
                     else
                        {self.ReturnAction}
                     end
                  end
               else NumberEntry,tkSet(@Val)
               end
            end
         end

         meth Inc(I)
            TS
         in
            lock
               TS        =  @TimeStamp
               TimeStamp <- TS+1
               Increment <- I
            end
            NumberEntry, DoInc(TS+1 IncStep IncWait)
         end

         meth DoInc(TS S W)
            case
               lock
                  case @TimeStamp==TS then
                     NewS   = case S==0 then
                                 Increment <- @Increment * IncStep IncStep
                              else S-1
                              end
                     NewVal = {CoerceAdd @Val @Increment}
                     MinV   = case self.MinVal of unit then NewVal
                              elseof M then {Max NewVal M}
                              end
                     MaxV   = case self.MaxVal of unit then MinV
                              elseof M then {Min MinV M}
                              end
                  in
                     NumberEntry, Update(MaxV) NewS
                  else ~1
                  end
               end
            of ~1 then skip elseof N then
               {Delay W}
               NumberEntry, DoInc(TS N IncTime)
            end
         end

         meth IncStop
            TimeStamp <- @TimeStamp + 1
         end
      end

   end

   local
      DarkColor   = black
      BrightColor = white

      ValueHeight = 14
      ValueBorder = 14
      ScaleHeight = 8
      ScaleBorder = 2
      SliderWidth = 16
      TickSize    = 6

      TitleFont   = '-adobe-helvetica-bold-r-normal-*-10-*-*-*-*-*-*-*'

      class TickCanvas
         from Tk.canvas

         meth init(parent:P width:W ticks:N) = M
            TickCanvas,tkInit(parent:             P
                              width:              W
                              highlightthickness: 0
                              height:             TickSize+1)
         end

         meth drawTicks(Xs)
            case Xs of nil then skip
            [] X|Xr then
               X0 = X - ScaleBorder - 2
               X1 = X0 + 1
               X2 = X1 + 1
               X3 = X2 + 1
               Y0 = 0
               Y1 = Y0 + 1
               Y2 = TickSize - 2
               Y3 = Y2 + 1
            in
               TickCanvas,tk(crea rectangle X0 Y0 X3 Y3 outline:BrightColor)
               TickCanvas,tk(crea rectangle X1 Y1 X2 Y2 outline:DarkColor)
               TickCanvas,drawTicks(Xr)
            end
         end

      end

      class TickScale
         from Tk.scale
         feat Ticks
         meth init(parent:P ticks:N width:W action: A)
            TickScale,tkInit(parent:             P
                             highlightthickness: 0
                             sliderlength:       SliderWidth
                             action:             A
                             'from':             0
                             to:                 N
                             length:             W
                             width:              ScaleHeight
                             resolution:         1
                             showvalue:          false
                             orient:             horizontal)
            self.Ticks = N
            TickScale,tkBind(event:  '<Configure>'
                             action: P # drawTicks)
         end

         meth getCoords($)
            TickScale,GetCoords(0 self.Ticks $)
         end

         meth GetCoords(I N $)
            case I>N then nil else
               {Tk.returnInt lindex(l(self coords I) 0)} |
               TickScale,GetCoords(I+1 N $)
            end
         end
      end

   in

      class DiscreteScale
         from Tk.frame

         feat
            Value
            Scale
            Ticks
            Coords
            Values
         attr
            CurValue: 0

         meth init(parent:  P
                   width:   Width
                   values:  Vs
                   initpos: N)
            DiscreteScale,tkInit(parent:P highlightthickness:0)
            NoTicks   = {Length Vs} - 1
         in
            self.Value = {New Tk.canvas tkInit(parent: self
                                               width:  Width + 2*ValueBorder
                                               height: ValueHeight)}
            self.Scale = {New TickScale init(parent: self
                                             width:  Width
                                             action: self # Action
                                             ticks:  NoTicks)}
            self.Ticks = {New TickCanvas init(parent: self
                                              width:  Width
                                              ticks:  NoTicks)}
            {Tk.batch [pack(self.Value self.Scale self.Ticks side:top)
                       update(idletasks)]}
            self.Values = Vs
            {self.Scale tk(set N-1)}
            CurValue    <- {Nth Vs N}.1
         end

         meth Action(S)
            N   = {Tk.string.toInt S}+1
            V#L = {Nth self.Values N}
            X   = {Nth self.Coords N}
         in
            {self.Value tk(delete all)}
            {self.Value tk(crea text X+ValueBorder 0
                           anchor:n text:L font:TitleFont)}
            CurValue <- V
         end

         meth drawTicks
            Cs = {self.Scale getCoords($)}
         in
            self.Coords = Cs
            thread
               {self.Ticks drawTicks(Cs)}
            end
         end

         meth get($)
            @CurValue
         end

      end
   end

   local
      proc {Select Url ?Base ?Ext}
         S={Reverse {VirtualString.toString Url}} R
      in
         Ext  = {String.toAtom {Reverse {String.token S &. $ ?R}}}
         Base = {String.toAtom {Reverse {String.token R &/ $ _}}}
      end
      fun {MkImg Url}
         Ext Base
      in
         {Select Url Base Ext}
         Base # case Ext==xbm then
                   {New Tk.image tkInit(type:bitmap url:Url)}
                else
                   {New Tk.image tkInit(type:photo format:Ext url:Url)}
                end
      end
   in
      fun {LoadImages Vs}
         {List.toRecord images {Map Vs MkImg}}
      end
   end

in

   tkTools(error:       Error
           dialog:      Dialog
           menubar:     MakeMenu
           textframe:   Textframe
           notebook:    Notebook
           note:        Note
           scale:       DiscreteScale
           numberentry: NumberEntry
           images:      LoadImages)

end
