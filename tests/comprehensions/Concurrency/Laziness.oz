%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% feed paragraph to see it execute
declare
Xs1 Xs2
in
{Browse 'Xs1 '#Xs1}
{Browse 'Xs2 '#Xs2}
thread Xs1#Xs2 = [1:A 2:A if A mod 2 == 0 for lazy A in 0 ; A+1] end

%% make elements in Xs1 needed
{List.drop Xs1 2 _}

