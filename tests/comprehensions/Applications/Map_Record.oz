%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% Equivalent of Map for records
declare
L = rec(1 a:2 3)
% mapping function
fun {Fun X} 2*X end
% normal Map
{Browse {Record.map L Fun}} % rec(2 6 a:4)
% comprehension Map
fun {MapRC R Fct}
   [{Fct X} for F:X through R]
   % we could also do [2*X for X in L]
end
{Browse {MapRC L Fun}}      % rec(2 6 a:4)