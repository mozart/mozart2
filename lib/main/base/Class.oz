%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
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

declare
   Class IsClass IsInstanceOf
in

fun {IsClass X}
   {IsChunk X} andthen {HasFeature X `ooPrintName`}
end

local
   GetClass = {`Builtin` getClass 2}

   proc {AssertClass C Op}
      case {IsClass C} then skip else
         {`RaiseError` kernel(type Op [C] 'class' 1
                              'Module Class')}
      end
   end

   proc {AssertNonFinal C Op}
      {AssertClass C Op}
      case {HasFeature C `ooParents`} then skip else
         {`RaiseError` object(fromFinalClass C.`ooPrintName` Op)}
      end
   end

   fun {GetParents C}
      {AssertNonFinal C 'Class.parents'}
      C.`ooParents`
   end

   fun {MethodNames C}
      {AssertClass C 'Class.methodNames'}
      {Dictionary.keys C.`ooMeth`}
   end

   fun {AttrNames C}
      {AssertClass C 'Class.attrNames'}
      {Arity C.`ooAttr`}
   end

   fun {FeatNames C}
      {AssertClass C 'Class.featNames'}
      {Arity C.`ooFreeFeatR`}
   end

   fun {PropNames C}
      {AssertClass C 'Class.propNames'}
      case {Not {HasFeature C `ooParents`}}
      then
         final | case C.`ooLocking` then [locking] else nil end
      else
         case C.`ooLocking` then [locking] else nil end
      end
   end

   fun {HasProperty C P}
      {AssertClass C 'Class.property'}
      case P
      of final   then {Not {HasFeature C `ooParents`}}
      [] locking then C.`ooLocking`
      end
   end

in


   local
      fun {SubClassOfParent Cs C2}
         case Cs of nil then false
         [] C1|Cr then {SubClass C1 C2} orelse {SubClassOfParent Cr C2}
         end
      end

      fun {SubClass C1 C2}
         {AssertClass C2 'IsInstanceOf'}
         case C1==C2 then true else
            {AssertNonFinal C1 'IsInstanceOf'}
            {SubClassOfParent {GetParents C1} C2}
         end
      end
   in
      fun {IsInstanceOf O C}
         {SubClass {GetClass O} C}
      end
   end

   Class = 'class'(is:           IsClass
                   get:          GetClass
                   methodNames:  MethodNames
                   attrNames:    AttrNames
                   featNames:    FeatNames
                   propNames:    PropNames
                   hasProperty:  HasProperty
                   parents:      GetParents
                   extendFeatures: `extend`
                   getFeature:   fun {$ C F}
                                    X=C.`ooUnFreeFeat`.F
                                 in
                                    case {IsDet X} andthen X==`ooFreeFlag` then
                                       {`RaiseError` kernel('.' C F)} _
                                    else X
                                    end
                                 end
                   hasFeature:   fun {$ C F}
                                    X={CondSelect C.`ooUnFreeFeat`
                                       F `ooFreeFlag`}
                                 in
                                    case {IsDet X} andthen X==`ooFreeFlag` then
                                       false
                                    else
                                       true
                                    end
                                 end
                   isInstanceOf: IsInstanceOf)

end
