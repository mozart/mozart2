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

functor $
export
   Return

body
   fun {RetA} a end

   Return =
   future([
           adjoinAt(proc {$}
                       Ts=[a(a:b)#{ByNeed RetA}#a#b
                           a(a:b)#a#{ByNeed RetA}#b
                           a(b:a)#a#b#{ByNeed RetA}]
                    in
                       {ForAll Ts proc {$ R#A1#A2#A3}
                                     if {AdjoinAt A1 A2 A3} == R then skip
                                     end
                                  end}
                    end
                    keys:[future byNeed adjoin adjoinAt])

           adjoinList(proc {$}
                         Ts=[
                             a#{ByNeed RetA}#nil
                            ]
                      in
                         {ForAll Ts proc {$ R#A1#A2}
                                       if {AdjoinList A1 A2} == R then skip
                                       end
                                    end}
                      end
                      keys:[future byNeed adjoin adjoinList])

           arity(proc {$}
                    Ts=[
                        nil#{ByNeed RetA}
                       ]
                 in
                    {ForAll Ts proc {$ R#A}
                                  if {Arity A} == R then skip
                                  end
                               end}
                 end
                 keys:[future byNeed arity])
          ])
end
