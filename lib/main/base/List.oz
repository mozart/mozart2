%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Martin Henz, 1997
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


fun {MakeList N}
   if N>0 then _|{MakeList N-1} else nil end
end

fun {IsList Xs}
   case Xs of _|Xr then {IsList Xr} [] nil then true else false end
end

fun {Append Xs Ys}
   case Xs of nil then Ys
   [] X|Xr then X|{Append Xr Ys}
   end
end

fun {Member X Ys}
   case Ys of nil then false
   [] Y|Yr then X==Y orelse {Member X Yr}
   end
end

local
   fun {DoLength Xs N}
      case Xs of nil  then N
      [] _|Xr then {DoLength Xr N+1}
      end
   end
in
   fun {Length Xs} {DoLength Xs 0} end
end

local
   fun {DoNth Xs N}
      X|Xr = Xs in case N of 1 then X else {DoNth Xr N-1} end
   end
in
   fun {Nth Xs N}
      case N>0 of true then {DoNth Xs N} end
   end
end

local
   fun {DoReverse Xs Ys}
      case Xs of nil then Ys
      [] X|Xr then {DoReverse Xr X|Ys}
      end
   end
in
   fun {Reverse Xs} {DoReverse Xs nil} end
end

fun {Map Xs P}
   case Xs of nil then nil
   [] X|Xr then {P X}|{Map Xr P}
   end
end

fun {FoldL Xs P Z}
   case Xs of nil then Z
   [] X|Xr then {FoldL Xr P {P Z X}}
   end
end

fun {FoldLTail Xs P Z}
   case Xs of nil then Z
   [] _|Xr then {FoldLTail Xr P {P Z Xs}}
   end
end

fun {FoldR Xs P Z}
   case Xs of nil then Z
   [] X|Xr then {P X {FoldR Xr P Z}}
   end
end

fun {FoldRTail Xs P Z}
   case Xs of nil then Z
   [] _|Xr then {P Xs {FoldRTail Xr P Z}}
   end
end

proc {ForAll Xs P}
   case Xs of nil then skip
   [] X|Xr then {P X} {ForAll Xr P}
   end
end

fun {All Xs F}
   case Xs of nil then true
   [] X|Xr then {F X} andthen {All Xr F}
   end
end

fun {Some Xs F}
   case Xs of nil then false
   [] X|Xr then {F X} orelse {Some Xr F}
   end
end

proc {ForAllTail Xs P}
   case Xs of nil then skip
   [] _|Xr then {P Xs} {ForAllTail Xr P}
   end
end

fun {AllTail Xs F}
   case Xs of nil then true
   [] _|Xr then {F Xs} andthen {AllTail Xr F}
   end
end

fun {Filter Xs F}
   case Xs of nil then nil
   [] X|Xr then if {F X} then X|{Filter Xr F} else {Filter Xr F} end
   end
end

local
   fun {DoFlatten Xs Start End}
      case Xs of
         X|Xr then S S1 in
         if {DoFlatten X S S1}
         then S=Start {DoFlatten Xr S1 End}
         else S2 in Start=X|S2 {DoFlatten Xr S2 End}
         end
      [] nil then Start=End true
      else false
      end
   end
in
   fun {Flatten X}
      Start in if {DoFlatten X Start nil} then Start else X end
   end
end


local
   fun {DoMerge X Xr Ys F}
      case Ys of nil then X|Xr
      [] Y|Yr then
         if {F X Y} then X|{DoMerge Y Yr Xr F}
         else Y|{DoMerge X Xr Yr F}
         end
      end
   end
   fun {DoSort N Xs Ys P}
      case N
      of 0 then Ys=nil Ys
      [] 1 then X|!Ys=Xs in [X]
      [] 2 then X1|X2|!Ys=Xs in
         if {P X1 X2} then [X1 X2] else [X2 X1] end
      [] 3 then X1|X2|X3|!Ys=Xs in
         if {P X1 X2} then
            if {P X2 X3} then [X1 X2 X3]
            elseif {P X1 X3} then [X1 X3 X2]
            else [X3 X1 X2]
            end
         else
            if {P X1 X3} then [X2 X1 X3]
            elseif {P X2 X3} then [X2 X3 X1]
            else [X3 X2 X1]
            end
         end
      else
         N2     = N div 2 Xr
         MX|MXr = {DoSort N2 Xs Xr P}
      in
         {DoMerge MX MXr {DoSort N-N2 Xr Ys P} P}
      end
   end
in
   fun {Sort Xs P}
      {DoSort {Length Xs} Xs nil P}
   end
   fun {Merge Xs Ys P}
      case Xs of nil then Ys
      [] X|Xr then {DoMerge X Xr Ys P}
      end
   end
end

local
   %%
   %% Conventional Wisdom :-)
   %%
   fun {ListTail N T}
      case N>0 of true then _|{ListTail N-1 T} elsecase N==0 of true then T end
   end

   fun {Subtract Xs Y}
      case Xs of nil then nil
      [] X|Xr then if X\=Y then X|{Subtract Xr Y} else Xr end
      end
   end

   fun {Last X Xs}
      case Xs of nil then X
      [] XX|Xr then {Last XX Xr}
      end
   end

   local
      fun {Find X Xr Ys}
         case Ys of nil then false
         [] Y|Yr then
            if X==Y then {Sub Xr Yr} else {Find X Xr Yr} end
         end
      end
   in
      fun {Sub Xs Ys}
         case Xs
         of nil then true
         [] X|Xr then {Find X Xr Ys}
         end
      end
   end

   fun {Take Xs N}
      case Xs of nil then nil
      [] X|Xr then if N>0 then X|{Take Xr N-1} else N=0 nil end
      end
   end

   fun {Drop Xs N}
      case Xs of nil then nil
      [] _|Xr then if N>0 then {Drop Xr N-1} else N=0 Xs end
      end
   end

   proc {TakeDrop Xs N ?Ys ?Zs}
      case Xs of nil then Ys=nil Zs=nil
      [] X|Xr then
         if N>0 then Ys=X|{TakeDrop Xr N-1 $ Zs}
         else N=0 Ys=nil Zs=Xs
         end
      end
   end

   %%
   %% Higher Order Stuff without indices
   %%
   proc {Partition Xs F ?Ys ?Zs}
      case Xs of nil then Ys=nil Zs=nil
      [] X|Xr then
         if {F X} then Ys=X|{Partition Xr F $ Zs}
         else Zs=X|{Partition Xr F Ys $}
         end
      end
   end

   fun {TakeWhile Xs F}
      case Xs of nil then nil
      [] X|Xr then if {F X} then X|{TakeWhile Xr F} else nil end
      end
   end

   fun {DropWhile Xs F}
      case Xs of nil then nil
      [] X|Xr then if {F X} then {DropWhile Xr F} else Xs end
      end
   end

   proc {TakeDropWhile Xs F ?Ys ?Zs}
      case Xs of nil then Ys=nil Zs=nil
      [] X|Xr then
         if {F X} then  Ys=X|{TakeDropWhile Xr F $ Zs}
         else Ys=nil Zs=Xs
         end
      end
   end

   %%
   %% Higher Order Stuff with Indices
   %%
   fun {MapInd Xs I P}
      case Xs of nil then nil
      [] X|Xr then {P I X}|{MapInd Xr I+1 P}
      end
   end

   fun {FoldLInd Xs I P Z}
      case Xs of nil then Z
      [] X|Xr then {FoldLInd Xr I+1 P {P I Z X}}
      end
   end

   fun {FoldRInd Xs I P Z}
      case Xs of nil then Z
      [] X|Xr then {P I X {FoldRInd Xr I+1 P Z}}
      end
   end

   fun {FoldLTailInd Xs I P Z}
      case Xs of nil then Z
      [] _|Xr then {FoldLTailInd Xr I+1 P {P I Z Xs}}
      end
   end

   fun {FoldRTailInd Xs I P Z}
      case Xs of nil then Z
      [] _|Xr then {P I Xs {FoldRTailInd Xr I+1 P Z}}
      end
   end

   proc {ForAllInd Xs I P}
      case Xs of nil then skip
      [] X|Xr then {P I X} {ForAllInd Xr I+1 P}
      end
   end

   fun {AllInd Xs I F}
      case Xs of nil then true
      [] X|Xr then {F I X} andthen {AllInd Xr I+1 F}
      end
   end

   proc {ForAllTailInd Xs I P}
      case Xs of nil then skip
      [] _|Xr then {P I Xs} {ForAllTailInd Xr I+1 P}
      end
   end

   fun {AllTailInd Xs I F}
      case Xs of nil then true
      [] _|Xr then {F I Xs} andthen {AllTailInd Xr I+1 F}
      end
   end

   fun {SomeInd Xs I F}
      case Xs of nil then false
      [] X|Xr then {F I X} orelse {SomeInd Xr I+1 F}
      end
   end

   fun {FilterInd Xs I F}
      case Xs of nil then nil
      [] X|Xr then
         if {F I X} then X|{FilterInd Xr I+1 F}
         else {FilterInd Xr I+1 F}
         end
      end
   end

   proc {PartitionInd Xs I F ?Ys ?Zs}
      case Xs of nil then Ys=nil Zs=nil
      [] X|Xr then
         if {F I X} then Ys=X|{PartitionInd Xr I+1 F $ Zs}
         else Zs=X|{PartitionInd Xr I+1 F Ys $}
         end
      end
   end

   fun {TakeWhileInd Xs I F}
      case Xs of nil then nil
      [] X|Xr then if {F I X} then X|{TakeWhileInd Xr I+1 F} else nil end
      end
   end

   fun {DropWhileInd Xs I F}
      case Xs of nil then nil
      [] X|Xr then if {F I X} then {DropWhileInd Xr I+1 F} else Xs end
      end
   end

   proc {TakeDropWhileInd Xs I F ?Ys ?Zs}
      case Xs of nil then Ys=nil Zs=nil
      [] X|Xr then
         if {F I X} then Ys=X|{TakeDropWhileInd Xr I+1 F $ Zs}
         else Ys=nil Zs=Xs
         end
      end
   end


   fun {Zip Xs Ys P}
      case Xs of nil then case Ys of nil then nil end
      [] X|Xr then case Ys of Y|Yr then {P X Y}|{Zip Xr Yr P} end
      end
   end

   fun {NumberInc F T S}
      if F>T then nil else F|{NumberInc F+S T S} end
   end

   fun {NumberDec F T S}
      if F<T then nil else F|{NumberDec F+S T S} end
   end

   local
      proc {EnterArgs Xs N T}
         case Xs of nil then skip
         [] X|Xr then T.N=X {EnterArgs Xr N+1 T}
         end
      end
   in
      proc {ToTuple L Xs ?T}
         T = {MakeTuple L {Length Xs}}
         {EnterArgs Xs 1 T}
      end
   end

   fun {IsPrefix Xs Ys}
      case Xs of nil then true
      [] X|Xr then
         case Ys of nil then false
         [] Y|Yr then X==Y andthen {IsPrefix Xr Yr}
         end
      end
   end

in

   List = list(make:          MakeList
               withTail:      ListTail
               is:            IsList
               append:        Append
               member:        Member
               length:        Length
               nth:           Nth
               last:
                  fun {$ Xs}
                     case Xs of X|Xr then {Last X Xr} end
                  end
               subtract:      Subtract
               sub:           Sub
               reverse:       Reverse
               sort:          Sort
               merge:         Merge
               flatten:       Flatten
               zip:           Zip
               number:
                  fun {$ F T S}
                     if S>0 then {NumberInc F T S} else {NumberDec F T S} end
                  end
               take:          Take
               drop:          Drop
               takeDrop:      TakeDrop

               toTuple:       ToTuple
               toRecord:      Boot_List.toRecord

               map:           Map
               foldL:         FoldL
               foldR:         FoldR
               foldLTail:     FoldLTail
               foldRTail:     FoldRTail
               forAll:        ForAll
               all:           All
               some:          Some
               forAllTail:    ForAllTail
               allTail:       AllTail
               filter:        Filter
               partition:     Partition
               takeWhile:     TakeWhile
               dropWhile:     DropWhile
               takeDropWhile: TakeDropWhile
               mapInd:
                  fun {$ Xs P}
                     {MapInd Xs 1 P}
                  end
               foldLInd:
                  fun {$ Xs P Z}
                     {FoldLInd Xs 1 P Z}
                  end
               foldRInd:
                  fun {$ Xs P Z}
                     {FoldRInd Xs 1 P Z}
                  end
               foldLTailInd:
                  fun {$ Xs P Z}
                     {FoldLTailInd Xs 1 P Z}
                  end
               foldRTailInd:
                  fun {$ Xs P Z}
                     {FoldRTailInd Xs 1 P Z}
                  end
               forAllInd:
                  proc {$ Xs P}
                     {ForAllInd Xs 1 P}
                  end
               allInd:
                  fun {$ Xs F}
                     {AllInd Xs 1 F}
                  end
               someInd:
                  fun {$ Xs F}
                     {SomeInd Xs 1 F}
                  end
               forAllTailInd:
                  proc {$ Xs P}
                     {ForAllTailInd Xs 1 P}
                  end
               allTailInd:
                  fun {$ Xs F}
                     {AllTailInd Xs 1 F}
                  end
               filterInd:
                  fun {$ Xs F}
                     {FilterInd Xs 1 F}
                  end
               partitionInd:
                  proc {$ Xs F ?Ys ?Zs}
                     {PartitionInd Xs 1 F Ys Zs}
                  end
               takeWhileInd:
                  fun {$ Xs F}
                     {TakeWhileInd Xs 1 F}
                  end
               dropWhileInd:
                  fun {$ Xs F}
                     {DropWhileInd Xs 1 F}
                  end
               takeDropWhileInd:
                  proc {$ Xs F ?Ys ?Zs}
                     {TakeDropWhileInd Xs 1 F Ys Zs}
                  end
               isPrefix:
                  IsPrefix
              )

end
