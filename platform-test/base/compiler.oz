%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Compiler
export
   Return
define
   Return =
   compiler([unnestEquationInRecord(equal(proc {$ B}
					     Y
					     fun {P}
						B = {IsDet Y} Y
					     end
					  in
					     _ = f({P} Y=y)
					  end true)
				    keys: [compiler unnesting fixedBug])
	     unnest(proc {$}
		       fun {F1 X} X = 1 1 end
		       fun {F2 X} {Wait X} 2 end
		       X
		    in
		       _ = [{F1 X} {F2 X}]
		    end
		    keys: [compiler unnesting fixedBug])
	     localEnvInThreads(proc {$}
				  fun {X Y} Y end
				  S
			       in
				  {proc {$}
				      thread
					 case S of 1 then skip else skip end
				      end
				      {X {X S} _}
				   end}
			       end
			       keys: [compiler codeGen fixedBug])
	     clippedTestTree(proc {$}
				{fun {$ X}
				    case X of a(_ ...) then 1
				    [] b then 2
				    elseif {IsRecord X} then 3
				    else unit
				    end
				 end x} = 3
			     end
			     keys: [compiler codeGen fixedBug])
	     xshuffle(%% PR#1329
                      proc {$}
                         NUM = 20
                         LENGTH = 40000.0
                             
                         fun {C2Pos C}
                            ({IntToFloat C} - 1.0) * (LENGTH / {IntToFloat NUM})
                         end
                      in    
                         {fun {$ Type Entry}
                             Pos C Dur
                          in
                             local SpeedSec DurSoFar in
                                SpeedSec = Entry.speed / 3.6
                                
                                if Entry.c == NUM then
                                   DurSoFar = 0
                                else
                                   Pos = {C2Pos Entry.c+1}
                                   C = Entry.c+1
                                   DurSoFar = (Pos - Entry.pos) / SpeedSec
                                end
                                %% {Show Entry}
                                Dur = (Entry.buggyone - DurSoFar)
                             end
                                
                             someatom(type:Type pos:Pos c:C buggyone:Dur)
                          end handover someatom(c:1 buggyone:1.0 pos:1.0 speed:1.0 time:1.0) _}
                      end
                      keys: [compiler codeGen fixedBug])
	     exhandler_initsrs(%% PR#1291
                               proc {$}
                                  proc {Skip _} skip end
                               in
                                  {IsDet {fun {$ V1} V2 in
                                             case V1 of a then
                                                try V2=a catch _ then skip end
                                                a=a
                                             else
                                                V2 = b
                                             end
                                             {Skip V2}
                                             V2
                                          end a} true}
                               end
                               keys: [compiler codeGen fixedBug])
	     register_optimiser(%% PR#1070
                                %% If the engine throws an exception then this test will halt the
                                %% test suite run immediately. We can't catch the exception, I guess
                                %% the feedVirtualString runs the compiler in a sub-thread.
                                proc {$}
                                   TestProg = 
                                   "local proc {Skip _ _ _} skip end in "#
                                   "{fun lazy {$ S I N} "#
                                   "if I==N then skip else C in skip end "#
                                   "{Skip S I N} a "#
                                   "end a a a} "#
                                   "end"
                                in
                                   {proc {$ VS ?Result} E I S in
                                       E = {New Compiler.engine init()}
                                       I = {New Compiler.interface init(E)}
                                       {E enqueue(setSwitch(expression true))}
                                       {E enqueue(setSwitch(threadedqueries false))}
                                       %% Test requires +staticvarnames
                                       {E enqueue(setSwitch(staticvarnames true))}
                                       {E enqueue(feedVirtualString(VS return(result: ?Result)))}
                                       thread
                                          {I sync()}
                                          if {I hasErrors($)} then Ms in
                                             {I getMessages(?Ms)}
                                             S = error(compiler(evalExpression VS Ms))
                                          else
                                             S = success
                                          end
                                       end
                                       case S of error(M) then
                                          {Exception.raiseError M}
                                       [] success then skip
                                       end
                                    end TestProg _}
                                end
                                keys: [compiler codeGen fixedBug])

             bigDatastructure(proc {$}
				 {fun {$}
				     f(f(["00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"])
				       f(["00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"
					  "0000000000"])
				       f(["00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"
					  "00000000000000000000"]))
				  end _}
			      end
			      keys: [compiler codeGen fixedBug])
	    ])
end
