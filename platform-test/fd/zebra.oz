functor

import

   FD

   Search

export
   Return
define

Zebra = 
	 proc {$ Nb}
	    Groups     = [ [english spanish japanese italian norvegian]
			   [green red yellow blue white]
			   [painter diplomat violinist doctor sculptor]
				     [dog zebra fox snails horse]
			   [juice water tea coffee milk] ]
	    Properties = {FoldR Groups Append nil}
	    proc {Partition Group}
      % The properties in Group hold for distinct house numbers
	       {FD.distinct {Map Group fun {$ P} Nb.P end}}
	    end
	    proc {Adjacent X Y}
	       {FD.distance X Y '=:' 1}
	    end
	 in
   % Nb maps all properties to house numbers
	    {FD.record number Properties 1#5 Nb}
	    {ForAll Groups Partition}
	    Nb.english = Nb.red
	    Nb.spanish = Nb.dog
	    Nb.japanese = Nb.painter
	    Nb.italian = Nb.tea
	    Nb.norvegian = 1
	    Nb.green = Nb.coffee
	    Nb.green >: Nb.white
	    Nb.sculptor = Nb.snails
	    Nb.diplomat = Nb.yellow
	    Nb.milk = 3
	    {Adjacent Nb.norvegian Nb.blue}
	    Nb.violinist = Nb.juice
	    {Adjacent Nb.fox Nb.doctor}
	    {Adjacent Nb.horse Nb.diplomat}
	    Nb.zebra = Nb.white
	    {FD.distribute ff Nb}
	 end

ZebraSol =
[number(
    blue:2 
    coffee:5 
    diplomat:3 
    doctor:4 
    dog:3 
    english:4 
    fox:5 
    green:5 
    horse:4 
    italian:2 
    japanese:5 
    juice:1 
    milk:3 
    norvegian:1 
    painter:5 
    red:4 
    sculptor:2 
    snails:2 
    spanish:3 
    tea:2 
    violinist:1 
    water:4 
    white:1 
    yellow:3 
    zebra:1)]

Return=

   fd([
       zebra([
	      all(equal(fun {$} {Search.base.all Zebra} end
			ZebraSol)
		  keys: [fd])
	     ])
       zebra_entailed([
		       all(entailed(proc {$} {Search.base.all Zebra _} end)
		  keys: [fd entailed])
	     ])
      ])
end




