%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Contributor:
%%%
%%% Copyright:
%%%   Denys Duchier, 1999
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
import BootPort(newServiceVar:NewServiceVar) at 'x-oz://boot/Port'
export new : NewService
define
   %% ServiceFunction should be a 2ary procedure
   %% {NewService ServiceFunction} returns a new
   %% 2ary procedure InvokeService that can be invoked
   %% from any subordinated space.
   %% {InvokeService Request} executes
   %% {ServiceFunction Request} in the home space of
   %% the service and return the result.  If Request
   %% contains variables from spaces below that of the
   %% service, an exception is raised.
   proc {NewService ServiceFunction InvokeService}
      L P = {NewPort L}
      proc {ServiceHandler Request#Reply}
         Reply =
         try answer({ServiceFunction Request})
         catch E then except(E) end
      end
   in
      thread {ForAll L ServiceHandler} end
      proc {InvokeService Request Answer}
         Reply = {NewServiceVar P}
      in
         {Send P Request#Reply}
         case Reply
         of answer(A) then A=Answer
         [] except(E) then raise E end
         end
      end
   end
end
