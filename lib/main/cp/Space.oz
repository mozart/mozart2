%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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
   BootSpace(is:         Is
             new:        New
             ask:        Ask
             askVerbose: AskVerbose
             clone:      Clone
             merge:      Merge
             inject:     Inject
             commit:     Commit
             choose:     BootChoose)
   at 'x-oz://boot/Space'

prepare

   proc {Fail _}
      fail
   end

export
   Is
   New
   Ask
   AskVerbose
   Clone
   Merge
   Inject
   Commit
   Discard
   WaitStable
   Choose

define

   proc {Discard S}
      {Inject S Fail}
   end

   proc {WaitStable}
      {Wait {BootChoose 1}}
   end

   fun {Choose X}
      if {IsInt X} then {BootChoose X}
      else X.{BootChoose {Width X}}
      end
   end

end
