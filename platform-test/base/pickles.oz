%%%
%%% Authors:
%%%   Ralf Scheidhauer <scheidhr@dfki.de>
%%%
%%% Copyright:
%%%   Ralf Scheidhauer, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%   http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Pickle(save load)
   OS(tmpnam unlink)
export
   Return
define
   fun {TrySave Val File}
      try
         {Pickle.save Val File}
         nil
      catch error(dp(generic
                     'Resources found during save'
                     ['Resources'#X _]) ...)
      then X
      end
   end

   Nogoods =
     [{NewCell 1}
      _
      {New BaseObject noop}
      proc native {$} skip end
      class $ prop native end
      Pickle.save
     ]

   NN = {NewName}
   Goods =
     [4711
      111111111111111111111111111111111111111111111111
      23.056
      f(a:    'an atom with blanks'
        NN:   BaseObject
        2:    Append
        true: fun {$ X Y} X+Y end
        cycle: Goods)
     ]

   Return =
   pickles(proc {$}
              Tmp = {OS.tmpnam}
           in
              {All Nogoods fun {$ X} {TrySave X Tmp}==[X] end}=true
              {TrySave Goods Tmp} = nil
              {Pickle.load Tmp} = Goods
              {OS.unlink Tmp}
           end
           keys:[pickles])
end
