%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                      %%
%% QTk                                                                  %%
%%                                                                      %%
%%  (c) 2000 Université catholique de Louvain. All Rights Reserved.     %%
%%  The development of QTk is supported by the PIRATES project at       %%
%%  the Université catholique de Louvain.  This file is subject to the  %%
%%  general Mozart license.                                             %%
%%                                                                      %%
%%  Author: Donatien Grolaux                                            %%
%%                                                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
