%%% Copyright © 2014, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice,
%%% this list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

functor

import
    Reflection at 'x-oz://boot/Reflection'
    BootName at 'x-oz://boot/Name'

export
    Return

define
    Return = reflection([
        become(
            keys: [reflection become]
            1: proc {$}
                P = {NewCell 1}
                R = {NewArray 0 1 _}
                Q = P
            in
                true = (P == Q)
                true = (P \= R)
                true = (Q \= R)
                true = {IsCell P}
                true = {IsCell Q}
                true = {IsArray R}
                {Reflection.become P R}
                true = (P == Q)
                true = (P == R)
                true = (Q == R)
                false = {IsCell P}
                false = {IsCell Q}
                true = {IsArray P}
                true = {IsArray Q}
                true = {IsArray R}
            end
        )

        getStructuralBehavior(
            keys: [reflection getStructuralBehavior]
            1: proc {$}
                P
                class C from BaseObject end
            in
                for A#B in [
                    value#1
                    value#x
                    value#unit
                    value#true
                    value#false
                    value#1.5
                    value#~0.3
                    value#nil
                    value#{VirtualString.toCompactString "12345"}
                    value#{VirtualByteString.toCompactByteString [0 1 2 3 4]}
                    value#{BootName.newUnique test}
                    structural#"string"
                    structural#[1 2 3 4]
                    structural#(1#2)
                    structural#(r(a:1 b:2))
                    token#{NewCell 1}
                    token#{NewArray 0 1 _}
                    token#C
                    token#{New C noop}
                    token#{NewName}
                    token#{NewLock}
                    token#{NewPort _}
                    token#proc {$} skip end
                    token#{NewWeakDictionary _}
                    token#{NewDictionary}
                    token#{NewChunk x}
                    variable#_
                    variable#P
                    variable#(!!P)
                ] do
                    A = {Reflection.getStructuralBehavior B}
                end
            end
        )

        reflectiveVariable(
            keys: [reflection reflectiveVariable]
            1: proc {$}
                S = _
                V = {Reflection.newReflectiveVariable S}
                Q = V
                A B C
            in
                thread
                    true = (Q == 5)
                end
                thread
                    {Delay 100}
                    V = 5
                    true = (V == 5)
                end

                variable = {Reflection.getStructuralBehavior V}

                A|B = S
                markNeeded = A.1 % <- probably we don't need to do anything with `markNeeded`?
                A.2 = unit
                C|_ = B
                bind(5) = C.1
                C.2 = unit

                variable = {Reflection.getStructuralBehavior V}
                {Reflection.bindReflectiveVariable V 5}
                value = {Reflection.getStructuralBehavior V}
            end
        )

        reflectiveEntity(
            keys: [reflection reflectiveEntity]
            1: proc {$}
                S
                E = {Reflection.newReflectiveEntity S}
                G
            in
                thread
                    123 = @E
                    456 = {Get E 678}
                    G = 789
                end

                token = {Reflection.getStructuralBehavior E}

                (isCell(true)#unit)|(access(123)#unit)|(arrayGet(678 456)#unit)|_ = S

                {Wait G}
                789 = G
            end
        )

        throwExceptionEntity(
            keys: [reflection throwExceptionEntity]
            1: proc {$}
                SE
                E = {Reflection.newReflectiveEntity SE}
                EException
            in
                thread
                    try
                        {Put E 1 2}
                        EException = unit
                    catch X then
                        EException = X
                    end
                end

                (_#{Value.failed someException})|_ = SE
                true = (EException == someException)
            end
        )

        throwExceptionVariable(
            keys: [reflection throwExceptionVariable]
            1: proc {$}
                SV
                V = {Reflection.newReflectiveVariable SV}
                VException
                ExceptionToRaise = {Exception.failure something}
            in
                thread
                    try
                        V = 4
                        VException = unit
                    catch X then
                        VException = X
                    end
                end

                (_#{Value.failed ExceptionToRaise})|_ = SV
                true = (VException == ExceptionToRaise)
            end
        )
    ])
end
