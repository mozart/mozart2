%%%
%%% Authors:
%%%   Ralf Scheidhauer <scheidhr@dfki.de>
%%%
%%% Copyright:
%%%   Ralf Scheidhauer, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Pickle(save load saveCompressed pack unpack)
   OS(tmpnam unlink)
   FS(value)
export
   Return
define

   fun {TrySave Val File}
      try
	 {Pickle.save Val File}
	 nil
      catch error(dp(generic 'pickle:nogoods'
		     _ ('Resources'#X)|_) ...) then
	 X
      []    error(dp(generic 'pickle:resources'
		     _ ('Resources'#X)|_) ...) then
	 X
      end
   end

   fun {TryPack Val}
      try
	 {Pickle.pack Val _} nil
      catch error(dp(generic 'pickle:nogoods'
		     _ ('Resources'#X)|_) ...) then
	 X
      []    error(dp(generic 'pickle:resources'
		     _ ('Resources'#X)|_) ...) then
	 X
      end
   end

   Nogoods = 
     [{NewCell 1}
      {NewPort _}
      _
      _::0#1
      {New BaseObject noop}
      proc sited {$} skip end
      class $ prop sited end
      Pickle.save
     ]
   
   NN = {NewName}
   Goods = 
     [4711
      111111111111111111111111111111111111111111111111
      23.056
      {NewChunk Goods}
      f(a:    'an atom with blanks'
	NN:   BaseObject
	2:    Append
	true: fun {$ X Y} X+Y end
	cycle: Goods)
      {ByteString.make "bla"}
      {FS.value.make [1 4 6]}
     ]
   
   Return =
   pickles([file(proc {$}
		    Tmp = {OS.tmpnam} LoadedGoods
		 in
		    %% check nogoods
		    {All Nogoods fun {$ X} {TrySave X Tmp}==[X] end}=true
		    %% check saving
		    {TrySave Goods Tmp} = nil
		    LoadedGoods = {Pickle.load Tmp}
		    %%
		    cond Goods = LoadedGoods
		    then skip
		    else
		       raise
			  base(pickles('loaded goods mismatched:'
				       #Goods#LoadedGoods))
		       end
		    end

		    %% check compressed save
		    {Pickle.saveCompressed Goods Tmp 9}
		    {Pickle.load Tmp} = Goods

		    {OS.unlink Tmp}
		 end
		 keys:[pickle])
	    pack(proc {$}
		    LoadedGoods
		    Tmp
		 in
		    %% check nogoods
		    {All Nogoods fun {$ X} {TryPack X}==[X] end}=true
		    %% check saving
		    {TryPack Goods} = nil
		    Tmp={Pickle.pack Goods}
		    LoadedGoods = {Pickle.unpack Tmp}
		    %%
		    cond Goods = LoadedGoods
		    then skip
		    else
		       raise
			  base(pickles('packed goods mismatched:'
				       #Goods#LoadedGoods))
		       end
		    end
		 end
		 keys:[pickle])])
end



