%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1999
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor $
import
   System(show printName)
export
   quoteString  : QuoteStr
   convert      : ConvertAtomExternal
   atom         : AtomNode
   label        : LabelNode
   separator    : SeparatorNode
   separatorSML : SeparatorSMLNode
   feature      : FeatureNode
   featureInd   : FeatureIndNode
   bitmap       : BitmapNode
   proxy        : ProxyNode
   embraced     : EmbracedNode
   box          : BoxedNode
   empty        : EmptyNode
   tupleSML     : TupleSMLNode
   recordSML    : RecordSMLNode
define
   QuoteStr
   local
%       fun {OctStr I Ir}
%        ((I div 64) mod 8 + &0)|((I div 8)  mod 8 + &0)|(I mod 8 + &0)|Ir
%       end
%       fun {SkipQuoting As}
%        case As
%        of A|Ar then
%           {Char.type A} == lower andthen {IsAlphaNum Ar}
%        else true
%        end
%       end
      fun {IsAlphaNum As}
         case As
         of nil  then true
         [] A|Ar then
            T = {Char.type A}
         in
            ((T == upper) orelse (T == lower) orelse (T == digit) orelse (A == 95)) andthen {IsAlphaNum Ar}
         end
      end
   in
      fun {QuoteStr Is}
         case Is
         of nil  then nil
         [] I|Ir then
            case {Char.type I}
%           of space then
%              case I
%              of &\n then &\\|&n|{QuoteStr Ir}
%              [] &\f then &\\|&f|{QuoteStr Ir}
%              [] &\r then &\\|&r|{QuoteStr Ir}
%              [] &\t then &\\|&t|{QuoteStr Ir}
%              [] &\v then &\\|&v|{QuoteStr Ir}
%              else I|{QuoteStr Ir}
%              end
%           [] other then
%              case I
%              of &\a then &\\|&a|{QuoteStr Ir}
%              [] &\b then &\\|&b|{QuoteStr Ir}
%              else &\\|{OctStr I {QuoteStr Ir}}
%              end
            of punct then
               case I
               of 34  then 92|34|{QuoteStr Ir}  %% '"'
               [] 36  then 92|36|{QuoteStr Ir}  %% '$'
               [] 39  then 92|39|{QuoteStr Ir}  %% '''
               [] 92  then 92|92|{QuoteStr Ir}  %% '\'
               [] 91  then 92|91|{QuoteStr Ir}  %% '['
               [] 93  then 92|93|{QuoteStr Ir}  %% ']'
               [] 123 then 92|123|{QuoteStr Ir} %% '{'
               [] 125 then 92|125|{QuoteStr Ir} %% '}'
               else I|{QuoteStr Ir}
               end
            else I|{QuoteStr Ir}
            end
         end
      end
      proc {ConvertAtomExternal V PrintStr LenStr}
         LenStr   = {Value.toVirtualString V 0 0}
         PrintStr = {QuoteStr LenStr}
      end
%      fun {ConvertAtom V}
%        {QuoteStr {Value.toVirtualString V 0 0}}
%      end
   end

   local
      class SharedValues
         attr
            visual       %% Visual Reference
            tag          %% Own Tag
            xDim         %% X Dimension
            string       %% String (Limiter/Feature)
            dirty : true %% Dirty Flag
      end

      class CombinedValues from SharedValues
         attr
            yDim     %% YDimension
            lastXDim %% X Dimension of Last Object
            node     %% Node Reference
         meth create(Node Visual)
            @visual = Visual
            @tag    = {Visual newTag($)}
            @node   = Node
         end
         meth getValue($)
            {@node getValue($)}
         end
         meth getNode($)
            @node
         end
         meth getInnerNode($)
            @node
         end
         meth getXDim($)
            @xDim
         end
         meth getXYDim($)
            @xDim|@yDim
         end
         meth getLastXDim($)
            @lastXDim
         end
         meth isVert($)
            {@node isVert($)}
         end
         meth isSep($)
            true
         end
         meth isProxy($)
            {@node isProxy($)}
         end
         meth mustChange($)
            true
         end
         meth change(Node)
            node <- Node
         end
         meth makeDirty
            dirty <- true
            {@node makeDirty}
         end
      end

      class SecondTags
         attr
            secTag %% Second Complete Tag Tree
      end

      class GetType
         meth getType($)
            {@node getType($)}
         end
         meth notEmbraced($)
            {@node notEmbraced($)}
         end
      end

      class SharedProcs
         meth getXDim($)
            @xDim
         end
         meth makeDirty
            dirty <- true
         end
         meth searchNode(XA YA X Y $)
            if X >= XA andthen X < (XA + @xDim) andthen YA == Y then self else nil end
         end
         meth getMenuType($)
            {@parent getMenuType($)}
         end
         meth getFirstItem($)
            @tag
         end
         meth getTag($)
            @tag
         end
      end
   in
      class AtomNode from SharedValues SharedProcs
         attr
            index  %% Parent Node Index
            type   %% Internal Atom Type
            parent %% Parent Node
         meth create(Value Parent Index Visual Type)
            StrVal = {VirtualString.toString Value}
         in
            @visual = Visual
            @tag    = {Visual newTag($)}
            @string = {QuoteStr StrVal}
            @xDim   = {VirtualString.length StrVal}
            @index  = Index
            @type   = Type
            @parent = Parent
         end
         meth getIndex($)
            @index
         end
         meth getLastXDim($)
            @xDim
         end
         meth layout
            skip
         end
         meth layoutX($)
            @xDim
         end
         meth layoutY($)
            @xDim|1
         end
         meth getXDim($)
            @xDim
         end
         meth isVert($)
            false
         end
         meth draw(X Y)
            if @dirty
            then dirty <- false {@visual printXY(X Y @string @tag @type)}
            else {@visual place(X Y @tag)}
            end
         end
         meth drawX(X Y $)
            AtomNode, draw(X Y) (X + @xDim)
         end
         meth drawY(X Y $)
            AtomNode, draw(X Y) (Y + 1)
         end
         meth undraw
            if @dirty then skip else {@visual delete(@tag)} end
         end
         meth dirtyUndraw
            if @dirty then skip else {@visual delete(@tag)} end
            dirty <- true
         end
         meth getSelectionNode($)
            @parent
         end
      end

      class LabelNode from SharedValues SecondTags SharedProcs
         attr
            value  %% Store Reference
            parent %% Parent Node
            limStr %% Limiter String
         prop
            final
         meth create(LabVal Limiter Parent Visual)
            @visual = Visual
            @tag    = {Visual newTag($)}
            @secTag = {Visual newTag($)}
            @parent = Parent
            @value  = LabVal
            @limStr = Limiter
         end
         meth getIndex($)
            0
         end
         meth getRootIndex(I $)
            {@parent getRootIndex(0 $)}
         end
         meth getSimpleRootIndex(I $)
            {@parent getSimpleRootIndex(0 $)}
         end
         meth layoutX($)
            XDim = @xDim
         in
            if {IsFree XDim}
            then
               PrintStr = @string
            in
               XDim = ({VirtualString.length {ConvertAtomExternal @value PrintStr}} + 1)
            end
            XDim
         end
         meth drawX(X Y $)
            Visual  = @visual
            XDim    = @xDim
            StringX = (XDim - 1)
         in
            if @dirty
            then
               dirty <- false
               {Visual printXY(X Y @string @tag label)}
               {Visual printXY((X + StringX) Y @limStr @secTag internal)}
            else {Visual doublePlace(X Y StringX @tag @secTag)}
            end
            (X + XDim)
         end
         meth undraw
            if @dirty
            then skip
            else
               Visual = @visual
            in
               dirty <- true
               {Visual delete(@tag)}
               {Visual delete(@secTag)}
            end
         end
         meth getSelectionNode($)
            @parent
         end
      end

      class FeatureNode from CombinedValues SecondTags GetType
         attr
            sDim %% String Length
         meth create(FeaVal Visual Node)
            String = @string
         in
            CombinedValues, create(Node Visual)
            @secTag = {Visual newTag($)}
            String  = if {IsAtom FeaVal}
                      then {ConvertAtomExternal FeaVal _}
                      elseif {IsName FeaVal}
                      then '<N:'#{System.printName FeaVal}#'>'
                      else FeaVal
                      end
            @sDim   = {VirtualString.length String}
         end
         meth smlCreate(FeaVal Visual Node)
            sepString <- '='
            FeatureNode, create(FeaVal Visual Node)
         end
         meth isInfix($)
            {@node isInfix($)}
         end
         meth layout
            FeaX = (@sDim + 1)
            Node = @node
         in
            case {Node layoutY($)}
            of XDim|YDim then
               xDim     <- (FeaX + XDim)
               yDim     <- YDim
               lastXDim <- (FeaX + {Node getLastXDim($)})
            end
         end
         meth layoutX($)
            FeatureNode, layout @xDim
         end
         meth layoutY($)
            FeatureNode, layout @xDim|@yDim
         end
         meth draw(X Y)
            Visual = @visual
            SDim   = @sDim
         in
            if @dirty
            then
               dirty <- false
               {Visual printXY(X Y @string @tag feature)}
               {Visual printXY((X + SDim) Y ':' @secTag colon)}
            else {Visual doublePlace(X Y SDim @tag @secTag)}
            end
            {@node draw((X + SDim + 1) Y)}
         end
         meth drawX(X Y $)
            FeatureNode, draw(X Y) (X + @xDim)
         end
         meth drawY(X Y $)
            FeatureNode, draw(X Y) (Y + @yDim)
         end
         meth isFresh($)
            {@node isFresh($)}
         end
         meth eliminateFresh(I)
            {@node eliminateFresh(I)}
         end
         meth undraw
            if @dirty
            then skip
            else
               Visual = @visual
            in
               dirty <- true
               {Visual delete(@tag)}
               {Visual delete(@secTag)}
               {@node undraw}
            end
         end
         meth searchNode(XA YA X Y $)
            {@node searchNode((XA + @sDim + 1) YA X Y $)}
         end
         meth getFirstItem($)
            @tag
         end
         meth getTag($)
            @tag
         end
         meth getSelectionNode($)
            {@node getParent($)}
         end
      end

      class FeatureIndNode from FeatureNode
         meth layout
            FeaX = (@sDim + 1)
            Node = @node
         in
            case {Node layoutY($)}
            of XDim|YDim then
               if {{Node getParent($)} getHorzMode($)}
               then
                  xDim     <- (FeaX + XDim)
                  yDim     <- YDim
                  lastXDim <- (FeaX + {Node getLastXDim($)})
               else
                  RealXDim = {Max (FeaX - 3) XDim}
               in
                  xDim     <- (3 + RealXDim)
                  yDim     <- (YDim + 1)
                  lastXDim <- (3 + {Node getLastXDim($)})
               end
            end
         end
         meth layoutX($)
            FeatureIndNode, layout @xDim
         end
         meth layoutY($)
            FeatureIndNode, layout @xDim|@yDim
         end
         meth draw(X Y)
            Visual = @visual
            SDim   = @sDim
            Node   = @node
         in
            if @dirty
            then
               dirty <- false
               {Visual printXY(X Y @string @tag feature)}
               {Visual printXY((X + SDim) Y ':' @secTag colon)}
            else {Visual doublePlace(X Y SDim @tag @secTag)}
            end
            if {{Node getParent($)} getHorzMode($)}
            then {Node draw((X + SDim + 1) Y)}
            else {Node draw((X + 3) (Y + 1))}
            end
         end
         meth drawX(X Y $)
            FeatureIndNode, draw(X Y) (X + @xDim)
         end
         meth drawY(X Y $)
            FeatureIndNode, draw(X Y) (Y + @yDim)
         end
         meth searchNode(XA YA X Y $)
            Node = @node
         in
            if {{Node getParent($)} getHorzMode($)}
            then {Node searchNode((XA + @sDim + 1) YA X Y $)}
            else {Node searchNode((XA + 3) (YA + 1) X Y $)}
            end
         end
      end

      class SeparatorNode from CombinedValues GetType
         meth create(SepVal Visual Node)
            @string = SepVal
            CombinedValues, create(Node Visual)
         end
         meth getIndex($)
            0
         end
         meth getMenuType($)
            {{@node getParent($)} getMenuType($)}
         end
         meth isInfix($)
            {@node isInfix($)}
         end
         meth layout
            Node = @node
         in
            case {Node layoutY($)}
            of XDim|YDim then
               LXDim = ({Node getLastXDim($)} + 1)
            in
               xDim     <- {Max XDim LXDim}
               yDim     <- YDim
               lastXDim <- LXDim
            end
         end
         meth layoutX($)
            SeparatorNode, layout @xDim
         end
         meth layoutY($)
            SeparatorNode, layout @xDim|@yDim
         end
         meth draw(X Y)
            Visual = @visual
            Node   = @node
            NewY   = ({Node drawY(X Y $)} - 1)
            NewX   = (X + @lastXDim - 1)
         in
            if @dirty
            then dirty <- false {Visual printXY(NewX NewY @string @tag separator)}
            else {Visual place(NewX NewY @tag)}
            end
         end
         meth drawX(X Y $)
            SeparatorNode, draw(X Y) (X + @xDim)
         end
         meth drawY(X Y $)
            SeparatorNode, draw(X Y) (Y + @yDim)
         end
         meth isFresh($)
            {@node isFresh($)}
         end
         meth eliminateFresh(I)
            {@node eliminateFresh(I)}
         end
         meth undraw
            if @dirty then skip else dirty <- true {@node undraw} {@visual delete(@tag)} end
         end
         meth searchNode(XA YA X Y $)
            Node = @node
         in
            if X == (XA + @lastXDim - 1) andthen Y == (YA + @yDim - 1)
            then self
            elsecase {Node getXYDim($)}
            of XDim|YDim then
               YM = (YA + YDim)
            in
               if Y >= YA andthen Y < YM andthen X >= XA andthen X < (XA + XDim)
               then {Node searchNode(XA YA X Y $)}
               else nil
               end
            end
         end
         meth remove($)
            if @dirty then skip else {@visual delete(@tag)} end @node
         end
         meth getFirstItem($)
            {@node getFirstItem($)}
         end
         meth getSelectionNode($)
            {@node getParent($)}
         end
      end

      class SeparatorSMLNode from SeparatorNode
         meth layout
            Node = @node
         in
            case {Node layoutY($)}
            of XDim|YDim then
               LXDim = ({Node getLastXDim($)} + {VirtualString.length @string})
            in
               xDim     <- {Max XDim LXDim}
               yDim     <- YDim
               lastXDim <- LXDim
            end
         end
         meth layoutX($)
            SeparatorSMLNode, layout @xDim
         end
         meth layoutY($)
            SeparatorSMLNode, layout @xDim|@yDim
         end
         meth draw(X Y)
            Visual = @visual
            Node   = @node
            NewY   = ({Node drawY(X Y $)} - 1)
            String = @string
            NewX   = (X + @lastXDim - {VirtualString.length String})
         in
            if @dirty
            then dirty <- false {Visual printXY(NewX NewY String @tag separator)}
            else {Visual place(NewX NewY @tag)}
            end
         end
         meth drawX(X Y $)
            SeparatorSMLNode, draw(X Y) (X + @xDim)
         end
         meth drawY(X Y $)
            SeparatorSMLNode, draw(X Y) (Y + @yDim)
         end
         meth searchNode(XA YA X Y $)
            Node   = @node
            XSep   = (XA + @lastXDim)
            SepDim = {VirtualString.length @string}
         in
            if ((SepDim == 2 andthen (X == (XSep - 1) orelse X == (XSep - 2)))
                orelse (SepDim == 1 andthen X == (XSep - 1)))
               andthen Y == (YA + @yDim - 1)
            then self
            elsecase {Node getXYDim($)}
            of XDim|YDim then
               YM = (YA + YDim)
            in
               if Y >= YA andthen Y < YM andthen X >= XA andthen X < (XA + XDim)
               then {Node searchNode(XA YA X Y $)}
               else nil
               end
            end
         end
         meth changeSep(SepVal)
            if @dirty then skip else dirty <- true {@visual delete(@tag)} end string <- SepVal
         end
      end

      class TupleSMLNode from SeparatorNode
         meth create(FeaVal Visual Node)
            @string = if {{Node getParent($)} isLast(Node $)} then '' else ',' end
            CombinedValues, create(Node Visual)
         end
         meth layout
            Node = @node
         in
            case {Node layoutY($)}
            of XDim|YDim then
               DeltaX = {VirtualString.length @string}
               LXDim  = ({Node getLastXDim($)} + DeltaX)
            in
               xDim     <- {Max XDim LXDim}
               yDim     <- YDim
               lastXDim <- LXDim
            end
         end
         meth layoutX($)
            TupleSMLNode, layout @xDim
         end
         meth layoutY($)
            TupleSMLNode, layout @xDim|@yDim
         end
         meth draw(X Y)
            Visual = @visual
            Node   = @node
            NewY   = ({Node drawY(X Y $)} - 1)
            NewX   = (X + @lastXDim - 1)
            String = @string
         in
            case String
            of '' then skip
            elseif @dirty
            then dirty <- false {Visual printXY(NewX NewY String @tag separator)}
            else {Visual place(NewX NewY @tag)}
            end
         end
         meth drawX(X Y $)
            TupleSMLNode, draw(X Y) (X + @xDim)
         end
         meth drawY(X Y $)
            TupleSMLNode, draw(X Y) (Y + @yDim)
         end
         meth undraw
            if @dirty
            then skip
            else
               dirty <- true
               case @string of '' then skip else {@visual delete(@tag)} end
            end
            {@node undraw}
         end
         meth searchNode(XA YA X Y $)
            Node = @node
         in
            if {VirtualString.length @string} == 1 andthen
               X == (XA + @lastXDim - 1) andthen Y == (YA + @yDim - 1)
            then self
            elsecase {Node getXYDim($)}
            of XDim|YDim then
               YM = (YA + YDim)
            in
               if Y >= YA andthen Y < YM andthen X >= XA andthen X < (XA + XDim)
               then {Node searchNode(XA YA X Y $)}
               else nil
               end
            end
         end
         meth remove($)
            if @dirty orelse @string == '' then skip else {@visual delete(@tag)} end
            @node
         end
      end


      local
         class FeatureSMLNode from FeatureNode
            meth draw(X Y)
               Visual = @visual
               SDim   = @sDim
            in
               if @dirty
               then
                  dirty <- false
                  {Visual printXY(X Y @string @tag feature)}
                  {Visual printXY((X + SDim) Y '=' @secTag colon)}
               else {Visual doublePlace(X Y SDim @tag @secTag)}
               end
               {@node draw((X + SDim + 1) Y)}
            end
            meth drawX(X Y $)
               FeatureSMLNode, draw(X Y) (X + @xDim)
            end
            meth drawY(X Y $)
               FeatureSMLNode, draw(X Y) (Y + @yDim)
            end
            meth getParent($)
               {@node getParent($)}
            end
         end
      in
         class RecordSMLNode from TupleSMLNode
            meth create(FeaVal Visual Node)
               NewNode = {New FeatureSMLNode create(FeaVal Visual Node)}
            in
               @string = if {{Node getParent($)} isLast(Node $)} then '' else ',' end
               CombinedValues, create(NewNode Visual)
            end
            meth change(Node)
               {@node change(Node)}
            end
         end
      end

      class BitmapNode
         attr
            value        %% Bitmap Value
            type         %% Node Type
            parent       %% Parent Object
            index        %% Parent Entry Index
            visual       %% Visual Reference
            tag          %% Own Tag
            dirty : true %% Dirty Flag
            buffer       %% Rescue Value
         prop
            final
         meth create(Value Parent Index Visual)
            @parent = Parent
            @index  = Index
            @visual = Visual
            @tag    = {Visual newTag($)}
            @value  = case Value
                      of width then
                         @type = widthbitmap
                         {Visual get(widgetWidthLimitBitmap $)}
                      [] depth then
                         @type = depthbitmap
                         {Visual get(widgetDepthLimitBitmap $)}
                      end
         end
         meth isInfix($)
            false
         end
         meth isDirty($)
            @dirty
         end
         meth seekEnd($)
            @parent
         end
         meth downNotify
            skip
         end
         meth treeCreate(Value Parent Index Visual ResValue)
            @buffer = ResValue
            BitmapNode, create(Value Parent Index Visual)
         end
         meth setRescueValue(Value)
            @buffer = Value
         end
         meth getValue($)
            @buffer
         end
         meth getRescueValue($)
            @buffer
         end
         meth getType($)
            @type
         end
         meth getParent($)
            @parent
         end
         meth getIndex($)
            @index
         end
         meth getRootIndex(I $)
            {@parent getRootIndex(@index $)}
         end
         meth getSimpleRootIndex(I $)
            {@parent getSimpleRootIndex(@index $)}
         end
         meth collectTags(I Ts $)
            {@parent collectTags(@index @tag|Ts $)}
         end
         meth mustChange($)
            false
         end
         meth getInnerNode($)
            self
         end
         meth isSep($)
            false
         end
         meth isProxy($)
            false
         end
         meth isRef($)
            false
         end
         meth addSeps(I)
            skip
         end
         meth layout
            skip
         end
         meth layoutX($)
            2
         end
         meth layoutY($)
            2|1
         end
         meth getXDim($)
            2
         end
         meth getYDim($)
            1
         end
         meth getXYDim($)
            2|1
         end
         meth getLastXDim($)
            2
         end
         meth isVert($)
            false
         end
         meth notEmbraced($)
            true
         end
         meth graphHorzMode(I Mode HorzMode)
            HorzMode = {Not Mode}
         end
         meth draw(X Y)
            if @dirty
            then
               dirty <- false
               {@visual paintXY(X Y @value @tag @type)}
            else {@visual place(X Y @tag)}
            end
         end
         meth drawX(X Y $)
            BitmapNode, draw(X Y) (X + 2)
         end
         meth drawY(X Y $)
            BitmapNode, draw(X Y) (Y + 1)
         end
         meth isFresh($)
            false
         end
         meth eliminateFresh(I)
            skip
         end
         meth getFirstItem($)
            @tag
         end
         meth getTag($)
            @tag
         end
         meth undraw
            if @dirty then skip else dirty <- true {@visual delete(@tag)} end
         end
         meth searchNode(XA YA X Y $)
            if X >= XA andthen X < (XA + 2) andthen YA == Y then self else nil end
         end
         meth getMenuType($)
            @type|self
         end
         meth isMapped(Index $)
            {@parent isMapped(@index $)}
         end
         meth makeDirty
            dirty <- true
         end
         meth map(Index F)
            Val      = @value
            NewValue = try {F Val}
                       catch X then
                          mapping_failed(ex:{Value.byNeed fun {$} X end} val:Val)
                       end
         in
            {@parent link(@index NewValue)}
         end
         meth unmap
            {@parent unlink(@index)}
         end
         meth action(Index P)
            if {IsTuple P}
            then {self P}
            else try {P @value} catch _ then skip end
            end
         end
         meth modifyWidth(Index N)
            {@parent modifyWidth(Index N)}
         end
         meth modifyDepth(Index N)
            {@parent modifyDepth(Index N)}
         end
         meth reinspect
            {@parent notify}
            {@parent replace(@index @value replaceNormal)}
         end
         meth getSelectionNode($)
            self
         end
      end

      local
         class SharedProxyValues from GetType
            meth getParent($)
               {@node getParent($)}
            end
            meth getIndex($)
               {@node getIndex($)}
            end
            meth getRootIndex(I $)
               {@node getRootIndex(I $)}
            end
            meth getSimpleRootIndex(I $)
               {@node getSimpleRootIndex(I $)}
            end
            meth collectTags(I Ts $)
               {@node collectTags(I Ts $)}
            end
            meth getLData($)
               {@node getLData($)}
            end
            meth isRef($)
               {@node isRef($)}
            end
            meth addSeps(I)
               {@node addSeps(I)}
            end
            meth getMenuType($)
               {@node getMenuType($)}
            end
            meth changeWidth(N)
               {@node changeWidth(N)}
            end
            meth changeDepth(N)
               {@node changeDepth(N)}
            end
            meth map(F)
               {@node map(F)}
            end
            meth unmap
               {@node unmap}
            end
            meth isMapped(Index $)
               {@node isMapped(Index $)}
            end
         end
      in
         class ProxyNode from SharedProxyValues
            attr
               node         %% Active Node
               old          %% Old Node
               tag          %% Own Tag
               visual       %% Visual Object
               dirty : true %% Dirty Flag
            meth create(Passive Active Index Visual Depth)
               @node   = Active
               @old    = Passive
               @tag    = {Visual newTag($)}
               @visual = Visual
            end
            meth isInfix($)
               {@node isInfix($)}
            end
            meth isDirty($)
               @dirty
            end
            meth seekEnd($)
               {@node getParent($)}
            end
            meth downNotify
               {@node downNotify}
            end
            meth getValue($)
               {@node getValue($)}
            end
            meth notify
               {@node notify}
            end
            meth mustChange($)
               true
            end
            meth change(Node)
               node <- Node
            end
            meth unbox($)
               @old
            end
            meth isSep($)
               false
            end
            meth getInnerNode($)
               self
            end
            meth getNode($)
               @node
            end
            meth isProxy($)
               true
            end
            meth isVert($)
               {@node isVert($)}
            end
            meth layout
               {@node layout}
            end
            meth layoutX($)
               {@node layoutX($)}
            end
            meth layoutY($)
               {@node layoutY($)}
            end
            meth getXDim($)
               {@node getXDim($)}
            end
            meth getYDim($)
               {@node getYDim($)}
            end
            meth getXYDim($)
               {@node getXYDim($)}
            end
            meth getLastXDim($)
               {@node getLastXDim($)}
            end
            meth graphHorzMode(I Mode HorzMode)
               {@node graphHorzMode(I Mode HorzMode)}
            end
            meth draw(X Y)
               ProxyNode, drawRectangle(X Y) {@node draw(X Y)}
            end
            meth drawX(X Y $)
               ProxyNode, drawRectangle(X Y) {@node drawX(X Y $)}
            end
            meth drawY(X Y $)
               ProxyNode, drawRectangle(X Y) {@node drawY(X Y $)}
            end
            meth drawRectangle(X Y)
               Node   = @node
               Visual = @visual
               XYDim  = {Node getXYDim($)}
               Dirty  = @dirty
            in
               if Dirty then dirty <- false end
               {Visual drawRectangle(X Y @tag XYDim Dirty)}
            end
            meth isFresh($)
               {@node isFresh($)}
            end
            meth eliminateFresh(I)
               {@node eliminateFresh(I)}
            end
            meth undraw
               if @dirty then skip else dirty <- true {@visual delete(@tag)} {@node undraw} end
            end
            meth searchNode(XA YA X Y $)
               {@node searchNode(XA YA X Y $)}
            end
            meth getFirstItem($)
               {@node getFirstItem($)}
            end
            meth getTag($)
               {@node getTag($)}
            end
            meth makeDirty
               dirty <- true {@node makeDirty}
            end
         end

         class EmbracedNode from CombinedValues SecondTags SharedProxyValues
            attr
               obrace %% Opening Brace
               cbrace %% Closing Brace
            prop
               final
            meth create(Value Parent Index Visual Type)
               CombinedValues, create(Value Visual)
               @secTag = {Visual newTag($)}
               case Type
               of round then @obrace = '(' @cbrace = ')'
               else @obrace = '{' @cbrace = '}'
               end
            end
            meth isInfix($)
               false
            end
            meth isSep($)
               false
            end
            meth isProxy($)
               false
            end
            meth layout
               Node = @node
            in
               case {Node layoutY($)}
               of XDim|YDim then
                  LXDim = ({Node getLastXDim($)} + 1)
               in
                  xDim     <- (1 + {Max LXDim XDim})
                  yDim     <- YDim
                  lastXDim <- (1 + LXDim)
               end
            end
            meth layoutX($)
               EmbracedNode, layout @xDim
            end
            meth layoutY($)
               EmbracedNode, layout @xDim|@yDim
            end
            meth notEmbraced($)
               false
            end
            meth draw(X Y)
               Visual = @visual
               NewX   = (X + @lastXDim - 1) NewY
            in
               if @dirty
               then
                  dirty <- false
                  {Visual printXY(X Y @obrace @tag braces)}
                  NewY = ({@node drawY((X + 1) Y $)} - 1)
                  {Visual printXY(NewX NewY @cbrace @secTag braces)}
               else
                  {Visual place(X Y @tag)}
                  NewY = ({@node drawY((X + 1) Y $)} - 1)
                  {Visual place(NewX NewY @secTag)}
               end
            end
            meth drawX(X Y $)
               EmbracedNode, draw(X Y) (X + @xDim)
            end
            meth drawY(X Y $)
               EmbracedNode, draw(X Y) (Y + @yDim)
            end
            meth isFresh($)
               {@node isFresh($)}
            end
            meth eliminateFresh(I)
               {@node eliminateFresh(I)}
            end
            meth undraw
               if @dirty
               then skip
               else
                  Visual = @visual
               in
                  dirty <- true
                  {Visual delete(@tag)}
                  {@node undraw}
                  {Visual delete(@secTag)}
               end
            end
            meth searchNode(XA YA X Y $)
               {@node searchNode((XA + 1) YA X Y $)}
            end
            meth getFirstItem($)
               @tag
            end
            meth getTag($)
               {@node getTag($)}
            end
            meth makeDirty
               dirty <- true {@node makeDirty}
            end
         end
      end
   end

   class BoxedNode
      prop
         final
      attr
         value
      meth create(Value)
         @value = Value
      end
      meth getValue($)
         @value
      end
      meth undraw
         skip
      end
      meth mustChange($)
         false
      end
      meth isProxy($)
         false
      end
   end

   class EmptyNode
      attr
         parent %% Parent Object
      prop
         final
      meth create(Parent)
         @parent = Parent
      end
      meth isInfix($)
         false
      end
      meth seekEnd($)
         @parent
      end
      meth downNotify
         skip
      end
      meth isSep($)
         false
      end
      meth isProxy($)
         false
      end
      meth addSeps(I)
         skip
      end
      meth layout
         skip
      end
      meth layoutX($)
         0
      end
      meth layoutY($)
         0|1
      end
      meth getXDim($)
         0
      end
      meth getYDim($)
         1
      end
      meth getXYDim($)
         0|1
      end
      meth isVert($)
         false
      end
      meth notEmbraced($)
         true
      end
      meth draw(X Y)
         skip
      end
      meth drawX(X Y $)
         X
      end
      meth drawY(X Y $)
         (Y + 1)
      end
      meth isFresh($)
         false
      end
      meth eliminateFresh(I)
         skip
      end
      meth undraw
         skip
      end
      meth searchNode(XA YA X Y $)
         nil
      end
      meth isMapped(Index $)
         {@parent isMapped(@index $)}
      end
      meth makeDirty
         skip
      end
   end
end
