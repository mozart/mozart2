proc {EvalExpression VS Env ?Kill ?Result} E I S in
   E = {New CompilerEngine init()}
   I = {New QuietInterface init(E)}
   {E enqueue(mergeEnv(Env))}
   {E enqueue(setSwitch(expression true))}
   {E enqueue(setSwitch(threadedqueries false))}
   {E enqueue(feedVirtualString(VS return(result: ?Result)))}
   thread T in
      T = {Thread.this}
      proc {Kill}
         {E clearQueue()}
         {E interrupt()}
         {Thread.terminate T}
         S = unit
      end
      {Wait {E enqueue(ping($))}}
      case {I hasErrors($)} then Ms in
         {I getMessages(?Ms)}
         {Exception.raiseError compiler(evalExpression VS ?Ms)}
      else skip
      end
      S = unit
   end
   {Wait S}
end

fun {VirtualStringToValue VS}
   {EvalExpression VS env() _}
end
