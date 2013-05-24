functor

import

   FD

   Search

export
   Return
define
%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5315
%  Author: Joerg Wuertz
%  Email: wuertz@dfki.uni-sb.de
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

% Square tiling problem:
% A list of squares of given sizes must fit exactly into a fixed square.

   proc {StateConstraints Choice Xs Ys Ss SX SY}
      case Choice
      of 1 then   Ss=[3 2 2 1 1 1] SX=5 SY=4
      [] 2 then Ss=[18 15 14 10 9 8 7 4 1] SX=32 SY=33
      [] 3 then  Ss=[50 42 37 35 33 29 27 25 24 19 18 17 16 15 11 9 8 7 6 4 2] SX=112 SY=112
      else fail
      end
      {GenCoords Xs Ys Ss SX SY}
   end
   
   proc {GenCoords Xs Ys Ss SX SY}
      case Ss of nil then Xs=nil Ys=nil
      [] S|Sr
      then local X Xr Y Yr  in
	      Xs=X|Xr Ys=Y|Yr
	      X :: 0#SX-S  
	      Y :: 0#SY-S
	      {GenCoords Xr Yr Sr SX SY}
	   end
      end
   end
   
   proc {Capacity XCoord Sizes SX SY}
      {For 0 SX-1 1 proc{$ Pos} {Sum Pos XCoord Sizes SY}  end}
   end
   
   proc {Sum Pos XCoord Sizes SY}
      % the sum of all the heights of rectangles over this position must be SY
      case XCoord#Sizes 
      of (X|Xr)#(S|Sr)
      then
	 local B SS in
	    B :: 0#1
	    thread
	       cond X=<:Pos X>=:Pos-S+1 then B=1
	       [] X>=:Pos+1 then B=0
	       [] X=<:Pos-S then B=0
	       [] B=1 then X=<:Pos  X>=:Pos-S+1
	       [] B=0 then or X>=:Pos+1 [] X=<:Pos-S end
	       end
	    end
	    SY :: 0#FD.sup
	    {Sum Pos Xr Sr SS}
	    SY =:  B*S + SS
	 end
      [] nil#nil then SY=0
      end
   end
   
   
   fun {NoOverlap Xs Ys Ss}
      % No rectangles must overlap
      case Xs#Ys#Ss of nil#nil#nil then nil
      [] (X|Xr)#(Y|Yr)#(S|Sr)
      then {Append {NoOverlap1 Xr Yr Sr X Y S}
	 {NoOverlap Xr Yr Sr}}
      end
   end

   fun {NoOverlap1 Xs Ys Ss X1 Y1 S1}
      case Xs#Ys#Ss of nil#nil#nil then nil
      [] (X|Xr)#(Y|Yr)#(S|Sr)
      then {NoOverlap2 X1 Y1 S1 X Y S}|
	 {NoOverlap1 Xr Yr Sr X1 Y1 S1}
      end
   end
   
   fun {NoOverlap2 X1 Y1 S1 X2 Y2 S2}
      C in
	 C :: 1#4
	 thread
	    or X1+S1 =<: X2 C=1
	    [] X1 >=: X2+S2 C=2
	    [] Y1+S1 =<: Y2 C=3
	    [] Y1 >=: Y2+S2 C=4
	    end
	 end
	 C
   end

   proc {Square P XCoord YCoord Sizes}
      local SX SY Cs in
	 % SX and SY are global sizes
	 % The Coordinates give the starting point of the rectangles
	 {StateConstraints P XCoord YCoord Sizes SX SY}
	 Cs={NoOverlap XCoord YCoord Sizes}
	 {Capacity XCoord Sizes SX SY}
	 {Capacity YCoord Sizes SY SX}
         {FD.distribute ff Cs}
	 {FD.distribute ff XCoord}
	 {FD.distribute ff YCoord}
      end
   end

   TilingSol1 = [[0 0 18 22 23 15 15 18 22]#
		 [0 18 0 14 24 25 18 14 24]#
		 [18 15 14 10 9 8 7 4 1]]
   TilingSol2 = [[0 3 3 0 1 2]#[0 0 2 3 3 3]#[3 2 2 1 1 1]]

   Return=
   fd([tiling([
	       test1(equal(fun {$} {Search.base.one
				    proc{$ X} 
				       local Xs#Ys#Ss = !X in 
					  {Square 2 Xs Ys Ss} 
				       end 
				    end}
			   end
			   TilingSol1)
		     keys: [fd])
	       
	       test2(equal(fun {$} {Search.base.one
				    proc{$ X} 
				       local Xs#Ys#Ss=!X in 
					  {Square 1 Xs Ys Ss} 
				       end 
				    end}
			   end
			   TilingSol2)
		     keys: [fd])
	       test1_entailed(entailed(proc {$} {Search.base.one
						 proc{$ X} 
						    local Xs#Ys#Ss = !X in 
						       {Square 2 Xs Ys Ss} 
						    end 
						 end _}
				       end)
			      keys: [fd entailed])
	       
	       test2_entailed(entailed(proc {$} {Search.base.one
						 proc{$ X} 
						    local Xs#Ys#Ss=!X in 
						       {Square 1 Xs Ys Ss} 
						    end 
						 end _}
				       end)
		     keys: [fd entailed])
	      ])
      ])
   
end
