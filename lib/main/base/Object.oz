%%%
%%% Authors:
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


BaseObject

local

   %%
   %% Fallback routines that are supplied with classes
   %%
   local
      proc {FbApply C Mess}
         Meth = C.`ooMeth`
         L    = {Label Mess}
      in
         case {Dictionary.condGet Meth L false} of false then
            case {Dictionary.condGet Meth otherwise false} of false then
               {`RaiseError` object(lookup C Mess)}
            elseof M then {M otherwise(Mess)}
            end
         elseof M then {M Mess}
         end
      end

      local
         NewObject = Boot_Object.newObject
      in
         fun {FbNew C Message}
            O={NewObject C} in {O Message} O
         end
      end

   in
      Fallback = fallback(new:   FbNew
                          apply: FbApply)
   end

   %%
   %% Property tests
   %%
   fun {ClassIsFinal C}
      {Not {HasFeature C `ooMethSrc`}}
   end
   ClassIsSited   = Boot_Class.isSited
   ClassIsLocking = Boot_Class.isLocking

   local
      %%
      %% Builtins needed for class creation
      %%
      MarkSafe   = Boot_Dictionary.markSafe
      BuildClass = Boot_Class.new

      %%
      %% Inheritance does very little, it just determines the classes
      %% that define methods, attributes, or features. Additionally,
      %% it computes a dictionary of possible conflicts.
      %%
      local
         proc {Add Fs Src SrcP Conf}
            case Fs of nil then skip
            [] F|Fr then
               Def={Dictionary.get SrcP F}
            in
               %% Conflict arises, if already a definition there that
               %% originates from a different class
               if {Dictionary.member Src F} then
                  PrevDef={Dictionary.get Src F}
               in
                  if Def\=PrevDef then
                     CFs={Dictionary.condGet Conf F nil}
                  in
                     %% If the definition comes from the same source,
                     %% nothing has to be done. Otherwise, mark the
                     %% conflict by storing the conflicting definitions
                     {Dictionary.put Conf F
                      if {Member Def CFs} then
                         if {Member PrevDef CFs} then CFs else PrevDef|CFs end
                      else
                         Def|if {Member PrevDef CFs} then CFs
                             else PrevDef|CFs end
                      end}
                  end
               else
                  %% Store definining class
                  {Dictionary.put Src F {Dictionary.get SrcP F}}
               end
               {Add Fr Src SrcP Conf}
            end
         end
      in
         proc {Inherit Ps Src SrcF Conf}
            case Ps of nil then skip
            [] P|Pr then SrcP=P.SrcF in
               {Add {Dictionary.keys SrcP} Src SrcP Conf}
               {Inherit Pr Src SrcF Conf}
            end
         end
      end

      %%
      %% Compute method tables
      %%
      proc {SetMeth N NewMeth Meth FastMeth Defaults}
         %% NewMeth:  tuple of method specifications
         %% Meth:     dictionary of methods
         %% FastMeth: dictionary of fast-methods
         %% Defaults: dictionary of defaults
         if N>0 then
            One = NewMeth.N
            L   = One.1
         in
            if {IsLiteral L} then skip else
               {`RaiseError` object(nonLiteralMethod L)}
            end
            {Dictionary.put Meth L One.2}
            if {HasFeature One fast} then
               {Dictionary.put FastMeth L One.fast}
            else
               {Dictionary.remove FastMeth L}
            end
            if {HasFeature One default} then
               {Dictionary.put Defaults L One.default}
            else
               {Dictionary.remove Defaults L}
            end
            {SetMeth N-1 NewMeth Meth FastMeth Defaults}
         end
      end

      proc {CollectMeth Fs MethSrc Meth FastMeth Defaults}
         %% Collect methods from defining classes
         case Fs of nil then skip
         [] F|Fr then
            C={Dictionary.get MethSrc F}
            MethC=C.`ooMeth` FastMethC=C.`ooFastMeth` DefaultsC=C.`ooDefaults`
         in
            {Dictionary.put Meth F {Dictionary.get MethC F}}
            if {Dictionary.member FastMethC F} then
               {Dictionary.put FastMeth F {Dictionary.get FastMethC F}}
            else
               {Dictionary.remove FastMeth F}
            end
            if {Dictionary.member DefaultsC F} then
               {Dictionary.put Defaults F {Dictionary.get DefaultsC F}}
            else
               {Dictionary.remove Defaults F}
            end
            {CollectMeth Fr MethSrc Meth FastMeth Defaults}
         end
      end

      proc {ClearMeth N NewMeth Conf}
         %% Remove conflicts by new methods
         if N>0 then
            {Dictionary.remove Conf NewMeth.N.1}
            {ClearMeth N-1 NewMeth Conf}
         end
      end

      proc {DefMeth N NewMeth MethSrc C}
         %% Set defining class for new methods
         if N>0 then
            {Dictionary.put MethSrc NewMeth.N.1 C}
            {DefMeth N-1 NewMeth MethSrc C}
         end
      end

      %%
      %% Compute attributes and features
      %%
      proc {SetOther Fs New Oth}
         case Fs of nil then skip
         [] F|Fr then
            {Dictionary.put Oth F New.F}
            {SetOther Fr New Oth}
         end
      end

      proc {CollectOther Fs Src What Oth}
         case Fs of nil then skip
         [] F|Fr then C={Dictionary.get Src F} in
            {Dictionary.put Oth F C.What.F}
            {CollectOther Fr Src What Oth}
         end
      end

      proc {ClearOther Fs Conf}
         %% Remove conflicts by new attributes or features
         case Fs of nil then skip
         [] F|Fr then {Dictionary.remove Conf F} {ClearOther Fr Conf}
         end
      end

      proc {DefOther Fs Src C}
         %% Set defining class for new attributes or features
         case Fs of nil then skip
         [] F|Fr then {Dictionary.put Src F C} {DefOther Fr Src C}
         end
      end

      %%
      %% Computing free features
      %%
      local
         fun {Free As R}
            case As of nil then nil
            [] A|Ar then X=R.A in
               if {IsDet X} andthen X==`ooFreeFlag` then
                  A#`ooFreeFlag`|{Free Ar R}
               else {Free Ar R}
               end
            end
         end
      in
         fun {MakeFree R}
            %% Returns record that only contains free features of R
            {List.toRecord free {Free {Arity R} R}}
         end
      end

      local
         fun {ToOoNew As R}
            case As of nil then nil
            [] A|Ar then
               if {IsInt A} then R.A#`ooFreeFlag` else A#R.A end|{ToOoNew Ar R}
            end
         end
      in
         fun {SpecToOoNew R}
            {List.toRecord '#' {ToOoNew {Arity R} R}}
         end
      end

      %%
      %% Check parents for non-final classes
      %%
      proc {CheckParents Cs PrintName}
         case Cs of nil then skip
         [] C|Cr then
            if {IsClass C} then
               if {ClassIsFinal C} then
                  {`RaiseError` object(final C PrintName)}
               end
            else
               {`RaiseError` object(inheritanceFromNonClass C PrintName)}
            end
            {CheckParents Cr PrintName}
         end
      end

   in

      %%
      %% The real class creation
      %%
      proc {NewFullClass Parents NewMeth NewAttr NewFeat NewProp PrintName ?C}
         {CheckParents Parents PrintName}
         %% To be computed for methods
         Meth FastMeth Defaults MethSrc
         %% To be computed for attributes
         Attr AttrSrc
         %% To be computed for features
         Feat FreeFeat FeatSrc
         %% Properties
         IsLocking = ({Member locking NewProp} orelse
                      {Some Parents ClassIsLocking})
         IsSited   = ({Member sited NewProp}  orelse
                      {Some Parents ClassIsSited})
         IsFinal   = {Member final NewProp}
         NoNewMeth = {Width NewMeth}
         AsNewAttr = {Arity NewAttr}
         AsNewFeat = {Arity NewFeat}
      in
         if
            {All NewProp IsAtom} andthen
            {List.sub {Sort NewProp Value.'<'} [final locking sited]}
         then skip else
            {`RaiseError` object(illegalProp
                                 {FoldL NewProp fun {$ Ps P}
                                                   case P
                                                   of final then Ps
                                                   [] locking then Ps
                                                   [] sited then Ps
                                                   else P|Ps
                                                   end
                                                end nil})}
         end
         case Parents
         of nil then
            %% Methods
            Meth     = {Dictionary.new}
            FastMeth = {Dictionary.new}
            Defaults = {Dictionary.new}
            {SetMeth NoNewMeth NewMeth Meth FastMeth Defaults}
            %% Attributes
            Attr     = NewAttr
            %% Features
            Feat     = NewFeat
            FreeFeat = {MakeFree Feat}
            if IsFinal then skip else
               MethSrc = {Dictionary.new}
               AttrSrc = {Dictionary.new}
               FeatSrc = {Dictionary.new}
               {DefMeth NoNewMeth NewMeth MethSrc C}
               {DefOther AsNewAttr AttrSrc C}
               {DefOther AsNewFeat FeatSrc C}
            end
         [] [P] then
            %% Methods
            if NoNewMeth==0 then
               Meth     = P.`ooMeth`
               FastMeth = P.`ooFastMeth`
               Defaults = P.`ooDefaults`
               if IsFinal then skip else
                  MethSrc  = P.`ooMethSrc`
               end
            else
               Meth     = {Dictionary.clone P.`ooMeth`}
               FastMeth = {Dictionary.clone P.`ooFastMeth`}
               Defaults = {Dictionary.clone P.`ooDefaults`}
               {SetMeth NoNewMeth NewMeth Meth FastMeth Defaults}
               if IsFinal then skip else
                  MethSrc  = {Dictionary.clone P.`ooMethSrc`}
                  {DefMeth NoNewMeth NewMeth MethSrc C}
               end
            end
            %% Attributes
            if AsNewAttr==nil then
               Attr = P.`ooAttr`
               if IsFinal then skip else
                  AttrSrc = P.`ooAttrSrc`
               end
            else
               Attr = {Adjoin P.`ooAttr` NewAttr}
               if IsFinal then skip else
                  AttrSrc = {Dictionary.clone P.`ooAttrSrc`}
                  {DefOther AsNewAttr AttrSrc C}
               end
            end
            %% Features
            if AsNewFeat==nil then
               Feat     = P.`ooFeat`
               FreeFeat = P.`ooFreeFeat`
               if IsFinal then skip else
                  FeatSrc = P.`ooFeatSrc`
               end
            else
               Feat     = {Adjoin P.`ooFeat` NewFeat}
               FreeFeat = {MakeFree Feat}
               if IsFinal then skip else
                  FeatSrc = {Dictionary.clone P.`ooFeatSrc`}
                  {DefOther AsNewFeat FeatSrc C}
               end
            end
         else
            MethConf = {Dictionary.new}
            AttrConf = {Dictionary.new}
            FeatConf = {Dictionary.new}
         in
            %% Perform conflict checks
            MethSrc  = {Dictionary.new}
            AttrSrc  = {Dictionary.new}
            FeatSrc  = {Dictionary.new}
            %% Collect conflicts and defining classes
            {Inherit Parents MethSrc `ooMethSrc` MethConf}
            {Inherit Parents AttrSrc `ooAttrSrc` AttrConf}
            {Inherit Parents FeatSrc `ooFeatSrc` FeatConf}
            %% Resolve conflicts by new definitions
            {ClearMeth NoNewMeth NewMeth MethConf}
            {ClearOther AsNewAttr AttrConf}
            {ClearOther AsNewFeat FeatConf}
            %% Check whether still conflicts remain
            case
               ({Dictionary.entries MethConf} #
                {Dictionary.entries AttrConf} #
                {Dictionary.entries FeatConf})
            of nil#nil#nil then skip
            [] MCs#ACs#FCs then
               {`RaiseError` object(conflicts PrintName
                                    'meth':MCs 'attr':ACs 'feat':FCs)}
            end
            %% Construct methods
            Meth     = {Dictionary.new}
            FastMeth = {Dictionary.new}
            Defaults = {Dictionary.new}
            {CollectMeth {Dictionary.keys MethSrc} MethSrc
             Meth FastMeth Defaults}
            {SetMeth NoNewMeth NewMeth Meth FastMeth Defaults}
            {DefMeth NoNewMeth NewMeth MethSrc C}
            %% Construct attributes
            local
               TmpAttr={Dictionary.new}
            in
               {CollectOther {Dictionary.keys AttrSrc} AttrSrc
                `ooAttr` TmpAttr}
               {SetOther AsNewAttr NewAttr TmpAttr}
               {DefOther AsNewAttr AttrSrc C}
               Attr={Dictionary.toRecord 'attr' TmpAttr}
            end
            %% Construct features
            local
               TmpFeat={Dictionary.new}
            in
               {CollectOther {Dictionary.keys FeatSrc} FeatSrc
                `ooFeat` TmpFeat}
               {SetOther AsNewFeat NewFeat TmpFeat}
               {DefOther AsNewFeat FeatSrc C}
               Feat    ={Dictionary.toRecord 'feat' TmpFeat}
               FreeFeat={MakeFree Feat}
            end
         end

         %% Mark these dictionaries safe as it comes to marshalling
         {MarkSafe Meth}
         {MarkSafe FastMeth}
         {MarkSafe Defaults}

         %% Create the real class
         C = {BuildClass
              if IsFinal then
                 'class'(`ooAttr`:       Attr
                         `ooFeat`:       Feat
                         `ooFreeFeat`:   FreeFeat
                         `ooMeth`:       Meth
                         `ooFastMeth`:   FastMeth
                         `ooDefaults`:   Defaults
                         `ooPrintName`:  PrintName
                         `ooFallback`:   Fallback)
              else
                 %% Mark these dictionaries safe as it comes to marshalling
                 {MarkSafe MethSrc}
                 {MarkSafe AttrSrc}
                 {MarkSafe FeatSrc}
                 'class'(%% Information for methods
                         `ooMethSrc`:    MethSrc       % Dictionary
                         `ooMeth`:       Meth          % Dictionary
                         `ooFastMeth`:   FastMeth      % Dictionary
                         `ooDefaults`:   Defaults      % Dictionary
                         %% Information for attributes
                         `ooAttrSrc`:    AttrSrc       % Record
                         `ooAttr`:       Attr          % Record
                         %% Information for features
                         `ooFeatSrc`:    FeatSrc       % Dictionary
                         `ooFeat`:       Feat          % Record
                         `ooFreeFeat`:   FreeFeat      % Record
                         %% Other info
                         `ooPrintName`:  PrintName     % Atom
                         `ooFallback`:   Fallback)     % Record
              end
              IsLocking IsSited}
      end

      fun {NewClass Parents AttrSpec FeatSpec Prop}
         NewAttr={SpecToOoNew AttrSpec}
         NewFeat={SpecToOoNew FeatSpec}
      in
         {NewFullClass Parents '#' NewAttr NewFeat Prop 'Class.new'}
      end

   end


   %%
   %% Oo Extensions
   %%

   GetClass = Boot_Object.getClass

   fun {GetC OC}
      if {IsObject OC} then {GetClass OC} else OC end
   end

in

   BaseObject = {NewFullClass nil '#'(noop # proc {$ noop} skip end)
                 'attr' 'feat' nil 'Object.base'}

   Object = object(is:   IsObject
                   new:  New
                   base: BaseObject)

   Class = 'class'(is:             IsClass
                   new:            NewClass)

   OoExtensions = oo('class':      NewFullClass
                     getClass:     GetClass
                     getMethNames: fun {$ OC}
                                      {Dictionary.keys {GetC OC}.`ooMeth`}
                                   end
                     getAttrNames: fun {$ OC}
                                      {Arity {GetC OC}.`ooAttr`}
                                   end
                     getFeatNames: fun {$ OC}
                                      {Arity {GetC OC}.`ooFeat`}
                                   end
                     getProps:     fun {$ OC}
                                      C={GetC OC}
                                   in
                                      {Append
                                       if {ClassIsFinal C} then [final]
                                       else nil
                                       end
                                       if {ClassIsLocking C} then [locking]
                                       else nil
                                       end}
                                   end)
end
