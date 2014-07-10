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
   %BootPickle(pack:Pack unpack:Unpack) at 'x-oz://boot/Pickle'
   Pickle(pack:Pack unpack:Unpack packWithReplacements:PackWithReplacements)
   BootName(newUnique:NewUniqueName newNamed:NewNamedName) at 'x-oz://boot/Name'
   System
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

   BadThread

   Nogoods=
   [{NewCell 1}
    {NewPort _}
    _
    {New BaseObject noop}
    thread BadThread = {Thread.this} for _ in 1..200 do {Delay 10} end 42 end
    BadThread
   ]

   NN={NewName}
   Big={Pow 2 65}
   Goods=
   [4711 ~47
    Big ~Big
    23.056 ~3.14
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

    % read-only vars
    !!{fun lazy {$ X} X*2 end 3}

    % deduplication of same arities
    [rec(a:1 b:2) {Adjoin rec(a:3) rec(b:4)} rec(a:nope)]

    % Not serializable yet
    %{ByteString.make "bla"}

    % cycle
    c(cycle:Goods)
   ]

   % Chunks do not compare equal
   NotEql=
   [
    functor define {Delay 30*1000} raise unreachable end end
    BaseObject
    {NewChunk Goods}
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
           packNotEql(proc {$}
                         for E in NotEql do
                            {TryPack E} = nil
                         end
                         ({Unpack {Pack NotEql}}==NotEql) = false
                      end keys:[pickle])
           packBad(proc {$}
                      {All Nogoods fun {$ X} {TryPack X}==[X] end} = true
                      {Thread.terminate BadThread}
                   end keys:[pickle])

           packWithReplacements(
               proc {$}
                   A = {NewCell 1}
                   B = {NewCell 1}
                   C = A
                   S U
                   Replacements = [A#a B#b]
                   Obj = [fun {$} A#B#c end A B C d A]
               in
                   S = {PackWithReplacements Obj Replacements}
                   U = {Unpack S}
                   [a b a d a] = U.2
                   %a#b#c = {U.1}
                   %% ^ TODO cannot test this on local machine, the unpickler
                   %%   will recognize the anonymous function as a global node
                   %%   and reuse the existing method in this VM.
                   [A B C d A] = Obj.2
                   A#B#c = {Obj.1}
                   true = {IsCell A}
                   true = {IsCell B}
                   true = (A \= B)
               end
           )
          ])
end
