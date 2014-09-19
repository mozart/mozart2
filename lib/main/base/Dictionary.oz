%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

Dictionary = dictionary(new:              NewDictionary
                        is:               IsDictionary
                        isEmpty:          Boot_Dictionary.isEmpty
                        put:              Boot_Dictionary.put
                        exchange:         proc {$ D LI OldVal NewVal}
                                             {Boot_Dictionary.exchangeFun D LI NewVal OldVal}
                                          end
                        condExchange:     proc {$ D LI DefVal OldVal NewVal}
                                             {Boot_Dictionary.condExchangeFun D LI DefVal
                                              NewVal OldVal}
                                          end
                        get:              Boot_Dictionary.get
                        condGet:          Boot_Dictionary.condGet
                        keys:             Boot_Dictionary.keys
                        entries:          Boot_Dictionary.entries
                        items:            Boot_Dictionary.items
                        remove:           Boot_Dictionary.remove
                        removeAll:        Boot_Dictionary.removeAll
                        clone:            Boot_Dictionary.clone
                        member:           Boot_Dictionary.member
                        toRecord:         fun {$ L D}
                                             {List.toRecord L {Boot_Dictionary.entries D}}
                                          end
                        weak:             WeakDictionary
                       )
