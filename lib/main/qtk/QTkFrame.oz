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


class QTkFrame

   from Frame Tk.frame QTkClass

   feat
      widgetType:frame
      typeInfo:r(all:{Record.adjoin GlobalInitType
                      r(borderwidth:pixel
                        cursor:cursor
                        highlightbackground:color
                        highlightcolor:color
                        highlightthickness:pixel
                        relief:relief
                        takefocus:boolean
                        background:color bg:color
                        'class':atom
                        colormap:no
                        container:boolean
                        height:pixel
                        width:pixel
                        visual:no)}
                 uninit:r
                 unset:{Record.adjoin GlobalUnsetType
                        r('class':unit
                          colormap:unit
                          container:unit
                          visual:unit)}
                 unget:{Record.adjoin GlobalUngetType
                        r('class':unit
                          colormap:unit
                          container:unit
                          visual:unit)})

   meth init(M)
      lock
         QTkClass,{Record.filterInd {Record.adjoin M init}
                   fun{$ I _}
                      {Int.is I}==false
                   end}
         Tk.frame,{TkInit M}
         Frame,init(M)
      end
   end

   meth destroy
      lock
         {ForAll {self getChildren($)}
          proc{$ C}
             try {C destroy} catch _ then skip end
          end}
      end
   end

end

{RegisterWidget r(widgetType:td
                  feature:true
                  qTkTd:QTkFrame)}

{RegisterWidget r(widgetType:lr
                  feature:true
                  qTkLr:QTkFrame)}
