%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                      %%
%%  QTk                                                                 %%
%%                                                                      %%
%%  (c) 2000 Université catholique de Louvain.  All Rights Reserved.    %%
%%  The development of this software is supported by the PIRATES        %%
%%  project at the Université catholique de Louvain.  This file is      %%
%%  subject to the general Mozart license.                              %%
%%                                                                      %%
%%  Author: Donatien Grolaux                                            %%
%%                                                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

functor

import QTk

define

   Look={QTk.newLook}

   {Look.set td(relief:sunken background:red)}
   {Look.set label(background:red relief:raised borderwidth:5 glue:we)}

   Look2={QTk.newLook}

   {Look2.set label(background:blue relief:sunken)}
   {Look2.set td(relief:sunken borderwidth:5 glue:nswe)}

   {{QTk.build td(td(glue:nswe look:Look
                     label(init:"a") background:green
                     scrollframe(label(init:"b"))
                     panel(td(title:"1" label(init:"Hello"))
                           td(title:"2" label(init:"World")))
                     td(look:Look2
                        lrrubberframe(label(text:"Hello")
                                      label(text:"World")))))} show}

end
