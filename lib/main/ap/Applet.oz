functor
import
   GetArgs
   Tk
   System.exit
export
   exit     : Exit
   args     : Args
   %% the idea is that the application should itself provide
   %% the value for Spec. Once this is done, the corresponding
   %% parser is invoked and the top level window is initialized
   spec     : Spec
   toplevel : Toplevel
body
   Spec Args Toplevel
   Exit = System.exit
   thread
      {Wait Spec}
      Args     = {GetArgs.applet Spec}
      Toplevel = {New Tk.toplevel tkInit(withdraw: true
                                         title:    Args.title
                                         delete:   proc {$} {Exit 0} end)}
      {Tk.batch
       case Args.width>0 andthen Args.height>0 then
          [wm(geometry  Toplevel Args.width#x#Args.height)
           wm(resizable Toplevel false false)
           update(idletasks)
           wm(deiconify Toplevel)]
       else
          [update(idletasks)
           wm(deiconify Toplevel)]
       end}
   end
end
