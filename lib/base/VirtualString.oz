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
%% Module
%%

local
    fun {JoinBy L Sep}
       case L
       of H|nil then H
       [] H|T then H#Sep#{JoinBy T Sep}
       [] nil then nil
       end
    end

    fun {ChangeSign V Replacement}
        if {IsInt V} andthen V < 0 then
            Replacement#~V                  % Note: require bigint support here.
        elseif {IsFloat V} then S Parts in
            S = {VirtualString.toString V}
            Parts = {UnicodeString.tokens S &-}
            {JoinBy Parts Replacement}
        elseif {IsTuple V} andthen {Label V} == '#' then
            {Record.map  V  fun {$ A} {ChangeSign A Replacement} end}
        else
            V
        end
    end
in

    IsVirtualString = Boot_VirtualString.is
    VirtualString = virtualString(
        is: IsVirtualString
        toUnicodeString: Boot_VirtualString.toString
        toString: fun {$ V} {UnicodeString.toString {VirtualString.toString V}} end
        toAtom: fun {$ V} {String.toAtom {VirtualString.toString V}} end
        toByteString: fun {$ V} {ByteString.make V} end
        length: Boot_VirtualString.length
        changeSign: ChangeSign
    )
end

