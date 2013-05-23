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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

import
   Remote(manager)
   Property(get)
   TestMisc(getHostNames win32)
   System
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
		     {ForAll {TestMisc.getHostNames}
		      proc {$ Host}
			 if TestMisc.win32 andthen Fork == rsh
			 then {System.show 'rsh not supported under win32'}
                         % workaround: Redhat does not allow rsh localhost by default
			 elseif Host == localhost andthen  Fork == rsh
			 then skip
			 else
%			    {System.show init(host:Host fork:Fork detach:Detach)}
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
