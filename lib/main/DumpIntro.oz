%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%   Christian Schulte, 1997
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

\ifdef LILO

%% The following ensures that this file works with the `-g' command
%% line option:  With debug information, an application of the unbound
%% variable `=` would be generated; the thread would block.
\pushSwitches
\switch -debuginfocontrol

declare
local
   Load     = {`Builtin` load 2}
   Base     = {Load 'Base.ozp'}
   Standard = {Load 'Standard.ozp'}
in
   \insert 'Base.env'
   = Base
   \insert 'Standard.env'
   = Standard
end

\popSwitches

\else

%% The following ensures that this file works with the `-g' command
%% line option:  With debug information, an application of the unbound
%% variable `=` would be generated; the thread would block.
\pushSwitches
\switch -debuginfocontrol

declare
local
   Load     = {`Builtin` load 2}
   Base     = {Load 'Base.ozc'}
   Standard = {Load 'Standard.ozc'}
in
   \insert 'Base.env'
   = Base
   \insert 'Standard.env'
   = Standard
end

\popSwitches

\endif
