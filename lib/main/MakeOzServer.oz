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

    Module.{link}
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
               try
                  try
                     X = case {Procedure.is What} then {What}
                         elsecase {Chunk.is What} andthen
                            {HasFeature What apply} then
                            {Module.link '' What}
                         end
                  in
                     {Port.send RunRet okay(X)}
                  catch E then
                     {Port.send RunRet exception({Record.subtract E debug})}
                  end
               catch _ then
                  {Port.send RunRet failed}
               end
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
