%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   fun {MakeServer Import Status}
      CS CP={NewPort CS}
   in
      thread
         {ForAll CS
          proc {$ Task}
             case Task
             of idle(Ack)  then Ack=unit
             [] run(P Ack) then
                Ack = try
                         case {Procedure.arity P}
                         of 0 then {P} okay
                         [] 1 then {P Import} okay
                         end
                      catch E then exception(E)
                      end
             end
          end}
      end
      proc {$ Task}
         case Task
         of ping(Ack) then Ack=unit
         [] close     then Status=0
         [] idle(_)   then {Port.send CP Task}
         [] run(_ _)  then {Port.send CP Task}
         end
      end
   end

in

   {Application.exec
    'ozserver'
    c('AP':lazy 'SP':lazy 'OP':lazy
      'DP':lazy 'CP':lazy 'WP':lazy)

    fun {$ IMPORT}
       \insert 'DP.env'
       = IMPORT.'DP'
    in

       proc {$ Argv ?Status}
          S P={Port.new S}
       in
          try
             {Connection.take Argv.gate P}
             thread
                {ForAll S {MakeServer IMPORT Status}}
             end
          catch _ then Status=1
          end
          {Wait Status}
       end

    end
    single(ticket(type:atom))}
end
