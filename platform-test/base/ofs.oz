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

   fun {RFL X}
      {VirtualString.toAtom {System.valueToVirtualString X 20 20}}
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
                       {Wait R}
                       R=true
                    end)
           keys: [ofs record entailment])

        t6(entailed(proc {$}
                       D E D1 E1 R
                    in
                       D^left=D1 E^left=E1
                       thread
                          R = if D=E then true else false end
                       end
                       D1=10
                       E1=20
                       {Wait R}
                       R=false
                    end)
           keys: [ofs record entailment])

        t7(entailed(proc {$}
                       D E R
                    in
                       D^left=10 E^right=20
                       R = thread
                              if D=E then true else false end
                           end
                       D = E
                       {Wait R}
                       R = true
                    end)
           keys: [ofs record entailment])

        t8(entailed(proc {$}
                       X R1 R2
                    in
                       X^foo=10
                       thread
                          R1=if X=open(foo:10 bar:20) then true else false end
                       end
                       thread
                          R2=if X=open(foo:10 bar:20) then true else false end
                       end
                       X=open(foo:_ bar:20)
                       {Wait R1}
                       R1 = true
                       {Wait R2}
                       R2 = true
                    end)
           keys: [ofs record entailment])

        t9(entailed(proc {$}
                       X R1 R2 R3
                    in
                       X^foo=10
                       thread
                          R1=if X=open(foo:10 bar:20) then true else false end
                       end
                       thread
                          R2=if X=open(foo:10 bar:20) then true else false end
                       end
                       thread
                          R3=if X=open(foo:10 bar:20) then true else false end
                       end
                       X=open(foo:_ bar:30)
                       {Wait R1}
                       R1 = false
                       {Wait R2}
                       R2 = false
                       {Wait R3}
                       R3 = false
                    end)
           keys: [ofs record entailment])

        t10(entailed(proc {$}
                        X R1 R2 R3 R4
                     in
                        X^foo=10
                        thread
                           R1=if X=open(foo:10) then true else false end
                        end
                        thread
                           R2=if X=open(foo:20) then true else false end
                        end
                        thread
                           R3=if X=open(foo:30) then true else false end
                        end
                        thread
                           R4=if X=open(foo:10) then true else false end
                        end
                        X=open(foo:_)
                        {Wait R1} R1=true
                        {Wait R2} R2=false
                        {Wait R3} R3=false
                        {Wait R4} R4=true
                     end)
            keys: [ofs record entailment])

        t11(entailed(proc {$}
                        X Y R
                     in
                        {TellRecord two Y}
                        X^foo=10 Y^bar=20
                        thread
                           R=if X=Y then true else false end
                        end
                        {TellRecord two X}
                        {RFL X}='two(foo:10 ...)'
                        {RFL Y}='two(bar:20 ...)'
                        X=Y
                        {Wait R}
                        R=true
                     end)
            keys: [ofs record entailment])
       ])
end


        /*

proc {Test11 Show Name} Name='test11'
   {Show '*** test 11 ***'}
   local X Y in
      X^foo=10 Y^bar=20
      {TellRecord man X}
      {TellRecord man Y}
      thread if X=Y then {Show ja11} else {Show nein11} end end
      {Show X} {Show Y}
      X^baz=23
      local Z in
         Y^baz=Z
         Z=24
      end
      {Show X} {Show Y}
   end
end


proc {Test12 Show Name} Name='test12'
   {Show '*** test 12 ***'}
   local X Y in
      X^foo=10 Y^bar=20
      thread if X=Y then {Show ja12} else {Show nein12} end end
      X^baz=23
      X^zip=10
      X^cat=10
      Y^bing=100
      {TellRecord ahab X}
      {TellRecord ahab Y}
      {Show X} {Show Y}
      X=Y
      {Show X} {Show Y}
   end
end


proc {Test13 Show Name} Name='test13'
   {Show '*** test 13 ***'}
   local X Y D in
      {TellRecord open X}
      X^foo=X
      {Show X}
      X=open(foo:_)
      {Show X}
   end
end


proc {Test14 Show Name} Name='test14'
   {Show '*** test 14 ***'}
   local X Y D in
      X^foo=Y Y^bar=X
      thread if X=Y then {Show yes14} else {Show no14} end end
      X=Y
   end
end


proc {Test15 Show Name} Name='test15'
   {Show '*** test 15 ***'}
   local X Y D in
      X^foo=Y X^bar=10 Y^foo=X Y^zip=20
      thread if X=Y then {Show yes15} else {Show no15} end end
      X=Y
   end
end


proc {Test15_1 Show Name} Name='test15.1'
   {Show '*** test 15.1 ***'}
   local X Y D in
      X^foo=X X^bar=10 Y^foo=Y Y^zip=20
      thread if X=Y then {Show yes151} else {Show no151} end end
      X^axe=10
      Y^axe=11
   end
end


proc {Test16_1 Show Name} Name='test16.1'
   {Show '*** test 16.1 ***'}
   local X X1 in
      X^foo=X1
      thread if A in A^foo=23 X=A then {Show yes161} else {Show no161} end end
      X1=24
   end
end


proc {Test16_2 Show Name} Name='test16.2'
   {Show '*** test 16.2 ***'}
   local X X1 in
      X^foo=X1
      thread if A in A^foo=23 X=A then {Show yes162} else {Show no162} end end
      X1=23
   end
end


proc {Test16_3 Show Name} Name='test16.3'
   {Show '*** test 16.3 ***'}
   local X X1 in
      X^foo=X1
      thread if A in X=A A^foo=23 then {Show yes163} else {Show no163} end end
      X1=23
   end
end


proc {Test16_4 Show Name} Name='test16.4'
   {Show '*** test 16.4 ***'}
   local X X1 in
      X^foo=X1
      thread if A in X=A A^foo=23 then {Show yes164} else {Show no164} end end
      X1=24
   end
end


proc {Test16_5 Show Name} Name='test16.5'
   {Show '*** test 16.5 ***'}
   local X X1 in
      X^foo=X1
      thread
         if A in A^bar=100 X=A A^foo=23
         then {Show yes165}
         else {Show no165}
         end
      end
      X1=23
      X^bar=101
   end
end


proc {Test16_6 Show Name} Name='test16.6'
   {Show '*** test 16.6 ***'}
   local X X1 in
      X^foo=X1
      thread
         if A in A^bar=100 X=A A^foo=23
         then {Show yes166}
         else {Show no166}
         end
      end
      X1=23
      X^bar=100
   end
end


proc {Test16_7 Show Name} Name='test16.7'
   {Show '*** test 16.7 ***'}
   local X X1 in
      X^foo=X1 X^bar=100
      thread if A in X=A A^foo=23 then {Show yes167} else {Show no167} end end
      X1=23
   end
end


proc {Test17 Show Name} Name='test17'
   {Show '*** test 17 ***'}
   local X Y in
      X^foo=10 Y^bar=20
      thread if X=Y then {Show ja} else {Show nein} end end
      X=Y
      X=open(foo:_ bar:_)
      {Show X}
   end
end


proc {Test18 Show Name} Name='test18'
   {Show '*** test 18 ***'} % Gert's first bug discovery
   local X F Y G in
      thread X^F=2 end
      thread X^G=6 end
      F=f
      G=g
      if X^f=_ X^g=_ then {Show X} else skip end
      if X^f=_ then {Show X^f} else skip end
      if X^g=_ then {Show X^g} else skip end
   end
end


proc {Test19 Show Name} Name='test19'
   {Show '*** test 19 ***'}
   local X F Y G in
      thread X^F=2 end
      thread X^G=6 end
      G=g
      F=f
      if X.f=_ X.g=_ then {Show X} else skip end
      if X^f=_ X^g=_ then {Show X} else skip end
      if X^f=_ then {Show X^f} else skip end
      if X^g=_ then {Show X^g} else skip end
   end
end


proc {Test20 Show Name} Name='test20'
   {Show '*** test 20 ***'}
   local X F G H in
      thread
         X^F=2
         X^G=6
         X^H=24
      end
      G=g
      H=h
      F=f
      if X^f=_ X^g=_ X^h=_ then
         {Show X}
         {Show X^f}
         {Show X^g}
         {Show X^h}
      else skip end
   end
end


proc {Test21 Show Name} Name='test21'
   {Show '*** test 21 ***'}
   local X F G in
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
         {Show X^f}
         {Show X^g}
      else skip end
   end
end


proc {Test22 Show Name} Name='test22'
   {Show '*** test 22 ***'}
   local X F G H in
      thread
         {TellRecord banzai X}
         {MyTell X F 2}
         {MyTell X G 6}
         {MyTell X H 24}
      end
      F=f
      H=h
      G=g
      X^h=_
      X^f=_
      X^g=_
      if A B C in {TWait A} X^g=B {TWait B} {TWait C} X^f=A X^h=C then
         {Show X^f}
         {Show X^g}
         {Show X^h}
      else skip end
   end
end


proc {Test23 Show Name} Name='test23'
   {Show '*** test 23 ***'}
   local X F G H in
      {MyTell X F 2} {MyTell X F 2} {MyTell X F 2}
      {MyTell X G 6} {MyTell X G 6} {MyTell X G 6}
      {TellRecord banzai X}
      {MyTell X H 24} {MyTell X H 24} {MyTell X H 24}
      {Show X}
      F=f F=f F=f
      H=h H=h H=h
      G=g G=g G=g
      X^h=_ X^h=_ X^h=_
      X^f=_ X^f=_ X^f=_
      X^g=_ X^g=_ X^g=_
      if A B C in {TWait A} {TWait B} X^f=C {TWait C} X^h=A X^g=B then
         {Show X^f}
         {Show X^g}
         {Show X^h}
      else skip end
   end
end


proc {Test24 Show Name} Name='test24'
   {Show '*** test 24 ***'}
   local X F G H in
      {MyTell X F 2} {MyTell X F 2} {MyTell X F 2}
      {TellRecord bingo X}
      {MyTell X G 6} {MyTell X G 6} {MyTell X G 6}
      {MyTell X H 24} {MyTell X H 24} {MyTell X H 24}
      {Show X}
      F=f
      H=h
      G=g
      X^h=_
      X^f=_
      X^g=_
      if A B C in X^g=B {TWait A} {TWait B} {TWait C} X^h=A X^g=B X^f=C then
         {Show X^f}
         {Show X^g}
         {Show X^h}
      else skip end
   end
end

proc {Test25 Show Name} Name='test25'
   {Show '*** test 25 ***'}
   local X Y in
      X^a=1 X^b=2 X^c=3 X^d=4 X^e=5 X^f=6 X^g=7 X^h=8 X^i=9
      {TellRecord big X}
      {TellRecord big Y}
      Y^q=10 Y^r=11 Y^s=12 Y^t=13 Y^u=14 Y^v=15 Y^w=16 Y^x=17
      {Show X}
      {Show Y}
      X=Y
      {Show X}
      {Show Y}
      X=big(a:_ b:_ c:_ d:_ e:_ f:_ g:_ h:_ i:_ j:_ q:_ r:_ s:_ t:_ u:_ v:_ w:_ x:_ y:_)
      X.j=999
      X.y=888
      {Show X}
      {Show Y}
   end
end

proc {Test26 Show Name} Name='test26'
   {Show '*** test 26 ***'}
   local X S1 S2 S3 S4 in
      X^foo=100
      {Sync 1  S1 proc {$} if X=cat(foo:_ bar:_) then {Show yes26a} else {Show no26a} end end}
      {Sync S1 S2 proc {$} if X^bar=_ then {Show yes26b} else {Show no26b} end end}
      {Sync S2 S3 proc {$} if Y in Y^baz=23 X=Y then {Show yes26c} else {Show no26c} end end}
      {Sync S3 S4 proc {$} if Y in Y^baz=24 X=Y then {Show yes26d} else {Show no26d} end end}
      {Sync S4 _  proc {$} if X^bonk=_ then {Show yes26e} else {Show no26e} end end}
      X=cat(foo:_ bar:44 baz:23)
      {Show X}
   end
end

proc {Test27 Show Name} Name='test27'
   {Show '*** test 27 ***'}
   local X in
      if X^foo=_ X=cat(bar:_ baz:23) then
         {Show yes27a}
      else
         {Show no27a}
      end
   end
end

proc {Test28 Show Name} Name='test28'
   {Show '*** test 28 ***'}
   local F X S1 S2 S3 S4 S5 in
      F={NewName}
      {Sync 1  S1 proc {$} if X^F=11 then {Show yes28a} else {Show no28a} end end}
      {Sync S1 S2 proc {$} if X^F=10 then {Show yes28b} else {Show no28b} end end}
      {Sync S2 S3 proc {$} if X=boo(F:_ bar:_) then {Show yes28c} else {Show no28c} end end}
      {Sync S3 S4 proc {$} if X=boo(F:_) then {Show yes28d} else {Show no28d} end end}
      {Sync S4 S5 proc {$} if X=boo(F:10) then {Show yes28e} else {Show no28e} end end}
      {Sync S5 _  proc {$} if X=boo(F:11) then {Show yes28f} else {Show no28f} end end}
      X^F=10
      X={Id boo(F:_)}
      if X^F=11 then {Show yes28g} else {Show no28g} end
      if X^F=10 then {Show yes28h} else {Show no28h} end
      if X=boo(F:_ bar:_) then {Show yes28i} else {Show no28i} end
      if X=boo(F:_) then {Show yes28j} else {Show no28j} end
      if X=boo(F:10) then {Show yes28k} else {Show no28k} end
      if X=boo(F:11) then {Show yes28l} else {Show no28l} end
   end
end

proc {Test29 Show Name} Name='test29'
   {Show '*** test 29 ***'}
   local F G H X Y Z in
      F={NewName} G={NewName} H={NewName}
      X^F=a X^G=a X^H=a X^{NewName}=a
      {TellRecord t29 X}
      {Label X Z}
      {Show X}
      {Label X Y}
      {Show 1#Y}
      case {IsLiteral Z} then {Show 2#Z} end
   end
end

proc {Test30 Show Name} Name='test30'
   {Show '*** test 30 ***'}
   local
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
      {Show X}
      {Show Y}
      X=Y
      {Show X}
   end
end

proc {Test31 Show Name} Name='test31'
   {Show '*** test 31 ***'}
   local
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
      {Show X}
   end
end

proc {Test32 Show Name} Name='test32'
   {Show '*** test 32 ***'}
   local
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
      {Show X}
   end
end


proc {Test33 Show Name} Name='test33'
   {Show '*** test 33 ***'}
   local
      X
   in
      {TellRecord g3 X^f^e}
      {TellRecord f7 X^a^b^c^d^e^f}
      {TellRecord g6 X^f^e^d^c^b}
      {TellRecord g5 X^f^e^d^c}
      {TellRecord f1 X}
      {TellRecord g4 X^f^e^d}
      {Show X^f^e^d}
      {TellRecord f6 X^a^b^c^d^e}
      {TellRecord f5 X^a^b^c^d}
      X^a^b^c^d^e^f=X^f^e^d^c^b^a
      {TellRecord f1 X}
      {TellRecord f4 X^a^b^c}
      {Show X^a^b^c}
      {TellRecord g2 X^f}
      {TellRecord f2 X^a}
      {TellRecord f3 X^a^b}
      {TellRecord f7 X^f^e^d^c^b^a}
      {Show X}
   end
end


proc {Test34 Show Name} Name='test34'
   {Show '*** test 34 ***'}
   local
      X Y S1 S2 S3 S4 S5 S6 S7
   in
      {Sync 1 S1 proc {$}
         if {Wait X} then {Show yes34a} else {Show no34a} end
      end}
      {Sync S1 S2 proc {$}
         if
            if {Wait X} then fail else skip end
         then {Show yes34b}
         else {Show no34b}
         end
      end}
      {Sync S2 S3 proc {$}
         if {Wait X} then {Show yes34c} else {Show no34c} end
      end}
      {Sync S3 S4 proc {$}
         if
            if {Wait X} then fail else skip end
         then {Show yes34d}
         else {Show no34d}
         end
      end}
      Y=basketball
      {TellRecord Y X}
      X^Y=Y
      {Sync S4 S5 proc {$}
                     if A in thread {Wait A} end {Label X A} then {Show 1#X} end
                  end}
      {Sync S5 S6 proc {$}
                     if A in {Label X A} {Wait A} then {Show 2#X} end
      end}
      X=Y(Y:Y)
      {Sync S6 S7 proc {$}
         {Show X}
      end}
   end
end


proc {Test35 Show Name} Name='test35'
   {Show '*** test 35 ***'}
   local
      X Y Z A B C
      proc {TypeEnum X Y}
         thread case {IsRecord X} then {Show yesclrecord#Y} else {Show noclrecord#Y} end end
         thread case {IsAtom X} then {Show yesatom#Y} else {Show noatom#Y} end end
         thread case {IsLiteral X} then {Show yesliteral#Y} else {Show noliteral#Y} end end
         thread case {IsTuple X} then {Show yestuple#Y} else {Show notuple#Y} end end
         thread case {IsRecordC X} then {Show yesanyrecord#Y} else {Show noanyrecord#Y} end end
         thread case {IsName X} then {Show yesname#Y} else {Show noname#Y} end end
         thread case {IsInt X} then {Show yesint#Y} else {Show noint#Y} end end
         thread case {IsFloat X} then {Show yesfloat#Y} else {Show nofloat#Y} end end
         thread case {IsNumber X} then {Show yesnumber#Y} else {Show nonumber#Y} end end
         thread case {IsChunk X} then {Show yeschunk#Y} else {Show nochunk#Y} end end
         thread case {IsProcedure X} then {Show yesprocedure#Y} else {Show noprocedure#Y} end end
         thread case {IsCell X} then {Show yescell#Y} else {Show nocell#Y} end end
      end

   in
      {TypeEnum X 1}
      X^big=small

      {TypeEnum A 2}
      A^big=small
      A=foo(big:_)

      {TypeEnum Y 4}
      {TellRecord foo Y}
   end
end


%
proc {Test36 Show Name} Name='test36'
   {Show '*** test 36 ***'}
   local
      X1 Y1 X2 Y2 X3 Y3 X4 Y4 X5 Y5 X6 Y6 X7 Y7 X8 Y8
      S1 S2 S3 S4 S5 S6 S7 S8
   in
      {Sync 1 S1 proc {$} if X1=a then {Show yes36a} else {Show no36a} end end}
      X1^foo=_

      {Sync S1 S2 proc {$} if X2=b then {Show yes36b} else {Show no36b} end end}
      Y2=c
      {TellRecord Y2 X2}

      {Sync S2 S3 proc {$} if X3=b then {Show yes36c} else {Show no36c} end end}
      X3^foo=_
      Y3=c
      {TellRecord Y3 X3}

      {Sync S3 S4 proc {$} if X4=b(a:_) then {Show yes36d} else {Show no36d} end end}
      X4^a=_
      Y4=c
      {TellRecord Y4 X4}
      if {Wait {Label X4}} then {Show X4} end

      {Sync S4 S5 proc {$} if X5=b(a:_) then {Show yes36e} else {Show no36e} end end}
      thread {TellRecord X5 Y5} end
      X5=c

      S5=S6

      thread {TellRecord Y7 X7} end
      {Sync S6 S7 proc {$} if X7=b then {Show yes36g} else {Show no36g} end end}
      Y7=b
      X7=Y7

      thread {TellRecord Y8 X8} end
      {Sync S7 _  proc {$} if X8=b then {Show yes36h} else {Show no36h} end end}
      Y8=b
      X8^a=_
   end
end


% Some bigger unifications
proc {Test37 Show Name} Name='test37'
   {Show '*** test 37 ***'}
   local X Y Z W Q
   in
      X^a=5 X^b=6 X^c=7 X^d=8
      {TellRecord f X}
      {Show X}

      Y^e=10 Y^f=11 Y^g=12 Y^h=13 Y^i=14
      {TellRecord f Y}
      {Show Y}
      X=Y
      {Show X}

      Z^aa=20 Z^ab=21 Z^ac=22 Z^ad=23 Z^ae=24
      {TellRecord f Z}
      {Show Z}
      X=Z
      {Show X}

      W^ba=30 W^bb=31 W^bc=32 W^bd=33 W^be=34 W^bf=35 W^bg=36
      {TellRecord f W}
      {Show W}
      X=W
      {Show X}

      Q^q1=40 Q^q2=41  Q^q3=42  Q^q4=43  Q^q5=44  Q^q6=45  Q^q7=46  Q^q8=47
      Q^q9=48 Q^q10=49 Q^q11=50 Q^q12=51 Q^q13=52 Q^q14=53 Q^q15=54 Q^q16=55
      {TellRecord f Q}
      {Show Q}
      X=Q
      {Show X}
   end
end

proc {Test38 Show Name} Name='test38'
   {Show '*** test 38 ***'}
   local X Y in
      thread if X^a=_ then {Show yes38a} else {Show no38a} end end
      thread if X^b=_ then {Show yes38b} else {Show no38b} end end
      thread if X^c=_ X^g=_ then {Show yes38c} else {Show no38c} end end
      {TellRecord foo X}
      {Show X}
      thread if X^d=_ X^h=_ X^i=_ then {Show yes38d} else {Show no38d} end end
      {Show X}
      thread if X^e=_ then {Show yes38e} else {Show no38e} end end
      {Show X}
      thread if X^f=_ then {Show yes38f} else {Show no38f} end end
      {Show X}
      X^i=9 {Show X}
      X^h=9 {Show X}
      X^g=9 {Show X}
      X^f=9 {Show X}
      X^e=9 {Show X}
      X^d=9 {Show X}
      Y^c=9 Y^b=9 Y^a=9
      {TellRecord foo Y}
      {Show Y}
      Y=X
      {Show X}
   end
end

proc {Test39 Show Name} Name='test39'
   {Show '*** test 39 ***'}
   local A B C D in
      thread if A=foo(a:_ b:_ ...) then {Show yes39a} else {Show no39a} end end
      thread if A=foo(b:_ a:_ ...) then {Show yes39b} else {Show no39b} end end
      thread if A=foo(a:_ b:_ c:_ ...) then {Show yes39c} else {Show no39c} end end
      thread if A=foo(c:_ b:_ a:_ ...) then {Show yes39d} else {Show no39d} end end
      thread if A=foo(a:1 ...) then {Show yes39e} else {Show no39e} end end
      thread if A=foo(a:2 ...) then {Show yes39f} else {Show no39f} end end
      A^b=10
      A^a=1
      {TellRecord foo A}
      A^c=_

      {TellRecord foo B}
      thread if B=foo(a:_ b:_ ...) then {Show yes39a2} else {Show no39a2} end end
      thread if B=foo(b:_ a:_ ...) then {Show yes39b2} else {Show no39b2} end end
      thread if B=foo(a:_ b:_ c:_ ...) then {Show yes39c2} else {Show no39c2} end end
      thread if B=foo(c:_ b:_ a:_ ...) then {Show yes39d2} else {Show no39d2} end end
      thread if B=foo(a:1 ...) then {Show yes39e2} else {Show no39e2} end end
      thread if B=foo(a:2 ...) then {Show yes39f2} else {Show no39f2} end end
      B^b=10
      B^a=1
      B=foo(a:_ b:_)
   end
end

proc {Test40 Show Name} Name='test40'
   {Show '*** test 40 ***'}
   local A B C D
      proc {T A B}
         thread if A.a=12 A.b=13 then {Show yes40a23#B} else {Show no40a23#B} end end
         thread if A.a=13 A.b=12 then {Show yes40a32#B} else {Show no40a32#B} end end
         thread if A.a=13 A.b=12 then {Show yes40a32#B} else {Show no40a32#B} end end
         thread if A.a=13 A.b=13 then {Show yes40a33#B} else {Show no40a33#B} end end
         thread if A.a=13 A.b=13 then {Show yes40a33#B} else {Show no40a33#B} end end
         thread if A.a=12 A.b=12 then {Show yes40a22#B} else {Show no40a22#B} end end
         thread if A.a=12 A.b=12 then {Show yes40a22#B} else {Show no40a22#B} end end
         thread if A.a=12 A.b=13 then {Show yes40a23#B} else {Show no40a23#B} end end
         thread if A^a=12 A^b=13 then {Show yes40a23hat#B} else {Show no40a23hat#B} end end
         thread if A^a=13 A^b=12 then {Show yes40a32hat#B} else {Show no40a32hat#B} end end
         thread if A^a=13 A^b=12 then {Show yes40a32hat#B} else {Show no40a32hat#B} end end
         thread if A^a=13 A^b=13 then {Show yes40a33hat#B} else {Show no40a33hat#B} end end
         thread if A^a=13 A^b=13 then {Show yes40a33hat#B} else {Show no40a33hat#B} end end
         thread if A^a=12 A^b=12 then {Show yes40a22hat#B} else {Show no40a22hat#B} end end
         thread if A^a=12 A^b=12 then {Show yes40a22hat#B} else {Show no40a22hat#B} end end
         thread if A^a=12 A^b=13 then {Show yes40a23hat#B} else {Show no40a23hat#B} end end
      end
   in
      {T A 1}
      A^a=12
      A^b=12
      {TellRecord foo A}
      A=foo(a:_ b:_)

      {T B 2}
      B^a=12
      B^b=12
      {TellRecord foo B}

      {T C 3}
      C^a=12
      C^b=12

      {T D 4}
      D^a=12
   end
end

proc {Test41 Show Name} Name='test41'
   {Show '*** test 41 ***'}
   local X Y Z in
      thread if {TellRecord foo X} then {Show yes41a} else {Show no41a} end end
      thread if X^bar=10 {TellRecord foo X} then {Show yes41b} else {Show no41b} end end
      thread if {TellRecord foo X} X^bar=10 then {Show yes41c} else {Show no41c} end end
      thread if X^bar=10 then {Show yes41d} else {Show no41d} end end
      thread if X^bar=10 {TellRecord foo X} X^bar=10 then {Show yes41e} else {Show no41e} end end
      thread if {TellRecord foo X} X^bar=10 {TellRecord foo X} then {Show yes41f} else {Show no41f} end end

      thread if {TellRecord foo X} X.bar=10 then {Show yes41z1} else {Show no41z1} end end
      thread if X.bar=10 then {Show yes41z2} else {Show no41z2} end end
      thread if {TellRecord foo X} then {Show yes41z3} else {Show no41z3} end end

      {TellRecord foo X}
      X^bar=Y
      Y=10

      thread if {TellRecord foo Z} {TellRecord bar Z} then {Show yes41g} else {Show no41g} end end
      thread if Z in {TellRecord foo Z} {TellRecord bar Z} then {Show yes41h} else {Show no41h} end end
   end
   % local A B C in
   %    thread if {Label A B} then {Show yes41i} else {Show no41i} end end
   % end
end

proc {Test42 Show Name} Name='test42'
   {Show '*** test 42 ***'}
   local A B C in
      thread {Adjoin A B C} end
      {TellRecord foo A}
      {TellRecord bar B}
      {Show A} {Show B}
      A=foo(a:10 b:20)
      B=bar(b:30 c:40)
      {Show A} {Show B}
      if {Wait C} then {Show 1#C} end
   end
   local A B C in
      {TellRecord foo A}
      thread {Adjoin A B C} end
      % {Label A foo}
      {TellRecord bar B}
      {Show A} {Show B}
      A=foo(a:10 b:20)
      B=bar(b:30 c:40)
      {Show A} {Show B}
      if {Wait C} then {Show 2#C} end
   end
   local A B C in
      {TellRecord bar B}
      thread {Adjoin A B C} end
      {TellRecord foo A}
      {Show A} {Show B}
      A=foo(a:10 b:20)
      B=bar(b:30 c:40)
      {Show A} {Show B}
      if {Wait C} then {Show 3#C} end
   end
end

proc {Test43 Show Name}
   S1 S2
in
   Name='test43'
   {Show '*** test 43 ***'}
   local X Y Z in
      {Label foo1 X}
      {Show X}
      {Label foo2(a:12 b:23) Y}
      {Show Y}
      {Label foo3(a:_ b:_ ...) Z}
      {Show Z}
   end
   local A B C in
      B^a=1 B^b=2
      thread {Label B}=A end
      {TellRecord foo4 B}
      {Sync S1 _ proc {$} if {Wait A} then {Show A} end end}
      {Show B}
   end
   local A B C in
      {TellRecord foo5 B}
      {Label B A}
      {Show A}
      {Show B}
   end
   local A B C in
      thread {Label B A} end
      {TellRecord foo6 B}
      {Sync 1 S1 proc {$} if {Wait A} then {Show A} end end}
      {Show B}
   end
end

proc {Test44 Show Name}
   S1 S2 S3 S4 S5 S6 S7
in
   Name='test44'
   {Show '*** test 44 ***'}
   local A B C in
      thread {Label B A} end
      B^a=3 B^b=4
      {TellRecord foo1 B}
      {Sync 1 S1 proc {$} if {Wait A} then {Show A} end end}
      {Sync S1 S2 proc {$} if {Wait {Label B}} then {Show B} end end}
   end
   local A B C in
      B^a=5 B^b=6 thread {Label B}=A end
      {Sync S2 S3 proc {$} if {Wait A} then {Show A} end end}
      {Sync S3 S4 proc {$} if {Wait {Label B}} then {Show B} end end}
      {TellRecord foo2 B}
   end
   local A B C in
      B^a=7 B^b=8
      thread {Label B A} end
      {TellRecord foo3 B}
      {Sync S4 S5 proc {$} if {Wait A} then {Show A} end end}
      {Sync S5 S6 proc {$} if {Wait {Label B}} then {Show B} end end}
   end
   local X4 Y4 in
      thread {TellRecord Y4 X4} end
      X4^a=9
      Y4=c
      {Sync S6 S7 proc {$} if {Wait {Label X4}} then {Show X4} end end}
   end
end

proc {Test45 Show Name} Name='test45'
   {Show '*** test 45 ***'}
   local H C S1 S2 in
      {TellRecord h H}
      {Sync 1 S1 proc {$} thread H.subcat=1 end end} {Show H}
      H^cat=c {Show H}
      H^subcat=1 {Show H}
      H=h(cat:_ subcat:_ dog:3) {Show H}

      C^cat=1 {TellRecord c C} {Show C}
      {Sync S1 S2 proc {$} thread C.subcat=nil end end} {Show C}
      C=c(cat:_ subcat:_ dog:3)
      {Wait C.subcat} {Show C}
   end
end

% Test of DynamicArity with '^':
proc {Test46 Show Name} Name='test46'
   {Show '*** test 46 ***'}
   local X L in
      X=foo(a:1 ...)
      {Show X}
      L={DynamicArity X}
      {Show L}
      X^b=2 {Show X} {Wait L.2} {Show L}
      X^c=5 {Show X} {Wait L.2.2} {Show L}
      X^d=7 {Show X} {Wait L.2.2.2} {Show L}
      X^h=9 {Show X} {Wait L.2.2.2.2} {Show L}
      X=foo(b:_ c:_ d:_ a:_ h:_ i:11 j:13) {Show X}
      {Wait L.2.2.2.2.2.2.2}
   end
end

% Test of DynamicArity with unification:
proc {Test47 Show Name} Name='test47'
   {Show '*** test 47 ***'}
   local A B C D I J K L M in
      A=foo(1:1 2:2 ...)
      B=foo(2:2 3:3 ...)
      C=foo(4:1 5:4 6:5 7:6 8:7 9:8 10:9 ...)
      D=foo(b:2 i:9 j:10 k:11 l:12 m:13 n:14 o:15 ...)
      I={DynamicArity A}
      J={DynamicArity B}
      K={DynamicArity C}
      L={DynamicArity D}
      {Show A} {Show I}
      {Show B} {Show J}
      {Show C} {Show K}
      {Show D} {Show L}
      A=B {Show A} {Wait I.2.2} {Show I} {Show B} {Wait J.2.2} {Show J}
      B=C {Show C} {Wait K.2.2.2.2.2.2.2.2} {Show K}
      C=D {Show D} M=L.2.2.2.2.2.2.2.2.2.2.2.2.2.2 {Wait M} {Show L} % {Show M}
   end
end

% A first test of entailment using DynamicArity:
proc {Test48 Show Name} Name='test48'
   {Show '*** test 48 ***'}
   local X Y Z in
      X=foo(a:1 ...)
      {Show X}
      thread if {DynamicArity X _} then {Show yes48x} else {Show no48x} end end
      X=foo(a:1)

      Y=foo(a:1 ...)
      {Show Y}
      thread if {DynamicArity Y _} then {Show yes48y} else {Show no48y} end end
      Y=foo(a:1 b:2)

      Z=foo(a:1 ...)
      {Show Z}
      thread if {DynamicArity Z _} then {Show yes48z} else {Show no48z} end end
      Z^b=2
      Z^a=1
      Z=foo(a:1 b:2)
   end
end

% Test of unification of two OFS's
proc {Test49 Show Name} Name='test49'
   {Show '*** test 49 ***'}
   local X Y I J in
      X=foo(a:1 b:2 c:3 d:4 e:5 f:6 g:7 h:8 ...)
      Y=foo(g:7 h:8 i:9 j:10 k:11 l:12 m:13 n:14 ...)
      I={DynamicArity X} {Show X} {Show I}
      J={DynamicArity Y} {Show Y} {Show J}
      X=Y {Show X} {Show I} {Show J}
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_ g:_ h:_ i:_ j:_ k:_ l:_ m:_ n:_)
      {Show X} {Show I} {Show J}
   end
end

% Test that DynamicArity works for Literals and determined records
proc {Test50 Show Name} Name='test50'
   {Show '*** test 50 ***'}
   local A B in
      A={DynamicArity foo(a:1 b:2 c:3)}
      {Show A}

      %% kost@ : an empty line must appear in the output;
      B={DynamicArity foo}
      {Show B}
   end
end

% Test that DynamicArity works for Names and undetermined features
proc {Test51 Show Name} Name='test51'
   {Show '*** test 51 ***'}
   local X F L in
      {TellRecord foo51 X}
      X^a=1
      thread L={DynamicArity X} end
      {Show L}
   end
   local X F L in
      %%!!! X=foo({NewName}:1 ...)
      F = {NewName}
      X=foo(F:1 ...)
      {Show X}
   end
end

% Test that the Kill parameter works
proc {Test52 Show Name} Name='test52'
   {Show '*** test 52 ***'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      X^a=1 X^b=2
      K=1
      X^c=4 X^d=5 X^e=6
      {Wait L.2.2} {Show L} {Show X}
   end
   {Show '*a*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      K=1
      X^f=1 X^g=2
      X^h=4 X^i=5 X^j=6
      {Wait L} {Show L} {Show X}
   end
   {Show '*b*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      X^k=1 X^l=2
      X^m=4 X^n=5 X^o=6
      K=1
      {Wait L.2.2.2.2.2} {Show L} {Show X}
   end
   {Show '*c*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      X^a=1 X^b=2
      K=1
      X^c=4 X^d=5 X^e=6
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      {Wait {IsList L}} {Show L} {Show X}
   end
   {Show '*d*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      K=1
      X^a=1 X^b=2
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      X^c=4 X^d=5 X^e=6
      {Wait {IsList L}} {Show L} {Show X}
   end
   {Show '*e*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      X^a=1 X^b=2
      X^c=4 X^d=5 X^e=6
      K=1
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      {Wait {IsList L}} {Show L} {Show X}
   end
   {Show '*f*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      X^a=1 X^b=2
      X^c=4 X^d=5 X^e=6
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      K=1
      {Wait {IsList L}} {Show L} {Show X}
   end
   {Show '*g*'}
   local X K L in
      {TellRecord foo X}
      L={DynamicArityCancel X K}
      {Show L} {Show X}
      K=1
      X=foo(a:_ b:_ c:_ d:_ e:_ f:_)
      X^a=1 X^b=2
      X^c=4 X^d=5 X^e=6
      {Wait {IsList L}} {Show L} {Show X}
   end
end

% Test that unifying two OFS works well with DynamicArity
proc {Test53 Show Name} Name='test53'
   {Show '*** test 53 ***'}
   local X Y K A B in
      {TellRecord foo X}
      {TellRecord foo Y}
      A={DynamicArityCancel X _}
      B={DynamicArityCancel Y _}
      X=foo(a:1 ...)
      Y=foo(c:3 ...)
      {Show X} {Wait A} {Show A} {Show Y} {Wait B} {Show B}
      X=Y
      {Show X} {Wait A.2} {Show A} {Show Y} {Wait B.2} {Show B}
      X^f=6
      {Show X} {Wait A.2.2} {Show A} {Show Y} {Wait B.2.2} {Show B}
      X^g=7
      {Show X} {Wait A.2.2.2} {Show A} {Show Y} {Wait B.2.2.2} {Show B}
   end
end

% Test that unifying two OFS works well when one's DA is killed
proc {Test54 Show Name} Name='test54'
   {Show '*** test 54 ***'}
   local X Y K A B K in
      {TellRecord foo X}
      {TellRecord foo Y}
      A={DynamicArityCancel X _}
      B={DynamicArityCancel Y K}
      X=foo(b:2 ...)
      Y=foo(e:5 ...)
      {Show X} {Wait A} {Show A} {Show Y} {Wait B} {Show B}
      X=Y
      {Show X} {Wait A.2} {Show A} {Show Y} {Wait B.2} {Show B}
      K=1
      X^f=6
      {Show X} {Wait A.2.2} {Show A} {Show Y}
      {Wait {IsList B}} {Show B}
   end
end

% Test that combinations of names and features are shown correctly:
proc {Test55 Show Name} Name='test55'
   {Show '*** test 55 ***'}
   local X Y F1 F2 F3 in
      F1 = {NewName} F2 = {NewName} F3 = {NewName}
      X=foo(a:1 F1:42 z:3 F2:42 p:5 ...)
      {Show X}
      Y=foo(F3:2 z:3 a:1 p:5 ...)
      {Show Y}
   end
   local X Y A B in
      {NewName A}
      {NewName B}
      X=foo(a:1 A:42 z:3 B:42 p:5 ...)
      {Show X}
      Y=foo(A:2 z:3 a:1 p:5 ...)
      {Show Y}
   end
end

% Test equality/disequality of OFS's:
proc {Test56 Show Name} Name='test56'
   {Show '*** test 56 ***'}
   local X Y F1 F2 in
      %%!!! X=foo({NewName}:1 {NewName}:2 a:3 b:4 c:5 ...)
      F1 = {NewName} F2 = {NewName}
      X=foo(F1:1 F2:2 a:3 b:4 c:5 ...)
      X^{NewName}=6
      X^{NewName}=7
      Y=foo(f:1 g:2 h:3 ...)
      X^aa=1
      Y^aa=2
      if X=Y then {Show yes56a} else {Show no56a} end
   end
   local X Y F1 F2 in
      %%!!! X=foo({NewName}:1 {NewName}:2 a:3 b:4 c:5 ...)
      F1 = {NewName} F2 = {NewName}
      X=foo(F1:1 F2:2 a:3 b:4 c:5 ...)
      X^{NewName}=6
      X^{NewName}=7
      Y=foo(f:1 g:2 h:3 ...)
      thread if X=Y then {Show yes56b} else {Show no56b} end end
      X^aa=1
      Y^aa=2
   end
   local X Y F1 F2 in
      %%!!! X=foo({NewName}:1 {NewName}:2 a:3 b:4 c:5 ...)
      F1 = {NewName} F2 = {NewName}
      X=foo(F1:1 F2:2 a:3 b:4 c:5 ...)
      X^{NewName}=6
      X^{NewName}=7
      Y=foo(f:1 g:2 h:3 ...)
      thread if X=Y then {Show yes56c} else {Show no56c} end end
      X=Y
   end
   local X Y F1 F2 in
      %%!!! X=foo({NewName}:1 {NewName}:2 a:3 b:4 c:5 ...)
      F1 = {NewName} F2 = {NewName}
      X=foo(F1:1 F2:2 a:3 b:4 c:5 ...)
      X^{NewName}=6
      X^{NewName}=7
      Y=foo(f:1 g:2 h:3 ...)
      X=Y
      if X=Y then {Show yes56d} else {Show no56d} end
   end
end

% Test of the constrained sort hierarchy
proc {Test57 Show Name} Name='test57'
   {Show '*** test 57 ***'}
   local
      proc {PersonCode X}    X::[1 2 3 4 5 6] end
      proc {StudentCode X}   X::[1       5  ] end
      proc {EmployeeCode X}  X::[1 2 3 4    ] end
      proc {StaffCode X}     X::[1   3      ] end
      proc {FacultyCode X}   X::[  2        ] end
      proc {WorkstudyCode X} X::[1          ] end

      proc {StudentDemon X}
         thread if {StudentCode X^code} then
            X=sort(advisor:{NewFaculty} roommate:{NewPerson} ...)
         else skip end end
      end

      proc {FacultyDemon X}
         thread if {FacultyCode X^code} then
            X=sort(secretary:{NewStaff} assistant:{NewPerson} ...)
         else skip end end
      end

      proc {Demons X}
         {FacultyDemon X}
         {StudentDemon X}
      end

      proc {NewPerson X}    X=sort(code:{PersonCode} ...)    {Demons X} end
      proc {NewStudent X}   X=sort(code:{StudentCode} ...)   {Demons X} end
      proc {NewEmployee X}  X=sort(code:{EmployeeCode} ...)  {Demons X} end
      proc {NewStaff X}     X=sort(code:{StaffCode} ...)     {Demons X} end
      proc {NewFaculty X}   X=sort(code:{FacultyCode} ...)   {Demons X} end
      proc {NewWorkstudy X} X=sort(code:{WorkstudyCode} ...) {Demons X} end
   in
      local E S in
         E={NewEmployee}
         S={NewStudent}
         {Wait {IsRecordC S.advisor}}
         {Show S}
         {Show E}
         S=E
         % Demons not activated immediately
         % (How do I get them to run?)
         % Doesn't work: {SearchOne proc {$ X} X={NewEmployee}={NewStudent} end A}
         %               {{A.1} X}
         {Show E}
      end
   end
end

proc {Test58 Show Name} Name='test58'
   {Show '*** test 58 ***'}
   local X W B1 B2 B3 B4 in
      {FD.int 0#FD.sup W}
      {TellRecord foo X}
      {WidthC X W}
      X^a=1
      {Wait {FD.is W}} {Show W} {Show X}
      {FD.reflect.min W B1}
      X^b=2
      {WaitShrink W} {Show W} {Show X}
      W<:4 {Show W} {Show X}
      {Label X foo} {Show W} {Show X}
      W=2 {Show W} {Wait X} {Show X}
   end
end

proc {Test59 Show Name} Name='test59'
   {Show '*** test 59 ***'}
   local X W in
      {FD.int 0#FD.sup W}
      {TellRecord foo X}
      {WidthC X W}
      X^a=1
      X^b=2 {WaitShrink W}
      W<:4
      W=2
      {Show W} {Show X}
      {Label X foo}
      {Show W} {Wait X} {Show X}
   end
end

proc {Test60 Show Name} Name='test60'
   {Show '*** test 60 ***'}
   local X W in
      {FD.int 0#FD.sup W}
      {TellRecord foo X}
      {WidthC X W}
      X^a=1 W=2
      {Show W} {Show X}
      {Label X foo}
      {Show W} {Show X}
      X^b=2
      {Show W} {Wait X} {Show X}
   end
end

proc {Test61 Show Name} Name='test61'
   {Show '*** test 61 ***'}
   local X W in
      X^a=1 W=2
      {Show W} {Show X}
      {TellRecord foo X}
      {Show W} {Show X}
      X^b=2
      {Show W} {Show X}
      {WidthC X W}
      {Show W} {Wait X} {Show X}
   end
end

% Tests 62 to 68 test WidthC with various argument types:
% UVAR with all widths:
proc {Test62 Show Name} Name='test62'
   {Show '*** test 62 ***'}
   local X1 X2 X3 X4 X5 W1 W2 W in
      {TellRecord foo X1}
      {WidthC X1 W} W::1#100
      thread if {WidthC X2 56789} then {Show yes62} else {Show no62} end end
      X2=foo(a:1 b:2 c:3)
      {TellRecord foo X3}
      {WidthC X3 5}
      {TellRecord foo X4}
      {WidthC X4 W1}
      thread if {Wait W2} then {Show W2} end end
      {TellRecord foo X5}
      {WidthC X5 W2}
   end
end

% SVAR with all widths:
proc {Test63 Show Name} Name='test63'
   {Show '*** test 63 ***'}
   local X1 X2 X3 X4 X5 W1 W2 W in
      thread if {Wait X1} then {Show X1} end end
      thread if {Wait X2} then {Show X2} end end
      thread if {Wait X3} then {Show X3} end end
      thread if {Wait X4} then {Show X4} end end
      thread if {Wait X5} then {Show X5} end end
      {TellRecord foo X1}
      {WidthC X1 W} W::1#100
      X2=foo(a:1 b:2 c:3)
      thread if {WidthC X2 56789} then {Show yes63} else {Show no63} end end
      {TellRecord foo X3}
      {WidthC X3 5}
      {TellRecord foo X4}
      {WidthC X4 W1}
      thread if {Wait W2} then {Show W2} end end
      {TellRecord foo X5}
      {WidthC X5 W2}
   end
end

% OFS with all widths:
proc {Test64 Show Name} Name='test64'
   {Show '*** test 64 ***'}
   local W1 W2 W in
      {WidthC foo(a:1 ...) W} W::1#100
      thread if {WidthC foo(a:1 b:2 c:4 d:5 ...) 2} then {Show yes64} else {Show no64} end end
      {WidthC foo(a:1 ...) 5}
      {WidthC foo(a:1 ...) W1}
      thread if {Wait W2} then {Show W2} end end
      {WidthC foo(a:1 ...) W2}
   end
end

% SRecord with all widths:
proc {Test65 Show Name} Name='test65'
   {Show '*** test 65 ***'}
   local W1 W2 W in
      {WidthC foo(a:1) W} W::1#100
      if {WidthC foo(a:1) 789} then {Show yes65} else {Show no65} end
      if {WidthC foo(a:1) 5} then {Show yes65} else {Show no65} end
      {WidthC foo(a:1) W1}
      thread if {Wait W2} then {Show W2} end end
      {WidthC foo(a:1) W2}
   end
end

% Literal with all widths:
proc {Test66 Show Name} Name='test66'
   {Show '*** test 66 ***'}
   local W1 W2 W in
      W::0#100 {WidthC foo W}
      if {WidthC foo 456789} then {Show yes66} else {Show no66} end
      if {WidthC foo 5} then {Show yes66} else {Show no66} end
      {WidthC foo W1}
      thread if {Wait W2} then {Show W2} end end
      {WidthC foo W2}
   end
end

% All records with literal width: (failure everywhere)
proc {Test68 Show Name} Name='test68'
   {Show '*** test 68 ***'}
   local X1 X2 in
      if {WidthC foo(a:1 ...) {Id bar}} then {Show yes68} else {Show no68} end
      if {WidthC foo(a:1) {Id bar}} then {Show yes68} else {Show no68} end
      if {WidthC foo {Id bar}} then {Show yes68} else {Show no68} end
      {TellRecord foo X1}
      if {WidthC X1 {Id bar}} then {Show yes68} else {Show no68} end
      thread if {Wait X2} then {Show X2} end end
      {TellRecord foo2 X2}
      if {WidthC X2 {Id bar}} then {Show yes68} else {Show no68} end
   end
end

% WidthC used for entailment checking:
proc {Test69 Show Name} Name='test69'
   {Show '*** test 69 ***'}
   local X W in
      thread if {WidthC X W} then {Show yes69a} else {Show no69a} end end
      X=foo(a:1 b:2 ...)
      W=2
      X=foo(b:2 a:1)
   end
   local X W in
      thread if {WidthC X W} then {Show yes69b} else {Show no69b} end end
      X=foo(a:1 b:2 ...)
      W=2
      X=foo(b:2 a:1 c:3)
   end
   local X W in
      W = {FD.decl}
      thread if {WidthC X W} then {Show yes69c} else {Show no69c} end end
      X=foo(a:1 b:2 ...) X=foo(b:2 a:1)
      W>:2
   end
   local X W in
      thread if {WidthC X W} then {Show yes69d} else {Show no69d} end end
      X=foo(a:1 b:2 ...) X=foo(b:2 a:1)
      W>:2
      W::1#1000
   end
end

proc {Test70 Show Name}
   X
in
   Name='test70'
   {Show '*** test 70 ***'}
   thread {Show {Label X}} end
   {TellRecord foobar X}
end

proc {Test71 Show Name}
   X
in
   Name='test71'
   {Show '*** test 71 ***'}
   X^axe=bijl
   thread {Show {Label X}} end
   {TellRecord foobar X}
end

proc {Test72 Show Name}
   X F
in
   Name='test72'
   {Show '*** test 72 ***'}
   F::0#FD.sup
   thread X^F=1 end
   F=33333
   {Wait {HasFeature X 33333}}
   {Show X}
end

*/
