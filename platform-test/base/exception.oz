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
   System

export Return

define
   Return =
   exception([
              object(proc {$}
                        local
                           class X from BaseObject
                              prop
                                 locking
                              attr a:b
                              meth tkInit
                                 if @a==b then a<-c end
                              end
                              meth c
                                 lock
                                    {Delay 1000}
                                    {System.show '*** here i am'}
                                 end
                              end
                           end
                           Y
                        in
                           thread
                              try
                                 Y = {New X tkInit}
                                 {Y tkInit}
                                 %% this error escapes the try
                              catch error(...) then skip
                              end
                           end
                        end
                     end
                     keys:[exception object])

              'self'(equal(fun {$}
                              class CA
                                 meth whoAmI($)
                                    a
                                 end
                                 meth raiseIt
                                    raise gaga end
                                 end
                              end
                              class CB
                                 meth whoAmI($)
                                    b
                                 end
                                 meth check($)
                                    try
                                       {A raiseIt} _
                                    catch gaga then
                                       {self whoAmI($)}
                                    end
                                 end
                              end
                              A = {New CA whoAmI(_)}
                              B = {New CB whoAmI(_)}
                           in
                              {B check($)}
                           end
                           b)
                     keys:['self' object exception])


              'lock'(proc {$}
                        local X = thread {NewLock} end in
                           try
                              lock X then
                                 X=b   %% escapes try
                              end
                           catch failure(...) then skip
                           end
                        end
                     end
                     keys:[exception 'lock'])
             ])
end
