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

declare
   Object
   IsObject
   BaseObject
   New
   %% Needed by other modules
   `extend`              % Module Class
   `ooFreeFlag`          % Module Class
   `ooParents`           % Module Class
   `ooPrintName`         % Module Class
   `ooMeth`              % Module Class
   `ooAttr`              % Module Class
   `ooLocking`           % Module Class
   `ooNative`            % Module Class
   `ooUnFreeFeat`        % Module Class
   `ooFreeFeatR`         % Module Class
in

IsObject      = {`Builtin` 'Object.is'    2}
New           = {`Builtin` 'Object.new'         3}


local
   NewUniqueName = {`Builtin` 'Name.newUnique' 2}
in
   `ooMeth`           = {NewUniqueName 'ooMeth'}
   `ooAttr`           = {NewUniqueName 'ooAttr'}
   `ooLocking`        = {NewUniqueName 'ooLocking'}
   `ooNative`         = {NewUniqueName 'ooNative'}
   `ooParents`        = {NewUniqueName 'ooParents'}
   `ooFreeFlag`       = {NewUniqueName 'ooFreeFlag'}
   `ooPrintName`      = {NewUniqueName 'ooPrintName'}
   `ooUnFreeFeat`     = {NewUniqueName 'ooUnFreeFeat'}
   `ooFreeFeatR`      = {NewUniqueName 'ooFreeFeatR'}
end

%%
%% Object and Class Creation
%%

local

   local
      NewUniqueName = {`Builtin` 'Name.newUnique' 2}
   in
      `ooNewAttr`        = {NewUniqueName 'ooNewAttr'}
      `ooNewFeat`        = {NewUniqueName 'ooNewFeat'}
      `ooFastMeth`       = {NewUniqueName 'ooFastMeth'}
      `ooNewMeth`        = {NewUniqueName 'ooNewMeth'}
      `ooDefaults`       = {NewUniqueName 'ooDefaults'}
      `ooFallback`       = {NewUniqueName 'ooFallback'}
      `ooId`             = {NewUniqueName 'ooId'}
   end


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
               {`RaiseError` object(lookup C.`ooPrintName` Mess)}
            elseof M then {M otherwise(Mess)}
            end
         elseof M then {M Mess}
         end
      end

      local
         NewObject = {`Builtin` 'Object.newObject' 2}
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
   MakeClass = {`Builtin` 'Object.makeClass' 7}
   MarkSafe  = {`Builtin` 'Dictionary.markSafe' 1}

   local
      %% Initialize mapping from ids to classes and return classes
      fun {InitMap Cs ITCM IG FCs}
         case Cs of nil then FCs
         [] C|Cr then I=C.`ooId` in
            {InitMap Cr ITCM IG
             case {Dictionary.member ITCM I} then FCs
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
             case {Member I1 Is} then Is else I1|Is end}
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
            [] X|Xr then case X==Y then Xr else X|{Remove Xr Y} end
            end
         end

         fun {RemoveBefore Is L ITCM IG NLs}
            case Is of nil then NLs
            [] I|Ir then
               case {Dictionary.member IG I} then
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
               case {Dictionary.keys IG}==nil then nil
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
         M = One.2
         F = {CondSelect One fast    NoArg}
         D = {CondSelect One default NoArg}
      in
         {Dictionary.put Meth L M}
         case F==NoArg then {Dictionary.remove FastMeth L}
         else {Dictionary.put FastMeth L F}
         end
         case D==NoArg then {Dictionary.remove Defaults L}
         else {Dictionary.put Defaults L D}
         end
      end
   in
      proc {SetMethods N NewMeth Meth FastMeth Defaults}
         %% NewMeth:  tuple of method specifications
         %% Meth:     dictionary of methods
         %% FastMeth: dictionary of fast-methods
         %% Defaults: dictionary of defaults
         case N==0 then skip else One=NewMeth.N in
            {SetOne One Meth FastMeth Defaults}
            {SetMethods N-1 NewMeth Meth FastMeth Defaults}
         end
      end

      local
         %% Adding of non conflicting methods
         proc {AddMethods N NewMeth Meth FastMeth Defaults}
            %% Spec of args as with EnterMethods
            case N==0 then skip else One=NewMeth.N in
               case {Dictionary.member Meth One.1} then skip else
                  {SetOne One Meth FastMeth Defaults}
               end
               {AddMethods N-1 NewMeth Meth FastMeth Defaults}
            end
         end

         proc {SafeAdd N NewMeth C SoFar Meth FastMeth Defaults}
            case N==0 then skip else
               One=NewMeth.N L=One.1
            in
               case {Dictionary.member SoFar L} then
                  ConflictC = {Dictionary.get SoFar L}
               in
                  {`RaiseError` object(sharing
                                       C.`ooPrintName`
                                       ConflictC.`ooPrintName`
                                       'method' L)}
               elsecase {Dictionary.member Meth L} then skip else
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
               case Cr==nil then NewMeth=C.`ooNewMeth` in
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
            case {Dictionary.member D A} then skip else
               {Dictionary.put D A R.A}
            end
            {AddOther Ar R D}
         end
      end

      proc {SafeAdd As R C SoFar D}
         case As of nil then skip
         [] A|Ar then
            case {Dictionary.member SoFar A} then
               ConflictC = {Dictionary.get SoFar A}
            in
               {`RaiseError` object(sharing
                                    C.`ooPrintName`
                                    ConflictC.`ooPrintName`
                                    'feature or attribute' A)}
            elsecase {Dictionary.member D A} then skip
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
            case Cr==nil then R=C.T in {AddOther {Arity R} R D}
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
            case {IsDet X} andthen X==`ooFreeFlag` then
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
         case {HasFeature C `ooPrintName`} then
            case {HasFeature C `ooParents`} then skip else
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
         case P1r==nil then
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
           case IsFinal then
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

   %%
   %% Run time library
   %%
   {`runTimePut` 'ooPrivate' {`Builtin` 'Name.new' 1}}
   {`runTimePut` '@' {`Builtin` 'Object.\'@\'' 2}}
   {`runTimePut` '<-' {`Builtin` 'Object.\'<-\'' 2}}
   {`runTimePut` 'ooExch' {`Builtin` 'Object.ooExch' 3}}
   {`runTimePut` ',' {`Builtin` 'Object.\',\'' 2}}
   {`runTimePut` 'ooGetLock' {`Builtin` 'Object.ooGetLock' 1}}
   {`runTimePut` 'class' `class`}

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
            case S==DS then Sr else S|MasterObject,DoDel(Sr DS $) end
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
            case OldMaster==unit then
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
            case OldMaster==unit then
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
                 ',':             {`Builtin` 'Object.\',\''           2}
                 '@':             {`Builtin` 'Object.\'@\''           2}
                 '<-':            {`Builtin` 'Object.\'<-\''          2}
                 'class':         `class`

                 %% only in module
                 send:            {`Builtin` 'Object.send' 3}
                 master:          MasterObject
                 slave:           SlaveObject
                )
end
