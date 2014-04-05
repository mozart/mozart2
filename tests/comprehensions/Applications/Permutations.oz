%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% Generates all permutations with list comprehension
declare
Coin = [head tail]
{Browse [[X Y] for X in Coin for Y in Coin]}