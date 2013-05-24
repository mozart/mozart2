functor

import

   FD

   Search

export
   Return
define


% From Constraint Satisfaction using CLP, AI 58(1992), 113-159
% Assembly line with 10 slots. 10 cars out of 6 classes.
% 5 production units providing a certain option.
% Each unit has a capacity, eg. 2 of 3: of 3 consecutive slots at
%   most 2 may afford this unit (option).



   local StateDomains OutOf SumUp StateCapacityConstraints
      StateDemandConstraints StateLinkConstraints StateSurrogates in

      proc {StateDomains Slots Options NbSlots NbClasses NbOptions}
	 {FD.list NbSlots 1#NbClasses Slots}
	 {MakeTuple a NbOptions*NbSlots Options}
	 {Record.forAll Options proc {$ X} X :: 0#1 end}
      end

% Implements R out of S for option Option
% in S consecutive slots at most R can have option Option
% Ops is the option tuple
% Ops_i^j:  slot i requires option j; Ops.(j-1)*NbSlots+i
% O11, O21, O31, O41, O12, O22, O32, O42 etc. for 4 slots
      proc {OutOf R S Ops NbSlots Option}
	 local From To in
	    From = (Option-1)*NbSlots + 1
	    To = (Option-1)*NbSlots + NbSlots - (S-1)
	    {For From To 1 proc{$ C} {SumUp Ops C C+S-1} =<: R end}
	 end
      end

% Ops.From + Ops.(From+1) + ... + Ops.To = Res
      proc {SumUp Ops From To Res}
	 {Loop.forThread From To 1 proc{$ In Index Out}
				      Out :: 0#FD.sup
				      Out=:In+Ops.Index
				   end 0 Res}
      end

% OptionInfo.1 = R#S#O|...  R outof S  from option O
      proc {StateCapacityConstraints Options NbSlots OptionInfo}

	 {ForAll OptionInfo proc{$ X} local R S O in !X=R#S#O {OutOf R S Options NbSlots O} end end}
      end

      local GetNumber in
	 fun{GetNumber CarInfo OpInfo}
	    case OpInfo#CarInfo 
	    of (H|R)#((_#Nb)|T) then cond H=1 
				     then Nb+{GetNumber T R} 
				     else {GetNumber T R} 
				     end
	    [] nil#nil then 0
	    end
	 end
% p cars require option j. 
% O1j+...+O(nbslots-s)j >= p-r
	 proc {StateSurrogates Options NbSlots OptionInfo2 OptionInfo1 CarInfo}
	    case OptionInfo2#OptionInfo1
	    of (H2|T2)#((R#S#O)|T1) 
	    then local P in 
	   % P = number of cars requiring option coded by H2
		    P= {GetNumber CarInfo H2}  
		    {For 1 NbSlots div S 1
		     proc{$ K} local From To in
				  From = (O-1)*NbSlots+1
				  To = (O-1)*NbSlots+NbSlots-K*S
				  {SumUp Options From To} >=: P-K*R 
			       end
		     end}
		    {StateSurrogates Options NbSlots T2 T1 CarInfo}
		 end
	    else skip
	    end
	 end
      end   


% CarInfo = C#Nb|...;  Nb cars from class C
      proc {StateDemandConstraints Slots CarInfo}
	 {ForAll CarInfo proc{$ X} local C Nb in X=C#Nb {FD.atMost Nb Slots C} end end}
      end


% OptionInfo = [1 0 0 0 1 1]|...;   Option ? is required by classes 1,4,5
      proc {StateLinkConstraints Slots Options NbSlots OptionInfo}
	 {List.forAllInd Slots proc{$ SC Slot}
				  {List.forAllInd OptionInfo proc{$ OC OI}
								{FD.element Slot OI Options.((OC-1)*NbSlots+SC)}
							     end} 
			       end}
      end


      proc {StateConstraints Slots NbSlots NbOptions NbClasses OptionInfo CarInfo}
	 local Options in 
	    {StateDomains Slots Options NbSlots NbClasses NbOptions}
	    {StateCapacityConstraints Options NbSlots OptionInfo.1}
	    {StateDemandConstraints Slots CarInfo}
	    {StateLinkConstraints Slots Options NbSlots OptionInfo.2}
	    {StateSurrogates Options NbSlots OptionInfo.2 OptionInfo.1 CarInfo}
	    {FD.distribute ff Slots}
	    {FD.distribute ff Options}
	 end
      end

      CarsSol =
      [[1 2 6 3 5 4 4 5 3 6]]
   end % of local


   OutOfInfo = [1#2#1 2#3#2 1#3#3 2#5#4 1#5#5]  % R out of S for option
   OptionInfo = [[1 0 0 0 1 1][0 0 1 1 0 1][1 0 0 0 1 0][1 1 0 1 0 0][0 0 1 0 0 0]]  % class requires option?
   CarInfo = [1#1 2#1 3#2 4#2 5#2 6#2]    % number of cars of class

   Return=
   fd([cars([
 	     one(equal(fun {$}
			  {Search.base.one proc{$ Slots}
					{StateConstraints Slots 10 5 6 
					 OutOfInfo#OptionInfo CarInfo} end}
		       end
		       CarsSol)
		 keys: [fd])
 	     one_entailed(entailed(proc {$}
			  {Search.base.one proc{$ Slots}
					{StateConstraints Slots 10 5 6 
					 OutOfInfo#OptionInfo CarInfo} end _}
		       end)
		 keys: [fd entailed])
	    ])
      ])
   
end
