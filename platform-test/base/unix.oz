%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
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
   Open Remote
   SM at 'smallbuf.so{native}'
export
   Return
define
   Return = unix([
		  write1(Write1 keys:[module io write])
		 ])

   proc {Write1}
      RemoteReady Port Got Done
      functor Slurp
      import Open
      define
	 Sock = {New Open.socket init}
	 !Port = {Sock bind(port:$)}
	 {Sock listen}
	 !RemoteReady=unit
	 {Sock accept}
	 !Got = {Length {Sock read(list:$ size:all)}}
	 !Done=unit
      end
      T = {ByteString.make
	   local L={List.make 5000} in
	      {ForAll L proc {$ C} C=&x end}
	      L
	   end}
      R = {New Remote.manager init(fork:sh)}
      thread {R apply(name:'slurp' Slurp)} end
      {Wait RemoteReady}
      O = {New Open.socket init}
      try
	 %% need to poll until the other process really accepts connections
	 {For 1 100 1
	  proc {$ _}
	     try
		{O connect(port:Port)}
		raise ok end
	     catch system(...) then {Delay 100} end
	  end}
	 raise bad(noConnection) end
      catch ok then skip end
      {SM.smallbuf {O getDesc(_ $)} 1000}
      {O write(vs:T)}
      {O close}
      if Got\={ByteString.width T} then
	 raise bad(wrongSize) end
      end
      {Wait Done}
      {R close}
   in
      skip
   end
end
