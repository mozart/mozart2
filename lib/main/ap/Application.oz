%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
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

functor
import Pickle OS Open
export
   %% saving an executable functor
   Save GetSysletPrefix SetSysletPrefix
body
   SysletPrefix = {NewCell '#!/bin/sh\nexec ozengine $0 "$@"\n'}
   proc {GetSysletPrefix P} {Access SysletPrefix P} end
   proc {SetSysletPrefix P} {Assign SysletPrefix P} end
   proc {Save File App}
      TmpFile = {OS.tmpnam}
      Script  = {New Open.file
                 init(name:File flags:[create write truncate])}
   in
      try
         {Script write(vs:{GetSysletPrefix})}
         {Script close}
         {Pickle.save App TmpFile}
         {OS.system 'cat '#TmpFile#' >> '#File#'; chmod +x '#File _}
      catch E then
         raise E end
      finally
         {OS.unlink TmpFile}
      end
   end
end