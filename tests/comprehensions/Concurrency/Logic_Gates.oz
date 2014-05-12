%%
%% Author:
%%     Francois Fonteyn, 2014
%%

declare
%% opeartors
fun {And X Y} X*Y end
fun {Or X Y} X+Y-X*Y end
fun {Xor X Y} (X+Y) mod 2 end
%% returns a gate function with the given operator
fun {GateMaker F}
   fun {$ Xs Ys}
      thread [{F X Y} suchthat X in Xs Y in Ys] end
   end
end
%% all gates
AndG = {GateMaker And}
OrG  = {GateMaker Or}
XorG = {GateMaker Xor}
%% all operators in one gate
fun {AllGates Xs Ys}
   thread [and:{And X Y} 'or':{Or X Y} xor:{Xor X Y} suchthat X in Xs Y in Ys] end
end
%% example
Input1
Input2
{Browse 'Input 1'#Input1}
{Browse 'Input 2'#Input2}
{Browse 'And    '#{AndG  Input1 Input2}}
{Browse 'Or     '#{OrG   Input1 Input2}}
{Browse 'Xor    '#{XorG  Input1 Input2}}
{Browse 'All in one'}
{Browse {AllGates Input1 Input2}}
%% feed inputs
thread Input1#Input2 = [{OS.rand} mod 2 {OS.rand} mod 2 suchthat lazy A in 0 ; A<20 ;A+1 do {Delay 1000}] end
