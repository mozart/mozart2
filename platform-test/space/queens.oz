%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun {$ IMPORT}
   \insert '../lib/import.oz'
in
   space([queens(equal(fun {$}
                          fun {Iterate Board N X Y DX DY}
                             case 1=<X andthen X=<N andthen 1=<Y andthen Y=<N then
                                Board.Y.X | {Iterate Board N X+DX Y+DY DX DY}
                             else nil
                             end
                          end
                          fun {MidLine Board N X Y}
                             D=N-X
                          in
                             case D<0 then nil
                             elsecase D==0 then [Board.Y.X]
                             else
                                Board.Y.X|Board.Y.N|{MidLine Board N-1 X+1 Y}
                             end
                          end
                          proc {MkBoard N ?B}
                             {Record.forAll {MakeTuple board N}=B
                              fun {$} {MakeTuple row N} end}
                          end
                          proc {AtMostOne Xs I Hold}
                             case Xs
                             of X|Xr then
                                thread or X=1 Hold=I [] X=0 end end
                                {AtMostOne Xr I+1 Hold}
                             else skip
                             end
                          end
                          proc {ExactOne Xs I Hold In Out}
                             case Xs of X|Xr then Tmp in
                                thread or X=1 Hold=I [] X=0 Out=Tmp end end
                                {ExactOne Xr I+1 Hold Tmp In}
                             else In = Out
                             end
                          end
                          proc {ExactOneC Xs I Hold In Out}
                             case Xs of X|Xr then Tmp in
                                thread or X=1 Hold=I [] X=0 Out=Tmp end end
                                {ExactOne Xr I+1 Hold Tmp In}
                             else In = Out
                             end
                          end

                          proc {Queens N Board}
                             {MkBoard N Board}
                             {Loop.for 2 N 1
                              proc {$ I}
                                 {AtMostOne {Iterate Board N I N  1 ~1} 1 _}
                                 {AtMostOne {Iterate Board N I 1  1  1} 1 _}
                              end}
                             {Loop.for 1 N 1
                              proc {$ I}
                                 {AtMostOne {Iterate Board N 1 I  1 ~1} 1 _}
                                 {AtMostOne {Iterate Board N 1 I  1  1} 1 _}
                                 {ExactOneC {Iterate Board N I 1  0  1} 1 _ 0 1}
                              end}
                             {Loop.for N div 2 1 ~1
                              proc {$ I}
                                 {ExactOne {MidLine Board N 1 I} 1 _ 0 1}
                                 {ExactOne {MidLine Board N 1 N-I+1} 1 _ 0 1}
                              end}
                             case {IsOdd N} then
                                {ExactOne {MidLine Board N 1 (N div 2 + 1)} 1 _ 0 1}
                             else skip
                             end
                             {For 1 N 1 proc {$ I}
                                           {For 1 N 1 proc {$ J}
                                                         choice Board.I.J=1 then skip
                                                         []     Board.I.J=0 then skip
                                                         end
                                                      end}
                                        end}
                          end

                       in
                          {SearchOne fun {$} {Queens 8} end}
                       end
                       [board(row(1 0 0 0 0 0 0 0) row(0 0 0 0 1 0 0 0)
                              row(0 0 0 0 0 0 0 1) row(0 0 0 0 0 1 0 0)
                              row(0 0 1 0 0 0 0 0) row(0 0 0 0 0 0 1 0)
                              row(0 1 0 0 0 0 0 0) row(0 0 0 1 0 0 0 0))])
                 keys: ['or' 'thread' space 'choice' tuple])])
end
