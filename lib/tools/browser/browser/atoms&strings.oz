%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  (Old) Functions to maintain lists (from old version of Atom.oz);
%%%
%%%
%%%

local FindChar1 in
   %%
   AtomConcat = Atom.concat
   VSLength = VirtualString.length
   %%
   %%  only for reflect.oz!!!
   fun{AtomConcatAll L}
      case L
      of H|R then {AtomConcat {AtomConcatAll H}{AtomConcatAll R}}
      [] nil then ''
      else L
      end
   end
   %%
   %% 'S' is a string;
   %% 'C' is an ascii-code;
   fun {FindChar S C}
      {FindChar1 S C 1}
   end
   fun {FindChar1 S C N}
      case S of H|R then if H = C then N
                         else {FindChar1 R C N+1}
                         fi
      else ~1
      end
   end
   %%
   %% 'S' is a string;
   %% 'P' is an integer;
   fun {Tail S P}
      case P=<1 then S
      else
         case S of H|R then {Tail R P-1} else nil end
      end
   end
   %%
   %%
   fun {Head S P}
      case P<1 then nil
      else
         case S of H|R then H|{Head R P-1} else nil end
      end
   end
   %%
   %%
   fun {GetStrs Str Delim ParRes}
      local Ind in
         Ind = {FindChar Str Delim}
         %%
         case Ind == ~1 then {Append ParRes [Str]}
         else
         local HeadOf TailOf in
            HeadOf = {Head Str Ind-1}
            TailOf = {Tail Str Ind+1}
            %%
            {GetStrs TailOf Delim {Append ParRes [HeadOf]}}
         end
         end
      end
   end
   %%
   %%
   %%  Yields 'False' if 'L1' and 'L2' are equal;
   fun {DiffStrs L1 L2}
      case L1
      of nil then
         case L2
         of nil then False
         else True
         end
      [] E1|R1 then
         case L2
         of nil then True
         [] E2|R2 then
            case E1 == E2 then {DiffStrs R1 R2}
            else True
            end
         end
      end
   end
   %%
end
