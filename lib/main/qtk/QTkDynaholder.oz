%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Université catholique de Louvain
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
%  The development of QTk is supported by the PIRATES project at
%  the Université catholique de Louvain.

functor

import
   Tk
   QTkImage
   QTkDevel(splitParams:        SplitParams
            condFeat:           CondFeat
            convertToType:      ConvertToType
            qTkClass:           QTkClass
            subtracts:          Subtracts
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            getWidget:          GetWidget)

export
   WidgetType
   Feature
   QTkDynaholder

define
   WidgetType=dynaholder
   Feature=false
   Placeholder={GetWidget placeholder}

   class QTkDynaholder

      feat widgetType:WidgetType

      from Placeholder QTkClass

      meth init(M)
         lock
            UM
            IM
         in
            {Record.partitionInd {Record.adjoin M init}
             fun{$ I _}
                {Int.is I}==false
             end UM IM}
            Placeholder,init(UM)
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkDynaholder:QTkDynaholder)}

end
