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

local

   fun {Do Is}
      case Is of nil then nil
      [] I|Ir then
         case I==&\\ then &\\|&\\|{Do Ir}
         else I|{Do Ir}
         end
      end
   end

   fun {Double A}
      {Do {Atom.toString A}}
   end

in

   {Application.syslet
    'functor2env'
    functor $

    import
       Open.{file}
       Syslet.{exit args}
       LILO.{load}

    body

       Out = {New Open.file init(name:  Syslet.args.out
                                 flags: [write create truncate])}

       proc {O V}
          {Out write(vs:V#'\n')}
       end

       {O '%% Environment record generated, do not edit.'}
       {O ''}
       {O 'env('}

       A={LILO.load Syslet.args.'in'}

       {Wait A}

       {ForAll {Arity A}
        proc {$ A}
           S={Double A}
        in
           {O '\''#S#'\': '#S}
        end}
       {O ')'}

       {Out close}

       {Syslet.exit 0}

    end

    single(out(type:atom  default:stdout)
           'in'(type:atom))}

end
