%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% Generates all permutations with list comprehension
declare
Coin = [head tail]
{Browse [[X Y] suchthat X in Coin suchthat Y in Coin]}