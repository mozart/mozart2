functor
import
   DPB at 'x-oz://boot/DPB'
   C_DPStatistics at 'x-oz://boot/DPStatistics'
   C_DPMisc at 'x-oz://boot/DPMisc'
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
   {Wait DPB}

   SiteStatistics=C_DPStatistics.siteStatistics
   GetTablesInfo=C_DPStatistics.getTablesInfo
   GetNetInfo=C_DPStatistics.getNetInfo
   PerdioStatistics=C_DPStatistics.perdioStatistics

   CreateLogFile = C_DPMisc.createLogFile
   MessageCounter = C_DPMisc.getMsgCntr
end
