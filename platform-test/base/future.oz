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
   Space

export
   Return

define
   fun {RetA} a end

   Return =
   future([
	   status(proc {$}
		     X Y
		  in
		     X=!!Y
		     {Value.status X} = future
		     {Value.status Y} = free
		     {Some [X Y] IsNeeded} = false   % none is needed yet
		     {Value.makeNeeded X} {Delay 500}
		     {Value.status X} = future
		     {Value.status Y} = free
		     {All [X Y] IsNeeded} = true   % both must be needed
		     Y=42
		     X=42
		  end
		  keys:[future status need])

	   adjoinAt(proc {$}
		       Ts=[a(a:b)#{ByNeedFuture RetA}#a#b
			   a(a:b)#a#{ByNeedFuture RetA}#b
			   a(b:a)#a#b#{ByNeedFuture RetA}]
		    in
		       {ForAll Ts proc {$ R#A1#A2#A3}
				     true = {AdjoinAt A1 A2 A3} == R
				  end}
		    end
		    keys:[future byNeedFuture adjoin adjoinAt])

	   adjoinList(proc {$}
			 Ts=[
			     a#{ByNeedFuture RetA}#nil
			    ]
		      in
			 {ForAll Ts proc {$ R#A1#A2}
				       true = {AdjoinList A1 A2} == R
				    end}
		      end
		      keys:[future byNeedFuture adjoin adjoinList])

	   arity(proc {$}
		    Ts=[
			nil#{ByNeedFuture RetA}
		       ]
		 in
		    {ForAll Ts proc {$ R#A}
				  true = {Arity A} == R
			       end}
		 end
		 keys:[future byNeedFuture arity])

	   cycle(proc {$}
		    A = {ByNeedFuture fun {$} A end}
		 in
		    skip
		 end
		 keys:[future byNeedFuture cycle bug])		 

	   space(proc {$}
		    X Y S Go1 Go2
		 in
		    X=!!Y
		    S={Space.new proc {$ R} X=1 end}
		    thread
		       Go1 = unit
		       _ = {Space.merge S}
		       Go2 = unit
		    end
		    {Wait Go1} % first start thread to merge space
		    Y=1        % then bind future
		    {Wait Go2} % then wait until merge is successful
		 end
		 keys: [future space])

	   failed(proc {$}   %% futures and failed values
		     X Y F
		  in
		     % first create the future, then bind F to a failed value
		     X=!!F
		     F={Value.failed foo}
		     {Value.waitQuiet X}   % should not fail
		     try {Wait X} catch E then E=foo end
		     % take a future of the failed value F
		     Y=!!F
		     {Value.waitQuiet Y}   % should not fail
		     try {Wait Y} catch E then E=foo end
		  end
		  keys:[future failed waitQuiet])
	  ])
end

