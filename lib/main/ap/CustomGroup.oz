functor
export
   Register Get RegisterMember
define
   %% All known groups

   Registry = {Dictionary.new}

   %% for each group, all its members

   Members  = {Dictionary.new}
   Top      = {NewName}
   {Dictionary.put Members Top nil}

   %%

   proc {Register Group}
      Name = Group.1
   in
      if {Dictionary.member Registry Name} then
         {Exception.raiseError custom(alreadyExists Group)}
      else
         {Dictionary.put Registry Name Group}
         {RegisterMember Group}
      end
   end

   %%

   fun {GetParents G}
      L = {CondSelect G 'group' Top}
   in
      if {IsLiteral L} then [L] else L end
   end

   %%

   proc {RegisterMember Member}
      Type = {Label Member}
      Name = Member.1
      Spec = Type(Name)
   in
      {ForAll {GetParents Member}
       proc {$ Group}
          L = {Dictionary.condGet Members Group nil}
       in
          if {List.member Spec L} then skip else
             {Dictionary.put Members Group Spec|L}
          end
       end}
   end

   %%

   NotFound = {NewName}

   fun {Get Name}
      G = {Dictionary.condGet Registry Name NotFound}
   in
      if G==NotFound then
         {Exception.raiseError custom(unknownGroup Name)} unit
      else G end
   end
end
