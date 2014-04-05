%%
%% Author:
%%     Francois Fonteyn, 2014
%%

declare
In1 In2 Out1 Out2 Out3 MakeNeeded Producer
in
{Browse 'In1  '#In1}
{Browse 'In2  '#In2}
{Browse 'Out1 '#Out1}
{Browse 'Out2 '#Out2}
{Browse 'Out3 '#Out3}
thread In1 = [A for lazy A in 0..10 body {Delay 1000}] end
thread In2 = [A for lazy A in 0..5  body {Delay 1500}] end
thread Out1#Out2#Out3 = [A-B A*B A+B for A in In1:1 for lazy B in In2:3] end

%% we need the 3 first elements
{List.drop Out1 3 _}

%% finish streams
{List.drop Out3 67 _}
