%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% SimpleCreateObjects
%%%

%% IntCreateObject

class IntCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = int
   end
end

%% FloatCreateObject

class FloatCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = float
   end
end

%% AtomCreateObject

class AtomCreateObject
   from
      CreateObject

   attr
      buffer %% Rescue Value

   meth create(Value Parent Index Visual Depth)
      MakeStr = AtomCreateObject, fixTKBug(Value $)
      AtomStr = {Atom.toString Value}
   in
      @type = atom
      if AtomCreateObject, skipQuoting(AtomStr $)
      then CreateObject, create(MakeStr Parent Index Visual Depth)
      else CreateObject, create('\''#MakeStr#'\'' Parent Index Visual Depth)
      end
   end

   meth fixTKBug(Value $)
      case Value
      of nil then {Atom.toString Value}
      [] '#' then {Atom.toString Value}
      [] ''  then "\'\'"
      else Value
      end
   end

   meth skipQuoting(As $)
      case As
      of nil  then true
      [] A|Ar then
         ({Char.type A} == lower) andthen AtomCreateObject, isAlphaNum(Ar $)
      end
   end

   meth isAlphaNum(As $)
      case As
      of nil  then true
      [] A|Ar then
         Type = {Char.type A}
      in
         if ((Type == upper) orelse
               (Type == lower) orelse
               (Type == digit) orelse
               (A == 95))
         then AtomCreateObject, isAlphaNum(Ar $)
         else false
         end
      end
   end

   meth setRescueValue(Value)
      @buffer = Value
   end

   meth getRescueValue($)
      @buffer
   end
end

%% BoolCreateObject

class BoolCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = bool
   end
end

%% NameCreateObject

class NameCreateObject
   from
      CreateObject

   attr
      buffer %% Rescue Value

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = name
   end

   meth setRescueValue(Value)
      @buffer = Value
   end

   meth getRescueValue($)
      @buffer
   end
end

%% ProcedureCreateObject

class ProcedureCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = procedure
   end
end
