
% See Hentenryck page 165
% we have tasks A, B, C etc. with start dates SA, SB etc., durations and precedence relations.
% Eg. task A with duration has to be scheduled before task B, thus SB >=' SA+'7

functor

import

   FD

   Search

export
   Return
define


   proc {BuildHouse Sol}
      Sol = [_ _ _ _ _ _ _ _ _ _ _ _]
      Sol = {FD.dom 0#30}
      {Precedence Sol}
      {FD.distribute ff Sol}
   end

   proc {GeqOff X Y Off}
      X >=: Y + Off
   end

   proc {Precedence [SA  SB  SC  SD  SE  SF  SG  SH  _  SJ  SK  Send]}
      {GeqOff SB SA 7}
      {GeqOff SD SA 7}
      {GeqOff SC SB 3}
      {GeqOff SE SC 1}
      {GeqOff SE SD 8}
      {GeqOff SG SC 1}
      {GeqOff SG SD 8}
      {GeqOff SF SD 8}
      {GeqOff SF SC 1}
      {GeqOff SH SF 1}
      {GeqOff SJ SH 3}
      {GeqOff SK SG 1}
      {GeqOff SK SE 2}
      {GeqOff SK SJ 2}
      {GeqOff Send SK 1}
      choice Send = {FD.reflect.min Send} end
   end

   BuildHouseSol =
   [[0 7 10 7 15 15 15 16 0 19 21 22]]
   Return=
   fd([buildhouse([
		   one(equal(fun {$} {Search.base.one BuildHouse} end
			     BuildHouseSol)
		       keys: [fd])
		   one_entailed(entailed(proc {$} {Search.base.one BuildHouse _} end)
		       keys: [fd entailed])
		  ])
      ])
   
   
end 
