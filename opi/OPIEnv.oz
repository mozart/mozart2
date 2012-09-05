%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%   Christian Schulte, 1998
%%%   Denys Duchier, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Module(manager)
   Compiler(engine) at 'Main.ozf'
export
   base: BaseEnv
   system: SystemEnv
   shortcuts: ShortCutsEnv
   full: FullEnv
require
   DefaultURL(functorNames: Modules)
prepare
   ShortCuts = [%% Library
                'Pickle'('Load': [load]
                         'Save': [save])

                'Search'('SearchOne':  [base one]
                         'SearchAll':  [base all]
                         'SearchBest': [base best])

                'System'('Show':  [show]
                         'Print': [print])

                'Module'('Link':  [link]
                         'Apply': [apply])

                %% Tools
                'Browser'('Browse': [browse])

                'Explorer'('ExploreOne':  [one]
                           'ExploreAll':  [all]
                           'ExploreBest': [best])
                'Inspector'('Inspect': [inspect])
               ]

   fun {Dots M Fs}
      case Fs of nil then M
      [] F|Fr then {Dots M.F Fr}
      end
   end
define
   CompilerObject = {New Compiler.engine init()}
   BaseEnv = {CompilerObject enqueue(getEnv($))}

   ModMan = {New Module.manager init()}

   %% Get system modules
   SystemEnv = {List.toRecord env
                {Map Modules
                 fun {$ ModName}
                    ModName#{ModMan link(name: ModName $)}
                 end}}

   %% Provide shortcuts
   ShortCutsEnv = {FoldL ShortCuts
                   fun {$ Env SC}
                      Module = {ModMan link(name:{Label SC} $)}
                      ExtraEnv = {Record.map SC
                                  fun lazy {$ Fs}
                                     {Dots Module Fs}
                                  end}
                   in
                      {Adjoin Env ExtraEnv}
                   end env()}

   FullEnv = {Adjoin {Adjoin BaseEnv SystemEnv} ShortCutsEnv}
end
