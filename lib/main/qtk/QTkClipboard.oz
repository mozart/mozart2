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


class QTkClipboard

   prop locking

   meth init
      skip
   end

   meth append(format:Format<="STRING" type:Type<="STRING" displayof:Displayof<="." What)
      lock
         {ExecTk clipboard append("-format" Format "-type" Type "-displayof" Displayof "--" What)}
      end
   end

   meth get(selection:Selection<="PRIMARY" type:Type<="STRING" displayof:Displayof<="." Return)
      lock
         {ReturnTk clipboard selection(get displayof:Displayof type:Type selection:Selection Return)}
      end
   end

   meth clear(selection:Selection<="PRIMARY" displayof:Displayof<=".")
      lock
         {ExecTk clipboard clear(displayof:Displayof)}
         {ExecTk selection clear(selection:Selection displayof:Displayof)}
      end
   end
end

Clipboard={New QTkClipboard init}
