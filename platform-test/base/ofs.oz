%%%
%%% Authors:
%%%   Peter Van Roy <pvr@info.ucl.ac.be>
%%%   Christian Schulte <schulte@dfki.de>
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
%declare
   fun {RFL X}
      {VirtualString.toAtom {System.valueToVirtualString X 5 20}}
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
              if X=Y then true else false end
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
      {WT thread if X={F} then true else false end end}
   end

   proc {MAF X F}
      {WF thread if X={F} then true else false end end}
   end

in

   ofs([t1(equal(fun {$}
                    X A T1 T2
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
                    X A
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
                    Y Y1 Y2
                    Z Z1 Z2 T1 T2
                 in
                    Y^foo=100 Y^bar=Y2
                    Z^foo=Z1 Y^bar=bonk
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
                    A A1 B B1
                 in
                    A=open(foo:10 bar:20 baz:30 zip:40 funk:50 all:A1)
                    B^foo=B1 B^all=60 B^baz=30
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
                          if C^big=10 then R=true else R=false end
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
                       X R1 R2 R3
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
                               if A in A^foo=23 X=A then true else false end
                            end}
                        X1=24
                     end)
            keys: [ofs record entailment])

        t19(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WT thread
                               if A in A^foo=23 X=A then true else false end
                            end}
                        X1=23
                     end)
            keys: [ofs record entailment])

        t20(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WF thread
                               if A in X=A A^foo=23 then true else false end
                            end}
                        X1=24
                     end)
            keys: [ofs record entailment])

        t21(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WT thread
                               if A in X=A A^foo=23 then true else false end
                            end}
                        X1=23
                     end)
            keys: [ofs record entailment])

        t22(entailed(proc {$}
                        X X1
                     in
                        X^foo=X1
                        {WF thread
                               if A in A^bar=100 A^foo=23 X=A then true
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
                               if A in A^bar=100 A^foo=23 X=A then true
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
                               if A in A^bar=100 A^foo=23 X=A then true
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
                               if A in A^bar=100 A^foo=23 X=A then true
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
                        X F Y G
                     in
                        thread X^F=2 end
                        thread X^G=6 end
                        F=f
                        G=g
                        if X^f=_ X^g=_ then {RFL X}='_(f:2 g:6 ...)'
                        else skip end
                        if X^f=_ then {RFL X^f}='2'
                        else skip end
                        if X^g=_ then {RFL X^g}='6'
                        else skip end
                     end)
            keys: [ofs record entailment])

        t28(entailed(proc {$}
                        X F Y G
                     in
                        thread X^F=2 end
                        thread X^G=6 end
                        F=f
                        G=g
                        if X^f=_ X^g=_ then {RFL X}='_(f:2 g:6 ...)'
                        else skip end
                        if X.f=_ X.g=_ then {RFL X}='_(f:2 g:6 ...)'
                        else skip end
                        if X^f=_ then {RFL X^f}='2'
                        else skip end
                        if X^g=_ then {RFL X^g}='6'
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
                        if A B in X^f=A X^g=B {Wait A} {Wait B} then
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
                        {WF if X^foo=_ X=cat(bar:_ baz:23) then true
                            else false
                            end}
                     end)
            keys: [ofs record entailment])

        t32(entailed(proc {$}
                        {WF if X in X^foo=_ X=cat(bar:_ baz:23) then true
                            else false
                            end}
                     end)
            keys: [ofs record entailment])

        t33(entailed(proc {$}
                        X Y Z
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

        t39(entailed(proc {$}
                        A B C D
                        fun {T A}
                           [thread
                               if A.a=12 A.b=13 then true
                               else false
                               end
                            end
                            thread
                               if A.a=13 A.b=12 then true
                               else false
                               end
                            end
                            thread
                               if A.a=12 A.b=12 then true
                               else false
                               end
                            end
                            thread
                               if A.a=13 A.b=13 then true
                               else false
                               end
                            end

                            thread
                               if A^a=12 A^b=13 then true
                               else false
                               end
                            end
                            thread
                               if A^a=13 A^b=12 then true
                               else false
                               end
                            end
                            thread
                               if A^a=12 A^b=12 then true
                               else false
                               end
                            end
                            thread
                               if A^a=13 A^b=13 then true
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

       ])
end


        /*



% Test of DynamicArity with '^':
proc {Test46 RFL Name} Name='test46'
   {RFL '*** test 46 ***'}
   local X L in
      X=foo(a:1 ...)
      {RFL X}
      L={DynamicArity X}
      {RFL L}
      X^b=2 {RFL X} {Wait L.2} {RFL L}
      X^c=5 {RFL X} {Wait L.2.2} {RFL L}
      X^d=7 {RFL X} {Wait L.2.2.2} {RFL L}
      X^h=9 {RFL X} {Wait L.2.2.2.2} {RFL L}
      X=foo(b:_ c:_ d:_ a:_ h:_ i:11 j:13) {RFL X}
      {Wait L.2.2.2.2.2.2.2}
   end
end

% Test of DynamicArity with unification:
proc {Test47 RFL Name} Name='test47'
   {RFL '*** test 47 ***'}
   local A B C D I J K L M in
      A=foo(1:1 2:2 ...)
      B=foo(2:2 3:3 ...)
      C=foo(4:1 5:4 6:5 7:6 8:7 9:8 10:9 ...)
      D=foo(b:2 i:9 j:10 k:11 l:12 m:13 n:14 o:15 ...)
      I={DynamicArity A}
      J={DynamicArity B}
      K={DynamicArity C}
      L={DynamicArity D}
      {RFL A} {RFL I}
      {RFL B} {RFL J}
      {RFL C} {RFL K}
      {RFL D} {RFL L}
      A=B {RFL A} {Wait I.2.2} {RFL I} {RFL B} {Wait J.2.2} {RFL J}
      B=C {RFL C} {Wait K.2.2.2.2.2.2.2.2} {RFL K}
      C=D {RFL D} M=L.2.2.2.2.2.2.2.2.2.2.2.2.2.2 {Wait M} {RFL L} % {RFL M}
   end
end

% A first test of entailment using DynamicArity:
proc {Test48 RFL Name} Name='test48'
   {RFL '*** test 48 ***'}
   local X Y Z in
      X=foo(a:1 ...)
      {RFL X}
      thread if {DynamicArity X _} then {RFL yes48x} else {RFL no48x} end end
      X=foo(a:1)

      Y=foo(a:1 ...)
      {RFL Y}
      thread if {DynamicArity Y _} then {RFL yes48y} else {RFL no48y} end end
      Y=foo(a:1 b:2)

      Z=foo(a:1 ...)
      {RFL Z}
      thread if {DynamicArity Z _} then {RFL yes48z} else {RFL no48z} end end
      Z^b=2
      Z^a=1
      Z=foo(a:1 b:2)
   end
end

% Test of unification of two OFS's
proc {Test49 RFL Name} Name='test49'
   {RFL '*** test 49 ***'}
   local X Y I J in
      X=foo(a:1 b:2 c:3 d:4 e:5 f:6 g:7 h:8 ...)
      Y=foo(g:7 h:8 i:9 j:10 k:11 l:12 m:13 n:14 ...)
      I={DynamicArity X} {RFL X} {RFL I}
      J={DynamicArity Y} {RFL Y} {RFL J}
      X=Y {RFL X} {RFL I} {RFL J}
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_ g:_ h:_ i:_ j:_ k:_ l:_ m:_ n:_)
      {RFL X} {RFL I} {RFL J}
   end
end

% Test that DynamicArity works for Literals and determined records
proc {Test50 RFL Name} Name='test50'
   {RFL '*** test 50 ***'}
   local A B in
      A={DynamicArity foo(a:1 b:2 c:3)}
      {RFL A}

      %% kost@ : an empty line must appear in the output;
      B={DynamicArity foo}
      {RFL B}
   end
end

% Test that DynamicArity works for Names and undetermined features
proc {Test51 RFL Name} Name='test51'
   {RFL '*** test 51 ***'}
   local X F L in
      {TellRecord foo51 X}
      X^a=1
      thread L={DynamicArity X} end
      {RFL L}
   end
   local X F L in
      %%!!! X=foo({NewName}:1 ...)
      F = {NewName}
      X=foo(F:1 ...)
      {RFL X}
   end
end

% Test that the Kill parameter works
proc {Test52 RFL Name} Name='test52'
   {RFL '*** test 52 ***'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      X^a=1 X^b=2
      K=1
      X^c=4 X^d=5 X^e=6
      {Wait L.2.2} {RFL L} {RFL X}
   end
   {RFL '*a*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      K=1
      X^f=1 X^g=2
      X^h=4 X^i=5 X^j=6
      {Wait L} {RFL L} {RFL X}
   end
   {RFL '*b*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      X^k=1 X^l=2
      X^m=4 X^n=5 X^o=6
      K=1
      {Wait L.2.2.2.2.2} {RFL L} {RFL X}
   end
   {RFL '*c*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      X^a=1 X^b=2
      K=1
      X^c=4 X^d=5 X^e=6
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      {Wait {IsList L}} {RFL L} {RFL X}
   end
   {RFL '*d*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      K=1
      X^a=1 X^b=2
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      X^c=4 X^d=5 X^e=6
      {Wait {IsList L}} {RFL L} {RFL X}
   end
   {RFL '*e*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      X^a=1 X^b=2
      X^c=4 X^d=5 X^e=6
      K=1
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      {Wait {IsList L}} {RFL L} {RFL X}
   end
   {RFL '*f*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      X^a=1 X^b=2
      X^c=4 X^d=5 X^e=6
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      K=1
      {Wait {IsList L}} {RFL L} {RFL X}
   end
   {RFL '*g*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {RFL L} {RFL X}
      K=1
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      X^a=1 X^b=2
      X^c=4 X^d=5 X^e=6
      {Wait {IsList L}} {RFL L} {RFL X}
   end
end

% Test that unifying two OFS works well with DynamicArity
proc {Test53 RFL Name} Name='test53'
   {RFL '*** test 53 ***'}
   local X Y K A B in
      {TellRecord foo X}
      {TellRecord foo Y}
      A={DynamicArityCancel X _}
      B={DynamicArityCancel Y _}
      X=foo(a:1 ...)
      Y=foo(c:3 ...)
      {RFL X} {Wait A} {RFL A} {RFL Y} {Wait B} {RFL B}
      X=Y
      {RFL X} {Wait A.2} {RFL A} {RFL Y} {Wait B.2} {RFL B}
      X^f=6
      {RFL X} {Wait A.2.2} {RFL A} {RFL Y} {Wait B.2.2} {RFL B}
      X^g=7
      {RFL X} {Wait A.2.2.2} {RFL A} {RFL Y} {Wait B.2.2.2} {RFL B}
   end
end

% Test that unifying two OFS works well when one's DA is killed
proc {Test54 RFL Name} Name='test54'
   {RFL '*** test 54 ***'}
   local X Y K A B K in
      {TellRecord foo X}
      {TellRecord foo Y}
      A={DynamicArityCancel X _}
      B={DynamicArityCancel Y K}
      X=foo(b:2 ...)
      Y=foo(e:5 ...)
      {RFL X} {Wait A} {RFL A} {RFL Y} {Wait B} {RFL B}
      X=Y
      {RFL X} {Wait A.2} {RFL A} {RFL Y} {Wait B.2} {RFL B}
      K=1
      X^f=6
      {RFL X} {Wait A.2.2} {RFL A} {RFL Y}
      {Wait {IsList B}} {RFL B}
   end
end

% Test that combinations of names and features are RFLn correctly:
proc {Test55 RFL Name} Name='test55'
   {RFL '*** test 55 ***'}
   local X Y F1 F2 F3 in
      F1 = {NewName} F2 = {NewName} F3 = {NewName}
      X=foo(a:1 F1:42 z:3 F2:42 p:5 ...)
      {RFL X}
      Y=foo(F3:2 z:3 a:1 p:5 ...)
      {RFL Y}
   end
   local X Y A B in
      {NewName A}
      {NewName B}
      X=foo(a:1 A:42 z:3 B:42 p:5 ...)
      {RFL X}
      Y=foo(A:2 z:3 a:1 p:5 ...)
      {RFL Y}
   end
end


proc {Test58 RFL Name} Name='test58'
   {RFL '*** test 58 ***'}
   local X W B1 B2 B3 B4 in
      {FD.int 0#FD.sup W}
      {TellRecord foo X}
      {WidthC X W}
      X^a=1
      {Wait {FD.is W}} {RFL W} {RFL X}
      {FD.reflect.min W B1}
      X^b=2
      {WaitShrink W} {RFL W} {RFL X}
      W<:4 {RFL W} {RFL X}
      {Label X foo} {RFL W} {RFL X}
      W=2 {RFL W} {Wait X} {RFL X}
   end
end

proc {Test59 RFL Name} Name='test59'
   {RFL '*** test 59 ***'}
   local X W in
      {FD.int 0#FD.sup W}
      {TellRecord foo X}
      {WidthC X W}
      X^a=1
      X^b=2 {WaitShrink W}
      W<:4
      W=2
      {RFL W} {RFL X}
      {Label X foo}
      {RFL W} {Wait X} {RFL X}
   end
end

proc {Test60 RFL Name} Name='test60'
   {RFL '*** test 60 ***'}
   local X W in
      {FD.int 0#FD.sup W}
      {TellRecord foo X}
      {WidthC X W}
      X^a=1 W=2
      {RFL W} {RFL X}
      {Label X foo}
      {RFL W} {RFL X}
      X^b=2
      {RFL W} {Wait X} {RFL X}
   end
end

proc {Test61 RFL Name} Name='test61'
   {RFL '*** test 61 ***'}
   local X W in
      X^a=1 W=2
      {RFL W} {RFL X}
      {TellRecord foo X}
      {RFL W} {RFL X}
      X^b=2
      {RFL W} {RFL X}
      {WidthC X W}
      {RFL W} {Wait X} {RFL X}
   end
end

% Tests 62 to 68 test WidthC with various argument types:
% UVAR with all widths:
proc {Test62 RFL Name} Name='test62'
   {RFL '*** test 62 ***'}
   local X1 X2 X3 X4 X5 W1 W2 W in
      {TellRecord foo X1}
      {WidthC X1 W} W::1#100
      thread if {WidthC X2 56789} then {RFL yes62} else {RFL no62} end end
      X2=foo(a:1 b:2 c:3)
      {TellRecord foo X3}
      {WidthC X3 5}
      {TellRecord foo X4}
      {WidthC X4 W1}
      thread if {Wait W2} then {RFL W2} end end
      {TellRecord foo X5}
      {WidthC X5 W2}
   end
end

% SVAR with all widths:
proc {Test63 RFL Name} Name='test63'
   {RFL '*** test 63 ***'}
   local X1 X2 X3 X4 X5 W1 W2 W in
      thread if {Wait X1} then {RFL X1} end end
      thread if {Wait X2} then {RFL X2} end end
      thread if {Wait X3} then {RFL X3} end end
      thread if {Wait X4} then {RFL X4} end end
      thread if {Wait X5} then {RFL X5} end end
      {TellRecord foo X1}
      {WidthC X1 W} W::1#100
      X2=foo(a:1 b:2 c:3)
      thread if {WidthC X2 56789} then {RFL yes63} else {RFL no63} end end
      {TellRecord foo X3}
      {WidthC X3 5}
      {TellRecord foo X4}
      {WidthC X4 W1}
      thread if {Wait W2} then {RFL W2} end end
      {TellRecord foo X5}
      {WidthC X5 W2}
   end
end

% OFS with all widths:
proc {Test64 RFL Name} Name='test64'
   {RFL '*** test 64 ***'}
   local W1 W2 W in
      {WidthC foo(a:1 ...) W} W::1#100
      thread if {WidthC foo(a:1 b:2 c:4 d:5 ...) 2} then {RFL yes64} else {RFL no64} end end
      {WidthC foo(a:1 ...) 5}
      {WidthC foo(a:1 ...) W1}
      thread if {Wait W2} then {RFL W2} end end
      {WidthC foo(a:1 ...) W2}
   end
end

% SRecord with all widths:
proc {Test65 RFL Name} Name='test65'
   {RFL '*** test 65 ***'}
   local W1 W2 W in
      {WidthC foo(a:1) W} W::1#100
      if {WidthC foo(a:1) 789} then {RFL yes65} else {RFL no65} end
      if {WidthC foo(a:1) 5} then {RFL yes65} else {RFL no65} end
      {WidthC foo(a:1) W1}
      thread if {Wait W2} then {RFL W2} end end
      {WidthC foo(a:1) W2}
   end
end

% Literal with all widths:
proc {$}
   local W1 W2 W in
      W::0#100 {WidthC foo W}
      if {WidthC foo 456789} then {RFL yes66} else {RFL no66} end
      if {WidthC foo 5} then {RFL yes66} else {RFL no66} end
      {WidthC foo W1}
      thread if {Wait W2} then {RFL W2} end end
      {WidthC foo W2}
   end
end

% All records with literal width: (failure everywhere)
proc {$}
   local X1 X2 in
      if {WidthC foo(a:1 ...) {Id bar}} then {RFL yes68} else {RFL no68} end
      if {WidthC foo(a:1) {Id bar}} then {RFL yes68} else {RFL no68} end
      if {WidthC foo {Id bar}} then {RFL yes68} else {RFL no68} end
      {TellRecord foo X1}
      if {WidthC X1 {Id bar}} then {RFL yes68} else {RFL no68} end
      thread if {Wait X2} then {RFL X2} end end
      {TellRecord foo2 X2}
      if {WidthC X2 {Id bar}} then {RFL yes68} else {RFL no68} end
   end
end

% WidthC used for entailment checking:
proc {$}
   local X W in
      thread if {WidthC X W} then {RFL yes69a} else {RFL no69a} end end
      X=foo(a:1 b:2 ...)
      W=2
      X=foo(b:2 a:1)
   end
   local X W in
      thread if {WidthC X W} then {RFL yes69b} else {RFL no69b} end end
      X=foo(a:1 b:2 ...)
      W=2
      X=foo(b:2 a:1 c:3)
   end
   local X W in
      W = {FD.decl}
      thread if {WidthC X W} then {RFL yes69c} else {RFL no69c} end end
      X=foo(a:1 b:2 ...) X=foo(b:2 a:1)
      W>:2
   end
   local X W in
      thread if {WidthC X W} then {RFL yes69d} else {RFL no69d} end end
      X=foo(a:1 b:2 ...) X=foo(b:2 a:1)
      W>:2
      W::1#1000
   end
end

proc {$}
   X
in
   thread {RFL {Label X}} end
   {TellRecord foobar X}
end

proc {$}
   X
in
   X^axe=bijl
   thread {RFL {Label X}} end
   {TellRecord foobar X}
end

proc {$}
   X F
in
   F::0#FD.sup
   thread X^F=1 end
   F=33333
   {Wait {HasFeature X 33333}}
   {RFL X}
end

*/
