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


%%
%% Global
%%

MakeRecord = Boot_Record.make

%%
%% Module
%%
local
   fun {MakePairs As R}
      case As of nil then nil
      [] A|Ar then A#R.A|{MakePairs Ar R}
      end
   end

   fun {Subtract R F}
      {List.toRecord {Label R} {MakePairs {List.subtract {Arity R} F} R}}
   end

   local
      proc {MemberDrop Xs Y ?Zs ?B}
         case Xs of nil then Zs=nil B=false
         [] X|Xr then
            if X==Y then Zs=Xr B=true else Zs=X|{MemberDrop Xr Y $ ?B} end
         end
      end
      fun {SubtractArity As Ss}
         case As of nil then nil
         [] A|Ar then Sr in
            if {MemberDrop Ss A ?Sr} then {SubtractArity Ar Sr}
            else A|{SubtractArity Ar Ss}
            end
         end
      end
   in
      fun {SubtractList R Fs}
         {List.toRecord {Label R} {MakePairs {SubtractArity {Arity R} Fs} R}}
      end
   end

   %%
   %% Higher-order Stuff without Indices
   %%
   proc {Map As X P Y}
      case As of nil then skip
      [] A|Ar then {P X.A Y.A} {Map Ar X P Y}
      end
   end

   proc {MapT I W X P Y}
      if I=<W then {P X.I Y.I} {MapT I+1 W X P Y} end
   end

   fun {FoldL As X P Z}
      case As of nil then Z
      [] A|Ar then {FoldL Ar X P {P Z X.A}}
      end
   end

   fun {FoldLT I W X P Z}
      if I<W then {FoldLT I+1 W X P {P Z X.I}}
      else {P Z X.I}
      end
   end

   fun {FoldR As X P Z}
      case As of nil then Z
      [] A|Ar then {P X.A {FoldR Ar X P Z}}
      end
   end

   fun {FoldRT I W X P Z}
      if I<W then {P X.I {FoldRT I+1 W X P Z}}
      else {P X.I Z}
      end
   end

   proc {ForAll As X P}
      case As of nil then skip
      [] A|Ar then {P X.A} {ForAll Ar X P}
      end
   end

   proc {ForAllT I W X P}
      if I=<W then {P X.I} {ForAllT I+1 W X P} end
   end

   fun {All As X P}
      case As of nil then true
      [] A|Ar then {P X.A} andthen {All Ar X P}
      end
   end

   fun {AllT I W X P}
      if I=<W then {P X.I} andthen {AllT I+1 W X P}
      else true
      end
   end

   fun {Some As X P}
      case As of nil then false
      [] A|Ar then {P X.A} orelse {Some Ar X P}
      end
   end

   fun {SomeT I W X P}
      I=<W andthen ({P X.I} orelse {SomeT I+1 W X P})
   end

   fun {Filter As X P}
      case As of nil then nil
      [] A|Ar then XA=X.A in
         if {P XA} then A#XA|{Filter Ar X P}
         else {Filter Ar X P}
         end
      end
   end

   proc {Part As X P ?Bs ?Cs}
      case As of nil then Bs=nil Cs=nil
      [] A|Ar then XA=X.A in
         if {P XA} then Bs=A#XA|{Part Ar X P $ Cs}
         else Cs=A#XA|{Part Ar X P Bs $}
         end
      end
   end

   fun {Take As X P}
      case As of nil then nil
      [] A|Ar then XA=X.A in
         if {P XA} then A#XA|{Take Ar X P} else nil end
      end
   end

   fun {Drop As X P}
      case As of nil then nil
      [] A|Ar then XA=X.A in
         if {P XA} then nil else A#XA|{Drop Ar X P} end
      end
   end

   proc {TakeDrop As X P ?Bs ?Cs}
      case As of nil then Bs=nil Cs=nil
      [] A|Ar then XA=X.A in
         if {P XA} then Bs=A#XA|{TakeDrop Ar X P $ Cs}
         else Bs=nil Cs={MakePairs As X}
         end
      end
   end

   %%
   %% Higher-order Stuff with Indices
   %%
   proc {MapInd As X P Y}
      case As of nil then skip
      [] A|Ar then {P A X.A Y.A} {MapInd Ar X P Y}
      end
   end

   proc {MapIndT I W X P Y}
      if I=<W then {P I X.I Y.I} {MapIndT I+1 W X P Y} end
   end

   fun {FoldLInd As X P Z}
      case As of nil then Z
      [] A|Ar then {FoldLInd Ar X P {P A Z X.A}}
      end
   end

   fun {FoldLIndT I W X P Z}
      if I=<W then {FoldLIndT I+1 W X P {P I Z X.I}}
      else Z
      end
   end

   fun {FoldRInd As X P Z}
      case As of nil then Z
      [] A|Ar then {P A X.A {FoldRInd Ar X P Z}}
      end
   end

   fun {FoldRIndT I W X P Z}
      if I=<W then {P I X.I {FoldRIndT I+1 W X P Z}}
      else Z
      end
   end

   proc {ForAllInd As X P}
      case As of nil then skip
      [] A|Ar then {P A X.A} {ForAllInd Ar X P}
      end
   end

   proc {ForAllIndT I W X P}
      if I=<W then {P I X.I} {ForAllIndT I+1 W X P} end
   end

   fun {AllInd As X P}
      case As of nil then true
      [] A|Ar then {P A X.A} andthen {AllInd Ar X P}
      end
   end

   fun {AllIndT I W X P}
      if I=<W then {P I X.I} andthen {AllIndT I+1 W X P}
      else true
      end
   end

   fun {SomeInd As X P}
      case As of nil then false
      [] A|Ar then {P A X.A} orelse {SomeInd Ar X P}
      end
   end

   fun {SomeIndT I W X P}
      I=<W andthen ({P I X.I} orelse {SomeIndT I+1 W X P})
   end

   fun {FilterInd As X P}
      case As of nil then nil
      [] A|Ar then XA=X.A in
         if {P A XA} then A#XA|{FilterInd Ar X P}
         else {FilterInd Ar X P}
         end
      end
   end

   proc {PartInd As X P ?Bs ?Cs}
      case As of nil then Bs=nil Cs=nil
      [] A|Ar then XA=X.A in
         if {P A XA} then Bs=A#XA|{PartInd Ar X P $ Cs}
         else Cs=A#XA|{PartInd Ar X P Bs $}
         end
      end
   end

   fun {TakeInd As X P}
      case As of nil then nil
      [] A|Ar then XA=X.A in
         if {P A XA} then A#XA|{TakeInd Ar X P} else nil end
      end
   end

   fun {DropInd As X P}
      case As of nil then nil
      [] A|Ar then XA=X.A in
         if {P A XA} then nil else A#XA|{DropInd Ar X P} end
      end
   end

   proc {TakeDropInd As X P ?Bs ?Cs}
      case As of nil then Bs=nil Cs=nil
      [] A|Ar then XA=X.A in
         if {P A XA} then Bs=A#XA|{TakeDropInd Ar X P $ Cs}
         else Bs=nil Cs={MakePairs As X}
         end
      end
   end

   fun {Zip As R1 R2 P}
      case As of nil then nil
      [] A|Ar then
         if {HasFeature R1 A} then A#{P R1.A R2.A}|{Zip Ar R1 R2 P}
         else {Zip Ar R1 R2 P}
         end
      end
   end

   proc {ZipT I W T1 T2 P T3}
      if I=<W then T3.I={P T1.I T2.I} {ZipT I+1 W T1 T2 P T3} end
   end

   fun {ToList As R}
      case As of nil then nil
      [] A|Ar then R.A|{ToList Ar R}
      end
   end

   fun {ToListT I W T}
      if I>W then nil else T.I|{ToListT I+1 W T} end
   end

   fun {ToListInd As R}
      case As of nil then nil
      [] A|Ar then A#R.A|{ToListInd Ar R}
      end
   end

   fun {ToListIndT I W T}
      if I>W then nil else I#T.I|{ToListIndT I+1 W T} end
   end

   CloneRecord = Boot_Record.clone

in

   Record = record(is:           IsRecord
                   make:         MakeRecord
                   clone:        CloneRecord

                   label:        Label
                   width:        Width

                   arity:        Arity
                   adjoin:       Adjoin
                   adjoinAt:     AdjoinAt
                   adjoinList:   AdjoinList

                   subtract:     Subtract
                   subtractList: SubtractList

                   toList:
                      fun {$ R}
                         if {IsTuple R} then {ToListT 1 {Width R} R}
                         else {ToList {Arity R} R}
                         end
                      end
                   toListInd:
                      fun {$ R}
                         if {IsTuple R} then {ToListIndT 1 {Width R} R}
                         else {ToListInd {Arity R} R}
                         end
                      end

                   map:
                      proc {$ R1 P R2}
                         R2={CloneRecord R1}
                         if {IsTuple R1} then
                            {MapT 1 {Width R1} R1 P R2}
                         else
                            {Map {Arity R1} R1 P R2}
                         end
                      end
                   foldL:
                      fun {$ R P Z}
                         if {IsTuple R} then
                            if {IsLiteral R} then Z
                            else {FoldLT 1 {Width R} R P Z}
                            end
                         else {FoldL {Arity R} R P Z}
                         end
                      end
                   foldR:
                      fun {$ R P Z}
                         if {IsTuple R} then
                            if {IsLiteral R} then Z
                            else {FoldRT 1 {Width R} R P Z}
                            end
                         else {FoldR {Arity R} R P Z}
                         end
                      end
                   forAll:
                      proc {$ R P}
                        if {IsTuple R} then {ForAllT 1 {Width R} R P}
                        else {ForAll {Arity R} R P}
                        end
                      end
                   all:
                      fun {$ R P}
                        if {IsTuple R} then {AllT 1 {Width R} R P}
                        else {All {Arity R} R P}
                        end
                      end
                   some:
                      fun {$ R P}
                         if {IsTuple R} then {SomeT 1 {Width R} R P}
                         else {Some {Arity R} R P}
                         end
                      end
                   filter:
                      fun {$ R P}
                         {List.toRecord {Label R} {Filter {Arity R} R P}}
                      end
                   partition:
                      proc {$ R1 P ?R2 ?R3}
                         AXs BXs L={Label R1}
                      in
                         {Part {Arity R1} R1 P ?AXs ?BXs}
                         R2={List.toRecord L AXs}
                         R3={List.toRecord L BXs}
                      end
                   takeWhile:
                      fun {$ R P}
                         {List.toRecord {Label R} {Take {Arity R} R P}}
                      end
                   dropWhile:
                      fun {$ R P}
                         {List.toRecord {Label R} {Drop {Arity R} R P}}
                      end
                   takeDropWhile:
                      proc {$ R1 P ?R2 ?R3}
                         AXs BXs L={Label R1}
                      in
                         {TakeDrop {Arity R1} R1 P ?AXs ?BXs}
                         R2={List.toRecord L AXs}
                         R3={List.toRecord L BXs}
                      end

                   mapInd:
                      proc {$ R1 P ?R2}
                         R2={CloneRecord R1}
                         if {IsTuple R1} then
                            {MapIndT 1 {Width R1} R1 P R2}
                         else
                            {MapInd {Arity R1} R1 P R2}
                         end
                      end
                   foldLInd:
                      fun {$ R P Z}
                         if {IsTuple R} then
                            if {IsLiteral R} then Z
                            else {FoldLIndT 1 {Width R} R P Z}
                            end
                         else {FoldLInd {Arity R} R P Z}
                         end
                      end
                   foldRInd:
                      fun {$ R P Z}
                         if {IsTuple R} then
                            if {IsLiteral R} then Z
                            else {FoldRIndT 1 {Width R} R P Z}
                            end
                         else {FoldRInd {Arity R} R P Z}
                         end
                      end
                   forAllInd:
                      proc {$ R P}
                         if {IsTuple R} then {ForAllIndT 1 {Width R} R P}
                         else {ForAllInd {Arity R} R P}
                         end
                      end
                   allInd:
                      fun {$ R P}
                         if {IsTuple R} then {AllIndT 1 {Width R} R P}
                         else {AllInd {Arity R} R P}
                         end
                      end
                   someInd:
                      fun {$ R P}
                         if {IsTuple R} then {SomeIndT 1 {Width R} R P}
                         else {SomeInd {Arity R} R P}
                         end
                      end
                   filterInd:
                      fun {$ R P}
                         {List.toRecord {Label R} {FilterInd {Arity R} R P}}
                      end
                   partitionInd:
                      proc {$ R1 P ?R2 ?R3}
                         AXs BXs L={Label R1}
                      in
                         {PartInd {Arity R1} R1 P ?AXs ?BXs}
                         R2={List.toRecord L AXs}
                         R3={List.toRecord L BXs}
                      end
                   takeWhileInd:
                      fun {$ R P}
                         {List.toRecord {Label R} {TakeInd {Arity R} R P}}
                      end
                   dropWhileInd:
                      fun {$ R P}
                         {List.toRecord {Label R} {DropInd {Arity R} R P}}
                      end
                   takeDropWhileInd:
                      proc {$ R1 P ?R2 ?R3}
                         AXs BXs L={Label R1}
                      in
                         {TakeDropInd {Arity R1} R1 P ?AXs ?BXs}
                         R2={List.toRecord L AXs}
                         R3={List.toRecord L BXs}
                      end

                   zip:
                      proc {$ R1 R2 P ?R3}
                         if {IsTuple R1} andthen {IsTuple R2} then
                            W={Min {Width R1} {Width R2}}
                         in
                            {MakeTuple {Label R1} W ?R3}
                            {ZipT 1 W R1 R2 P R3}
                         else
                            {List.toRecord {Label R1}
                             {Zip {Arity R1} R1 R2 P} ?R3}
                         end
                      end
                   toDictionary: Boot_Record.toDictionary

                   waitOr: Boot_Record.waitOr
                  )

end
