%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Martin Mueller, 1997
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


local

   fun {IsFeature X}
      {IsInt X} orelse {IsLiteral X}
   end

   fun {IsOrdered X}
      {IsNumber X} orelse {IsAtom X}
   end

   fun {IsUnary X}
      {IsObject X} orelse
      ({IsProcedure X} andthen {ProcedureArity X}==1)
   end

   fun {IsPair X}
      case X of _#_ then true else false end
   end

   fun {IsListOf Xs P}
      case Xs of nil then true
      [] X|Xr then {P X} andthen {IsListOf Xr P}
      else false end
   end

   fun {IsPairOf X P1 P2}
      {IsPair X} andthen {P1 X.1} andthen {P2 X.2}
   end

   fun {IsRecordOf R Fs P}
      case Fs of nil then true
      [] F|Fr then {P R.F} andthen {IsRecordOf R Fr  P}
      end
   end

   fun {IsPropertyList Xs}
      {IsListOf Xs fun {$ X} {IsPair X} andthen {IsLiteral X.1} end}
   end

   local
      fun {IsComplexDomSpec Xs}
         {IsInt Xs} orelse
         {IsPairOf Xs IsInt IsInt} orelse
         {IsListOf Xs fun {$ X}
                         {IsInt X} orelse {IsPairOf X IsInt IsInt}
                      end}
      end
   in
      fun {IsDomainSpec Xs}
         case Xs
         of compl(Ys) then {IsComplexDomSpec Ys}
         else {IsComplexDomSpec Xs} end
      end
   end

   fun {IsTrue X}
      X == true
   end

   fun {IsFalse X}
      X == false
   end

   fun {IsComparable X}
      {IsNumber X} orelse {IsAtom X}
   end

   fun {IsRecordOrChunk X}
      {IsRecord X} orelse {IsChunk X}
   end

   fun {IsRecordCOrChunk X}
      {IsRecordC X} orelse {IsChunk X}
   end

   fun {IsProcedureOrObject X}
      {IsProcedure X} orelse {IsObject X}
   end

   fun {IsProcedure0 X}
      {IsProcedure X} andthen {Procedure.arity X} == 0
   end

   fun {IsProcedure1 X}
      {IsProcedure X} andthen {Procedure.arity X} == 1
   end

   fun {IsProcedure2 X}
      {IsProcedure X} andthen {Procedure.arity X} == 2
   end

   fun {IsProcedure3 X}
      {IsProcedure X} andthen {Procedure.arity X} == 3
   end

   fun {IsProcedure4 X}
      {IsProcedure X} andthen {Procedure.arity X} == 4
   end

   fun {IsProcedure5 X}
      {IsProcedure X} andthen {Procedure.arity X} == 5
   end

   fun {IsProcedure6 X}
      {IsProcedure X} andthen {Procedure.arity X} == 6
   end

   fun {IsProcedure7Plus X}
      {IsProcedure X} andthen {Procedure.arity X} > 6
   end

in

   functor prop once

   import
      FDB.is
         from 'x-oz://boot/FDB'

      FSB.{isValueB isVarB}
         from 'x-oz://boot/FSB'

      System.{printName}

   export
      is:      Is
      ask:     Ask

   body

      IsFDIntC  = FDB.is
      IsFSet    = FSB.isValueB
      IsFSetC   = FSB.isVarB

      fun {IsFDVector X}
         case {IsRecord X}
         then case {Label X}=='|'
              then {IsListOf X IsFDIntC}
              else {IsRecordOf X {Arity X} IsFDIntC}
              end
         else false end
      end

      Is = is(array:               IsArray
              atom:                IsAtom
              bitArray:            IsBitArray
              bool:                IsBool
              cell:                IsCell
              char:                IsChar
              chunk:               IsChunk
              'class':             IsClass
              comparable:          IsComparable
              dictionary:          IsDictionary
              domainSpec:          IsDomainSpec
              int:                 IsInt
              'false':             IsFalse
              fdIntC:              IsFDIntC
              fdVector:            IsFDVector
              feature:             IsFeature
              float:               IsFloat
              fset:                IsFSet
              fsetC:               IsFSetC
              foreignPointer:      IsForeignPointer
              list:                IsList
              'lock':              IsLock
              literal:             IsLiteral
              name:                IsName
              number:              IsNumber
              object:              IsObject
              ordered:             IsOrdered
              pair:                IsPair
              port:                IsPort
              procedure:           IsProcedure
              'procedure/0':       IsProcedure0
              'procedure/1':       IsProcedure1
              'procedure/2':       IsProcedure2
              'procedure/3':       IsProcedure3
              'procedure/4':       IsProcedure4
              'procedure/5':       IsProcedure5
              'procedure/6':       IsProcedure6
              'procedure/>6':      IsProcedure7Plus
              procedureOrObject:   IsProcedureOrObject
              propertyList:        IsPropertyList
              record:              IsRecord
              recordC:             IsRecordC
              recordOrChunk:       IsRecordOrChunk
              recordCOrChunk:      IsRecordCOrChunk
              space:               IsSpace
              string:              IsString
              'thread':            IsThread
              tuple:               IsTuple
              'true':              IsTrue
              unary:               IsUnary
              'unit':              IsUnit
              value:               fun {$ _} true end
              virtualString:       IsVirtualString
             )

      local
         fun {GenericAsk TypeTest TypeName}
            proc {$ X}
               case {TypeTest X} then skip else
                  {Exception.raiseError kernel(type {System.printName TypeTest}
                                               [X]
                                               TypeName
                                               1
                                               'Type.ask')}
               end
            end
         end
      in
         Ask = ask(generic:           GenericAsk
                   array:             {GenericAsk IsArray array}
                   atom:              {GenericAsk IsAtom atom}
                   bitArray:          {GenericAsk IsBitArray bitArray}
                   bool:              {GenericAsk IsBool bool}
                   cell:              {GenericAsk IsCell cell}
                   char:              {GenericAsk IsChar char}
                   chunk:             {GenericAsk IsChunk chunk}
                   'class':           {GenericAsk IsClass 'class'}
                   comparable:        {GenericAsk IsComparable comparable}
                   dictionary:        {GenericAsk IsDictionary dictionary}
                   domainSpec:        {GenericAsk IsDomainSpec domainSpec}
                   int:               {GenericAsk IsInt int}
                   fdIntC:            {GenericAsk IsFDIntC fd}
                   fdVector:          {GenericAsk IsFDVector fdVector}
                   'false':           {GenericAsk IsTrue 'false'}
                   feature:           {GenericAsk IsFeature feature}
                   float:             {GenericAsk IsFloat float}
                   fset:              {GenericAsk IsFSet fset}
                   fsetC:             {GenericAsk IsFSetC fsetC}
                   foreignPointer:    {GenericAsk IsForeignPointer
                                       foreignPointer}
                   list:              {GenericAsk IsList list}
                   literal:           {GenericAsk IsLiteral literal}
                   'lock':            {GenericAsk IsLock 'lock'}
                   name:              {GenericAsk IsName name}
                   number:            {GenericAsk IsNumber number}
                   object:            {GenericAsk IsObject object}
                   ordered:           {GenericAsk IsOrdered ordered}
                   pair:              {GenericAsk IsPair pair}
                   port:              {GenericAsk IsPort port}
                   procedure:         {GenericAsk IsProcedure procedure}
                   'procedure/0':     {GenericAsk IsProcedure0 'procedure/0'}
                   'procedure/1':     {GenericAsk IsProcedure1 'procedure/1'}
                   'procedure/2':     {GenericAsk IsProcedure2 'procedure/2'}
                   'procedure/3':     {GenericAsk IsProcedure3 'procedure/3'}
                   'procedure/4':     {GenericAsk IsProcedure4 'procedure/4'}
                   'procedure/5':     {GenericAsk IsProcedure5 'procedure/5'}
                   'procedure/6':     {GenericAsk IsProcedure6 'procedure/6'}
                   'procedure/>6':    {GenericAsk IsProcedure7Plus
                                       'procedure/>6'}
                   procedureOrObject: {GenericAsk IsProcedureOrObject
                                       procedureOrObject}
                   propertyList:      {GenericAsk IsPropertyList propertyList}
                   record:            {GenericAsk IsRecord record}
                   recordC:           {GenericAsk IsRecordC recordC}
                   recordOrChunk:     {GenericAsk IsRecordOrChunk
                                       recordOrChunk}
                   recordCOrChunk:    {GenericAsk IsRecordCOrChunk
                                       recordCOrChunk}
                   space:             {GenericAsk IsSpace space}
                   string:            {GenericAsk IsString string}
                   'thread':          {GenericAsk IsThread 'thread'}
                   'true':            {GenericAsk IsTrue 'true'}
                   tuple:             {GenericAsk IsTuple tuple}
                   unary:             {GenericAsk IsUnary unary}
                   'unit':            {GenericAsk IsUnit 'unit'}
                   value:             proc {$ _} skip end
                   virtualString:     {GenericAsk IsVirtualString
                                       virtualString}
                  )
      end

   end

end
