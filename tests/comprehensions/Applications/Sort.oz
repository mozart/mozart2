%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% Sorting a list with list comprehension
declare
fun {Sort L}
   case L
   of nil then nil
   [] H|T then Split in
      Split = [smaller:X if X<H greaterOrEqual:X if X>=H for X in T]
      {Append {Sort Split.smaller} H|{Sort Split.greaterOrEqual}}
   end
end
{Browse {Sort [3 9 0 1 5 1 4 3 10 ~1]}}