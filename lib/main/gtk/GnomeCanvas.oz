%
% Authors:
%   Andreas Simon (2000)
%
% Copyright:
%   Andreas Simon (2000)
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

functor

import
   Native at 'Gnome-Canvas.so{native}'
   GTK
   System

export
   \insert 'gnome-canvas-exports.oz'

define

   RegisterNativeObject = GTK.registerObject
   RegisterObject       = GTK.registerObject
   UnRegisterObject     = GTK.registerObject
   GetObject            = GTK.getObject

   % These are references to GTK classes
   Layout               = GTK.layout

   \insert 'gnome-canvas-classes.oz'

end % functor
