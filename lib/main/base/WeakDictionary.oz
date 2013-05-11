%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
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

WeakDictionary = weakDictionary(new:          Boot_WeakDictionary.new
                                is:           Boot_WeakDictionary.is
                                put:          Boot_WeakDictionary.put
                                exchange:     Boot_WeakDictionary.exchange
                                condExchange: Boot_WeakDictionary.condExchange
                                get:          Boot_WeakDictionary.get
                                condGet:      Boot_WeakDictionary.condGet
                                close:        Boot_WeakDictionary.close
                                keys:         Boot_WeakDictionary.keys
                                entries:      Boot_WeakDictionary.entries
                                items:        Boot_WeakDictionary.items
                                isEmpty:      Boot_WeakDictionary.isEmpty
                                toRecord:     Boot_WeakDictionary.toRecord
                                remove:       Boot_WeakDictionary.remove
                                removeAll:    Boot_WeakDictionary.removeAll
                                member:       Boot_WeakDictionary.member
                               )
