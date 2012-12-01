%%% Copyright © 2012, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% *  Redistributions of source code must retain the above copyright notice,
%%%    this list of conditions and the following disclaimer.
%%% *  Redistributions in binary form must reproduce the above copyright notice,
%%%    this list of conditions and the following disclaimer in the documentation
%%%    and/or other materials provided with the distribution.
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

fun {IsChar X}
   {IsInt X} andthen
   ((X >= 0 andthen X < 0xd800) orelse (X >= 0xe000 andthen X < 0x110000))
end

Char = char(is:       IsChar
            isAlpha:  fun {$ X} {Char.isUpper X} orelse {Char.isLower X} end
            isUpper:  fun {$ X} X >= &A andthen X =< &Z end
            isLower:  fun {$ X} X >= &a andthen X =< &z end
            isDigit:  fun {$ X} X >= &0 andthen X =< &9 end
            %isXDigit: Boot_Char.isXDigit
            isAlNum:  fun {$ X} {Char.isAlpha X} orelse {Char.isDigit X} end
            /*isSpace:  Boot_Char.isSpace
            isGraph:  Boot_Char.isGraph
            isPrint:  Boot_Char.isPrint
            isPunct:  Boot_Char.isPunct
            isCntrl:  Boot_Char.isCntrl*/
            toUpper:  fun {$ X} if {Char.isLower X} then X-32 else X end end
            toLower:  fun {$ X} if {Char.isUpper X} then X+32 else X end end
            toAtom:   fun {$ C}
                         if C == 0 then '' else {String.toAtom C|nil} end
                      end
            /*type:     Boot_Char.type*/)
