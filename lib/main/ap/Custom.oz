%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   CustomGroup(register)
   CustomOption(register get)
   CustomEdit(editOption)
export
   Register Get EditOption
define
   proc {Register What}
      case {Label What}
      of group  then {CustomGroup.register  What}
      [] option then {CustomOption.register What}
      end
   end
   Get = CustomOption.get
   EditOption = CustomEdit.editOption
end
