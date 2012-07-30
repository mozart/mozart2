%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

prepare

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
      else false
      end
   end

   local
      fun {IsPropertyPair X}
         case X of L#_ then {IsLiteral L} else false end
      end
   in
      fun {IsPropertyList Xs}
         {IsListOf Xs IsPropertyPair}
      end
   end

   local
      fun {IsIntOrIntPair X}
         case X of I#J then {IsInt I} andthen {IsInt J}
         else {IsInt X}
         end
      end
      fun {IsComplexDomSpec Xs}
         {IsIntOrIntPair Xs} orelse
         {IsListOf Xs IsIntOrIntPair}
      end
   in
      fun {IsDomainSpec Xs}
         case Xs
         of compl(Ys) then {IsComplexDomSpec Ys}
         else {IsComplexDomSpec Xs}
         end
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

   fun {IsNil X}
      X == nil
   end

   fun {IsCons X}
      case X of _|_ then true else false end
   end

   proc {Ignore _} skip end


import
\ifdef HAS_CSS
   FDB(is: IsFDIntC)
   at 'x-oz://boot/FDB'
   FSB('value.is': IsFSet
       'var.is':   IsFSetC)
   at 'x-oz://boot/FSB'
\endif
   Space(is: IsSpace)
   RecordC(is: IsRecordC)
   System(printName)

export
   is:      Is
   ask:     Ask

define

\ifndef HAS_CSS
   fun {IsFDIntC X} false end
   fun {IsFSet X} false end
   fun {IsFSetC X} false end
\endif

   fun {IsRecordCOrChunk X}
      {IsRecordC X} orelse {IsChunk X}
   end

   fun {IsFDVector X}
      case X of _|_ then
         {IsListOf X IsFDIntC}
      else
         {IsRecord X} andthen {Record.all X IsFDIntC}
      end
   end

   Is = is(array:               IsArray
           atom:                IsAtom
           bitArray:            IsBitArray
           bitString:           IsBitString
           byteString:          IsByteString
           bool:                IsBool
           cell:                IsCell
           char:                IsChar
           chunk:               IsChunk
           'class':             IsClass
           comparable:          IsComparable
           cons:                IsCons
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
           nilAtom:             IsNil
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
      fun {NewAsk TypeTest TypeName}
         proc {$ X}
            if {TypeTest X} then skip else
               {Exception.raiseError kernel(type {System.printName TypeTest}
                                            [X]
                                            TypeName
                                            1
                                            'Type.ask')}
            end
         end
      end
   in

      Ask = ask(generic:           NewAsk
                array:             {NewAsk IsArray array}
                atom:              {NewAsk IsAtom atom}
                bitArray:          {NewAsk IsBitArray bitArray}
                bitString:         {NewAsk IsBitString bitString}
                byteString:        {NewAsk IsByteString byteString}
                bool:              {NewAsk IsBool bool}
                cell:              {NewAsk IsCell cell}
                char:              {NewAsk IsChar char}
                chunk:             {NewAsk IsChunk chunk}
                'class':           {NewAsk IsClass 'class'}
                comparable:        {NewAsk IsComparable comparable}
                cons:              {NewAsk IsCons cons}
                dictionary:        {NewAsk IsDictionary dictionary}
                domainSpec:        {NewAsk IsDomainSpec domainSpec}
                int:               {NewAsk IsInt int}
                fdIntC:            {NewAsk IsFDIntC fd}
                fdVector:          {NewAsk IsFDVector fdVector}
                'false':           {NewAsk IsTrue 'false'}
                feature:           {NewAsk IsFeature feature}
                float:             {NewAsk IsFloat float}
                fset:              {NewAsk IsFSet fset}
                fsetC:             {NewAsk IsFSetC fsetC}
                foreignPointer:    {NewAsk IsForeignPointer
                                    foreignPointer}
                list:              {NewAsk IsList list}
                literal:           {NewAsk IsLiteral literal}
                'lock':            {NewAsk IsLock 'lock'}
                name:              {NewAsk IsName name}
                nilAtom:           {NewAsk IsNil nil}
                number:            {NewAsk IsNumber number}
                object:            {NewAsk IsObject object}
                ordered:           {NewAsk IsOrdered ordered}
                pair:              {NewAsk IsPair pair}
                port:              {NewAsk IsPort port}
                procedure:         {NewAsk IsProcedure procedure}
                'procedure/0':     {NewAsk IsProcedure0 'procedure/0'}
                'procedure/1':     {NewAsk IsProcedure1 'procedure/1'}
                'procedure/2':     {NewAsk IsProcedure2 'procedure/2'}
                'procedure/3':     {NewAsk IsProcedure3 'procedure/3'}
                'procedure/4':     {NewAsk IsProcedure4 'procedure/4'}
                'procedure/5':     {NewAsk IsProcedure5 'procedure/5'}
                'procedure/6':     {NewAsk IsProcedure6 'procedure/6'}
                'procedure/>6':    {NewAsk IsProcedure7Plus
                                    'procedure/>6'}
                procedureOrObject: {NewAsk IsProcedureOrObject
                                    procedureOrObject}
                propertyList:      {NewAsk IsPropertyList propertyList}
                record:            {NewAsk IsRecord record}
                recordC:           {NewAsk IsRecordC recordC}
                recordOrChunk:     {NewAsk IsRecordOrChunk
                                    recordOrChunk}
                recordCOrChunk:    {NewAsk IsRecordCOrChunk
                                    recordCOrChunk}
                space:             {NewAsk IsSpace space}
                string:            {NewAsk IsString string}
                'thread':          {NewAsk IsThread 'thread'}
                'true':            {NewAsk IsTrue 'true'}
                tuple:             {NewAsk IsTuple tuple}
                unary:             {NewAsk IsUnary unary}
                'unit':            {NewAsk IsUnit 'unit'}
                value:             Ignore
                virtualString:     {NewAsk IsVirtualString
                                    virtualString}
               )

   end

end
