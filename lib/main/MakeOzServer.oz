%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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

{Application.syslet
 'ozserver'
 functor $ prop once

 import
    Connection.{take}

    Syslet.{args exit}

    LILO.{link}

 body
    try
       RunRet # CtrlRet = {Connection.take Syslet.args.ticket}
       RunStr CtrlStr
    in
       {Port.send RunRet  {Port.new RunStr}}
       {Port.send CtrlRet {Port.new CtrlStr}}

       %% The server for running procedures and functors
       thread
          {ForAll RunStr
           proc {$ What}
              {Port.send RunRet
               try
                  X = case {Procedure.is What} then {What}
                      elsecase {Chunk.is What} andthen
                         {HasFeature What apply} then
                         {LILO.link unit What '.'}
                      end
               in
                  okay(X)
               catch E then
                  exception(E)
               end}
              end}
       end

       %% The server for control messages
       thread
          {ForAll CtrlStr
           proc {$ C}
              {Port.send CtrlRet
               okay(case C
                    of ping  then unit
                    [] close then {Syslet.exit 0} unit
                    end)}
           end}
       end

    catch _ then
       {Syslet.exit 1}
    end
 end

 single(ticket(type:atom))}
