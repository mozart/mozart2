%%%
%%% Authors:
%%%   Author's name (Author's email address)
%%%
%%% Contributors:
%%%   optional, Contributor's name (Contributor's email address)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
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
%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Denys Duchier, Christian Schulte
%%%  Email: duchier@ps.uni-sb.de, schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\ifndef DumpIntroLoaded

\switch -threadedqueries

\define DumpIntroLoaded

declare
  Base Standard Dump
in

declare
   \insert 'Base.env'
   = Base
in

declare
   \insert 'Standard.env'
   = Standard
in

local
   \insert 'DumpSettings.oz'
   Load = {`Builtin` load 2}
in
   Base     = {Load ComDIR#'Base'#ComEXT}
   Standard = {Load ComDIR#'Standard'#ComEXT}
end

\insert 'Dump.oz'

\endif
