%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
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
import System(show)
   CustomGroup(registerMember)
   Pickle(load save)
   Property(condGet)
   OS(getEnv)
export
   Register Get Set Reset Save Spec
define

   Registry = {Dictionary.new}
   Values   = {ByNeedFuture fun {$} {UserDictionary} end}

   proc {Register Option}
      Name = Option.1
   in
      {System.show registering(Name)}
      if {Dictionary.member Registry Name} then
         {Exception.raiseError custom(alreadyExists Option)}
      else
         {Dictionary.put Registry Name Option}
         {System.show enteredInRegistry}
         {CustomGroup.registerMember Option}
         {System.show registeredAsMember}
      end
   end

   NotFound = {NewName}

   fun {Spec Option}
      R = {Dictionary.condGet Registry Option NotFound}
   in
      if R==NotFound then
         {Exception.raiseError custom(unknownOption Option)}
         unit
      else R end
   end

   fun {Get Option}
      V = {Dictionary.condGet Values Option NotFound}
   in
      if V==NotFound then
         R = {Spec Option}
      in
         if {HasFeature R 'default'} then V = R.default in
            {Dictionary.put Values Option V} V
         elseif {HasFeature R 'init'} then V = {R.init} in
            {Dictionary.put Values Option V} V
         else
            {Exception.raiseError custom(noInitialization Option)}
            unit
         end
      else V end
   end

   proc {Set Option Value}
      {Dictionary.put Values Option Value}
      {Dictionary.put Changed Option set(Value)}
   end

   proc {Reset Option}
      {Dictionary.remove Values Option}
      {Dictionary.put Changed Option reset}
   end

   %%

   Changed = {Dictionary.new}

   fun {UserFile}
      case {Property.condGet 'user.custom.file' unit} of unit then
         case {OS.getEnv 'MOZART_CUSTOM_FILE'} of false then
            '~/.oz/CUSTOM'
         [] X then X end
      [] X then X end
   end

   fun {UserDictionary}
      {Record.toDictionary
       try {Pickle.load {UserFile}} catch _ then custom end}
   end

   proc {Save}
      D = {UserDictionary}
   in
      {ForAll {Dictionary.entries Changed}
       proc {$ Key#Change}
          case Change
          of set(V) then {Dictionary.put    D Key V}
          [] reset  then {Dictionary.remove D Key}
          end
       end}
      {Dictionary.removeAll Changed}
      {Pickle.save {Dictionary.toRecord custom D} {UserFile}}
   end

end
