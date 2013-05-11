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
import
   Error
export
   Asynchronous
   Synchronous
define

   %% asynchronous service fun

   fun {NewAsynchronousServiceFun1 ServiceFunction}
      L P = {NewPort L}
      proc {ServiceHandler Request#Result}
         try {ServiceFunction Request Result}
         catch E then {Error.printException E} end
      end
      fun {InvokeService Request}
         {Port.sendRecv P Request}
      end
   in
      thread {ForAll L ServiceHandler} end
      InvokeService
   end

   %% asynchronous service proc
   %% avoids making and having a ref to a useless global var

   fun {NewAsynchronousServiceProc1 ServiceProc}
      L P = {NewPort L}
      proc {ServiceHandler Request}
         try {ServiceProc Request}
         catch E then {Error.printException E} end
      end
      proc {InvokeService Request}
         {Send P Request}
      end
   in
      thread {ForAll L ServiceHandler} end
      InvokeService
   end

   %% synchronous service fun

   fun {NewSynchronousServiceFun1 ServiceFunction}
      L P = {NewPort L}
      proc {ServiceHandler Request#Reply}
         Reply =
         try answer({ServiceFunction Request})
         catch E then except(E) end
      end
      fun {InvokeService Request}
         case {Port.sendRecv P Request}
         of answer(V) then V
         [] except(E) then raise E end end
      end
   in
      thread {ForAll L ServiceHandler} end
      InvokeService
   end

   %% synchronous service proc
   %% needs the global var anyway for synchronization

   fun {NewSynchronousServiceProc1 ServiceProc}
      S = {NewSynchronousServiceFun1
           fun {$ X} {ServiceProc X} unit end}
      proc {InvokeService X}
         {S X _}
      end
   in
      InvokeService
   end

   %% for convenience allow 0,1,2,3 ary functions

   fun {NewServiceFun NewServiceFun1 F}
      case {Procedure.arity F}
      of 1 then
         S = {NewServiceFun1
              fun {$ _} {F} end}
         fun {InvokeService} {S unit} end
      in
         InvokeService
      [] 2 then {NewServiceFun1 F}
      [] 3 then
         S = {NewServiceFun1
              fun {$ X#Y} {F X Y} end}
         fun {InvokeService X Y} {S X#Y} end
      in
         InvokeService
      [] 4 then
         S = {NewServiceFun1
              fun {$ X#Y#Z} {F X Y Z} end}
         fun {InvokeService X Y Z} {S X#Y#Z} end
      in
         InvokeService
      end
   end

   fun {NewAsynchronousServiceFun F}
      {NewServiceFun NewAsynchronousServiceFun1 F}
   end

   fun {NewSynchronousServiceFun F}
      {NewServiceFun NewSynchronousServiceFun1 F}
   end

   %% for convenience allow 0,1,2,3,4 ary procedures

   fun {NewServiceProc NewServiceProc1 P}
      case {Procedure.arity P}
      of 0 then
         S = {NewServiceProc1
              proc {$ _} {P} end}
         proc {InvokeService} {S unit} end
      in
         InvokeService
      [] 1 then {NewServiceProc1 P}
      [] 2 then
         S = {NewServiceProc1
              proc {$ X#Y} {P X Y} end}
         proc {InvokeService X Y} {S X#Y} end
      in
         InvokeService
      [] 3 then
         S = {NewServiceProc1
              proc {$ X#Y#Z} {P X Y Z} end}
         proc {InvokeService X Y Z} {S X#Y#Z} end
      in
         InvokeService
      [] 4 then
         S = {NewServiceProc1
              proc {$ X#Y#Z#U} {P X Y Z U} end}
         proc {InvokeService X Y Z U} {S X#Y#Z#U} end
      in
         InvokeService
      end
   end

   fun {NewAsynchronousServiceProc P}
      {NewServiceProc NewAsynchronousServiceProc1 P}
   end

   fun {NewSynchronousServiceProc P}
      {NewServiceProc NewSynchronousServiceProc1 P}
   end

   Asynchronous = asynchronous(newFun  : NewAsynchronousServiceFun
                               newProc : NewAsynchronousServiceProc)
   Synchronous  =  synchronous(newFun  : NewSynchronousServiceFun
                               newProc : NewSynchronousServiceProc)
end
