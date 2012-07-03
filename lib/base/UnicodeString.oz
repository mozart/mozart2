%%%
%%% Authors:
%%%   Kenny Chan <kennytm@gmail.com>
%%%
%%% Copyright:
%%%   Kenny Chan, 2012
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

%%
%% StringOffset
%%

StringOffset = stringOffset(
    is: Boot_StringOffset.is
    toInt: Boot_StringOffset.toInt
    advance: Boot_StringOffset.advance
)

%%
%% UnicodeString
%%

local
    fun {FoldLInd S P Offset CurVal}
        NextOffset = {StringOffset.advance Offset S 1}
        ShouldBreak NewVal
    in
        if NextOffset \= false then
            {P Offset CurVal S.Offset ShouldBreak NewVal}
            if ShouldBreak then
                NewVal
            else
                {FoldLInd S P NextOffset NewVal}
            end
        else
            CurVal
        end
    end

    fun {FoldRInd S P Offset CurVal}
        PrevOffset = {StringOffset.advance Offset S ~1}
    in
        if PrevOffset \= false then
            {FoldRInd S P PrevOffset {P PrevOffset S.PrevOffset CurVal}}
        else
            CurVal
        end
    end
in

    IsUnicodeString = Boot_String.is
    UnicodeStringToAtom = Boot_String.toAtom
    %UnicodeStringToInt = Boot_String.toInt
    %UnicodeStringToFloat = Boot_String.toFloat

    UnicodeString = unicodeString(
        is: IsUnicodeString
        toAtom: UnicodeStringToAtom
        %isAtom: Boot_String.isAtom
        %toInt: StringToInt
        %isInt: Boot_String.isInt
        %toFloat: StringToFloat
        %isFloat: Boot_String.isFloat

        append: Boot_String.append
        slice: Boot_String.slice
        search: Boot_String.search
        'end': Boot_String.'end'
        isPrefix: fun {$ X Y} {Boot_String.hasPrefix Y X} end
        isSuffix: fun {$ X Y} {Boot_String.hasSuffix Y X} end

        length: Boot_VirtualString.length

        token:
            proc {$ S Needle ?Before ?After}
                NeedleBegin NeedleEnd
            in
                {UnicodeString.search S 0 Needle NeedleBegin NeedleEnd}
                if NeedleBegin \= false then
                    Before = {UnicodeString.slice S 0 NeedleBegin}
                    After = {UnicodeString.slice S NeedleEnd {UnicodeString.'end' S}}
                else
                    Before = S
                    After = ""
                end
            end

        tokens:
            fun {$ S Needle}
                Before After
            in
                {UnicodeString.token S Needle Before After}
                Before|if After == "" then nil else {UnicodeString.tokens After Needle} end
            end

        foldLInd:
            fun {$ S P Init}
                {FoldLInd  S  proc {$ I V C ?ShouldBreak ?Val}
                    Val = {P I V C}
                    ShouldBreak = false
                end  0  Init}
            end
        foldRInd:
            fun {$ S P Init}
                {FoldRInd  S  P  {UnicodeString.'end' S}  Init}
            end

        foldL:
            fun {$ S P Init}
                {UnicodeString.foldLInd  S  fun {$ I V C} {P V C} end  Init}
            end

        foldR:
            fun {$ S P Init}
                {UnicodeString.foldRInd  S  fun {$ I C V} {P C V} end  Init}
            end

        forAllInd:
            proc {$ S P}
                {UnicodeString.foldLInd  S  proc {$ I V C R} {P I C} end  _  _}
            end
        forAll:
            proc {$ S P}
                {UnicodeString.forAllInd  S  proc {$ I C} {P C} end}
            end

        allInd:
            fun {$ S P}
                {FoldLInd  S  proc {$ I V C ?ShouldBreak ?Val}
                    Val = {P I C}
                    ShouldBreak = {Not Val}
                end  0  true}
            end

        someInd:
            fun {$ S P}
                {FoldLInd  S  proc {$ I V C ?ShouldBreak ?Val}
                    Val = {P I C}
                    ShouldBreak = Val
                end  0  false}
            end

        all: fun {$ S P} {UnicodeString.allInd S fun {$ I C} {P C} end} end
        some: fun {$ S P} {UnicodeString.someInd S fun {$ I C} {P C} end} end

        toListWithTail:
            fun {$ S Tail}
                {UnicodeString.foldR  S  fun {$ C L} C|L end  Tail}
            end

        toList: fun {$ S} {UnicodeString.toListWithTail S nil} end

        toString:
            fun {$ S}
                {Map {UnicodeString.toList S} fun {$ C}
                    if C =< 255 then C else &? end
                end}
            end

        toTuple:
            fun {$ Label S}
                TupleWidth = {UnicodeString.length S}
                T = {MakeTuple Label TupleWidth}
            in
                {UnicodeString.foldL  S  fun {$ Index C}
                    T.Index = C
                    Index + 1
                end  1  _}
                T
            end

        toArray:
            fun {$ S}
                ArrayLength = {UnicodeString.length S}
                A = {NewArray  0  ArrayLength-1  unit}
            in
                {UnicodeString.foldL  S  fun {$ Index C}
                    A.Index := C
                    Index + 1
                end  0  _}
                A
            end
    )

end
