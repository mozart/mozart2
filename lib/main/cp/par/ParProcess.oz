%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://mozart.ps.uni-sb.de/
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

export
   worker: Process

import
   Remote(manager)

define

   class Process from Remote.manager
      feat name id
      meth init(name:Name id:Id)
         thread
            Remote.manager,init(host:Name)
            self.name = Name
            self.id   = Id
         end
      end
      meth plain(logger:L manager:M script:SF $)
         Id=self.id
      in
         {Wait self.name}
         (Remote.manager,apply(functor
                               import
                                  Module
                                  Worker(plain) at 'x-oz://system/ParWorker.ozf'
                               export
                                  worker: W
                               define
                                  %% Get the script module
                                  [S] = if {Functor.is SF} then
                                           {Module.apply [SF]}
                                        else
                                           {Module.link [SF]}
                                        end
                                  %% Start worker
                                  W = {Worker.plain
                                       init(logger:  L
                                            manager: M
                                            id:      Id
                                            script:  S.script)}
                               end $)).worker
      end
      meth best(logger:L manager:M script:SF $)
         Id=self.id
      in
         {Wait self.name}
         (Remote.manager,apply(functor
                               import
                                  Module
                                  Worker(best) at 'x-oz://system/ParWorker.ozf'
                               export
                                  worker: W
                               define
                                  %% Get the script module
                                  [S] = if {Functor.is SF} then
                                           {Module.apply [SF]}
                                        else
                                           {Module.link [SF]}
                                        end
                                  %% Start worker
                                  W = {Worker.best
                                       init(logger:  L
                                            manager: M
                                            id:      Id
                                            order:   S.order
                                            script:  S.script)}
                               end $)).worker
      end
   end

end
