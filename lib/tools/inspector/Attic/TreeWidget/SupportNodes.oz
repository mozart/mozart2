%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% SupportNodes Functor
%%%

functor $

import
   Tk(canvasTag menu menuentry)

export
   options          : OpMan
   embraceNode      : EmbraceNode
   nullNode         : NullNode
   proxyNode        : ProxyNode
   bitmapTreeNode   : BitmapTreeNode
   internalAtomNode : InternalAtomNode

define
   class OptionManager
      from
         BaseObject

      attr
         dict %% Internal Dictionary

      meth create
         @dict = {Dictionary.new}
      end

      meth set(Name Value)
         {Dictionary.put @dict Name Value}
      end

      meth get(Name $)
         {Dictionary.get @dict Name}
      end

      meth isKey(Name $)
         try
            _ = {Dictionary.get @dict Name}
            true
         catch _ then
            false
         end
      end
   end

   OpMan = {New OptionManager create}

   \insert 'Create/BaseCreateObject.oz'
   \insert 'Create/SupportCreateObjects.oz'
   \insert 'Layout/BaseLayoutObject.oz'
   \insert 'Layout/SupportLayoutObjects.oz'
   \insert 'Draw/BaseDrawObject.oz'
   \insert 'Draw/SupportDrawObjects.oz'

   %% Embrace Node

   class EmbraceNode
      from
         EmbraceCreateObject
         EmbraceLayoutObject
         EmbraceDrawObject

      prop
         final
   end

   %% Dummy Node

   class NullNode
      from
         NullCreateObject
         NullLayoutObject
         NullDrawObject

      prop
         final
   end

   %% Proxy Node (for link operations)

   class ProxyNode
      from
         ProxyCreateObject
         ProxyLayoutObject
         ProxyDrawObject

      prop
         final
   end

   %% BitmapTreeNode

   class BitmapTreeNode
      from
         BitmapCreateObject
         BitmapLayoutObject
         BitmapDrawObject

      prop
         final
   end

   %% InternalAtomNode

   class InternalAtomNode
      from
         InternalAtomCreateObject
         InternalAtomLayoutObject
         InternalAtomDrawObject

      prop
         final
   end
end
