%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

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
