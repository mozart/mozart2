%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
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
%% Module
%%

fun {IsString Is}
   case Is
   of I|Ir then
      {IsChar I} andthen {IsString Ir}
   [] nil then
      true
   else
      false
   end
end

fun {StringToAtom Is}
   if {IsString Is} then
      {VirtualString.toAtom Is}
   else
      raise typeError('String' Is) end
   end
end

local
   HexBase = base(&0:0 &1:1 &2:2 &3:3 &4:4 &5:5 &6:6 &7:7 &8:8 &9:9
                  &A:10 &B:11 &C:12 &D:13 &E:14 &F:15
                  &a:10 &b:11 &c:12 &d:13 &e:14 &f:15)

   DecBase = base(&0:0 &1:1 &2:2 &3:3 &4:4 &5:5 &6:6 &7:7 &8:8 &9:9)
   OctBase = base(&0:0 &1:1 &2:2 &3:3 &4:4 &5:5 &6:6 &7:7)
   BinBase = base(&0:0 &1:1)

   fun {RaiseStringNoInt Is}
      {Exception.raiseError kernel(stringNoInt Is)}
      unit
   end

   fun {StringToIntBase Base BaseRec Is OriginalIs Acc IsFirst}
      case Is
      of nil then
         if IsFirst then
            {RaiseStringNoInt OriginalIs}
         else
            Acc
         end
      [] I|Ir then
         Value = {CondSelect BaseRec I false}
      in
         if Value == false then
            {RaiseStringNoInt OriginalIs}
         else
            {StringToIntBase Base BaseRec Ir OriginalIs Acc*Base+Value false}
         end
      else
         {Exception.raiseError kernel(type 'String.toInt' [OriginalIs]
                                      'ProperString' 1)}
         unit
      end
   end
in
   fun {StringToInt Is}
      case Is
      of &~|&~|_ then
         {RaiseStringNoInt Is}
      [] &~|Ir then
         ~{StringToInt Ir}
      [] &0|nil then
         0
      [] &0|&X|Ir then
         {StringToIntBase 16 HexBase Ir Is 0 true}
      [] &0|&x|Ir then
         {StringToIntBase 16 HexBase Ir Is 0 true}
      [] &0|&B|Ir then
         {StringToIntBase 2 BinBase Ir Is 0 true}
      [] &0|&b|Ir then
         {StringToIntBase 2 BinBase Ir Is 0 true}
      [] &0|Ir then
         {StringToIntBase 8 OctBase Ir Is 0 true}
      else
         {StringToIntBase 10 DecBase Is Is 0 true}
      end
   end
end

fun {StringToFloat Is}
   {Boot_VirtualString.toFloat Is}
end

local
   fun {StringToUnicodeString Is}
      if {IsString Is} then
         {VirtualString.toUnicodeString Is}
      else
         raise typeError('String' Is) end
      end
   end

   proc {Token Is J ?T ?R}
      case Is of nil then T=nil R=nil
      [] I|Ir then
         if I==J then T=nil R=Ir
         else Tr in T=I|Tr {Token Ir J Tr R}
         end
      end
   end

   fun {Tokens Is C Js Jr}
      case Is of nil then Jr=nil
         case Js of nil then nil else [Js] end
      [] I|Ir then
         if I==C then NewJs in
            Jr=nil Js|{Tokens Ir C NewJs NewJs}
         else NewJr in
            Jr=I|NewJr {Tokens Ir C Js NewJr}
         end
      end
   end

   /* It used to be that atoms could not contain '\0' (the null character).
    * So this function tested against any 0 in the string.
    * As of Mozart 2.0, any string can be converted to an atom, so this
    * function always returns true.
    */
   fun {StringIsAtom Is}
      true
   end

in

   String = string(is:      IsString
                   isAtom:  StringIsAtom
                   toAtom:  StringToAtom
                   isInt:   fun {$ S}
                               try {StringToInt S _} true
                               catch _ then false
                               end
                            end
                   toInt:   StringToInt
                   isFloat: fun {$ S}
                               try {StringToFloat S _} true
                               catch _ then false
                               end
                            end
                   toFloat: StringToFloat
                   token:   Token
                   tokens:  fun {$ S C}
                               Ss in {Tokens S C Ss Ss}
                            end)
end
