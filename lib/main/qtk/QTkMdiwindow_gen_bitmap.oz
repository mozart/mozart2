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

functor

import
   Application
   QTkImageLibBoot(newImageLibrary: NewImageLibrary
            saveImageLibrary:SaveImageLibrary)

define

   I={NewImageLibrary}
   {I newBitmap(file:"mini-close.xbm")}
   {I newBitmap(file:"mini-minimize.xbm")}
   {I newBitmap(file:"mini-maximize.xbm")}
   {I newBitmap(file:"mini-restore.xbm")}
   {I newBitmap(file:"mini-menu.xbm")}
   {SaveImageLibrary I "QTkMdiwindow_bitmap.ozf"}
   {Application.exit 0}

end
