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

   AllLoader = {Application.loader
                c('SP':            eager
                  'OP':            eager
                  'DP':            eager
                  'AP':            lazy
                  'CP':            lazy
                  'WP':            lazy
                  'Panel':         lazy
                  'Browser':       lazy
                  'Explorer':      lazy
                  'Compiler':      lazy
                  'CompilerPanel': lazy
                  'Emacs':         lazy
                  'Ozcar':         lazy
                  'Profiler':      lazy
                  'Gump':          lazy
                  'GumpScanner':   lazy
                  'GumpParser':    lazy
                  'Misc':          lazy)}


   proc {RemoteServer RunRet CtrlRet Import Close}
      RunStr CtrlStr
   in
      {Port.send RunRet  {Port.new RunStr}}
      {Port.send CtrlRet {Port.new CtrlStr}}

      %% The server for running procedures
      thread
         {ForAll RunStr
          proc {$ P}
             {Port.send RunRet
              try
                 X = case {Procedure.arity P}
                     of 1 then {P}
                     [] 2 then {P Import}
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
              case C
              of ping  then unit
              [] close then {Close} unit
              end}
          end}
      end

   end

in

   {Application.exec
    'ozserver'
    c

    fun {$ _}
       IMPORT = {AllLoader}
    in
       proc {$ Argv ?Status}
          try
             Show = {`Builtin` 'Show' 1}
             {Show waiting(Argv.ticket)}
             {Show waiting(IMPORT)}
             RunRet # CtrlRet = {IMPORT.'DP'.'Connection'.take Argv.ticket}
             {Show taken(RunRet CtrlRet)}
          in
             {RemoteServer RunRet CtrlRet IMPORT proc {$}
                                                    Status = 0
                                                 end}
          catch _ then Status = 1
          end
          {Wait Status}
       end

    end

    single(ticket(type:atom))
   }

end
