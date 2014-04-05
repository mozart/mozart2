%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% List comprehension flatten
declare
L = [[[1] 2] 3 4 [[5 [6 7]] 8] 9 [[[10]]]]
fun {FlattenLC L}
   [A for _:A in L if A \= nil]
end
{Browse 'Normal flatten:'}
{Browse {Flatten L}}
{Browse 'List comprehension flatten:'}
{Browse {FlattenLC L}}