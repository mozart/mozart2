%%
%% Author:
%%     Francois Fonteyn, 2014
%%

functor
import
   Application
   Tester at 'Tester.ozf'
define
   local
      fun {Fun} 1 end
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% Add tests from here...
                [A#B#C#D#E for A in 1..4 B in 11..13 if A+B<16 for C in 1 ; C<10 ; C+2 D in [1 2] E in 30..100 if A+B+C+D+E<100]
                #[1#11#1#1#30 1#11#3#2#31 2#12#1#1#30 2#12#3#2#31]

                [A#B#C#D#E#F for A in 1..4 B in 11..13 if A+B<16 for C in 1 ; C<10 ; C+2 D in [1 2] E in 30..100 if A+B+C+D+E<100 for F in 1..1]
                #[1#11#1#1#30#1 1#11#3#2#31#1 2#12#1#1#30#1 2#12#3#2#31#1]

                [A#B#C#D#E#F for A in 1..4 B in 11..13 if A+B<16
                                                          for C in 1 ; C<10 ; C+2 D in [1 2] E in 30..100 if A+B+C+D+E<100
                                                                                                             for F from Fun _ in 1..1]
                #[1#11#1#1#30#1 1#11#3#2#31#1 2#12#1#1#30#1 2#12#3#2#31#1]

                [[A AA B] for A in 1..100 AA in [1 0 3] if A == AA for B in [f o l o] if B \= l]
                #[[1 1 f] [1 1 o] [1 1 o] [3 3 f] [3 3 o] [3 3 o]]
                %% ...to here.
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end