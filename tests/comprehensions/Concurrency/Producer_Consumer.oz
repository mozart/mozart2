%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% feed paragraph to see it execute
local
   Xs Ys
in
   {Browse 'Output: Ys = 2*Xs'}
   {Browse 'Xs '#Xs}
   {Browse 'Ys '#Ys}
   thread Xs = [A suchthat lazy A in 10..25 do {Delay 1000}] end
   thread Ys = [2*A suchthat A in Xs if A mod 2 == 1] end
end
