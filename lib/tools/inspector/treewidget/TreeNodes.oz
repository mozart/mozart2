%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1999
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor $
import
   CreateObjects
   LayoutObjects
   DrawObjects
export
   Nodes
define
   %% Specify Nodes to be exported
   NodeSpecs = [
                %% Export All Nodes (raw)
                all # nodes('create' : CreateObjects
                            'layout' : LayoutObjects
                            'draw'   : DrawObjects
                            'tree'   : Nodes)

                %% Generic Node
                generic # [generic generic generic]

                %% Atomic Nodes
                int        # [int int base]
                float      # [float float base]
                atom       # [atom atom base]
                name       # [name name base]
                procedure  # [procedure procedure base]
                string     # [string string base]
                byteString # [byteString byteString base]

                %% Container Nodes
                %% Record Variants
                record          # [record record record]
                recordInd       # [recordInd recordInd recordInd]
                kindedRecord    # [kindedRecord record kindedRecord]
                kindedRecordInd # [kindedRecordInd recordInd kindedRecordInd]
                %% Tuple Variants
                hashTuple     # [hashTuple hashTuple hashTuple]
                pipeTuple     # [pipeTuple pipeTuple pipeTuple]
                labelTuple    # [labelTuple labelTuple labelTuple]
                labelTupleInd # [labelTuple labelTupleInd labelTupleInd]

                %% Logic-, Future- and Constraint-Variables
                free     # [free free free]
                future   # [future future future]
                failed   # [failed failed failed]
                fdInt    # [fdInt fdInt fdInt]
                fsVal    # [fsVal fdInt fdInt]
                fsHelper # [fsHelper fdInt fdInt]
                fsVar    # [fsVar fsVar fdInt]

                %% Relation Mode Helper
                variableRef # [variableRef variableRef variableRef]

                %% Container Nodes (Relation Mode)
                %% Record Variants
                recordGr          # [recordGr recordGr recordGr]
                recordGrInd       # [recordGrInd recordGrInd recordGrInd]
                kindedRecordGr    # [kindedRecordGr recordGr kindedRecordGr]
                kindedRecordGrInd # [kindedRecordGr recordGr kindedRecordGrInd]
                %% Tuple Variants
                hashTupleGr     # [hashTupleGr hashTupleGr hashTupleGr]
                pipeTupleGrS    # [pipeTupleGr pipeTupleGr pipeTupleGrS]
                pipeTupleGrM    # [pipeTupleGr pipeTupleGr pipeTupleGrM]
                labelTupleGr    # [labelTupleGr labelTupleGr labelTupleGr]
                labelTupleGrInd # [labelTupleGr labelTupleGrInd labelTupleGrInd]

                %% Logic-, Future- and Constraint-Variants (Relation Mode)
                freeGr   # [freeGr freeGr freeGr]
                futureGr # [futureGr futureGr futureGr]
                fdIntGr  # [fdIntGr fdIntGr fdIntGr]
                fsValGr  # [fsValGr fdIntGr fdIntGr]
                fsVarGr  # [fsVarGr fsVarGr fdIntGr]
               ]
   %% Node Builder
   local
      fun {GetCreate Key}
         CK = if Key == base then createObject else {VirtualString.toAtom Key#'CreateObject'} end
      in
         CreateObjects.CK
      end
      fun {GetLayout Key}
         CK = if Key == base then layoutObject else {VirtualString.toAtom Key#'LayoutObject'} end
      in
         LayoutObjects.CK
      end
      fun {GetDraw Key}
         CK = if Key == base then drawObject else {VirtualString.toAtom Key#'DrawObject'} end
      in
         DrawObjects.CK
      end
   in
      fun {MakeNode [C L D]}
         {Class.new [{GetCreate C} {GetLayout L} {GetDraw D}] 'attr' 'feat' [final]}
      end
   end

   %% Create the Export Record
   Nodes = {Record.make nodes {Map NodeSpecs fun {$ F#_} F end}}
   %% Assign Classes to Export Record
   case NodeSpecs
   of (Feat#Desc)|NodeSpecR then
      Nodes.Feat = Desc %% Assign all without mapping
      {List.forAll NodeSpecR proc {$ Feat#Desc} Nodes.Feat = {MakeNode Desc} end}
   end
end
