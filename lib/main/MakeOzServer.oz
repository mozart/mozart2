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

local

   \insert 'DP/MakeAllLoader.oz'

   \insert 'DP/RemoteServer.oz'

in

   {Application.syslet
    'ozserver'
    c

    fun {$ _}
       IMPORT = {AllLoader}
    in
       proc {$ Argv ?Status}
          try
             RunRet # CtrlRet = {IMPORT.'DP'.'Connection'.take Argv.ticket}
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
