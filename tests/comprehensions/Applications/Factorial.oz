%%
%% Author:
%%     Francois Fonteyn, 2014
%%

declare
fun  {FactLC N}
   R L
in
   L = [c:collect:C for A in N ; A >= 0 ; A-1 do
                       if A == N then {C 1} end
                       if A == 0 then R = {Nth L.c N-A+1}
                       else {C {Nth L.c N-A+1}*A}
                       end]
   R
end
for I in 0..10 do
   {Browse {VirtualString.toAtom "Fact("#I#") = "#{FactLC I}}}
end