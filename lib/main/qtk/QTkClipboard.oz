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
