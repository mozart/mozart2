%
% Authors:
%   Andreas Simon (2000)
%
% Copyright:
%   Andreas Simon (2000)
%
% Last change:
%   $Date$
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
   Native at 'glade.so{native}'
   GTK
%   System

export
   GladeXML

define

   class GladeXML from BaseObject
      attr
         nativeObject
         handlerRegistry % handler names (Atoms) -> handler

      meth getNative($) % get native GTK object from an Oz object
         @nativeObject
      end

      % Registry stuff

      meth initHandlerRegistry
         handlerRegistry <- {Dictionary.new $}
      end
      meth registerHandler(Name Handler)
         {Dictionary.put @handlerRegistry Name Handler}
      end
      meth getHandlerFromAtom(Name ?Handler)
         {Dictionary.get @handlerRegistry Name Handler}
      end

      % Glade methods

      meth new(FName Root)
         nativeObject <- {Native.xmlNew FName Root}
         {GTK.registerObject self}
         GladeXML, initHandlerRegistry
      end
      meth newWithDomain(FName Root Domain)
         nativeObject <- {Native.xmlNewWithDomain FName Root Domain}
         {GTK.registerObject self}
         GladeXML, initHandlerRegistry
      end
      meth signalConnect(Name Handler)
         Id
      in
         {GTK.dispatcher registerHandler(Handler Id)}
         GladeXML, registerHandler(Name Handler)
         {Native.xmlSignalConnectFull @nativeObject Name Id}
      end
   end
end % functor
