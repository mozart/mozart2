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

local
   class DialogBoxC
      meth init skip end
      meth Diag(cmd:_
                defaultextension:_ <= _
                filetypes:_        <= _
                initialdir:_       <= _
                initialfile:_      <= _
                title:_            <= _
                1:_) = M
         {Record.forAllInd M
          proc{$ I V}
             Err={CheckType
                  case I
                  of cmd then [tk_getSaveFile tk_getOpenFile]
                  [] defaultextension then vs
                  [] filetypes then no
                  [] initialdir then vs
                  [] initialfile then vs
                  [] title then vs
                  [] 1 then free end
                  V}
          in
             if Err==unit then skip else
                {Exception.raiseError qtk(typeError I dialogbox Err M)}
             end
          end}
         {ReturnTk unit {Record.subtract {Record.adjoin M M.cmd} cmd} vs}
      end
      meth save(...)=M
         {self {Record.adjoin M Diag(cmd:tk_getSaveFile)}}
      end
      meth load(...)=M
         {self {Record.adjoin M Diag(cmd:tk_getOpenFile)}}
      end
      meth color(initialcolor:_  <= _
                 title:_         <= _
                 1:_)=M
         {Record.forAllInd M
          proc{$ I V}
             Err={CheckType
                  case I
                  of initialcolor then color
                  [] title then vs
                  [] 1 then free end
                  V}
          in
             if Err==unit then skip else
                {Exception.raiseError qtk(typeError I dialogbox Err M)}
             end
          end}
         {ReturnTk unit {Record.adjoin M tk_chooseColor} color}
      end

   end
in
   DialogBox={New DialogBoxC init}
end
