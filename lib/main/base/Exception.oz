%%%
%%% Authors:
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% Global
%%

Exception = exception('raise':    Raise
                      raiseError: Boot_Exception.raiseError
                      %%
                      %% wrapper functions
                      %%
                      error:      fun {$ E}
                                     error(E debug: unit)
                                  end
                      system:     fun {$ E}
                                     system(E debug: unit)
                                  end
                      failure:    fun {$ D}
                                     failure(debug: failure(info: [D]))
                                  end)
