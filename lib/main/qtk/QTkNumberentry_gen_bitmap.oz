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
   {I newBitmap(file:"mini-inc.xbm")}
   {I newBitmap(file:"mini-dec.xbm")}
   {SaveImageLibrary I "QTkNumberentry_bitmap.ozf"}
   {Application.exit 0}

end
