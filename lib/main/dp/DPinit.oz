%\define DBG
functor
import
   DPB     at 'x-oz://boot/DPB'
   ConnectAcceptModule
   ConnectionFunctor
   AcceptFunctor
   DPMisc
   Pickle
   Module
   System
export
   Init
define
   {Wait DPB}
   ConnectState = {NewCell notStarted}
   proc{StartDP}
      AccMod = AcceptFunctor
      AccFunc = functor $ export Init define proc{Init} skip end end
      ConnFunc = ConnectionFunctor.connectionfunctor
   in
\ifdef DBG
      {System.show {DPMisc.initIPConnection r(acceptProc:AccFunc
                                              connectProc:ConnFunc)}}
\else
      _={DPMisc.initIPConnection r(acceptProc:AccFunc
                                   connectProc:ConnFunc)}
\endif
      {AccMod.accept}
      thread
         {ConnectAcceptModule.initConnection {DPMisc.getConnectWstream}}
      end
   end

   proc{Init} N in
      case {Exchange ConnectState $ N} of
         notStarted then
         {StartDP}
         N =  started
      elseof started then skip end
   end
end
