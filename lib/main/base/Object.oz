\ifdef NEWINHERITANCE
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


%%
%% Object and Class Creation
%%

`extend` BaseObject
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
   %% Builtins needed for class creation
   %%
   MakeClass = Boot_Object.makeClass
   MarkSafe  = Boot_Dictionary.markSafe

   fun {AddToList X Ys}
      if {Member X Ys} then Ys else X|Ys end
   end



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
                  %% If the definition comes from the same source,
                  %% nothing has to be done. Otherwise, mark the
                  %% conflict by storing the conflicting definitions
                  {Dictionary.put Conf F
                   {AddToList Def {AddToList PrevDef
                                   {Dictionary.condGet Conf F nil}}}}
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
      fun {Add A}
         A#`ooFreeFlag`
      end
   in
      fun {AddFree R As}
         {AdjoinList R {Map As Add}}
      end
   end

   %%
   %% Check parents for non-final classes
   %%

   proc {CheckParents Cs PrintName}
      case Cs of nil then skip
      [] C|Cr then
         if {HasFeature C `ooPrintName`} then
            if {HasFeature C `ooParents`} then skip else
               {`RaiseError` object(final C.`ooPrintName` PrintName)}
            end
         else {`RaiseError` object(inheritanceFromNonClass
                                   C PrintName)}
         end
         {CheckParents Cr PrintName}
      end
   end

   %%
   %% Test whether at least one parent has a certain property
   %%

   fun {HasPropertyParents Cs Prop}
      case Cs of nil then false
      [] C|Cr then C.Prop orelse {HasPropertyParents Cr Prop}
      end
   end


   %%
   %% The real class creation
   %%

   proc {`class` Parents NewMeth NewAttr NewFeat NewProp PrintName ?C}
      {CheckParents Parents PrintName}
      %% To be computed for methods
      Meth FastMeth Defaults MethSrc
      %% To be computed for attributes
      Attr AttrSrc
      %% To be computed for features
      Feat FreeFeat FeatSrc
      %% Properties
      IsLocking = ({Member locking NewProp} orelse
                   {HasPropertyParents Parents `ooLocking`})
      IsNative  = ({Member native NewProp}  orelse
                   {HasPropertyParents Parents `ooNative`})
      IsFinal   = {Member final   NewProp}
      NoNewMeth = {Width NewMeth}
      AsNewAttr = {Arity NewAttr}
      AsNewFeat = {Arity NewFeat}
   in
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
         Meth     = {Dictionary.clone P.`ooMeth`}
         FastMeth = {Dictionary.clone P.`ooFastMeth`}
         Defaults = {Dictionary.clone P.`ooDefaults`}
         {SetMeth NoNewMeth NewMeth Meth FastMeth Defaults}
         %% Attributes
         Attr     = {Adjoin P.`ooAttr` NewAttr}
         %% Features
         Feat     = {Adjoin P.`ooUnFreeFeat` NewFeat}
         FreeFeat = {MakeFree Feat}
         if IsFinal then skip else
            MethSrc  = {Dictionary.clone P.`ooMethSrc`}
            AttrSrc  = {Dictionary.clone P.`ooAttrSrc`}
            FeatSrc  = {Dictionary.clone P.`ooFeatSrc`}
            {DefMeth NoNewMeth NewMeth MethSrc C}
            {DefOther AsNewAttr AttrSrc C}
            {DefOther AsNewFeat FeatSrc C}
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
            {`RaiseError` object(conflicts PrintName 'meth':MCs 'attr':ACs 'feat':FCs)}
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
            {CollectOther {Dictionary.keys AttrSrc} AttrSrc `ooAttr` TmpAttr}
            {SetOther AsNewAttr NewAttr TmpAttr}
            {DefOther AsNewAttr AttrSrc C}
            Attr={Dictionary.toRecord 'attr' TmpAttr}
         end
         %% Construct features
         local
            TmpFeat={Dictionary.new}
         in
            {CollectOther {Dictionary.keys FeatSrc} FeatSrc `ooUnFreeFeat` TmpFeat}
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
      C = {MakeClass FastMeth
           if IsFinal then
              'class'(`ooAttr`:       Attr
                      `ooFreeFeatR`:  FreeFeat
                      `ooUnFreeFeat`: Feat
                      `ooMeth`:       Meth
                      `ooFastMeth`:   FastMeth
                      `ooDefaults`:   Defaults
                      `ooPrintName`:  PrintName
                      `ooLocking`:    IsLocking
                      `ooNative`:     IsNative
                      `ooFallback`:   Fallback)
           else
              %% Mark these dictionaries safe as it comes to marshalling
              {MarkSafe MethSrc}
              {MarkSafe AttrSrc}
              {MarkSafe FeatSrc}
              'class'(`ooParents`:    Parents       % List of classes
                      %% Information for methods
                      `ooMethSrc`:    MethSrc       % Dictionary
                      `ooMeth`:       Meth          % Dictionary
                      `ooFastMeth`:   FastMeth      % Dictionary
                      `ooDefaults`:   Defaults      % Dictionary
                      %% Information for attributes
                      `ooAttrSrc`:    AttrSrc       % Record
                      `ooAttr`:       Attr          % Record
                      %% Information for features
                      `ooFeatSrc`:    FeatSrc       % Dictionary
                      `ooUnFreeFeat`: Feat          % Record (rename, check)
                                                    % also free features
                      `ooFreeFeatR`:  FreeFeat      % Record (rename, check)
                      %% Other info
                      `ooPrintName`:  PrintName     % Atom
                      `ooFallback`:   Fallback      % Record
                      `ooLocking`:    IsLocking     % Bool
                      `ooNative`:     IsNative)     % Bool
           end
           Feat Defaults IsLocking IsNative}
   end
   fun {!`extend` From NewFeat NewFreeFeat}
      %% Methods
      Defaults  = From.`ooDefaults`
      Locking   = From.`ooLocking`
      Native    = From.`ooNative`
      Meth      = From.`ooMeth`
      FastMeth  = From.`ooFastMeth`
      %% Attributes
      Attr      = From.`ooAttr`
      %% Misc
      PrintName = From.`ooPrintName`
      %% Features
      Feat      = {AddFree {Adjoin From.`ooUnFreeFeat` NewFeat} NewFreeFeat}
      FreeFeat  = {MakeFree Feat}
   in
      {MakeClass FastMeth c(`ooAttr`:       Attr
                            `ooFreeFeatR`:  FreeFeat
                            `ooUnFreeFeat`: Feat
                            `ooMeth`:       Meth
                            `ooFastMeth`:   FastMeth
                            `ooDefaults`:   Defaults
                            `ooPrintName`:  PrintName
                            `ooLocking`:    Locking
                            `ooNative`:     Native
                            `ooFallback`:   Fallback)
       Feat Defaults Locking Native}
   end

   %% %%%%%%%%%%%%%%%%%%%%
   %% The Class BaseObject
   %% %%%%%%%%%%%%%%%%%%%%

   class !BaseObject

      meth noop
         skip
      end

   end


   %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% %  The Classes Object.master and Object.slave
   %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   local
      Slaves   = {NewName}
      AddSlave = {NewName}
      DelSlave = {NewName}
   in
      class MasterObject from BaseObject
         attr !Slaves: nil
         meth init
            Slaves <- nil
         end
         meth getSlaves($)
            @Slaves
         end
         meth !AddSlave(S)
            OldSlaves
         in
            OldSlaves = (Slaves <- S|OldSlaves)
         end
         meth DoDel(Ss DS $)
            S|Sr=Ss
         in
            if S==DS then Sr else S|MasterObject,DoDel(Sr DS $) end
         end
         meth !DelSlave(S)
            OldSlaves NewSlaves
         in
            OldSlaves = (Slaves <- NewSlaves)
            NewSlaves = MasterObject,DoDel(OldSlaves S $)
         end
      end

      class SlaveObject from BaseObject
         attr
            Master:unit
         meth becomeSlave(M)
            OldMaster NewMaster
         in
            OldMaster = (Master <- NewMaster)
            if OldMaster==unit then
               {M AddSlave(self)}
               NewMaster = M
            else
               NewMaster = OldMaster
               {`RaiseError` object(slaveNotFree)}
            end
         end
         meth isFree($)
            @Master==unit
         end
         meth free
            OldMaster NewMaster
         in
            OldMaster = (Master <- NewMaster)
            if OldMaster==unit then
               {`RaiseError` object(slaveAlreadyFree)}
            else
               {OldMaster DelSlave(self)}
               NewMaster = unit
            end
         end
      end
   end

   local
      PRIVATE = {NewName}
   in
      class MetaObject

         meth GetAttr(As $)
            case As of nil then nil
            [] A|Ar then (A|@A)|{self GetAttr(Ar $)}
            end
         end

         meth GetFeat(Fs $)
            case Fs of nil then nil
            [] F|Fr then (F|self.F)|{self GetFeat(Fr $)}
            end
         end

         meth toChunk($)
            C = {Class.get self}
         in
            {Chunk.new
             c(PRIVATE:
                  o('class': C
                    'attr':  {self GetAttr({Arity C.`ooAttr`} $)}
                    'feat':  {self GetFeat({Arity C.`ooFreeFeatR`} $)}))}
         end

         meth SetAttr(AXs)
            case AXs of nil then skip
            [] AX|AXr then A|X=AX in A<-X {self SetAttr(AXr)}
            end
         end

         meth SetFeat(FXs)
            case FXs of nil then skip
            [] FX|FXr then F|X=FX in self.F=X {self SetFeat(FXr)}
            end
         end

         meth frmChunk(Ch)
            o('class':C 'attr':A 'feat':F) = Ch.PRIVATE
         in
            C={Class.get self}
            {self SetAttr(A)}
            {self SetFeat(F)}
         end

         meth clone($)
            C = {Class.get self}
            O = {New C SetAttr({self GetAttr({Arity C.`ooAttr`} $)})}
         in
            {O SetFeat({self GetFeat({Arity C.`ooFreeFeatR`} $)})}
            O
         end
      end
   end

in

   Object=object(
                 %% Globally available
                 is:              IsObject
                 new:             New
                 base:            BaseObject
                 meta:            MetaObject
                 ',':             Boot_Object.','
                 '@':             Boot_Object.'@'
                 '<-':            Boot_Object.'<-'
                 exchange:        Boot_Object.ooExch
                 'class':         `class`

                 %% only in module
                 send:            Boot_Object.send
                 master:          MasterObject
                 slave:           SlaveObject
                )
end

\else
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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


%%
%% Object and Class Creation
%%

`extend` BaseObject
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
   %% Builtins needed for class creation
   %%
   MakeClass = Boot_Object.makeClass
   MarkSafe  = Boot_Dictionary.markSafe

   local
      %% Initialize mapping from ids to classes and return classes
      fun {InitMap Cs ITCM IG FCs}
         case Cs of nil then FCs
         [] C|Cr then I=C.`ooId` in
            {InitMap Cr ITCM IG
             if {Dictionary.member ITCM I} then FCs
             else
                {Dictionary.put ITCM I C}
                {Dictionary.put IG   I nil}
                {InitMap C.`ooParents` ITCM IG C|FCs}
             end}
         end
      end

      %% Build inheritance graph
      proc {AddIG I1 C1r IG}
         %% Note that classes are in inverse order!
         case C1r of nil then skip
         [] C2|C2r then
            I2=C2.`ooId` Is={Dictionary.get IG I2}
         in
            {Dictionary.put IG I2
             if {Member I1 Is} then Is else I1|Is end}
            {AddIG I2 C2r IG}
         end
      end

      proc {InitIG Cs IG}
         case Cs of nil then skip
         [] C|Cr then {AddIG C.`ooId` C.`ooParents` IG} {InitIG Cr IG}
         end
      end

      local
         %% Compute precedence
         fun {Remove Xs Y}
            case Xs of nil then nil
            [] X|Xr then if X==Y then Xr else X|{Remove Xr Y} end
            end
         end

         fun {RemoveBefore Is L ITCM IG NLs}
            case Is of nil then NLs
            [] I|Ir then
               if {Dictionary.member IG I} then
                  case {Remove {Dictionary.get IG I} L}
                  of nil then
                     {Dictionary.remove IG I}
                     {RemoveBefore Ir L ITCM IG {Dictionary.get ITCM I}|NLs}
                  elseof Ps then
                     {Dictionary.put IG I Ps}
                     {RemoveBefore Ir L ITCM IG NLs}
                  end
               else
                  {RemoveBefore Ir L ITCM IG NLs}
               end
            end
         end

         fun {RemoveLeader Ls Is ITCM IG NLs}
            %% Forall Is remove the leaders Ls and compute new leaders
            case Ls of nil then NLs
            [] L|Lr then
               {RemoveLeader Lr Is ITCM IG
                {RemoveBefore Is L.`ooId` ITCM IG NLs}}
            end
         end

         fun {GetPairs ITCM IG}
            %% Used for supplying error info
            {FoldR {Dictionary.entries IG}
             fun {$ A#Bs Ps}
                CA={Dictionary.get ITCM A}
             in
                {FoldR Bs fun {$ B Ps}
                             CB={Dictionary.get ITCM B}
                          in
                             CA.`ooPrintName` # CB.`ooPrintName`|Ps
                          end Ps}
             end nil}
         end
      in
         fun {Iterate Ls ITCM IG}
            case {RemoveLeader Ls {Dictionary.keys IG} ITCM IG nil} of nil then
               if {Dictionary.keys IG}==nil then nil
               else {`RaiseError` object(order {GetPairs ITCM IG})} _
               end
            elseof NLs then NLs|{Iterate NLs ITCM IG}
            end
         end
      end
   in
      fun {Precedence C}
         %% Computes the precedence of C not including C!
         ITCM = {Dictionary.new} % Mapping of class ids to classes
         IG   = {Dictionary.new} % Inheritance graph
      in
         {InitIG {InitMap [C] ITCM IG nil} IG}
         {Dictionary.remove IG C.`ooId`}
         {Iterate [C] ITCM IG}
      end
   end


   %%
   %% Compute method tables
   %%
   local
      NoArg = {NewName}

      proc {SetOne One Meth FastMeth Defaults}
         %% Enters a single method
         L = One.1
         if {IsLiteral L} then skip else
            {Exception.raiseError
             object(nonLiteralMethod L)}
         end
         M = One.2
         F = {CondSelect One fast    NoArg}
         D = {CondSelect One default NoArg}
      in
         {Dictionary.put Meth L M}
         if F==NoArg then {Dictionary.remove FastMeth L}
         else {Dictionary.put FastMeth L F}
         end
         if D==NoArg then {Dictionary.remove Defaults L}
         else {Dictionary.put Defaults L D}
         end
      end
   in
      proc {SetMethods N NewMeth Meth FastMeth Defaults}
         %% NewMeth:  tuple of method specifications
         %% Meth:     dictionary of methods
         %% FastMeth: dictionary of fast-methods
         %% Defaults: dictionary of defaults
         if N\=0 then One=NewMeth.N in
            {SetOne One Meth FastMeth Defaults}
            {SetMethods N-1 NewMeth Meth FastMeth Defaults}
         end
      end

      local
         %% Adding of non conflicting methods
         proc {AddMethods N NewMeth Meth FastMeth Defaults}
            %% Spec of args as with EnterMethods
            if N\=0 then One=NewMeth.N in
               if {Dictionary.member Meth One.1} then skip else
                  {SetOne One Meth FastMeth Defaults}
               end
               {AddMethods N-1 NewMeth Meth FastMeth Defaults}
            end
         end

         proc {SafeAdd N NewMeth C SoFar Meth FastMeth Defaults}
            if N\=0 then
               One=NewMeth.N L=One.1
            in
               if {Dictionary.member SoFar L} then
                  ConflictC = {Dictionary.get SoFar L}
               in
                  {`RaiseError` object(sharing
                                       C.`ooPrintName`
                                       ConflictC.`ooPrintName`
                                       'method' L)}
               elseif {Dictionary.member Meth L} then skip else
                  {Dictionary.put SoFar L C} % Store conflict class
                  {SetOne One Meth FastMeth Defaults}
               end
               {SafeAdd N-1 NewMeth C SoFar Meth FastMeth Defaults}
            end
         end

         proc {SafeAddMethods Cs SoFar Meth FastMeth Defaults}
            case Cs of nil then skip
            [] C|Cr then NewMeth=C.`ooNewMeth` in
               {SafeAdd {Width NewMeth} NewMeth C SoFar Meth FastMeth Defaults}
               {SafeAddMethods Cr SoFar Meth FastMeth Defaults}
            end
         end
      in
         proc {InheritMethods OCs Meth FastMeth Defaults}
            case OCs of nil then skip
            [] Cs|OCr then C|Cr=Cs in
               if Cr==nil then NewMeth=C.`ooNewMeth` in
                  {AddMethods {Width NewMeth} NewMeth Meth FastMeth Defaults}
               else
                  {SafeAddMethods Cs {Dictionary.new} Meth FastMeth Defaults}
               end
               {InheritMethods OCr Meth FastMeth Defaults}
            end
         end
      end
   end

   %%
   %% Compute attributes and features
   %%

   local
      proc {AddOther As R D}
         case As of nil then skip
         [] A|Ar then
            if {Dictionary.member D A} then skip else
               {Dictionary.put D A R.A}
            end
            {AddOther Ar R D}
         end
      end

      proc {SafeAdd As R C SoFar D}
         case As of nil then skip
         [] A|Ar then
            if {Dictionary.member SoFar A} then
               ConflictC = {Dictionary.get SoFar A}
            in
               {`RaiseError` object(sharing
                                    C.`ooPrintName`
                                    ConflictC.`ooPrintName`
                                    'feature or attribute' A)}
            elseif {Dictionary.member D A} then skip
            else
               {Dictionary.put D A R.A}
               {Dictionary.put SoFar A C} % Store class from which inherited
            end
            {SafeAdd Ar R C SoFar D}
         end
      end

      proc {SafeAddOther Cs SoFar D T}
         case Cs of nil then skip
         [] C|Cr then R=C.T in
            {SafeAdd {Arity R} R C SoFar D}
            {SafeAddOther Cr SoFar D T}
         end
      end
   in
      proc {InheritOther OCs D T}
         case OCs of nil then skip
         [] Cs|OCr then C|Cr=Cs in
            if Cr==nil then R=C.T in {AddOther {Arity R} R D}
            else {SafeAddOther Cs {Dictionary.new} D T}
            end
            {InheritOther OCr D T}
         end
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
      fun {Add A}
         A#`ooFreeFlag`
      end
   in
      fun {AddFree R As}
         {AdjoinList R {Map As Add}}
      end
   end

   %%
   %% Check parents for non-final classes
   %%

   proc {CheckParents Cs PrintName}
      case Cs of nil then skip
      [] C|Cr then
         if {HasFeature C `ooPrintName`} then
            if {HasFeature C `ooParents`} then skip else
               {`RaiseError` object(final C.`ooPrintName` PrintName)}
            end
         else {`RaiseError` object(inheritanceFromNonClass
                                   C PrintName)}
         end
         {CheckParents Cr PrintName}
      end
   end

   %%
   %% Test whether at least one parent has a certain property
   %%
   fun {HasPropertyParents Cs Prop}
      case Cs of nil then false
      [] C|Cr then C.Prop orelse {HasPropertyParents Cr Prop}
      end
   end


   %%
   %% The real class creation
   %%

   proc {`class` Parents NewMeth NewAttr NewFeat NewProp PrintName ?C}
      {CheckParents Parents PrintName}
      %% To be computed for methods
      Meth FastMeth Defaults
      %% To be computed for attributes
      Attr
      %% To be computed for features
      Feat FreeFeat
      %% Misc
      IsLocking = {Member locking NewProp} orelse {HasPropertyParents Parents `ooLocking`}
      IsNative  = {Member native NewProp}  orelse {HasPropertyParents Parents `ooNative`}
      IsFinal   = {Member final   NewProp}
      TmpC = c(`ooId`:         {NewName}         % Name
               `ooParents`:    {Reverse Parents} % List of classes
               %% Information for methods
               `ooNewMeth`:    NewMeth       % Tuple of specs
               `ooMeth`:       Meth          % Dictionary
               `ooFastMeth`:   FastMeth      % Dictionary
               `ooDefaults`:   Defaults      % Dictionary
               %% Information for attributes
               `ooNewAttr`:    NewAttr       % Record
               `ooAttr`:       Attr          % Record
               %% Information for features
               `ooNewFeat`:    NewFeat       % Record
               `ooUnFreeFeat`: Feat          % Record (rename, check)
                                          % also includes free features
               `ooFreeFeatR`:  FreeFeat      % Record (rename, check)
               %% Other info
               `ooPrintName`:  PrintName     % Atom
               `ooFallback`:   Fallback      % Record
               `ooLocking`:    IsLocking     % Bool
               `ooNative`:     IsNative     % Bool
              )
   in
      case Parents of nil then
         %% Methods
         Meth     = {Dictionary.new}
         FastMeth = {Dictionary.new}
         Defaults = {Dictionary.new}
         {SetMethods {Width NewMeth} NewMeth Meth FastMeth Defaults}
         %% Attributes
         Attr     = NewAttr
         %% Features
         Feat     = NewFeat
         FreeFeat = {MakeFree Feat}
      [] P1|P1r then
         if P1r==nil then
            %% Methods
            Meth     = {Dictionary.clone P1.`ooMeth`}
            FastMeth = {Dictionary.clone P1.`ooFastMeth`}
            Defaults = {Dictionary.clone P1.`ooDefaults`}
            {SetMethods {Width NewMeth} NewMeth Meth FastMeth Defaults}
            %% Attributes
            Attr     = {Adjoin P1.`ooAttr` NewAttr}
            %% Features
            Feat     = {Adjoin P1.`ooUnFreeFeat` NewFeat}
            FreeFeat = {MakeFree Feat}
         else OCs={Precedence TmpC} in
            %% Methods
            Meth     = {Dictionary.new}
            FastMeth = {Dictionary.new}
            Defaults = {Dictionary.new}
            {SetMethods {Width NewMeth} NewMeth Meth FastMeth Defaults}
            {InheritMethods OCs Meth FastMeth Defaults}
            %% Attributes
            local
               TmpAttr = {Record.toDictionary NewAttr}
            in
               {InheritOther OCs TmpAttr `ooNewAttr`}
               Attr = {Dictionary.toRecord a TmpAttr}
            end
            %% Features
            local
               TmpFeat = {Record.toDictionary NewFeat}
            in
               {InheritOther OCs TmpFeat `ooNewFeat`}
               Feat     = {Dictionary.toRecord f TmpFeat}
               FreeFeat = {MakeFree Feat}
            end
         end
      end

      %% Mark these dictionaries safe as it comes to marshalling
      {MarkSafe Meth}
      {MarkSafe FastMeth}
      {MarkSafe Defaults}

      %% Create the real class
      C = {MakeClass FastMeth
           if IsFinal then
              'class'(`ooAttr`:       Attr
                      `ooFreeFeatR`:  FreeFeat
                      `ooUnFreeFeat`: Feat
                      `ooMeth`:       Meth
                      `ooFastMeth`:   FastMeth
                      `ooDefaults`:   Defaults
                      `ooPrintName`:  PrintName
                      `ooLocking`:    IsLocking
                      `ooNative`:     IsNative
                      `ooFallback`:   Fallback)
           else TmpC
           end
           Feat Defaults IsLocking IsNative}
   end
   fun {!`extend` From NewFeat NewFreeFeat}
      %% Methods
      Defaults  = From.`ooDefaults`
      Locking   = From.`ooLocking`
      Native    = From.`ooNative`
      Meth      = From.`ooMeth`
      FastMeth  = From.`ooFastMeth`
      %% Attributes
      Attr      = From.`ooAttr`
      %% Misc
      PrintName = From.`ooPrintName`
      %% Features
      Feat      = {AddFree {Adjoin From.`ooUnFreeFeat` NewFeat} NewFreeFeat}
      FreeFeat  = {MakeFree Feat}
   in
      {MakeClass FastMeth c(`ooAttr`:       Attr
                            `ooFreeFeatR`:  FreeFeat
                            `ooUnFreeFeat`: Feat
                            `ooMeth`:       Meth
                            `ooFastMeth`:   FastMeth
                            `ooDefaults`:   Defaults
                            `ooPrintName`:  PrintName
                            `ooLocking`:    Locking
                            `ooNative`:     Native
                            `ooFallback`:   Fallback)
       Feat Defaults Locking Native}
   end

   %% %%%%%%%%%%%%%%%%%%%%
   %% The Class BaseObject
   %% %%%%%%%%%%%%%%%%%%%%

   class !BaseObject

      meth noop
         skip
      end

   end


   %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% %  The Classes Object.master and Object.slave
   %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   local
      Slaves   = {NewName}
      AddSlave = {NewName}
      DelSlave = {NewName}
   in
      class MasterObject from BaseObject
         attr !Slaves: nil
         meth init
            Slaves <- nil
         end
         meth getSlaves($)
            @Slaves
         end
         meth !AddSlave(S)
            OldSlaves
         in
            OldSlaves = (Slaves <- S|OldSlaves)
         end
         meth DoDel(Ss DS $)
            S|Sr=Ss
         in
            if S==DS then Sr else S|MasterObject,DoDel(Sr DS $) end
         end
         meth !DelSlave(S)
            OldSlaves NewSlaves
         in
            OldSlaves = (Slaves <- NewSlaves)
            NewSlaves = MasterObject,DoDel(OldSlaves S $)
         end
      end

      class SlaveObject from BaseObject
         attr
            Master:unit
         meth becomeSlave(M)
            OldMaster NewMaster
         in
            OldMaster = (Master <- NewMaster)
            if OldMaster==unit then
               {M AddSlave(self)}
               NewMaster = M
            else
               NewMaster = OldMaster
               {`RaiseError` object(slaveNotFree)}
            end
         end
         meth isFree($)
            @Master==unit
         end
         meth free
            OldMaster NewMaster
         in
            OldMaster = (Master <- NewMaster)
            if OldMaster==unit then
               {`RaiseError` object(slaveAlreadyFree)}
            else
               {OldMaster DelSlave(self)}
               NewMaster = unit
            end
         end
      end
   end

   local
      PRIVATE = {NewName}
   in
      class MetaObject

         meth GetAttr(As $)
            case As of nil then nil
            [] A|Ar then (A|@A)|{self GetAttr(Ar $)}
            end
         end

         meth GetFeat(Fs $)
            case Fs of nil then nil
            [] F|Fr then (F|self.F)|{self GetFeat(Fr $)}
            end
         end

         meth toChunk($)
            C = {Class.get self}
         in
            {Chunk.new
             c(PRIVATE:
                  o('class': C
                    'attr':  {self GetAttr({Arity C.`ooAttr`} $)}
                    'feat':  {self GetFeat({Arity C.`ooFreeFeatR`} $)}))}
         end

         meth SetAttr(AXs)
            case AXs of nil then skip
            [] AX|AXr then A|X=AX in A<-X {self SetAttr(AXr)}
            end
         end

         meth SetFeat(FXs)
            case FXs of nil then skip
            [] FX|FXr then F|X=FX in self.F=X {self SetFeat(FXr)}
            end
         end

         meth frmChunk(Ch)
            o('class':C 'attr':A 'feat':F) = Ch.PRIVATE
         in
            C={Class.get self}
            {self SetAttr(A)}
            {self SetFeat(F)}
         end

         meth clone($)
            C = {Class.get self}
            O = {New C SetAttr({self GetAttr({Arity C.`ooAttr`} $)})}
         in
            {O SetFeat({self GetFeat({Arity C.`ooFreeFeatR`} $)})}
            O
         end
      end
   end

in

   Object=object(
                 %% Globally available
                 is:              IsObject
                 new:             New
                 base:            BaseObject
                 meta:            MetaObject
                 ',':             Boot_Object.','
                 '@':             Boot_Object.'@'
                 '<-':            Boot_Object.'<-'
                 exchange:        Boot_Object.ooExch
                 'class':         `class`

                 %% only in module
                 send:            Boot_Object.send
                 master:          MasterObject
                 slave:           SlaveObject
                )
end
\endif
