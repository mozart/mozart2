%%
%% Author:
%%     Francois Fonteyn, 2014
%%

local N Fs Vs in
   N = 10 % compute factorials from 0 to 10
   '#'(factOf:Fs value:Vs) = [value:A factOf:I for I in 0..N A in 1 ; A*(I+1)]
   for F in Fs V in Vs do
      {Browse {VirtualString.toAtom "Fact("#F#") = "#V}}
   end
end