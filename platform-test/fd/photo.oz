functor

import

   FD

   Search

export
   Return
define

   proc {Photo Solution}
      
      Pos = position(alain:_  beatrice:_  christian:_  daniel:_
		     eliane:_  francois:_  gerard:_)
      
      fun {NextTo P Q}
	 (Pos.P+1 =: Pos.Q) + (Pos.P-1 =: Pos.Q) =: 1
      end
      
      Pre Satisfaction={FD.decl}
   in
      Pos = {FD.dom 1#7}
      Pre = preference({NextTo beatrice gerard}
		       {NextTo beatrice eliane}
		       {NextTo beatrice christian}
		       {NextTo francois eliane}
		       {NextTo francois daniel}
		       {NextTo francois alain}
		       {NextTo alain daniel}
		       {NextTo gerard christian})
      
      Satisfaction = {FD.sum Pre '=:'}
      {FD.distinct Pos}
      Solution = Pos#Satisfaction
      {FD.distribute ff Pos}
   end

   PhotoSol =
   [position(
	     alain:1 
	     beatrice:5 
	     christian:6 
	     daniel:2 
	     eliane:4 
	     francois:3 
	     gerard:7)#
    6]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   PhotoPrimer =
   proc {$ Root}
      Persons       = [betty chris donald fred gary mary paul]
      Preferences   = [betty#gary betty#mary chris#betty
		       chris#gary fred#mary fred#donald
		       paul#fred paul#donald]
      NbPersons     = {Length Persons}
      Alignment     = {FD.record alignment Persons 1#NbPersons}
      Satisfaction  = {FD.decl} 
      proc {Satisfied P#Q S}
	 {FD.reified.distance Alignment.P Alignment.Q '=:' 1 S}
      end
   in
      Root = Satisfaction#Alignment
      {FD. distinct Alignment}
      {FD.sum {Map Preferences Satisfied} '=:' Satisfaction}
      Alignment.fred <: Alignment.betty     % redundant
      {FD.distribute split Alignment}
      {FD.distribute generic(order:naive value:max) [Satisfaction]}
   end

   PhotoPrimerSol =
   [1#
    alignment(
	      betty:2 
	      chris:3 
	      donald:4 
	      fred:1 
	      gary:5 
	      mary:6 
	      paul:7)]

   Return=
   fd([photo([
	      primer(equal(fun {$}
			      {Search.base.one PhotoPrimer}
			   end
			   PhotoPrimerSol)
		     keys: [fd])
	      
	      best(equal(fun {$}
			    {Search.base.best Photo
			     proc{$ Old New} Old.2 <: New.2 end}
			 end
			 PhotoSol)
		   keys: [fd])
	      primer_entailed(entailed(proc {$}
			      {Search.base.one PhotoPrimer _}
				       end)
			      keys: [fd entailed])
	      
	      best_entailed(entailed(proc {$}
					{Search.base.best Photo
					 proc{$ Old New} Old.2 <: New.2 end _}
				     end)
		   keys: [fd entailed])
	     ])
      ])
   
end

