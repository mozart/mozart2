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
export
   Return

define
   Return=
   dp([
       mini(
          proc {$}
             {ForAll [true false]
              proc {$ Detach}
                 {ForAll [automatic sh rsh]
                  proc {$ Fork}
% Redhat does not allow rsh localhost by default
%                    {ForAll [localhost {OS.uName}.nodename]
                     {ForAll [{OS.uName}.nodename]
                      proc {$ Host}
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
                      end}
                  end}
              end}
          end
          keys:[remote])
      ])
end
