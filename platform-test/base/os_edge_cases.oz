%%%
%%% Authors:
%%%   Arthur Louette (UCLouvain)
%%%
%%% Copyright:
%%%   Arthur Louette, 2026
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
   OS

export
   Return

define
   Return =
   base([
      unicode(
         proc {$}
            ComplexString = "🚀_Test_Cyrillique_Привет_éàçù"
            VS = {VirtualString.toString ComplexString}
         in
            true = ({Length VS} > 0)
         end
         keys:[os unicode utf8]
      )

      getEnv(
         proc {$}
            PathEnv = {OS.getEnv "PATH"}
         in
            true = (PathEnv \= false)
         end
         keys:[os getenv system]
      )

      rand(
         proc {$}
            R1 = {OS.rand}
         in
            true = (R1 >= 0)
            for I in 1..1000 do
               true = ({OS.rand} >= 0)
            end
         end
         keys:[os rand stress]
      )
   ])
end