%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Université catholique de Louvain
%
% Last change:
%   $Date$ by $Author$
%   $Revision$
%
% This file is part of Mozart, an implementation
% of Oz 3:
%   http://www.mozart-oz.org
%
% See the file "LICENSE" or
%   http://www.mozart-oz.org/LICENSE.html
% for information on usage and redistribution
% of this file, and for a DISCLAIMER OF ALL
% WARRANTIES.
%
%  The development of QTk is supported by the PIRATES project at
%  the Université catholique de Louvain.

functor

import
   Application
   QTkImageLibBoot(newImageLibrary: NewImageLibrary
            saveImageLibrary:SaveImageLibrary)

define

   I={NewImageLibrary}
   {I newBitmap(file:"mini-inc.xbm")}
   {I newBitmap(file:"mini-dec.xbm")}
   {SaveImageLibrary I "QTkNumberentry_bitmap.ozf"}
   {Application.exit 0}

end
