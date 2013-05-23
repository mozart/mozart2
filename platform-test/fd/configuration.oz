functor

import

   FD

   Search

export
   Return
define


   RackSpecs = [r(power:150 slots:8  price:150)
		r(power:200 slots:16 price:200)]
   CardSpecs = [c(power:20)
		c(power:40)
		c(power:50)
		c(power:75)]
   NbRacks   = 5
   Cards     = cards(10 4 2 1)

   Order     = proc {$ Old New} Old.price >: New.price end

   Configuration = 
   {fun {$ RackSpecs CardSpecs NbRacks Cards}
       RackType        = {List.number 0 {Length RackSpecs} 1}
       RackPower       = 0|{Map RackSpecs fun {$ T} T.power end}
       RackPrice       = 0|{Map RackSpecs fun {$ T} T.price end}
       RackNbSlots     = 0|{Map RackSpecs fun {$ T} T.slots end}
       RackMaxNbSlots  = {FoldR RackNbSlots Max 0}
       CardType        = {List.number 1 {Length CardSpecs} 1}
       CardPower       = {Map CardSpecs fun {$ T} T.power end}
       proc {Rack R}
	  Type
	  Power         = {FD.int RackPower} = thread {FD.sumC CardPower NbCards '=<:'} end
	  NbCards
	  Price
	  NbSlots       = {FD.int RackNbSlots}
       in
	  R = rack(
		   type: Type = {FD.int RackType}
		   cards: NbCards = {FD.record type CardType 0#RackMaxNbSlots}
		   price: Price = {FD.int RackPrice}
		  )
	  thread
	     if Type==0 then Power=0  Price=0  NbSlots=0
	     else Spec = {Nth RackSpecs Type} in
		Power=Spec.power  Price=Spec.price  NbSlots=Spec.slots
	     end
	  end
       end
       proc {RackList Racks}
	  {ForAll Racks Rack}
      % impose order to remove symmetries
	  {ForAllTail Racks 
	   proc {$ Rs}
	      case Rs of A|B|_ then
		 A.type =<: B.type
		 thread
		    if A.type == B.type then A.cards.1 >=: B.cards.1
		    else skip end
		 end
	      else skip end
	   end}
       end
       proc {Match Racks Cards}
	  {ForAll CardType
	   proc {$ T}
	      {FD.sum {Map Racks fun {$ R} R.cards.T end} '=:' Cards.T}
	   end}
       end
       proc {Distribute Racks}
	  CompList = {FoldR Racks
		      fun {$ R Cs}
			 {Append {Record.toList R.cards} Cs}
		      end
		      nil}
	  TypeList = {Map Racks fun {$ R} R.type end}
       in
	  {FD.distribute naive TypeList}
	  {FD.distribute ff CompList}
       end
    in
       proc {$ X}
	  Racks = {MakeList NbRacks} = {RackList}
	  Price = {FD.decl} = {FD.sum {Map Racks fun {$ R} R.price end} '=:'}
       in
	  X = p(price:Price racks:Racks)
	  {Match Racks Cards} 
	  {Distribute Racks}
       end
    end
    RackSpecs
    CardSpecs
    NbRacks
    Cards
   }

		
   ConfigurationSol =
   [p(price:550 
      racks:[rack(cards:type(0 0 0 0) price:0 type:0) 
	     rack(cards:type(0 0 0 0) price:0 type:0) 
	     rack(
		  cards:type(7 0 0 0) 
		  price:150 
		  type:1) 
	     rack(
		  cards:type(2 4 0 0) 
		  price:200 
		  type:2) 
	     rack(
		  cards:type(1 0 2 1) 
		  price:200 
		  type:2)])]

   Return=
   fd([configuration([
		      best(equal(fun {$}
				    {Search.base.best Configuration Order}
				 end
				 ConfigurationSol)
			   keys: [fd])
		      best_entailed(entailed(proc {$}
						{Search.base.best Configuration Order _}
					     end)
			   keys: [fd entailed])
		     ])
      ])


end
