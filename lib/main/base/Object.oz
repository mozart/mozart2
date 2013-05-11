%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local

   GetClass = Boot_Object.getClass

   %%
   %% Class manipulation
   %%
   ClassID            = {NewUniqueName classID}
   `ooClassIsSited`   = {NewUniqueName 'ooClassIsSited'}
   `ooClassIsLocking` = {NewUniqueName 'ooClassIsLocking'}

   fun {!IsClass X}
      {IsChunk X} andthen {HasFeature X ClassID}
   end

   fun {BuildClass Info IsLocking IsSited}
      {Chunk.new {Adjoin Info
                  'class'(ClassID:unit
                          `ooClassIsLocking`:IsLocking
                          `ooClassIsSited`:IsSited)}}
   end

   %%
   %% Fallback routines that are supplied with classes
   %%
   local
      proc {FbApply Mess Obj C}
         Meth = C.`ooMeth`
         L    = {Label Mess}
      in
         case {CondSelect Meth L false} of false then
            case {CondSelect Meth otherwise false} of false then
               {Exception.raiseError object(lookup C Mess)}
            [] M then {M Obj otherwise(Mess)}
            end
         [] M then {M Obj Mess}
         end
      end

      FbNew = New
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

   fun {ClassIsSited C}
      C.`ooClassIsSited`
   end

   fun {ClassIsLocking C}
      C.`ooClassIsLocking`
   end

   local
      %%
      %% Inheritance does very little, it just determines the classes
      %% that define methods, attributes, or features. Additionally,
      %% it computes a dictionary of possible conflicts.
      %%
      local
         proc {Add Fs SrcDict SrcP Conf}
            case Fs of nil then skip
            [] F|Fr then
               Def=SrcP.F
            in
               %% Conflict arises, if already a definition there that
               %% originates from a different class
               if {Dictionary.member SrcDict F} then
                  PrevDef={Dictionary.get SrcDict F}
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
                  {Dictionary.put SrcDict F Def}
               end
               {Add Fr SrcDict SrcP Conf}
            end
         end
      in
         proc {Inherit Ps SrcDict SrcF Conf}
            case Ps of nil then skip
            [] P|Pr then SrcP=P.SrcF in
               {Add {Arity SrcP} SrcDict SrcP Conf}
               {Inherit Pr SrcDict SrcF Conf}
            end
         end
      end

      %%
      %% Compute method tables
      %%
      proc {SetMeth N NewMeth MethDict FastMethDict DefaultsDict}
         %% NewMeth:      tuple of method specifications
         %% MethDict:     dictionary of methods
         %% FastMethDict: dictionary of fast-methods
         %% DefaultsDict: dictionary of defaults
         if N>0 then
            One = NewMeth.N
            L   = One.1
         in
            if {IsLiteral L} then skip else
               {Exception.raiseError object(nonLiteralMethod L)}
            end
            {Dictionary.put MethDict L One.2}
            if {HasFeature One fast} then
               {Dictionary.put FastMethDict L One.fast}
            else
               {Dictionary.remove FastMethDict L}
            end
            if {HasFeature One default} then
               {Dictionary.put DefaultsDict L One.default}
            else
               {Dictionary.remove DefaultsDict L}
            end
            {SetMeth N-1 NewMeth MethDict FastMethDict DefaultsDict}
         end
      end

      proc {CollectMeth Fs MethSrcDict MethDict FastMethDict DefaultsDict}
         %% Collect methods from defining classes
         case Fs of nil then skip
         [] F|Fr then
            C={Dictionary.get MethSrcDict F}
            MethC=C.`ooMeth` FastMethC=C.`ooFastMeth` DefaultsC=C.`ooDefaults`
         in
            {Dictionary.put MethDict F MethC.F}
            if {HasFeature FastMethC F} then
               {Dictionary.put FastMethDict F FastMethC.F}
            else
               {Dictionary.remove FastMethDict F}
            end
            if {HasFeature DefaultsC F} then
               {Dictionary.put DefaultsDict F DefaultsC.F}
            else
               {Dictionary.remove DefaultsDict F}
            end
            {CollectMeth Fr MethSrcDict MethDict FastMethDict DefaultsDict}
         end
      end

      proc {ClearMeth N NewMeth Conf}
         %% Remove conflicts by new methods
         if N>0 then
            {Dictionary.remove Conf NewMeth.N.1}
            {ClearMeth N-1 NewMeth Conf}
         end
      end

      proc {DefMeth N NewMeth MethSrcDict C}
         %% Set defining class for new methods
         if N>0 then
            {Dictionary.put MethSrcDict NewMeth.N.1 C}
            {DefMeth N-1 NewMeth MethSrcDict C}
         end
      end

      %%
      %% Compute attributes and features
      %%
      proc {SetOther Fs New OthDict}
         case Fs of nil then skip
         [] F|Fr then
            {Dictionary.put OthDict F New.F}
            {SetOther Fr New OthDict}
         end
      end

      proc {CollectOther Fs SrcDict What OthDict}
         case Fs of nil then skip
         [] F|Fr then C={Dictionary.get SrcDict F} in
            {Dictionary.put OthDict F C.What.F}
            {CollectOther Fr SrcDict What OthDict}
         end
      end

      proc {ClearOther Fs Conf}
         %% Remove conflicts by new attributes or features
         case Fs of nil then skip
         [] F|Fr then {Dictionary.remove Conf F} {ClearOther Fr Conf}
         end
      end

      proc {DefOther Fs SrcDict C}
         %% Set defining class for new attributes or features
         case Fs of nil then skip
         [] F|Fr then {Dictionary.put SrcDict F C} {DefOther Fr SrcDict C}
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
                  {Exception.raiseError object(final C PrintName)}
               end
            else
               {Exception.raiseError
                object(inheritanceFromNonClass C PrintName)}
            end
            {CheckParents Cr PrintName}
         end
      end

      %%
      %% Find parents that contribute definitions
      %%
      fun {FindDefs Cs What}
         case Cs of nil then nil
         [] C|Cr then
            if {Width C.What} == 0 then {FindDefs Cr What}
            else C|{FindDefs Cr What}
            end
         end
      end

   in

      %%
      %% The real class creation
      %%
      proc {NewFullClass Parents NewMeth NewAttr NewFeat0 NewProp PrintName ?C}
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
         NewFeat = if IsLocking then
                      %% Include `ooObjLock` in NewFeat
                      {AdjoinAt NewFeat0 `ooObjLock` `ooFreeFlag`}
                   else
                      NewFeat0
                   end
         NoNewMeth = {Width NewMeth}
         AsNewAttr = {Arity NewAttr}
         AsNewFeat = {Arity NewFeat}
         %% Check for illegal property values
         if
            {All NewProp IsAtom} andthen
            {List.sub {Sort NewProp Value.'<'} [final locking sited]}
         then skip else
            {Exception.raiseError
             object(illegalProp
                    {FoldL NewProp fun {$ Ps P}
                                      case P
                                      of final then Ps
                                      [] locking then Ps
                                      [] sited then Ps
                                      else P|Ps
                                      end
                                   end nil})}
         end
         %% Methods
         MCs=case {FindDefs Parents `ooMethSrc`}
             of nil then
                if NoNewMeth==0 then
                   Meth     = methods()
                   FastMeth = fastmeths()
                   Defaults = defaults()
                   MethSrc  = methodsSrc()
                else
                   MethDict     = {Dictionary.new}
                   FastMethDict = {Dictionary.new}
                   DefaultsDict = {Dictionary.new}
                in
                   {SetMeth NoNewMeth NewMeth MethDict FastMethDict DefaultsDict}
                   Meth     = {Dictionary.toRecord methods MethDict}
                   FastMeth = {Dictionary.toRecord fastmeths FastMethDict}
                   Defaults = {Dictionary.toRecord defaults DefaultsDict}
                   if IsFinal then skip else
                      MethSrcDict = {Dictionary.new}
                   in
                      {DefMeth NoNewMeth NewMeth MethSrcDict C}
                      MethSrc = {Dictionary.toRecord methodsSrc MethSrcDict}
                   end
                end
                nil
             [] [P] then
                if NoNewMeth==0 then
                   Meth     = P.`ooMeth`
                   FastMeth = P.`ooFastMeth`
                   Defaults = P.`ooDefaults`
                   if IsFinal then skip else
                      MethSrc  = P.`ooMethSrc`
                   end
                else
                   MethDict     = {Record.toDictionary P.`ooMeth`}
                   FastMethDict = {Record.toDictionary P.`ooFastMeth`}
                   DefaultsDict = {Record.toDictionary P.`ooDefaults`}
                in
                   {SetMeth NoNewMeth NewMeth MethDict FastMethDict DefaultsDict}
                   Meth     = {Dictionary.toRecord methods MethDict}
                   FastMeth = {Dictionary.toRecord fastmeths FastMethDict}
                   Defaults = {Dictionary.toRecord defaults DefaultsDict}
                   if IsFinal then skip else
                      MethSrcDict = {Record.toDictionary P.`ooMethSrc`}
                   in
                      {DefMeth NoNewMeth NewMeth MethSrcDict C}
                      MethSrc = {Dictionary.toRecord methodsSrc MethSrcDict}
                   end
                end
                nil
             [] Ps then
                Conf={Dictionary.new}
                MethSrcDict MethDict FastMethDict DefaultsDict
             in
                MethSrcDict = {Dictionary.new}
                %% Collect conflicts and defining classes
                {Inherit Ps MethSrcDict `ooMethSrc` Conf}
                %% Resolve conflicts by new definitions
                {ClearMeth NoNewMeth NewMeth Conf}
                %% Construct methods
                MethDict     = {Dictionary.new}
                FastMethDict = {Dictionary.new}
                DefaultsDict = {Dictionary.new}
                {CollectMeth {Dictionary.keys MethSrcDict} MethSrcDict
                 MethDict FastMethDict DefaultsDict}
                {SetMeth NoNewMeth NewMeth MethDict FastMethDict DefaultsDict}
                {DefMeth NoNewMeth NewMeth MethSrcDict C}
                Meth     = {Dictionary.toRecord methods MethDict}
                FastMeth = {Dictionary.toRecord fastmeths FastMethDict}
                Defaults = {Dictionary.toRecord defaults DefaultsDict}
                MethSrc  = {Dictionary.toRecord methodsSrc MethSrcDict}
                {Dictionary.entries Conf}
             end
         %% Attributes
         ACs=case {FindDefs Parents `ooAttrSrc`}
             of nil then
                Attr = NewAttr
                if AsNewAttr==nil then
                   AttrSrc = attrsSrc
                elseif IsFinal then skip
                else
                   AttrSrcDict = {Dictionary.new}
                in
                   {DefOther AsNewAttr AttrSrcDict C}
                   AttrSrc = {Dictionary.toRecord attrsSrc AttrSrcDict}
                end
                nil
             [] [P] then
                if AsNewAttr==nil then
                   Attr = P.`ooAttr`
                   if IsFinal then skip else
                      AttrSrc = P.`ooAttrSrc`
                   end
                else
                   Attr = {Adjoin P.`ooAttr` NewAttr}
                   if IsFinal then skip else
                      AttrSrcDict = {Record.toDictionary P.`ooAttrSrc`}
                   in
                      {DefOther AsNewAttr AttrSrcDict C}
                      AttrSrc = {Dictionary.toRecord attrsSrc AttrSrcDict}
                   end
                end
                nil
             [] Ps then Conf={Dictionary.new} AttrSrcDict in
                %% Perform conflict checks
                AttrSrcDict={Dictionary.new}
                %% Collect conflicts and defining classes
                {Inherit Ps AttrSrcDict `ooAttrSrc` Conf}
                %% Resolve conflicts by new definitions
                {ClearOther AsNewAttr Conf}
                %% Construct attributes
                Attr = local TmpAttrDict={Dictionary.new} in
                          {CollectOther {Dictionary.keys AttrSrcDict} AttrSrcDict
                           `ooAttr` TmpAttrDict}
                          {SetOther AsNewAttr NewAttr TmpAttrDict}
                          {DefOther AsNewAttr AttrSrcDict C}
                          {Dictionary.toRecord 'attr' TmpAttrDict}
                       end
                AttrSrc = {Dictionary.toRecord attrsSrc AttrSrcDict}
                {Dictionary.entries Conf}
             end
         %% Features
         FCs=case {FindDefs Parents `ooFeatSrc`}
             of nil then
                Feat = NewFeat
                if AsNewFeat==nil then
                   FreeFeat = Feat
                   FeatSrc  = featsSrc()
                else
                   FreeFeat = {MakeFree Feat}
                   if IsFinal then skip else
                      FeatSrcDict = {Dictionary.new}
                   in
                      {DefOther AsNewFeat FeatSrcDict C}
                      FeatSrc = {Dictionary.toRecord featsSrc FeatSrcDict}
                   end
                end
                nil
             [] [P] then
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
                      FeatSrcDict = {Record.toDictionary P.`ooFeatSrc`}
                   in
                      {DefOther AsNewFeat FeatSrcDict C}
                      FeatSrc = {Dictionary.toRecord featsSrc FeatSrcDict}
                   end
                end
                nil
             [] Ps then Conf={Dictionary.new} FeatSrcDict in
                FeatSrcDict = {Dictionary.new}
                %% Collect conflicts and defining classes
                {Inherit Ps FeatSrcDict `ooFeatSrc` Conf}
                %% Resolve conflicts by new definitions
                {ClearOther AsNewFeat Conf}
                %% Construct features
                Feat = local TmpFeatDict={Dictionary.new} in
                          {CollectOther {Dictionary.keys FeatSrcDict} FeatSrcDict
                           `ooFeat` TmpFeatDict}
                          {SetOther AsNewFeat NewFeat TmpFeatDict}
                          {DefOther AsNewFeat FeatSrcDict C}
                          {Dictionary.toRecord 'feat' TmpFeatDict}
                       end
                FreeFeat = {MakeFree Feat}
                FeatSrc = {Dictionary.toRecord featsSrc FeatSrcDict}
                {Dictionary.entries Conf}
             end
      in
         if MCs\=nil orelse ACs\=nil orelse FCs\=nil then
            {Exception.raiseError object(conflicts PrintName
                                         'meth':MCs 'attr':ACs 'feat':FCs)}
         end
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
                 'class'(%% Information for methods
                         `ooMethSrc`:    MethSrc       % Record
                         `ooMeth`:       Meth          % Record
                         `ooFastMeth`:   FastMeth      % Record
                         `ooDefaults`:   Defaults      % Record
                         %% Information for attributes
                         `ooAttrSrc`:    AttrSrc       % Record
                         `ooAttr`:       Attr          % Record
                         %% Information for features
                         `ooFeatSrc`:    FeatSrc       % Record
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

   fun {GetC OC}
      if {IsObject OC} then {GetClass OC} else OC end
   end

in

   fun {New C Mess}
      Obj = {Boot_Object.new C}
   in
      if {ClassIsLocking C} then
         Obj.`ooObjLock` = {NewLock}
      end
      {Obj Mess}
      Obj
   end

   BaseObject = {NewFullClass nil '#'(noop # proc {$ Obj Noop} skip end)
                 'attr' 'feat' nil 'Object.base'}

   Object = object(is:   IsObject
                   new:  New
                   base: BaseObject)

   Class = 'class'(is:             IsClass
                   new:            NewClass
                   getAttr:        fun {$ C A}
                                      C.`ooAttr`.A
                                   end)

   OoExtensions = oo('class':      NewFullClass
                     getClass:     GetClass
                     getMethNames: fun {$ OC}
                                      {Arity {GetC OC}.`ooMeth`}
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
                                   end
                     getObjLock:   fun {$ O}
                                      O.`ooObjLock`
                                   end)
end
