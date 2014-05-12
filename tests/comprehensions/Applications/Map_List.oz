%%
%% Author:
%%     Francois Fonteyn, 2014
%%

%% Equivalent of Map
declare
L = [1 2 3]
% mapping function
fun {Fun X} 2*X end
% normal Map
{Browse {Map L Fun}}   % [2 4 6]
% comprehension Map
fun {MapLC L Fct}
   [{Fct X} suchthat X in L]
   % we could also do [2*X suchthat X in L]
end
{Browse {MapLC L Fun}} % [2 4 6]