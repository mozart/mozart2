%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
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

functor

import
   Remote(manager)
   OS(uName)
   Property(get)
export
   Return

define
   Return=
   dp([
       mini(
          proc {$}
             {ForAll [true false]
              proc {$ Detach}
                 {ForAll
                  if {Property.get 'distribution.virtualsites'}
                  then [sh rsh virtual automatic]
                  else [sh rsh automatic]
                  end
                  proc {$ Fork}
                     {ForAll [localhost {OS.uName}.nodename]
                      proc {$ Host}
% workaround: Redhat does not allow rsh localhost by default
                         if Host == localhost andthen  Fork == rsh
                         then skip
                         else
                            S={New Remote.manager
                               init(host:Host fork:Fork detach:Detach)}
                         in
                            {S ping}
                            {S apply(url:'' functor
                                            import
                                               Property(put)
                                            export
                                               Hallo
                                            define
                                            {Property.put 'close.time' 1000}
                                               Hallo=hallo
                                            end $)}.hallo=hallo
                            {S ping}
                            {S close}
                         end
                      end}
                  end}
              end}
          end
          keys:[remote])
      ])
end
