%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun lazy {MakeAllLoader IMPORT}
   {Application.loader
    {List.toRecord full
     {Append
      {Map ['SP' 'OP' 'DP']
       fun {$ C}
          C#case {HasFeature IMPORT C} then X=IMPORT.C in value(fun {$} X end)
            else eager end
       end}
      {Map ['AP' 'CP' 'WP'
            'Panel' 'Browser' 'Explorer'
            'Compiler' 'CompilerPanel'
            'Emacs' 'Ozcar' 'Profiler'
            'Gump' 'GumpScanner' 'GumpParser'
            'Misc']
       fun {$ C}
          C#case {HasFeature IMPORT C} then X=IMPORT.C in value(fun {$} X end)
            else lazy end
       end}}}}
end
