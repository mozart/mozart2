%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Contributor:
%%%   Ralf Scheidhauer (scheidhr@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
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


Load      = {`Builtin` load 2}

local
   SmartSave = {`Builtin` smartSave 3}

   proc {SaveCarefully Value File RESOURCES RFOUND CALL}
      {SmartSave Value File RFOUND}
      case RESOURCES of unit then skip
      elsecase {List.all RFOUND
                fun {$ R} {List.member R RESOURCES} end}
      then skip
      else raise error(dp(save(resources:RESOURCES
                               found:RFOUND
                               call:CALL))
                       debug:debug)
              with debug end
      end
   end

in
   /*
      Desc is a record with the following optional features:

        resources       stateful resources allowed to be encountered during
                        save (unit means just ignore)
                        if unbound, it is unified with the resource
                        actually found (see found.resources)
        found           a record of 1 further feature:
        found.resources
                        the stateful resources actually encountered during
                        save (a subset of allowed resources).
   */
   proc {Save Value File Desc}
      CALL  = [Save Value File Desc]
      DESC  = case {VirtualString.is Desc} then
                 x(url:Desc resources:_)
              elsecase {Record.is Desc} then Desc
              else
                 raise error(dp(save(badArg call:CALL))
                             debug:debug)
                 with debug end
              end
      RSRCS = {CondSelect DESC 'resources'  nil}
      FOUND = {CondSelect DESC 'found' found}
      RFOUND= {CondSelect FOUND 'resources' _}
      RESOURCES  = case {IsDet RSRCS} then RSRCS else unit end
   in
      {SaveCarefully Value File RESOURCES RFOUND CALL}
      case {IsDet RSRCS} then skip
      else RSRCS=RFOUND end
   end
end

local

   SmartSave = {`Builtin` smartSave 3}

in

   Component = component(load:      Load
                         save:      Save
                         smartSave: SmartSave)

end
