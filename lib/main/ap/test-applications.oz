{Application.servlet
 '/home/ps-home/schulte/public_html/test-servlet.cgi'
 c('SP':eager)
 fun {$ IMPORT}
    \insert 'SP.env'
    = IMPORT.'SP'
 in
    fun {$ Args}
       {System.showInfo "Content-type: text/html\n\n"}
       {System.showInfo '<html>'}
       {System.showInfo '<pre>'}
       {System.set print(width:100 depth:100)}
       {Show Args}
       {System.showInfo '</pre>'}
       {System.showInfo '</html>'}
       0
    end
 end
 multiple(ostring(type:string optional:true)
          int(type:int)
          float(type:float default:56.0))}


{Application.applet
 'test-applet'
 c('SP':eager 'OP':eager 'WP':eager)
 fun {$ IMPORT}
    \insert 'SP.env'
    = IMPORT.'SP'
    \insert 'OP.env'
    = IMPORT.'OP'
    \insert 'WP.env'
    = IMPORT.'WP'
 in
    proc {$ T Args}
       Cs=Args.fg|Args.bg|red|blue|green|yellow|purple|pink|black|white|Cs
       C = {New class $
                   attr c:Cs
                   meth get($)
                      c <- @c.2 @c.1
                   end
                end
            get(_)}
       F = {New Tk.frame tkInit(parent:T)}
       M = {New Tk.message tkInit(parent:F
                                  bg: Args.bg
                                  fg: Args.fg
                                  text: {System.valueToVirtualString
                                         Args 100 100}
                                  bd:10)}
       B1 = {New Tk.button tkInit(parent:F
                                 text:'Change the background!'
                                 action: proc {$}
                                            {M tk(conf bg:{C get($)})}
                                         end)}
       B2 = {New Tk.button tkInit(parent:F
                                  text:'Change the foreground!'
                                  action: proc {$}
                                             {M tk(conf fg:{C get($)})}
                                          end)}
    in
       {Tk.batch [pack(F)
                  pack(M B1 B2 side:top fill:y)]}
    end
 end
 single(fg(type:string optional:false default:blue)
        bg(type:string default:yellow))}
