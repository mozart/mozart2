%%%
%%% Author:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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

fun {Link Us}
   %% Takes list of urls, returns list of modules
   ModMan = {New Module.manager init}
in
   %% Compute pairlist of module name and module
   {Map Us fun {$ U}
              {ModMan link(url:U $)}
           end}
end

fun {Apply UFs}
   %% Takes a list of functors or pairs of urls and functors,
   %% returns list of modules
   ModMan = {New Module.manager init}
in
   %% Compute pairlist of module name and module
   {Map UFs fun {$ UF}
               case UF of U#F then
                  {ModMan apply(url:U F $)}
               else
                  {ModMan apply(UF $)}
               end
            end}
end
