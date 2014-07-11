%%%
%%% Authors:
%%%   Kenny Chan <kennytm@gmail.com>
%%%
%%% Copyright:
%%%   Kenny Chan 2014
%%%
%%% Last change:
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

functor
import
    Serializer at 'x-oz://boot/Serializer'

export
    Return

define
    Return = serializer([
        extractByLabels1(
            proc {$}
                Q = {NewChunk a(1)}
                R = {NewChunk b(Q)}
                T = {NewChunk c(2)}
                S = [R Q fun {$} T end]
                L = {Serializer.extractByLabels S r(chunk:_)}
            in
                true = (Q \= R)
                true = (R \= T)
                true = (Q \= T)
                3 = {Length L}
                32 = for sum:S Obj#Rec in L do
                    chunk(_) = Rec
                    if Obj == Q then
                        {S 2}
                    elseif Obj == R then
                        {S 7}
                    elseif Obj == T then
                        {S 23}
                    else
                        {S 71}
                    end
                end
            end
        )

        extractByLabels2(
            proc {$}
                proc {TestFunc X _}
                    case X
                    of Y#r(Z) then {TestFunc Y Z}
                    [] Y|_ then {TestFunc Y _}
                    else skip
                    end
                end

                L = {Serializer.extractByLabels TestFunc r(patmatcapture:_)}
            in
                for _#Rec in L do
                    patmatcapture(A) = Rec
                in
                    true = {IsNumber A}
                end
            end
        )
    ])

end
