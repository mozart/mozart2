%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  Reporting any errors and warnings;
%%%
%%%
%%%

local MessageWindowObject in
   %%
   job
      %%  'ProtoMessageWindow' is not known yet;
      create MessageWindowObject from ProtoMessageWindow
         %%
         attr
            leaderWindow: InitValue
         %%

         %%
         meth get(?MW)
            case @window == InitValue then
               <<[createMessageWindow
                  pushButton(clear
                             proc {$} {self clear} end
                             _)
                  %% pushButton(iconify
                  %%         proc {$} {self iconify} end
                  %%         _)
                  pushButton(close
                             proc {$} {self closeWindow} end
                             _)]>>
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

   %%  ... And now, everywhere 'MessageWindowObject' is used, insert
   %%  job ... end
   %%
   proc {BrowserMessagesInit _}
      true
   end

   %%
   proc {BrowserMessagesExit W}
      job
         {MessageWindowObject closedLeaderWindow(W)}
      end
   end

   %%
   proc {BrowserMessagesFocus W}
      job
         {MessageWindowObject setLeaderWindow(W)}
      end
   end

   %%
   proc {BrowserMessagesNoFocus}
      job
         {MessageWindowObject setLeaderWindow(InitValue)}
      end
   end

   %%
   proc {BrowserError Desc}
      %%
      {Show '************************************************************'}
      {Show Desc}
      {Show '************************************************************'}
      %%
      job
         local MW HT L in
            MW = {MessageWindowObject get($)}
            %%
            %%
            L = {Length Desc}
            HT = {MakeTuple '#' L+1}
            {Loop.for 2 L+1 1 proc {$ I} HT.I = {Nth Desc I-1} end}
            HT.1 = 'ERROR: '
            {Show {String.toAtom {VirtualString.toString HT}}}
            {MW showIn(HT)}
         end
      end
   end

   %%
   proc {BrowserWarning Desc}
      %%
      job
         local MW HT L in
            MW = {MessageWindowObject get($)}
            %%
            %%
            L = {Length Desc}
            HT = {MakeTuple '#' L+1}
            {Loop.for 2 L+1 1 proc {$ I} HT.I = {Nth Desc I-1} end}
            HT.1 = 'WARNING: '
            {MW showIn(HT)}
         end
      end
   end

   %%
end
