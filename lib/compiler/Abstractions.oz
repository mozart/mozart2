%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

proc {EvalExpression VS Env ?Kill ?Result} E I S in
   E = {New Engine init()}
   I = {New Interface init(E)}
   {E enqueue(mergeEnv(Env))}
   {E enqueue(setSwitch(expression true))}
   {E enqueue(setSwitch(threadedqueries false))}
   {E enqueue(feedVirtualString(VS return(result: ?Result)))}
   thread T in
      T = {Thread.this}
      proc {Kill}
         {E clearQueue()}
         {E interrupt()}
         try
            {Thread.terminate T}
            S = killed
         catch _ then skip   % already dead
         end
      end
      {I sync()}
      if {I hasErrors($)} then Ms in
         {I getMessages(?Ms)}
         S = error(compiler(evalExpression VS Ms))
      else
         S = success
      end
   end
   case S of error(M) then
      {Exception.raiseError M}
   [] success then skip
   [] killed then skip
   end
end

fun {VirtualStringToValue VS}
   {EvalExpression VS env() _}
end
