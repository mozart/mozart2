%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local

   local
      fun {Flatten I V Ss}
         if I>0 then VI=V.I in
            {Flatten I-1 V if {IsTuple VI} andthen {Label VI}=='#' then
                              {Flatten {Width VI} VI Ss}
                           else
                              {ToString VI}|Ss
                           end}
         else Ss
         end
      end
      fun {App Is Sr}
         case Is of nil then {AllToString Sr}
         [] I|Ir then I|{App Ir Sr}
         end
      end
      fun {AllToString Ss}
         case Ss of nil then nil
         [] S|Sr then {App S Sr}
         end
      end
      fun {SignOzToOS Is}
         case Is of nil then nil
         [] I|Ir then
            case I of &~ then &- else I end|{SignOzToOS Ir}
         end
      end
   in
      proc {ToString V ?Res}
         Res = case {Value.type V}
               of int then
                  if V<0 then &-|{Int.toString {Abs V}}
                  else {Int.toString V}
                  end
               [] float then
                  {SignOzToOS {Float.toString V}}
               [] atom then
                  case V
                  of '#' then nil
                  [] nil then nil
                  else {Atom.toString V}
                  end
               [] byteString then
                  {Boot_ByteString.toString V}
               [] tuple then
                  case {Label V}
                  of '#' then {AllToString {Flatten {Width V} V nil}}
                  [] '|' then V
                  else
                     {Exception.raiseError
                      kernel(type 'VirtualString.toString'
                             [V Res] virtualString 1 nil)} unit
                  end
               else
                  {Exception.raiseError
                   kernel(type 'VirtualString.toString'
                          [V Res] virtualString 1 nil)} unit
               end
      end
   end

   local
      proc {ChangeSignAll I V S NewV}
         if I>0 then
            NewV.I={ChangeSign V.I S}
            {ChangeSignAll I-1 V S NewV}
         end
      end

      fun {ChangeLast Is S Js Jr}
         case Is of nil then Jr=nil Js
         [] I|Ir then
            case I of &~ then Jr=nil Js#S#Ir
            else Jt in Jr=I|Jt {ChangeLast Ir S Js Jt}
            end
         end
      end

      fun {ChangeSignFloat Is S}
         case Is of &~|Ir then Js in S#{ChangeLast Ir S Js Js}
         else Js in {ChangeLast Is S Js Js}
         end
      end
   in
      fun {ChangeSign V S}
         case {Value.type V}
         of int then if V<0 then S#~V else V end
         [] float then {ChangeSignFloat {Float.toString V} S}
         [] atom then V
         [] byteString then V
         [] tuple then
            case {Label V}
            of '#' then W={Width V} NewV={MakeTuple '#' W} in
               {ChangeSignAll W V S NewV}
               NewV
            [] '|' then V
            end
         end
      end
   end

   BiLength = Boot_VirtualString.length

in

   VirtualString = virtualString(is:         IsVirtualString
                                 toString:   fun {$ V}
                                                case V of _|_ then V
                                                [] nil then nil
                                                else {ToString V}
                                                end
                                             end
                                 toAtom:     fun {$ V}
                                                case V of nil then ''
                                                [] '#' then ''
                                                elseif {IsAtom V} then V else
                                                   {StringToAtom {ToString V}}
                                                end
                                             end

                                 toByteString:
                                    fun {$ Vs}
                                       {Boot_VirtualString.toByteString
                                        Vs 0 Vs}
                                    end

                                 changeSign: ChangeSign
                                 length:     fun {$ V}
                                                {BiLength V 0}
                                             end)

end
