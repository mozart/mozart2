%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Christian Schulte, 1997
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


local
   Entries = Boot_Dictionary.entries
in
   Dictionary =
   dictionary(new:          NewDictionary
              is:           IsDictionary
              put:          Boot_Dictionary.put
              get:          Boot_Dictionary.get
              condGet:      Boot_Dictionary.condGet
              keys:         Boot_Dictionary.keys
              entries:      Entries
              items:        Boot_Dictionary.items
              remove:       Boot_Dictionary.remove
              removeAll:    Boot_Dictionary.removeAll
              clone:        Boot_Dictionary.clone
              member:       Boot_Dictionary.member
              toRecord:     fun {$ L D}
                               {Boot_List.toRecord L {Entries D}}
                            end)
end
