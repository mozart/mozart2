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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

 functor $ prop once

 import
    Connection.{take}

    Syslet

    Module
 body
    Syslet.spec = single(ticket(type:atom))
    try
       RunRet # CtrlRet = {Connection.take Syslet.args.ticket}
       RunStr CtrlStr

       ModMan = {New Module.manager init}

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
                         elsecase {Functor.is What} then
                            {ModMan apply(url:'' What $)}
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
