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
   thread Xs = [A for lazy A in 10..25 body {Delay 1000}] end
   thread Ys = [2*A for A in Xs] end
end
