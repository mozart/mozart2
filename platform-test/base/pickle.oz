%%%
%%% Authors:
%%%   Ralf Scheidhauer <scheidhr@dfki.de>
%%%   Benoit Daloze
%%%
%%% Copyright:
%%%   Ralf Scheidhauer, 1998
%%%   Benoit Daloze, 2014
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
   BootPickle(pack:Pack unpack:Unpack) at 'x-oz://boot/Pickle'
   %Pickle(pack:Pack unpack:Unpack)
   BootName(newUnique:NewUniqueName newNamed:NewNamedName) at 'x-oz://boot/Name'
export
   Return
define
   fun {TryPack Val}
      try
         {Pack Val _} nil
      catch error(dp(generic 'pickle:resources'
                     _ ('Resources'#X)|_) ...) then
         X
      end
   end

   Nogoods=
   [{NewCell 1}
    {NewPort _}
    _
    {New BaseObject noop}
    thread {Delay 2000} 42 end
   ]

   NN={NewName}
   Goods=
   [4711
    111111111111111111111111111111111111111111111111
    23.056
    unit
    nil
    someAtom
    true
    false
    co|ns
    tu(pl e)
    rec(ord:with(some complex([struct "ure"])) 2.9 2324)
    'éèêÀ'|"été"
    {VirtualString.toCompactString "hèllò"}
    NN
    {NewUniqueName ahah}
    {NewNamedName hi}
    proc {$ X} X=2 end
    fun {$ Y} Y*3 end
    f(a:'an atom with blanks' NN:42 2:Append true:fun {$ X Y} X+Y end)
    %functor define {Delay 30*1000} raise unreachable end end % does not compare ==

    % read-only vars
    !!{fun lazy {$ X} X*2 end 3}

    % deduplication of same arities
    [rec(a:1 b:2) {Adjoin rec(a:3) rec(b:4)} rec(a:nope)]

    % Chunks are not comparing = yet
    %BaseObject
    %{NewChunk Goods}

    % Not serializable yet
    %{ByteString.make "bla"}

    % cycle
    c(cycle:Goods)
   ]

   Return=
   pickle([packGood(proc {$}
                       for E in Goods do
                          Packed={Pack E}
                       in
                          {Unpack Packed} = E
                       end

                       {TryPack Goods} = nil
                       {Unpack {Pack Goods}} = Goods
                    end
                    keys:[pickle])
           packBad(proc {$}
                      {All Nogoods fun {$ X} {TryPack X}==[X] end} = true
                   end keys:[pickle])
          ])
end
