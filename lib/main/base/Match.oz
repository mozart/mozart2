%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%% Provides pattern matching extensions, such as pattern matching
%%% for objects.

%%% Must be loaded after Class/Object Modules

declare
   `isInstanceOf` `chunkHasFeature`
in

`isInstanceOf`    = IsInstanceOf
`chunkHasFeature` = `hasFeature`
