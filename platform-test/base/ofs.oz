%%%
%%% Authors:
%%%   Peter Van Roy <pvr@info.ucl.ac.be>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Peter Van Roy, 1997
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

import
   FD RecordC

export
   Return

define

   fun {DA R}
      {RecordC.monitorArity R _}
   end

   MA         = RecordC.monitorArity
   TellRecord = RecordC.tell
   WidthC     = RecordC.width

   local
      proc {Do Xs Ys}
         case Xs of nil then skip
         [] X|Xr then
            if {Member X Ys} then {Do Xr {List.subtract Ys X}}
            else fail
            end
         end
      end
      fun {Take N Xs}
         if N==0 then nil else Xs.1|{Take N-1 Xs.2} end
      end
   in
      proc {WP Xs Ys}
         N ={Length Xs}
         Zs={Take N Ys}
      in
         {Do Xs Zs}
      end
   end

   fun {RFL X}
      {VirtualString.toAtom {Value.toVirtualString X 5 20}}
   end

   fun {RFLNOL X}
      {VirtualString.toAtom
       {List.dropWhile {Value.toVirtualString X 5 20}
        fun {$ I} I\=&( end}}
   end

   proc {WF X}
      thread
         {Wait X} X=false
      end
   end

   proc {WT X}
      thread
         {Wait X} X=true
      end
   end

   fun {EQ X Y}
      R1 = thread
              cond X=Y then true else false end
           end
      R2 = thread
              X == Y
           end
   in
      thread R1 == R2 andthen R1 end
   end

   proc {EQT X Y}
      {WT {EQ X Y}}
   end

   proc {EQF X Y}
      {WF {EQ X Y}}
   end

   proc {MAT X F}
      {WT thread cond X={F} then true else false end end}
   end

   proc {MAF X F}
      {WF thread cond X={F} then true else false end end}
   end

   Return=

   ofs([t1(equal(fun {$}
                    X T1 T2
                    R1 R2 R3 R4 R5 R6
                 in
                    X^foo=100 X^bar=200
                    T1 = X.foo R1={RFL T1} R2={RFL X^foo}
                    T2 = X.bar R3={RFL T2} R4={RFL X^bar}
                    {TellRecord open X}
                    R5={RFL X}
                    X=open(foo:_ bar:_)
                    R6={RFL X}
                    [R1 R2 R3 R4 R5 R6]
                 end
                 ['100' '100' '200' '200'
                  'open(bar:200 foo:100 ...)'
                  'open(bar:200 foo:100)'])
           keys: [ofs record])

        t2(equal(fun {$}
                    X
                    R1 R2
                 in
                    {TellRecord bingo X}
                    X^foo=100 X^bar=200
                    R1={RFL X}
                    X=bingo(foo:_ bar:_ baz:_)
                    X^baz=300
                    R2={RFL X}
                    [R1 R2]
                 end
                 ['bingo(bar:200 foo:100 ...)'
                  'bingo(bar:200 baz:300 foo:100)'])
           keys: [ofs record])

        t3(equal(fun {$}
                    R1 R2 R3 R4 R5 R6 R7 R8
                    Y
                    Z T1 T2
                 in
                    Y^foo=100 Y^bar=_
                    Z^foo=_ Y^bar=bonk
                    Y=Z
                    T1 = Z.foo R1={RFL T1} R2={RFL Z^foo}
                    T2 = Y.bar R3={RFL T2} R4={RFL Y^bar}
                    {TellRecord Y.bar Z}
                    R5={RFL Z} R6={RFL Y}
                    Y=bonk(a:1 foo:_ b:2 bar:_ c:3)
                    R7={RFL Z} R8={RFL Y}

                    [R1 R2 R3 R4 R5 R6 R7 R8]
                 end
                 ['100' '100' bonk bonk 'bonk(bar:bonk foo:100 ...)'
                  'bonk(bar:bonk foo:100 ...)'
                  'bonk(a:1 b:2 bar:bonk c:3 foo:100)'
                  'bonk(a:1 b:2 bar:bonk c:3 foo:100)'])
           keys: [ofs record])

        t4(equal(fun {$}
                    A B
                 in
                    A=open(foo:10 bar:20 baz:30 zip:40 funk:50 all:_)
                    B^foo=_ B^all=60 B^baz=30
                    A=B
                    [{RFL A} {RFL A.all} {RFL B.foo}]
                 end
                 ['open(all:60 bar:20 baz:30 foo:10 funk:50 zip:40)'
                  '60' '10'])
           keys: [ofs record])

        t5(entailed(proc {$}
                       C C1 R
                    in
                       C^big=C1
                       thread
                          cond C^big=10 then R=true else R=false end
                       end
                       C1=10
                       {WT R}
                    end)
           keys: [ofs record entailment])

        t6(entailed(proc {$}
                       D E D1 E1
                    in
                       D^left=D1 E^left=E1
                       {EQF D E}
                       D1=10
                       E1=20
                    end)
           keys: [ofs record entailment])

        t7(entailed(proc {$}
                       D E
                    in
                       D^left=10 E^right=20
                       {EQT D E}
                       D = E
                    end)
           keys: [ofs record entailment])

        t8(entailed(proc {$}
                       X
                    in
                       X^foo=10
                       {EQT X open(foo:10 bar:20)}
                       {EQT X open(foo:10 bar:20)}
                       X=open(foo:_ bar:20)
                    end)
           keys: [ofs record entailment])

        t9(entailed(proc {$}
                       X
                    in
                       X^foo=10
                       {EQF X open(foo:10 bar:20)}
                       {EQF X open(foo:10 bar:20)}
                       {EQF X open(foo:10 bar:20)}
                       X=open(foo:_ bar:30)
                    end)
           keys: [ofs record entailment])

        t10(entailed(proc {$}
                        X
                     in
                        X^foo=10
                        {EQT X open(foo:10)}
                        {EQF X open(foo:20)}
                        {EQF X open(foo:30)}
                        {EQT X open(foo:10)}
                        X=open(foo:_)
                     end)
            keys: [ofs record entailment])

        t11(entailed(proc {$}
                        X Y
                     in
                        {TellRecord two Y}
                        X^foo=10 Y^bar=20
                        {EQT X Y}
                        {TellRecord two X}
                        {RFL X}='two(foo:10 ...)'
                        {RFL Y}='two(bar:20 ...)'
                        X=Y
                     end)
            keys: [ofs record entailment])

        t12(entailed(proc {$}
                        X Y Z
                     in
                        X^foo=10 Y^bar=20
                        {TellRecord man X}
                        {TellRecord man Y}
                        {EQF X Y}
                        {RFL X}='man(foo:10 ...)'
                        {RFL Y}='man(bar:20 ...)'
                        X^baz=23
                        Y^baz=Z
                        Z=24
                        {RFL X}='man(baz:23 foo:10 ...)'
                        {RFL Y}='man(bar:20 baz:24 ...)'
                     end)
            keys: [ofs record entailment])

        t13(entailed(proc {$}
                        X Y
                     in
                        X^foo=10 Y^bar=20
                        {EQT X Y}
                        X^baz=23
                        X^zip=10
                        X^cat=10
                        Y^bing=100
                        {TellRecord ahab X}
                        {TellRecord ahab Y}
                        {RFL X}='ahab(baz:23 cat:10 foo:10 zip:10 ...)'
                        {RFL Y}='ahab(bar:20 bing:100 ...)'
                        X=Y
                        {RFL X}='ahab(bar:20 baz:23 bing:100 cat:10 foo:10 zip:10 ...)'
                        {RFL Y}='ahab(bar:20 baz:23 bing:100 cat:10 foo:10 zip:10 ...)'
                        end)
            keys: [ofs record entailment])


        t14(entailed(proc {$}
                        X
                     in
                        {TellRecord open X}
                        X^foo=X
                        {RFL X}='open(foo:open(foo:open(foo:open(foo:open(foo:open(,,,  ...) ...) ...) ...) ...)'
                        X=open(foo:_)
                        {RFL X}='open(foo:open(foo:open(foo:open(foo:open(foo:open(,,,))))))'
                        end)
            keys: [ofs record entailment])

        t15(entailed(proc {$}
                        X Y
                     in
                        X^foo=Y Y^bar=X
                        {EQT X Y}
                        X=Y
                     end)
            keys: [ofs record entailment])

        t16(entailed(proc {$}
                        X Y
                     in
                        X^foo=Y X^bar=10 Y^foo=X Y^zip=20
                        {EQT X Y}
                        X=Y
                     end)
            keys: [ofs record entailment])

        t17(entailed(proc {$}
                        X Y
                     in
                        X^foo=Y X^bar=10 Y^foo=X Y^zip=20
                        {EQF X Y}
                        X^axe=10
                        Y^axe=11
                     end)
            keys: [ofs record entailment])

        t18(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WF thread
                               cond A in A^foo=23 X=A then true else false end
                            end}
                        X1=24
                     end)
            keys: [ofs record entailment])

        t19(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WT thread
                               cond A in A^foo=23 X=A then true else false end
                            end}
                        X1=23
                     end)
            keys: [ofs record entailment])

        t20(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WF thread
                               cond A in X=A A^foo=23 then true else false end
                            end}
                        X1=24
                     end)
            keys: [ofs record entailment])

        t21(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WT thread
                               cond A in X=A A^foo=23 then true else false end
                            end}
                        X1=23
                     end)
            keys: [ofs record entailment])

        t22(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WF thread
                               cond A in A^bar=100 A^foo=23 X=A then true
                               else false
                               end
                            end}
                        X^bar=101
                        X1=23
                     end)
            keys: [ofs record entailment])

        t23(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WT thread
                               cond A in A^bar=100 A^foo=23 X=A then true
                               else false
                               end
                            end}
                        X^bar=100
                        X1=23
                     end)
            keys: [ofs record entailment])

        t24(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        X^bar=101
                        {WF thread
                               cond A in A^bar=100 A^foo=23 X=A then true
                               else false
                               end
                            end}
                        X1=23
                     end)
            keys: [ofs record entailment])

        t25(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        X^bar=100
                        {WT thread
                               cond A in A^bar=100 A^foo=23 X=A then true
                               else false
                               end
                            end}
                        X1=23
                     end)
            keys: [ofs record entailment])

        t26(entailed(proc {$}
                        X Y
                     in
                        X^foo=10 Y^bar=20
                        {EQT X Y}
                        X=Y
                        X=open(foo:_ bar:_)
                        {RFL X}='open(bar:20 foo:10)'
                     end)
            keys: [ofs record entailment])

        t27(entailed(proc {$}
                        X F G
                     in
                        thread X^F=2 end
                        thread X^G=6 end
                        F=f
                        G=g
                        cond X^f=_ X^g=_ then {RFLNOL X}='(f:2 g:6 ...)'
                        else skip end
                        cond X^f=_ then {RFL X^f}='2'
                        else skip end
                        cond X^g=_ then {RFL X^g}='6'
                        else skip end
                     end)
            keys: [ofs record entailment])

        t28(entailed(proc {$}
                        X F G
                     in
                        thread X^F=2 end
                        thread X^G=6 end
                        F=f
                        G=g
                        cond X^f=_ X^g=_ then {RFLNOL X}='(f:2 g:6 ...)'
                        else skip end
                        cond X.f=_ X.g=_ then {RFLNOL X}='(f:2 g:6 ...)'
                        else skip end
                        cond X^f=_ then {RFL X^f}='2'
                        else skip end
                        cond X^g=_ then {RFL X^g}='6'
                        else skip end
                     end)
            keys: [ofs record entailment])

        t29(entailed(proc {$}
                        X F G
                     in
                        thread
                           X^F=2
                           X^G=6
                           {TellRecord banzai X}
                        end
                        F=f
                        G=g
                        X^f=_
                        X^g=_
                        cond A B in X^f=A X^g=B {Wait A} {Wait B} then
                           {EQT X^f 2}
                           {EQT X^g 6}
                           {EQT {Label X} banzai}
                        else skip end
                     end)
            keys: [ofs record entailment])

        t30(entailed(proc {$}
                        X Y
                     in
                        X^a=1 X^b=2 X^c=3 X^d=4 X^e=5 X^f=6 X^g=7 X^h=8 X^i=9
                        {TellRecord big X}
                        {TellRecord big Y}
                        Y^q=10 Y^r=11 Y^s=12 Y^t=13 Y^u=14 Y^v=15 Y^w=16 Y^x=17
                        X=Y
                        X=big(a:_ b:_ c:_ d:_ e:_ f:_ g:_ h:_ i:_ j:_
                              q:_ r:_ s:_ t:_ u:_ v:_ w:_ x:_ y:_)
                        X.j=999
                        X.y=888
                        {EQT X big(a:1 b:2 c:3 d:4 e:5 f:6 g:7 h:8 i:9
                                   q:10 r:11 s:12 t:13 u:14 v:15 w:16 x:17
                                   j:999 y:888)}
                     end)
            keys: [ofs record entailment])



        t31(entailed(proc {$}
                        X
                     in
                        {WF cond X^foo=_ X=cat(bar:_ baz:23) then true
                            else false
                            end}
                     end)
            keys: [ofs record entailment])

        t32(entailed(proc {$}
                        {WF cond X in X^foo=_ X=cat(bar:_ baz:23) then true
                            else false
                            end}
                     end)
            keys: [ofs record entailment])

        t33(entailed(proc {$}
                        X Y
                        proc {Feats N X}
                           case N of 0
                           then skip
                           else
                              X^{NewName}=_
                              {Feats N-1 X}
                           end
                        end
                     in
                        X={Feats 5}
                        Y={Feats 7}
                        X=Y
                     end)
            keys: [ofs record entailment])


        t34(entailed(proc {$}
                        X
                     in
                        X^a^b^c^d^e^f=X^f^e^d^c^b^a
                        {TellRecord f1 X}
                        {TellRecord f2 X^a}
                        {TellRecord f3 X^a^b}
                        {TellRecord f4 X^a^b^c}
                        {TellRecord f5 X^a^b^c^d}
                        {TellRecord f6 X^a^b^c^d^e}
                        {TellRecord f7 X^a^b^c^d^e^f}
                        {TellRecord f1 X}
                        {TellRecord g2 X^f}
                        {TellRecord g3 X^f^e}
                        {TellRecord g4 X^f^e^d}
                        {TellRecord g5 X^f^e^d^c}
                        {TellRecord g6 X^f^e^d^c^b}
                        {TellRecord f7 X^f^e^d^c^b^a}
                        {RFL X}='f1(a:f2(b:f3(c:f4(d:f5(e:f6(,,,  ...) ...) ...) ...) f:g2(e:g3(d:g4(c:g5(b:g6(,,,  ...) ...) ...) ...) ...)'
                        end)
            keys: [ofs record entailment])

        t35(entailed(proc {$}
                        X
                     in
                        {TellRecord g6 X^f^e^d^c^b}
                        {TellRecord g5 X^f^e^d^c}
                        {TellRecord g2 X^f}
                        {TellRecord f5 X^a^b^c^d}
                        X^a^b^c^d^e^f=X^f^e^d^c^b^a
                        {TellRecord g3 X^f^e}
                        {TellRecord f3 X^a^b}
                        {TellRecord f7 X^f^e^d^c^b^a}
                        {TellRecord g4 X^f^e^d}
                        {TellRecord f7 X^a^b^c^d^e^f}
                        {TellRecord f1 X}
                        {TellRecord f6 X^a^b^c^d^e}
                        {TellRecord f4 X^a^b^c}
                        {TellRecord f1 X}
                        {TellRecord f2 X^a}
                        {RFL X}='f1(a:f2(b:f3(c:f4(d:f5(e:f6(,,,  ...) ...) ...) ...) f:g2(e:g3(d:g4(c:g5(b:g6(,,,  ...) ...) ...) ...) ...)'
                     end)
            keys: [ofs record entailment])

        t36(entailed(proc {$}
                        X
                     in
                        {TellRecord g3 X^f^e}
                        {TellRecord f7 X^a^b^c^d^e^f}
                        {TellRecord g6 X^f^e^d^c^b}
                        {TellRecord g5 X^f^e^d^c}
                        {TellRecord f1 X}
                        {TellRecord g4 X^f^e^d}
                        {RFL X^f^e^d}='g4(c:g5(b:g6(...) ...) ...)'
                        {TellRecord f6 X^a^b^c^d^e}
                        {TellRecord f5 X^a^b^c^d}
                        X^a^b^c^d^e^f=X^f^e^d^c^b^a
                        {TellRecord f1 X}
                        {TellRecord f4 X^a^b^c}
                        {RFL X^a^b^c}='f4(d:f5(e:f6(f:f7(...) ...) ...) ...)'
                        {TellRecord g2 X^f}
                        {TellRecord f2 X^a}
                        {TellRecord f3 X^a^b}
                        {TellRecord f7 X^f^e^d^c^b^a}
                        {RFL X}='f1(a:f2(b:f3(c:f4(d:f5(e:f6(,,,  ...) ...) ...) ...) f:g2(e:g3(d:g4(c:g5(b:g6(,,,  ...) ...) ...) ...) ...)'
                     end)
            keys: [ofs record entailment])


        t37(entailed(proc {$}
                        X Y Z W Q
                     in
                        X^a=5 X^b=6 X^c=7 X^d=8
                        {TellRecord f X}
                        {RFL X}='f(a:5 b:6 c:7 d:8 ...)'

                        Y^e=10 Y^f=11 Y^g=12 Y^h=13 Y^i=14
                        {TellRecord f Y}
                        {RFL Y}='f(e:10 f:11 g:12 h:13 i:14 ...)'
                        X=Y
                        {RFL X}='f(a:5 b:6 c:7 d:8 e:10 f:11 g:12 h:13 i:14 ...)'

                        Z^aa=20 Z^ab=21 Z^ac=22 Z^ad=23 Z^ae=24
                        {TellRecord f Z}
                        {RFL Z}='f(aa:20 ab:21 ac:22 ad:23 ae:24 ...)'
                        X=Z
                        {RFL X}='f(a:5 aa:20 ab:21 ac:22 ad:23 ae:24 b:6 c:7 d:8 e:10 f:11 g:12 h:13 i:14 ...)'

                        W^ba=30 W^bb=31 W^bc=32 W^bd=33 W^be=34 W^bf=35 W^bg=36
                        {TellRecord f W}
                        {RFL W}='f(ba:30 bb:31 bc:32 bd:33 be:34 bf:35 bg:36 ...)'
                        X=W
                        {RFL X}='f(a:5 aa:20 ab:21 ac:22 ad:23 ae:24 b:6 ba:30 bb:31 bc:32 bd:33 be:34 bf:35 bg:36 c:7 d:8 e:10 f:11 g:12 h:13 i:14 ...)'

                        Q^q1=40 Q^q2=41  Q^q3=42  Q^q4=43
                        Q^q5=44  Q^q6=45  Q^q7=46  Q^q8=47
                        Q^q9=48 Q^q10=49 Q^q11=50 Q^q12=51
                        Q^q13=52 Q^q14=53 Q^q15=54 Q^q16=55
                        {TellRecord f Q}
                        {RFL Q}='f(q1:40 q10:49 q11:50 q12:51 q13:52 q14:53 q15:54 q16:55 q2:41 q3:42 q4:43 q5:44 q6:45 q7:46 q8:47 q9:48 ...)'

                        X=Q
                        {RFL X}='f(a:5 aa:20 ab:21 ac:22 ad:23 ae:24 b:6 ba:30 bb:31 bc:32 bd:33 be:34 bf:35 bg:36 c:7 d:8 e:10 f:11 g:12 h:13 i:14 q1:40 q10:49 q11:50 q12:51 q13:52 q14:53 q15:54 q16:55 q2:41 q3:42 q4:43 q5:44 q6:45 q7:46 q8:47 q9:48 ...)'

                     end)
            keys: [ofs record entailment])

        t38(entailed(proc {$}
                        A
                     in
                        {MAT A fun {$} foo(a:_ b:_ ...) end}
                        {MAT A fun {$} foo(b:_ a:_ ...) end}
                        {MAT A fun {$} foo(a:_ b:_ c:_ ...) end}
                        {MAT A fun {$} foo(c:_ b:_ a:_ ...) end}
                        {MAT A fun {$} foo(a:1 ...) end}
                        {MAF A fun {$} foo(a:2 ...) end}
                        {MAT A fun {$} foo(a:_ b:10 c:_ ...) end}
                        {MAT A fun {$} foo(c:_ b:10 a:_ ...) end}
                        {MAF A fun {$} foo(a:_ b:1 c:_ ...) end}
                        {MAF A fun {$} foo(c:_ b:1 a:_ ...) end}

                        A^b=10
                        A^a=1
                        {TellRecord foo A}
                        A^c=_
                     end)
            keys: [ofs record entailment])

        t39(entailed(proc {$}
                        A
                     in
                        {MAT A fun {$} foo(a:_ b:_ ...) end}
                        {MAT A fun {$} foo(b:_ a:_ ...) end}
                        {MAT A fun {$} foo(a:_ b:_ c:_ ...) end}
                        {MAT A fun {$} foo(c:_ b:_ a:_ ...) end}
                        {MAT A fun {$} foo(a:1 ...) end}
                        {MAF A fun {$} foo(a:2 ...) end}
                        {MAT A fun {$} foo(a:_ b:10 c:_ ...) end}
                        {MAT A fun {$} foo(c:_ b:10 a:_ ...) end}
                        {MAF A fun {$} foo(a:_ b:1 c:_ ...) end}
                        {MAF A fun {$} foo(c:_ b:1 a:_ ...) end}

                        A^b=10
                        A^a=1
                        {TellRecord foo A}
                        A^c=_
                        A=foo(a:_ b:_ c:_ d:_)
                     end)
            keys: [ofs record entailment])

        t40(entailed(proc {$}
                        A
                     in
                        {MAT A fun {$} foo(a:_ b:_ ...) end}
                        {MAT A fun {$} foo(b:_ a:_ ...) end}
                        {MAT A fun {$} foo(a:_ b:_ c:_ ...) end}
                        {MAT A fun {$} foo(c:_ b:_ a:_ ...) end}
                        {MAT A fun {$} foo(a:1 ...) end}
                        {MAF A fun {$} foo(a:2 ...) end}
                        {MAT A fun {$} foo(a:_ b:10 c:_ ...) end}
                        {MAT A fun {$} foo(c:_ b:10 a:_ ...) end}
                        {MAF A fun {$} foo(a:_ b:1 c:_ ...) end}
                        {MAF A fun {$} foo(c:_ b:1 a:_ ...) end}

                        A^b=10
                        A^a=1
                        {TellRecord foo A}
                        A^c=_
                        A=foo(a:_ b:_ c:_)
                     end)
            keys: [ofs record entailment])

        t41(entailed(proc {$}
                        A B C D
                        fun {T A}
                           [thread
                               cond A.a=12 A.b=13 then true
                               else false
                               end
                            end
                            thread
                               cond A.a=13 A.b=12 then true
                               else false
                               end
                            end
                            thread
                               cond A.a=12 A.b=12 then true
                               else false
                               end
                            end
                            thread
                               cond A.a=13 A.b=13 then true
                               else false
                               end
                            end

                            thread
                               cond A^a=12 A^b=13 then true
                               else false
                               end
                            end
                            thread
                               cond A^a=13 A^b=12 then true
                               else false
                               end
                            end
                            thread
                               cond A^a=12 A^b=12 then true
                               else false
                               end
                            end
                            thread
                               cond A^a=13 A^b=13 then true
                               else false
                               end
                            end]
                        end
                     in
                        {EQT {T A} [true false false false
                                    true false false false]}
                        A^a=12
                        A^b=13
                        {TellRecord foo A}
                        A=foo(a:_ b:_)

                        {EQT {T B} [false true false false
                                    false true false false]}
                        B^a=13
                        B^b=12
                        {TellRecord foo B}
                        B=foo(a:_ b:_)

                        {EQT {T C} [false false true false
                                    false false true false]}
                        C^a=12
                        C^b=12
                        {TellRecord foo C}
                        C=foo(a:_ b:_)

                        {EQT {T D} [false false false true
                                    false false false true]}
                        D^a=13
                        D^b=13
                        {TellRecord foo D}
                        D=foo(a:_ b:_)
                     end)
            keys: [ofs record entailment])

        t42(entailed(proc {$}
                        X L
                     in
                        X=foo(a:1 ...)
                        L={DA X}
                        {WP [a] L}
                        X^b=2 {WP [a b] L}
                        X^c=5 {WP [a b c] L}
                        X^d=7 {WP [a b c d] L}
                        X^h=9 {WP [a b c d h] L}
                        X=foo(b:_ c:_ d:_ a:_ h:_ i:11 j:13)
                        {WP [a b c d h i j] L}
                     end)
            keys: [ofs record arity])

        t43(entailed(proc {$}
                        A B C D I J K L
                     in
                        A=foo(1:1 2:2 ...)
                        B=foo(2:2 3:3 ...)
                        C=foo(4:1 5:4 6:5 7:6 8:7 9:8 10:9 ...)
                        D=foo(b:2 i:9 j:10 k:11 l:12 m:13 n:14 o:15 ...)
                        I={DA A}
                        J={DA B}
                        K={DA C}
                        L={DA D}
                        {WP [1 2] I}
                        {WP [2 3] J}
                        {WP [4 5 6 7 8 9 10] K}
                        {WP [b i j k l m n o] L}
                        A=B
                        {WP [1 2 3] I}
                        {WP [2 3 1] J}
                        B=C
                        {WP [1 2 3 4 5 6 7 8 9 10] I}
                        {WP [2 3 1 4 5 6 7 8 9 10] J}
                        {WP [4 5 6 7 8 9 10 1 2 3] K}
                        C=D
                        {WP [1 2 3 4 5 6 7 8 9 10 m j i o k n l b] I}
                        {WP [2 3 1 4 5 6 7 8 9 10 m j i o k n l b] J}
                        {WP [4 5 6 7 8 9 10 1 2 3 m j i o k n l b] K}
                        {WP [b i j k l m n o 1 2 3 4 5 6 7 8 9 10] L}
                        A={MakeRecord foo
                           [b i j k l m n o 1 2 3 4 5 6 7 8 9 10]}
                        {IsList I _}
                        {IsList J _}
                        {IsList K _}
                        {IsList L _}
                     end)
            keys: [ofs record arity])

        t44(entailed(proc {$}
                        X Y Z
                     in
                        X=foo(a:1 ...)
                        thread cond {DA X _} then skip end end
                        X=foo(a:1)

                        Y=foo(a:1 ...)
                        thread cond {DA Y _} then skip end end
                        Y=foo(a:1 b:2)

                        Z=foo(a:1 ...)
                        thread cond {DA Z _} then skip end end
                        Z^b=2
                        Z^a=1
                        Z=foo(a:1 b:2)
                     end)
            keys: [ofs record arity entailment])

        t45(entailed(proc {$}
                        A B
                     in
                        A={DA foo(a:1 b:2 c:3)}
                        {WP [a b c] A}

                        B={DA foo}
                        {Wait B}
                        B=nil
                     end)
            keys: [ofs record arity])

        t46(entailed(proc {$}
                        X F
                     in
                        F = {NewName}
                        X=foo(F:1 ...)
                        {WP [F] {DA X}}
                        X=foo(F:1)
                     end)
            keys: [ofs record arity])

        t47(entailed(proc {$}
                        local X K L in
                           {TellRecord foo X}
                           L={MA X K}
                           X^a=1 X^b=2
                           {WP [a b] L}
                           {K}
                           {WP [a b] L}
                           X^c=4 X^d=5 X^e=6
                           {Length L}=2
                        end
                        local X K L in
                           {TellRecord foo X}
                           L={MA X K}
                           {K}
                           X^f=1 X^g=2
                           X^h=4 X^i=5 X^j=6
                           {Length L}=0
                        end
                        local X K L in
                           {TellRecord foo X}
                           L={MA X K}
                           X^k=1 X^l=2
                           X^m=4 X^n=5 X^o=6
                           {WP [k l m n o] L}
                           {K}
                           {WP [k l m n o] L}
                           {Length L}=5
                        end
                        local X K L in
                           {TellRecord foo X}
                           L={MA X K}
                           X^a=1 X^b=2
                           {WP [a b] L}
                           {K}
                           {WP [a b] L}
                           X^c=4 X^d=5 X^e=6
                           X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
                           {Length L}=2
                        end
                     end)
            keys: [ofs record arity])

        t48(entailed(proc {$}
                        X Y A B K1 K2
                     in
                        {TellRecord foo X}
                        {TellRecord foo Y}
                        A={MA X K1}
                        B={MA Y K2}
                        X=foo(a:1 ...)
                        Y=foo(c:3 ...)
                        {WP [a] A}
                        {WP [c] B}
                        X=Y
                        {WP [a c] A}
                        {WP [c a] B}
                        X^f=6
                        {WP [a c f] A}
                        {WP [c a f] B}
                        X^g=7
                        {WP [a c f g] A}
                        {WP [c a f g] B}
                        {K1} {K2}
                     end)
            keys: [ofs record arity])

        t49(entailed(proc {$}
                        X Y K A B K
                     in
                        {TellRecord foo X}
                        {TellRecord foo Y}
                        A={MA X _}
                        B={MA Y K}
                        X=foo(b:2 ...)
                        Y=foo(e:5 ...)
                        {WP [b] A}
                        {WP [e] B}
                        X=Y
                        {WP [b e] A}
                        {WP [e b] B}
                        {K}
                        X^f=6
                        {WP [b e f] A}
                        {WP [e b]   B}
                        {Length B}=2
                        X={MakeRecord foo [b e f]}
                     end)
            keys: [ofs record arity])

        t50(entailed(proc {$}
                        local X Y F1 F2 F3 in
                           F1 = {NewName} F2 = {NewName} F3 = {NewName}
                           X=foo(a:1 F1:42 z:3 F2:42 p:5 ...)
                           Y=foo(F3:2 z:3 a:1 p:5 ...)
                           X=Y
                           {WP [a z p F1 F2 F3] {DA X}}
                           X={MakeRecord foo [a z p F1 F2 F3]}
                        end
                        local X Y A B in
                           {NewName A}
                           {NewName B}
                           X=foo(a:1 A:42 z:3 B:42 p:5 ...)
                           Y=foo(A:2 z:3 a:1 p:5 ...)
                           {EQF X Y}
                        end
                     end)
            keys: [ofs record name])

        t51(entailed(proc {$}
                        X W
                     in
                        W={FD.decl}
                        {TellRecord foo X}
                        {WidthC X W}
                        X^a=1
                        cond W>:0 then
                           X^b=2
                           cond W>:1 then
                              W<:4
                              {Label X foo}
                              W=2
                              {EQT X foo(a:1 b:2)}
                           end
                        end
                     end)
            keys: [ofs record fd width])

        t52(entailed(proc {$}
                        X W
                     in
                        W={FD.decl}
                        {TellRecord foo X}
                        {WidthC X W}
                        X^a=1
                        W<:3
                        cond W::1#2 then
                           W=2
                           {Label X foo}
                           X^b=2
                           {EQT X foo(a:1 b:2)}
                        end
                     end)
            keys: [ofs record fd width])

        t53(entailed(proc {$}
                        X
                     in
                        thread {EQT {Label X} foobar} end
                        {TellRecord foobar X}
                     end)
            keys: [ofs record])

        t54(entailed(proc {$}
                        X
                     in
                        X^axe=bijl
                        thread {EQT {Label X} foobar} end
                        {TellRecord foobar X}
                     end)
            keys: [ofs record])

        t55(entailed(proc {$}
                        X F
                     in
                        F::0#FD.sup
                        thread X^F=1 end
                        F=33333
                        {Wait {HasFeature X 33333}}
                     end)
            keys: [ofs record])

        %% test whether '==' on local ofs vars does not change them
        %% (used to fail test#13 occasionally);
        t56(entailed(proc {$}
                        Xs Ys Sync in
                        Xs^a = ok
                        Ys^b = ok
                        thread
                           Sync = unit
                           _ = Xs == Ys
                        end
                        {Wait Sync}
                        Xs = a(a: ok b: ko)
                        Ys = a(b: ok a: ko)
                     end)
            keys: [ofs record])

        %% raph: t57 to t62 check what happens when a unification
        %% fails with open feature records.  The behavior must reflect
        %% the incremental tell semantics.
        t57(entailed(proc {$}
                        X Y Res in
                        X = foo(...)
                        Y = bar
                        Res = try X=Y ko catch _ then ok end
                        Res = ok
                        {RFL X} = 'foo(...)'
                        Y = bar
                     end)
            keys: [ofs record])

        t58(entailed(proc {$}
                        X Y Res in
                        X = foo(...)
                        Y = bar(a)
                        Res = try X=Y ko catch _ then ok end
                        Res = ok
                        {RFL X} = 'foo(...)'
                        Y = bar(a)
                     end)
            keys: [ofs record])

        t59(entailed(proc {$}
                        X Y Res in
                        X = foo(...)
                        Y = bar(a:1)
                        Res = try X=Y ko catch _ then ok end
                        Res = ok
                        {RFL X} = 'foo(...)'
                        Y = bar(a:1)
                     end)
            keys: [ofs record])

        t60(entailed(proc {$}
                        X Y Res in
                        X = foo(a:1 ...)
                        Y = bar(b:2 ...)
                        Res = try X=Y ko catch _ then ok end
                        Res = ok
                        {Label X} = foo
                        X.a = 1
                        if {Member b {RecordC.reflectArity X}} then X.b = 2 end
                        {Label Y} = bar
                        Y.b = 2
                        if {Member a {RecordC.reflectArity Y}} then Y.a = 1 end
                     end)
            keys: [ofs record])

        t61(entailed(proc {$}
                        X Y Res in
                        X = foo(a:1 b:1 ...)
                        Y^a = _
                        Y^b = 2
                        Res = try X=Y ko catch _ then ok end
                        Res = ok
                        {RFL X} = 'foo(a:1 b:1 ...)'
                        if {RecordC.hasLabel Y} then {Label Y} = foo end
                        if {IsDet Y.a} then X.a = Y.a end
                        Y.b = 2
                     end)
            keys: [ofs record])

        t62(entailed(proc {$}
                        X Y Res in
                        X^a = 1
                        Y^a = 2
                        Res = try X=Y ko catch _ then ok end
                        Res = ok
                        {TellRecord foo X}
                        {RFL X} = 'foo(a:1 ...)'
                        if {RecordC.hasLabel Y} then {Label Y} = foo end
                        Y.a = 2
                     end)
            keys: [ofs record])
       ])

end
