%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local

   local
      fun {AllToString I V S}
         case I>0 then {AllToString I-1 V {Append {ToString V.I} S}}
         else S
         end
      end
      fun {SignOzToOS Is}
         case Is of nil then nil
         [] I|Ir then
            case I of &~ then &- else I end|{SignOzToOS Ir}
         end
      end
   in
      fun {ToString V}
         case {Value.type V}
         of int then
            case V<0 then &-|{Int.toString {Abs V}}
            else {Int.toString V}
            end
         [] float then {SignOzToOS {Float.toString V}}
         [] atom then
            case V
            of '#' then nil
            [] nil then nil
            else {Atom.toString V}
            end
         [] tuple then
            case {Label V}
            of '#' then {AllToString {Width V} V ""}
            [] '|' then V
            end
         end
      end
   end

   local
      proc {ChangeSignAll I V S NewV}
         case I>0 then
            NewV.I={ChangeSign V.I S}
            {ChangeSignAll I-1 V S NewV}
         else skip
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
         of int then case V<0 then S#~V else V end
         [] float then {ChangeSignFloat {Float.toString V} S}
         [] atom then V
         [] bytestring then V
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
                                                case {IsAtom V} then V
                                                else
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
