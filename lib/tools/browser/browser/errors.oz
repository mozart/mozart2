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

local MessageWindowObject BrowserMessage in
   %%
   thread
      %%
      %%  'MessageWindowClass' is not known yet (might be);
      create MessageWindowObject from MessageWindowClass
         %%
         attr
            leaderWindow: InitValue

         %%
         meth get(?MW)
            case @window == InitValue then
               MessageWindowClass
               , createMessageWindow
               , pushButton(clear proc {$} {self clear} end _)
               , pushButton(close proc {$} {self closeWindow} end _)
            else true
            end

            %%
            MW = self
         end

         %%
         meth setLeaderWindow(BrowserWindow)
            leaderWindow <- BrowserWindow
         end

         %%
         meth unsetLeaderWindow
            leaderWindow <- InitValue
         end

         %%
         meth closedLeaderWindow(LW)
            case LW == @leaderWindow then
               leaderWindow <- InitValue
            else true
            end
         end
      end
   end
   %%

   %%
   proc {BrowserMessagesInit _} true end

   %%
   proc {BrowserMessagesExit W}
      thread {MessageWindowObject closedLeaderWindow(W)} end
   end

   %%
   proc {BrowserMessagesFocus W}
      thread {MessageWindowObject setLeaderWindow(W)} end
   end

   %%
   proc {BrowserMessagesNoFocus}
      thread {MessageWindowObject setLeaderWindow(InitValue)} end
   end

   %%
   proc {BrowserMessage Type Desc}
      thread
         local MW Message in
            MW = {MessageWindowObject get($)}

            %%
            Message = Type # Desc
            {Show '!'#Message}
            {Show {String.toAtom {VirtualString.toString Message}}}
            {MW showIn(Message)}
         end
      end
   end

   %%
   proc {BrowserError Desc} {BrowserMessage 'ERROR: ' Desc} end
   proc {BrowserWarning Desc} {BrowserMessage 'WARNING: ' Desc} end

   %%
end
