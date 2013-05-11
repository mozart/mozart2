functor
import
   Glue at 'x-oz://boot/Glue'
export
   SiteStatistics
   GetTablesInfo
   GetNetInfo
   PerdioStatistics
   CreateLogFile
   MessageCounter
define
   %%
   %% Force linking of base library
   %%
   {Wait Glue}

   SiteStatistics=Glue.siteStatistics
   GetTablesInfo=Glue.getTablesInfo
   GetNetInfo=Glue.getNetInfo
   PerdioStatistics=Glue.perdioStatistics

   CreateLogFile = Glue.createLogFile
   MessageCounter = Glue.getMsgCntr
end
