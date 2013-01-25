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

% TODO This should be made Unicode-aware

Char = char(is:       IsChar
            isAlpha:  fun {$ X}
                         {Char.isUpper X} orelse {Char.isLower X}
                      end
            isUpper:  fun {$ X}
                         (X >= &A andthen X =< &Z) orelse
                         (X >= 192 andthen X =< 222 andthen X \= 215)
                      end
            isLower:  fun {$ X}
                         (X >= &a andthen X =< &z) orelse
                         (X >= 223 andthen X =< 255 andthen X \= 247)
                      end
            isDigit:  fun {$ X}
                         X >= &0 andthen X =< &9
                      end
            isXDigit: fun {$ X}
                         (X >= &0 andthen X =< &9) orelse
                         (X >= &A andthen X =< &F) orelse
                         (X >= &a andthen X =< &f)
                      end
            isAlNum:  fun {$ X}
                         {Char.isAlpha X} orelse {Char.isDigit X}
                      end
            isSpace:  fun {$ X}
                         X == 32 orelse
                         (X >= 9 andthen X =< 13) orelse
                         X == 160
                      end
            isGraph:  fun {$ X}
                         {Char.isAlNum X} orelse {Char.isPunct}
                      end
            isPrint:  fun {$ X}
                         {Char.isGraph X} orelse X == 32 orelse X == 160
                      end
            isPunct:  fun {$ X}
                         (X >= 33 andthen X =< 47) orelse
                         (X >= 58 andthen X =< 64) orelse
                         (X >= 91 andthen X =< 96) orelse
                         (X >= 123 andthen X =< 126) orelse
                         (X >= 161 andthen X =< 191) orelse
                         (X == 215) orelse
                         (X == 247)
                      end
            isCntrl:  fun {$ X} X < 32 orelse X == 127 end
            toUpper:  fun {$ X} if {Char.isLower X} then X-32 else X end end
            toLower:  fun {$ X} if {Char.isUpper X} then X+32 else X end end
            toAtom:   fun {$ C}
                         if C == 0 then '' else {String.toAtom C|nil} end
                      end
            type:     fun {$ X}
                         if {Char.isUpper X} then upper
                         elseif {Char.isLower X} then lower
                         elseif {Char.isDigit X} then digit
                         elseif {Char.isSpace X} then space
                         elseif {Char.isPunct X} then punct
                         else other
                         end
                      end)
