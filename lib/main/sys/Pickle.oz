%% Copyright © 2011, Université catholique de Louvain
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%
%% *  Redistributions of source code must retain the above copyright notice,
%%    this list of conditions and the following disclaimer.
%% *  Redistributions in binary form must reproduce the above copyright notice,
%%    this list of conditions and the following disclaimer in the documentation
%%    and/or other materials provided with the distribution.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%% POSSIBILITY OF SUCH DAMAGE.

%%
%% Authors:
%%   Sébastien Doeraene <sjrdoeraene@gmail.com>
%%

functor

require
   GNode at 'x-oz://boot/GNode'
   BootSerializer at 'x-oz://boot/Serializer'
   BootBoot at 'x-oz://boot/Boot'
   Support at 'x-oz://boot/CompilerSupport'
   BootName at 'x-oz://boot/Name'
   BootReflection at 'x-oz://boot/Reflection'
   Debug at 'x-oz://boot/Debug'

prepare

   fun {RecordMapFeatVal R F}
      {List.toRecord {Label R}
       {Map {Record.toListInd R} F}}
   end

   IDToAtom = map(1:int
                  2:float
                  3:bool
                  4:'unit'
                  5:atom
                  6:cons
                  7:tuple
                  8:arity
                  9:record
                  10:builtin
                  11:codearea
                  12:patmatwildcard
                  13:patmatcapture
                  14:patmatconjunction
                  15:patmatopenrecord

                  16:abstraction
                  17:chunk
                  18:uniquename
                  19:name
                  20:namedname
                 )

   AtomToID = {RecordMapFeatVal IDToAtom fun {$ ID#Atom} Atom#ID end}

export
   Save
   SaveCompressed
   SaveWithHeader
   SaveWithCells

   Load
   LoadWithHeader

   Pack
   PackWithCells
   Unpack

   WriteValueToSink
   ReadValueFromSource

import
   Open

define

   HeaderMagic = [0x56 0xb4 0x8c 0x48]

   %%
   %% Sinks - thing that we can pickle into
   %%

   class OpenSink
      feat file

      meth init(File)
         self.file = File
      end

      meth write(VBS)
         {self.file write(vs:VBS)}
      end
   end

   class VBSSink
      feat head
      attr tail

      meth init
         self.head = @tail
      end

      meth write(VBS)
         NewTail in VBS|NewTail = tail <- NewTail
      end

      meth get($)
         @tail = nil
         {List.toTuple '#' self.head}
      end
   end

   %%
   %% Sources - thing that we can unpickle from
   %%

   class OpenSource
      feat file

      meth init(File)
         self.file = File
      end

      meth read(Size ?Result ?ActualSize)
         {self.file read(size:Size list:?Result len:?ActualSize)}
      end
   end

   class VBSSource
      attr pointer

      meth init(VBS)
         pointer <- {VirtualByteString.toList VBS}
      end

      meth read(Size ?Result ?ActualSize)
         OldPtr NewPtr
      in
         OldPtr = pointer <- NewPtr
         {List.takeDrop OldPtr Size ?Result ?NewPtr}
         ActualSize = {Length Result}
      end
   end

   %%
   %% Save and its variants
   %%

   proc {Save Value FileName}
      {SaveWithHeader Value FileName nil 0}
   end

   proc {SaveCompressed Value FileName Level}
      {SaveWithHeader Value FileName nil Level}
   end

   proc {SaveWithHeader Value FileName Header Level}
      File = {New Open.file init(name:FileName flags:[write create truncate])}
   in
      try
         Sink = {New OpenSink init(File)}
      in
         % TODO Actually write the header
         %{Sink write(Header)}
         %{Sink write(HeaderMagic)}
         {WriteValueToSink Sink Value}
      finally
         {File close}
      end
   end

   proc {SaveWithCells Value FileName Header Level}
      {SaveWithHeader Value FileName Header Level}
   end

   %%
   %% Load and its variants
   %%

   fun {Load URL}
      {LoadWithHeader URL}.2
   end

   fun {LoadWithHeader URL}
      File = {New Open.file init(url:URL flags:[read])}
   in
      try
         Source = {New OpenSource init(File)}
         Header Value
      in
         % TODO Read the header
         Header = nil
         Value = {ReadValueFromSource Source}
         Header#Value
      finally
         {File close}
      end
   end

   %%
   %% Pack and its variants
   %%

   fun {Pack Value}
      Sink = {New VBSSink init}
   in
      {WriteValueToSink Sink Value}
      {Sink get($)}
   end

   fun {PackWithCells Value}
      {Pack Value}
   end

   %%
   %% Unpack and its variants
   %%

   fun {Unpack VBS}
      Source = {New VBSSource init(VBS)}
   in
      {ReadValueFromSource Source}
   end

   %%
   %% WriteValueToSink -- the real thing for pickling
   %%

   proc {WriteValueToSink Sink TheValue}
      OldSetRaiseOnBlock = {Debug.getRaiseOnBlock {Thread.this}}
      {Debug.setRaiseOnBlock {Thread.this} true}

      Redirections

      ExistingFeatures = {NewDictionary}
      ExistingBuiltins = {NewDictionary}
      ExistingPatMatWildcard
      ExistingPatMatCaptures = {NewDictionary}
      ExistingArities = {NewDictionary}

      proc {Write VBS}
         {VirtualByteString.length VBS _}
         {Sink write(VBS)}
      end

      proc {WriteByte B}
         {Write [B]}
      end

      proc {WriteSize Size}
         {Write [Size div (256*256*256) mod 256
                 Size div (256*256) mod 256
                 Size div 256 mod 256
                 Size mod 256]}
      end

      proc {WriteRef Ref}
         {WriteSize Redirections.Ref}
      end

      proc {WriteUUIDOf Entity}
         {Write {GNode.getUUID {GNode.globalize Entity}}}
      end

      proc {WriteStr VS}
         Bytes = {Coders.encode VS [utf8]}
      in
         {WriteSize {VirtualByteString.length Bytes}}
         {Write Bytes}
      end

      proc {WriteAtom A}
         case A
         of nil then {WriteStr "nil"}
         [] '#' then {WriteStr "#"}
         else {WriteStr A}
         end
      end

      local
         proc {DoWriteRefs T I N}
            if I =< N then
               {WriteRef T.I}
               {DoWriteRefs T I+1 N}
            end
         end
      in
         proc {WriteRefs T N}
            {WriteSize N}
            {DoWriteRefs T 1 N}
         end
      end

      proc {WriteTupleArityRecordValue _ K}
         {WriteRef K.{Width K}}
         {WriteRefs K {Width K}-1}
      end

      proc {WriteCodeAreaValue A K}
         codearea(Code Arity XCount Ks PrintName DebugData) = K
      in
         {WriteUUIDOf A}
         {WriteSize {Width Code}}
         {Record.forAll Code proc {$ I} {Write [(I div 256) (I mod 256)]} end}
         {WriteSize Arity}
         {WriteSize XCount}
         {WriteStr PrintName}
         {WriteRef DebugData}
         {WriteRefs Ks {Width Ks}}
      end

      proc {WritePatMatOpenRecordValue _ K}
         {WriteRef K.{Width K}}
         {WriteRefs K {Width K}-1}
      end

      proc {WritePatMatConjunctionValue _ K}
         {WriteRefs K {Width K}}
      end

      proc {WriteAbstractionValue A K}
         {WriteUUIDOf A}
         {WriteRef K.{Width K}}
         {WriteRefs K {Width K}-1}
      end

      proc {WriteChunkValue _ K}
         {WriteRef K.1}
      end

      proc {WriteResource Value _}
         raise resource(Value) end
      end

      Ser = s(int:proc {$ A _} {WriteStr A} end
              float:proc {$ A _} {WriteStr A} end
              bool:proc {$ A _} {Write if A then [1] else [0] end} end
              'unit':proc {$ _ _} skip end
              atom:proc {$ A _} {WriteAtom A} end
              cons:proc {$ _ K} {WriteRef K.1} {WriteRef K.2} end
              tuple:WriteTupleArityRecordValue
              arity:WriteTupleArityRecordValue
              record:WriteTupleArityRecordValue
              builtin:proc {$ _ K} {WriteAtom K.1} {WriteAtom K.2} end
              codearea:WriteCodeAreaValue
              patmatwildcard:proc {$ _ _} skip end
              patmatcapture:proc {$ _ K} {WriteSize K.1} end
              patmatopenrecord:WritePatMatOpenRecordValue
              patmatconjunction:WritePatMatConjunctionValue

              abstraction:WriteAbstractionValue
              chunk:WriteChunkValue
              uniquename:proc {$ _ K} {WriteAtom K.1} end
              name:proc {$ A _} {WriteUUIDOf A} end
              namedname:proc {$ A K} {WriteUUIDOf A} {WriteAtom K.1} end
             )

      ActualSer = {RecordMapFeatVal Ser fun {$ F#V} AtomToID.F#V end}
   in
      local
         N
         Qs = {BootSerializer.serialize {BootSerializer.new} [TheValue#N]}
         Max = Qs.1

         fun {MakeInfo Qs}
            case Qs
            of nil then nil
            [] I#V#K#Qr then (I#V#K)|{MakeInfo Qr}
            end
         end

         proc {DoPackOne I#V#K}
            TypeID = {CondSelect AtomToID {Label K} 0}
            ValueWriter = {CondSelect ActualSer TypeID WriteResource}
         in
            Redirections.I = I
            {WriteSize I}
            {WriteByte TypeID}
            {ValueWriter V K}
         end

         proc {DoPackOneValueBehaved IVK}
            I#V#K = IVK
         in
            if {IsInt V} orelse {IsLiteral V} then
               case {Dictionary.condGet ExistingFeatures V false}
               of false then
                  {Dictionary.put ExistingFeatures V I}
                  {DoPackOne IVK}
               [] J then
                  Redirections.I = J
               end
            elsecase K
            of builtin(ModName BIName) then
               case {Dictionary.condGet ExistingBuiltins ModName false}
               of false then
                  ModDict = {NewDictionary} in
                  {Dictionary.put ModDict BIName I}
                  {Dictionary.put ExistingBuiltins ModName ModDict}
                  {DoPackOne IVK}
               [] ModDict then
                  case {Dictionary.condGet ModDict BIName false}
                  of false then
                     {Dictionary.put ModDict BIName I}
                     {DoPackOne IVK}
                  [] J then
                     Redirections.I = J
                  end
               end
            [] patmatwildcard then
               if {IsFree ExistingPatMatWildcard} then
                  ExistingPatMatWildcard = I
                  {DoPackOne IVK}
               else
                  Redirections.I = ExistingPatMatWildcard
               end
            [] patmatcapture(Index) then
               case {Dictionary.condGet ExistingPatMatCaptures Index false}
               of false then
                  {Dictionary.put ExistingPatMatCaptures Index I}
                  {DoPackOne IVK}
               [] J then
                  Redirections.I = J
               end
            else
               {DoPackOne IVK}
            end
         end

         proc {DoPackOneArity IVK}
            I#V#K = IVK
            LRef = Redirections.(K.{Width K})

            fun {Loop LRefList}
               case LRefList
               of nil then false
               [] H|T then
                  if H.2 == V then H.1
                  else {Loop T}
                  end
               end
            end
         in
            case {Dictionary.condGet ExistingArities LRef false}
            of false then
               {Dictionary.put ExistingArities LRef [IVK]}
               {DoPackOne IVK}
            [] LRefList then
               case {Loop LRefList}
               of false then
                  {Dictionary.put ExistingArities LRef IVK|LRefList}
                  {DoPackOne IVK}
               [] J then
                  Redirections.I = J
               end
            end
         end

         proc {DoPackSet InfoList PackOneProc Predicate ?RemainingInfo}
            InfoForNow
         in
            {List.partition InfoList Predicate ?InfoForNow ?RemainingInfo}
            {ForAll InfoForNow PackOneProc}
         end

         fun {HasValueBehavior X}
            {BootReflection.getStructuralBehavior X} == value
         end

         Info0 = {MakeInfo Qs}

         ReadOnlyVars = {Filter Info0 fun {$ _#V#_} {Value.isFuture V} end}
      in
         if ReadOnlyVars == nil then
            ResourcesInfo = {Filter Info0 fun {$ _#_#K}
                                             {Not {HasFeature Ser {Label K}}}
                                          end}
            if ResourcesInfo \= nil then
               Resources = {Map ResourcesInfo fun {$ IVK} IVK.2 end}
               Err = dp(generic 'pickle:resources'
                        'Resources found during pickling'
                        ['Resources'#Resources 'Filename'#'UNKNOWN FILENAME'])
            in
               {Exception.raiseError Err}
            end

            !Redirections = {MakeTuple '#' Max}

            {WriteSize Max}
            {WriteSize N}

            Info1 = {DoPackSet Info0 DoPackOneValueBehaved
                     fun {$ _#V#_}
                        {HasValueBehavior V}
                     end}
            Info2 = {DoPackSet Info1 DoPackOne
                     fun {$ _#V#_}
                        {IsLiteral V}
                     end}
            Info3 = {DoPackSet Info2 DoPackOneArity
                     fun {$ _#V#_}
                        {Support.isArity V}
                     end}
            {Record.forAllInd Redirections
             proc {$ I J} if {IsFree J} then J = I end end}
            Info4 = {DoPackSet Info3 DoPackOne
                     fun {$ _#_#K}
                        L = {Label K}
                     in
                        L \= abstraction andthen L \= chunk
                     end}
            Info5 = {DoPackSet Info4 DoPackOne fun {$ _} true end}
         in
            true = Info5 == nil
            {WriteSize 0}

            {Debug.setRaiseOnBlock {Thread.this} OldSetRaiseOnBlock}
         else % ReadOnlyVars \= nil
            % Wait for all the read only variables, then try again
            {Debug.setRaiseOnBlock {Thread.this} false}
            {ForAll ReadOnlyVars proc {$ _#V#_} {Value.makeNeeded V} end}
            {ForAll ReadOnlyVars proc {$ _#V#_} {Wait V} end}
            {Debug.setRaiseOnBlock {Thread.this} OldSetRaiseOnBlock}
            {WriteValueToSink Sink TheValue}
         end
      end
   end

   %%
   %% ReadValueFromSource -- the read thing for unpickling
   %%

   fun {ReadValueFromSource Source}
      proc {Read Size ?Result}
         if {Source read(Size ?Result $)} \= Size then
            {Exception.raiseError eofTooEarly}
         end
      end

      fun {ReadByte}
         {Read 1}.1
      end

      fun {ReadInt}
         [A B C D] = {Read 4}
      in
         A*(256*256*256) + B*(256*256) + C*256 + D
      end

      fun {ReadUUID}
         {VirtualByteString.toCompactByteString {Read 16}}
      end

      fun {ReadStr}
         Len = {ReadInt}
      in
         {Coders.decode {Read Len} [utf8]}
      end

      fun {ReadAtom}
         {VirtualString.toAtom {ReadStr}}
      end

      fun {ReadRef}
         Nodes.{ReadInt}
      end

      proc {ReadRefs Count ?R}
         R = {Tuple.make '#' Count}
         {Record.forAll R ReadRef}
      end

      fun {ReadTupleValue}
         L = {ReadRef}
         W = {ReadInt}
         Fields = {ReadRefs W}
      in
         {Adjoin Fields L}
      end

      fun {ReadArityValue}
         L = {ReadRef}
         W = {ReadInt}
         Features = {ReadRefs W}
      in
         {Support.makeArityDynamic L Features true}
      end

      fun {ReadRecordValue}
         A = {ReadRef}
         W = {ReadInt}
         Fields = {ReadRefs W}
      in
         {Support.makeRecordFromArity A Fields}
      end

      fun {ReadBuiltinValue}
         ModuleName = {ReadAtom}
         BuiltinName = {ReadAtom}
      in
         {BootBoot.getInternal ModuleName}.BuiltinName
      end

      fun {MakeCode RawCode}
         case RawCode
         of nil then nil
         [] Hi|Lo|T then (Hi*256 + Lo)|{MakeCode T}
         end
      end

      fun {ReadGlobalEntity CreateFun SkipProc}
         UUID = {ReadUUID}
         GlobalNode
      in
         if {GNode.load UUID ?GlobalNode} then
            {SkipProc}
            {GNode.getValue GlobalNode}
         else
            {CreateFun UUID GlobalNode}
         end
      end

      fun {ReadCodeAreaValue}
         {ReadGlobalEntity
            proc {$ UUID GlobalNode ?Result}
               CodeSize = {ReadInt}
               Code = {MakeCode {Read CodeSize*2}}
               Arity = {ReadInt}
               XCount = {ReadInt}
               PrintName = {ReadAtom}
               DebugData = {ReadRef}
               KCount = {ReadInt}
               Ks = {Record.toList {ReadRefs KCount}}
            in
               Result = {Support.newCodeArea Code Arity XCount Ks
                                             PrintName DebugData}
               {Support.setUUID Result UUID}
            end
            proc {$}
               CodeSize = {ReadInt}
               {Read CodeSize*2 + (4 + 4) _}
               {ReadStr _}
               {ReadInt _}
               KCount = {ReadInt}
            in
               {Read KCount*4 _}
            end}
      end

      fun {ReadPatMatConjunctionValue}
         W = {ReadInt}
         Parts = {ReadRefs W}
      in
         {Support.newPatMatConjunction Parts}
      end

      fun {ReadPatMatOpenRecordValue}
         A = {ReadRef}
         W = {ReadInt}
         Fields = {ReadRefs W}
      in
         {Support.newPatMatOpenRecord A Fields}
      end

      fun {ReadAbstractionValue}
         {ReadGlobalEntity
            proc {$ UUID GlobalNode ?Result}
               CodeArea = {ReadRef}
               GCount = {ReadInt}
               Gs = {Record.toList {ReadRefs GCount}}
            in
               Result = {Support.newAbstraction CodeArea Gs}
               {Support.setUUID Result UUID}
            end
            proc {$}
               {ReadInt _}
               PartCount = {ReadInt}
            in
               {Read PartCount*4 _}
            end}
      end

      fun {ReadChunkValue}
         Underlying = {ReadRef}
      in
         {Chunk.new Underlying}
      end

      fun {ReadNameValue}
         {ReadGlobalEntity
            proc {$ UUID GlobalNode ?R}
               R = {BootName.newWithUUID UUID}
               {GNode.getValue GlobalNode} = R
               {GNode.getProto GlobalNode} = immval
            end
            proc {$}
               skip
            end}
      end

      fun {ReadNamedNameValue}
         {ReadGlobalEntity
            proc {$ UUID GlobalNode ?R}
               PrintName = {ReadAtom}
            in
               R = {BootName.newNamedWithUUID PrintName UUID}
               {GNode.getValue GlobalNode} = R
               {GNode.getProto GlobalNode} = immval
            end
            proc {$}
               {ReadStr _}
            end}
      end

      Deser = d(int:fun {$} {StringToInt {ReadStr}} end
                float:fun {$} {StringToFloat {ReadStr}} end
                bool:fun {$} {Read 1}.1 \= 0 end
                'unit':fun {$} unit end
                atom:fun {$} {ReadAtom} end
                cons:fun {$} H = {ReadRef} T = {ReadRef} in H|T end
                tuple:ReadTupleValue
                arity:ReadArityValue
                record:ReadRecordValue
                builtin:ReadBuiltinValue
                codearea:ReadCodeAreaValue
                patmatwildcard:fun {$} {Support.newPatMatWildcard} end
                patmatcapture:fun {$} {Support.newPatMatCapture {ReadInt}} end
                patmatconjunction:ReadPatMatConjunctionValue
                patmatopenrecord:ReadPatMatOpenRecordValue

                abstraction:ReadAbstractionValue
                chunk:ReadChunkValue
                uniquename:fun {$} {BootName.newUnique {ReadAtom}} end
                name:ReadNameValue
                namedname:ReadNamedNameValue
               )

      ActualDeser = {RecordMapFeatVal Deser fun {$ F#V} AtomToID.F#V end}

      NodeCount = {ReadInt}
      Nodes = {Tuple.make '#' NodeCount}
      ResultIndex = {ReadInt}

      proc {ReadValuesLoop}
         Index = {ReadInt}
      in
         if Index \= 0 then % 0 means EOF here
            TypeID = {ReadByte}
            ValueReader = ActualDeser.TypeID
            Value = {ValueReader}
         in
            Nodes.Index = Value
            {ReadValuesLoop}
         end
      end
   in
      {ReadValuesLoop}
      Nodes.ResultIndex
   end

end
