%%%
%%% Author:
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Benjamin Lorenz, 1998
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   DefaultForeground
   DefaultBackground
   BlockedThreadColor

   if Tk.isColor then
      DefaultForeground = '#000000'
      DefaultBackground = '#F0F0F0'
      BlockedThreadColor = '#E07070'
   else
      DefaultForeground = black
      DefaultBackground = white
      BlockedThreadColor = black
   end
   DefaultFont = '7x13'

   proc {Spinner SlashList W X}
      if {IsFree X} then S|Sr = SlashList in
         {W tk(conf text:S)}
         {Delay 70}
         {Spinner Sr W X}
      end
   end

   SlashList = '/'|'-'|'\\'|'|'|SlashList
in
   class EvalDialog from Dialog
      prop locking
      feat Expr Result
      attr
         CurComp: unit CurCompUI: unit Self: unit
         EvalThread: unit SpinnerLock: unit
      meth tkInit(title:   Title   <= 'Query'
                  master:  Master  <= NoArg
                  root:    Root    <= master
                  buttons: Buttons <= nil
                  focus:   Focus   <= 0
                  env:     Env     <= env()
                  'self':  S       <= unit)
         CurComp <- {New Compiler.engine init()}
         {@CurComp enqueue(mergeEnv(Env))}
         CurCompUI <- {New Compiler.interface init(@CurComp)}
         Self <- S
         SpinnerLock <- {NewLock}

         Dialog, tkInit(title: Title
                        master: Master
                        root: Root
                        buttons: ('Eval'#(self#Eval())|
                                  'Exec'#(self#Exec())|
                                  'Reset'#(self#Reset())|
                                  'Done'#(self#Close())|Buttons)
                        focus: Focus
                        pack: false)
         Frame = {New Textframe tkInit(parent: self
                                       text: ('Eval Expression' #
                                              ' / Exec Statement'))}
         ExprLabel = {New Tk.label tkInit(parent: Frame.inner
                                          anchor: w
                                          text: 'Query:')}
         ExprEntry = {New Tk.entry tkInit(parent: Frame.inner
                                          font: DefaultFont
                                          background: DefaultBackground
                                          width: 40)}
         ResultLabel = {New Tk.label tkInit(parent: Frame.inner
                                            anchor: w
                                            text: 'Result:')}
         ResultEntry = {New Tk.label tkInit(parent: Frame.inner
                                            relief: sunken
                                            anchor: w
                                            font: DefaultFont
                                            background: DefaultBackground
                                            width: 40)}
      in
         self.Expr = ExprEntry
         self.Result = ResultEntry

         {self.toplevel tkBind(event: '<Escape>'
                               action: self#Close())}
         {ExprEntry tkBind(event: '<Meta-t>'
                           action: self#Reset())}
         {ExprEntry tkBind(event: '<Return>'
                           action: self#Eval())}
         {ExprEntry tkBind(event: '<Meta-Return>'
                           action: self#Exec())}

         {Tk.batch [grid(ExprLabel    row: 0 column: 0 padx: 1 pady: 1)
                    grid(ExprEntry    row: 0 column: 1 padx: 3 pady: 1)
                    grid(ResultLabel  row: 1 column: 0 padx: 1 pady: 1)
                    grid(ResultEntry  row: 1 column: 1 padx: 3 pady: 1)
                    grid(Frame        row: 0 column: 0 padx: 1 pady: 0)
                    focus(ExprEntry)]}
         EvalDialog, tkPack()
      end

      %%
      %% Actions
      %%

      meth Eval()
         case {self.Expr tkReturn(get $)} of "" then
            {self.Result tk(conf text:'Did you ask something?')}
         elseof S then
            EvalDialog, eval(S true)
         end
      end
      meth Exec()
         case {self.Expr tkReturn(get $)} of "" then
            {self.Result tk(conf text:'Did you say something?')}
         elseof S then
            EvalDialog, eval(S false)
         end
      end
      meth Reset()
         EvalDialog, Kill()
         {self.Result tk(conf text: '')}
      end
      meth Kill()
         lock
            if @EvalThread \= unit then
               {Thread.injectException @EvalThread interrupt}
               lock @SpinnerLock then skip end   %% wait for spinner to finish
               EvalThread <- unit
            end
         end
      end
      meth Close()
         EvalDialog, Kill()
         {self tkClose()}
      end

      %%
      %% Public Methods
      %%

      meth getCompiler($)
         @CurComp
      end
      meth eval(VS IsExpression <= true) VS2 in
         VS2 = if IsExpression then VS else VS#'\nunit' end
         EvalDialog, Kill()
         if @EvalThread == unit then Sync in
            try R in
               EvalThread <- {Thread.this}
               thread
                  lock @SpinnerLock then
                     {Delay 150}   %% short computations don't need a spinner
                     if {IsFree Sync} then
                        {self.Result tk(conf fg:DefaultForeground)}
                        {Thread.setThisPriority high}
                        {Spinner SlashList self.Result Sync}
                     end
                  end
               end
               {@CurComp enqueue(setSwitch(expression true))}
               {@CurComp enqueue(setSwitch(threadedqueries false))}
               {Wait {@CurComp enqueue(ping($))}}
               {@CurCompUI reset()}
               case @Self of unit then
                  {@CurComp
                   enqueue(feedVirtualString(VS2 return(result: ?R)))}
               else
                  {@CurComp enqueue(mergeEnv(env('`self`': @Self)))}
                  {@CurComp
                   enqueue(feedVirtualString('{Object.send eval($) '#
                                             'class meth eval($)\n'#
                                             VS2#'\nend end `self`}'
                                             return(result: ?R)))}
               end
               {Wait {@CurComp enqueue(ping($))}}
               Sync = unit
               lock @SpinnerLock then skip end   %% wait for spinner to finish
               if {@CurCompUI hasErrors($)} then ResultText in
                  if {Property.get 'oz.standalone'} then
                     ResultText = 'Compile Error'
                     {System.printInfo {@CurCompUI getVS($)}}
                  else
                     ResultText = 'Compile Error (see *Oz Emulator* buffer)'
                     {System.printInfo [17]#{@CurCompUI getVS($)}}
                  end
                  {self.Result tk(conf fg: BlockedThreadColor
                                  text: ResultText)}
               else E in
                  E = {Property.get errors}
                  {self.Result tk(conf fg: DefaultForeground
                                  text: {Value.toVirtualString R
                                         E.depth E.width})}
               end
               EvalThread <- unit
            catch interrupt then
               {@CurComp clearQueue()}
               {@CurComp interrupt()}
            finally
               Sync = unit
            end
         end
      end
   end
end
