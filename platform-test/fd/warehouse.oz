functor

import

   FD

   Search

export
   Return
define

% Locating Warehouses



% Capacity: Supplier --> Nat
   Capacity   = supplier(       1   4  2  1  3)
% CostMatrix: Store --> Supplier --> Nat
   CostMatrix = store(
		      supplier(20 24 11 25 30)
		      supplier(28 27 82 83 74)
		      supplier(74 97 71 96 70)
		      supplier( 2 55 73 69 61)
		      supplier(46 96 59 83  4)
		      supplier(42 22 29 67 59)
		      supplier( 1  5 73 59 56)
		      supplier(10 73 13 43 96)
		      supplier(93 35 63 85 46)
		      supplier(47 65 55 71 95)
		     )
   BuildingCost = 30
   fun {Regret X}
      M = {FD.reflect.min X} in {FD.reflect.nextLarger X M} - M
   end

   WareHouse =
   proc {$ X}
      NbSuppliers = {Width Capacity}
      NbStores    = {Width CostMatrix}
   % Supplier: Store --> Supplier
      Supplier    = {FD.tuple store NbStores 1#NbSuppliers}
   % Open: Supplier --> {0,1}
      Open        = {FD.tuple supplier NbSuppliers 0#1}
   % Cost: Store --> Nat
      Cost        = {FD.tuple store NbStores 0#FD.sup}
      SumCost     = {FD.decl} = {FD.sum Cost '=:'}
      NbOpen      = {FD.decl} = {FD.sum Open '=:'}
      TotalCost   = {FD.decl}
   in
      X = plan(supplier:Supplier cost:Cost totalCost:TotalCost)
      TotalCost =: SumCost + NbOpen*BuildingCost
      {For 1 NbStores 1
       proc {$ S}
	  Cost.S :: {Record.toList CostMatrix.S}
	  {FD.element Supplier.S CostMatrix.S Cost.S}
	  thread Open.(Supplier.S) = 1 end
       end}
      {For 1 NbSuppliers 1
       proc {$ S} 
	  {FD.atMost Capacity.S Supplier S}
       end}
      {FD.distribute
       generic(order: fun {$ X Y} {Regret X} > {Regret Y} end)
       Cost}
   end

   WareHouseSol =
   [plan(
	 cost:store(30 27 70 2 4 22 5 13 35 55) 
	 supplier:store(5 2 5 1 5 2 2 3 2 3) 
	 totalCost:383)]

   Return =
   fd([
       warehouse([
		  best(equal(fun {$} {Search.base.best WareHouse
				      proc {$ Old New}
					 Old.totalCost >: New.totalCost end}
			     end
			     WareHouseSol)
		       keys: [fd])
		  best_entailed(entailed(proc {$}
					    {Search.base.best WareHouse
					     proc {$ Old New}
						Old.totalCost >: New.totalCost
					     end _}
					 end)
				keys: [fd scheduling])
		 ])
      ])
   
end
