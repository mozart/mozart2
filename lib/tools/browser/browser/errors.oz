%%%
%%% Authors:
%%%   Konstantin Popov
%%%
%%% Copyright:
%%%   Konstantin Popov, 1997
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  Reporting any errors and warnings;
%%%
%%%
%%%

%%
local MWManagerObject BrowserMessage in
   %%
   %% It has static extent;
   MWManagerObject = {New class $
                             from Object.base
                             prop final
                             attr leaderWindow: !InitValue

                             %%
                             meth setLeaderWindow(W)
                                leaderWindow <- W
                             end
                             meth getLeaderWindow($)
                                @leaderWindow
                             end
                          end
                      noop}

   %%
   proc {BrowserMessagesFocus W}
      {MWManagerObject setLeaderWindow(W)}
   end

   %%
   proc {BrowserMessagesNoFocus}
      {MWManagerObject setLeaderWindow(InitValue)}
   end

   %%
   proc {BrowserMessage Type Desc}
      thread
         local Message in
            Message = Type # Desc

            %%
            {New MessageWindowClass
             make(leader:  {MWManagerObject getLeaderWindow($)}
                  message: Message) _}
         end
      end
   end

   %%
   proc {BrowserError Desc} {BrowserMessage 'ERROR: ' Desc} end
   proc {BrowserWarning Desc} {BrowserMessage 'WARNING: ' Desc} end

   %%
end
