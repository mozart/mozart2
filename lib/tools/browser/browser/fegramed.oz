%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Frank Essig
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%
% classes for graphical representation of browsed terms in Fegramed
%
% $ID$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              FE_BrowserClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


local
   FegramedFileExtension = ".feg"
   FegramedPathFile = ".fegramed_path"
in
   class FE_BrowserClass
   %
      attr
         FEApplication : FE_InitValue
         ShowCurrent   : False     % automatically show current term of Browser
      %

      meth browse(Term)
         <<BrowserClass browse(Term)>>
         case @ShowCurrent then
            <<ShowCurrentInFegramed>>
         else true
         end
      end

      %
      meth !FE_Browse   % Show selected term in Fegramed
         case @selected of !InitValue then true
         elseof Sel then  {self ShowTermObjectInFE( Sel )}
         end
      end
      %
      meth !FE_SetShowCurrent(X)
         ShowCurrent <- X
      end
      %
      meth WriteFegramedFile( TermObject ?FileName ?Ack )
         FE FegramedTerm File in
         {FE_GenSym reset}
         FegramedTerm = {TermObject fE_Term( $ )}
         FileName = {Unix.tempName "" "feg"}#!FegramedFileExtension
         File={New Open.file [init(name: FileName
                                   flags: [read write 'create'])
                              write(vs:FegramedTerm) sync(Ack)]}
      end
      %
      meth ShowTermObjectInFE( PseudoObj )
         Ack FileName in
         <<WriteFegramedFile( PseudoObj ?FileName ?Ack )>>
         {Wait Ack}
         extern
            case @FEApplication of !FE_InitValue then
               FEApplication <- {New FE_Application [init newTerm(FileName)]}
            elseof Fegramed then
               case {Fegramed stillAlive($)} then
                  {Fegramed newTerm(FileName)}
               else
                  FEApplication <- {New FE_Application [init newTerm(FileName)]}
               end
            end
         end
      end
      %
      meth ShowCurrentInFegramed
         local PseudoObject in
            PseudoObject =
            {SubtreeIf @current termObject InitValue}

            %%
            case PseudoObject
            of !InitValue then {Show 'FE_BrowserClass::no current'}
            else {self ShowTermObjectInFE( PseudoObject )}
            end
         end
      end
      %
      meth !FE_StartFE
         FEApplication <- {New FE_Application init}
      end
      %
      meth !FE_CloseFE
         case @FEApplication of !FE_InitValue then true
         elseof FE then
            {FE cmd("quit")}
            FEApplication <- FE_InitValue
         end
      end
      meth !FE_CloseAllFE
         case @FEApplication of !FE_InitValue then true
         elseof FE then {FE cmd("closeall")}
         end
      end

   end



% class FE_Application
%

   class FE_Application from Open.pipe Open.text
      feat
         PidI
           %
      meth error( X )
         {BrowserWarning [{S2A {V2S X}}]}
      end

      meth init
         FegramedBin    % = "/usr/share/cl/disco/bin/fegramed"
         FileObject
      in
         case {Unix.system "test -f "#FegramedPathFile} == 0 then
            create FileObject from Open.file
               with [ init(name:FegramedPathFile flags:[read])
                      read(list:{proc{$ X}
                                    if {List.last X} = "\n".1 then
                                       !FegramedBin= {List.take X {List.length X}-1 $}
                                    else
                                       !FegramedBin = X
                                    fi
                                 end})
                      close  ]
            end
            {Wait FegramedBin}
            case {Unix.system "test -x "#FegramedBin} == 0 then
               <<Open.pipe init(cmd: FegramedBin
                                args:["-xrm \"Fegramed.geometry:600x800\""
                                      "-poll"]
                                pid : self.PidI)>>
               {self ReportFE}
            else
               {self error("Wrong path '"#FegramedBin#"'")}
            end
         else
            {self error("Can't find path '"#FegramedPathFile#"'")}
         end
      end
      %
      meth stillAlive( ?B )
         B = True
         /*
         B = case {Unix.system "ps "#self.PidI $} of 0 then True
             else False
             end
         */
      end
      %
      meth cmd(Cmd)
         {self putS(Cmd)}
      end
      %
      meth closed
         {Show 'FE_Application::closed'}
      end
      %
      meth getPidI( ?B )
         B = self.PidI
      end
      %
      %
      meth ReportFE
         %
         case <<Open.text getS($)>>
         of !False then {Show 'Fegramed has died'} {self closed}
         elseof S then
            {Show {String.toAtom {VirtualString.toString 'Fegramed says : '#S }}}
         end
      end
      %
      meth newTerm(FileName)
         \ifdef DEBUG
         {Show 'FE_Application::newTerm'}
         \endif
         {self cmd( "feature="#FileName)}
      end
   end
end  % local



class FE_Generic    % to all FE-Term classes
   %
   attr
      RefNumber
   %
   meth fE_getName( Name ?Back)
      N = case {IsName Name} then {System.getPrintName Name}
          elsecase Name
          of nil then "nil"
          [] ''  then "''"
          else Name
          end
   in
      Back = {List.map {VirtualString.toString N}
              fun{$ X} if X=&  then &_
                       %[] X=&# then "\\#"
                       else X
                       fi
              end
              $}
       end

   %
   meth fE_atomicNode( lab:Lab back:Back )
      Back = Lab
   end

   meth fE_edge( lab:Lab tree:T back:Back )
      Back = ' ( ' # Lab # ' ' # T # ' )'
   end

   meth fE_complexNode( type: T   subTree:SubTree
                     back: Back )
      Back =  T #' '#SubTree
   end

   meth fE_Term(Term)
\ifdef DEBUG
      {Show 'fE_TermObject'}
\endif
      Name = <<fE_getName(self.name $)>> in
      Term = <<fE_atomicNode(lab:Name back:$)>>
   end
   %
   %
   meth fE_getRef(?R)
      R = "#" # @RefNumber
   end
   %
   meth fE_setRef(?R)
      case @refVarName of '' then R=''
      elseof _#X then
         @RefNumber = X
         R= "#"#X#'='
      end
   end
   %
end   % FE_Generic




class FE_PseudoTermObject from FE_Generic
% to PseudoTermGenericObject in pseudoObject
   meth fE_Term(Term)
       \ifdef DEBUG
      {Show 'FE_PseudoTermObject'}
       \endif
      {@termObj fE_Term(Term)}
   end

end







/*************************************  ATOMS, INTS, NAMES, FLOATS  ***/

class FE_AtomObject from FE_Generic     % to AtomTermObject
end                                     % in termObject

class FE_IntObject from FE_Generic
end

class FE_FloatObject from FE_Generic
end

class FE_NameObject from FE_Generic
   meth fE_Term(Term)
      Term = <<fE_setRef($)>>#<<fE_atomicNode( lab:<<fE_getName(self.name $)>> back:$)>>
   end
end




/*********************** TUPLES **************************/

%
class FE_TupleObject from FE_Generic
   %
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_TupleObject'}
\endif
      Objs = <<getObjsList($)>> in
      Term = <<fE_setRef($)>>#<<fE_complexNode(type:Conj
                                         subTree:<<fE_edge(lab:<<fE_getName(self.name $)>>
                                                        tree:<<fE_complexNode(type:Disj
                                                                           subTree:<<fE_getSubTuples(Objs $)>>
                                                                           back:$)>>
                                                        back:$)>>
                                         back:$)>>
   end

   %
   %
  meth fE_getSubTuples(Objs ?X)
     X = {List.foldLInd Objs
          fun{$ I X Y} ' ( %'#I#' '#{Y fE_Term($)}#' ) '#X end '' $}
  end
end



class FE_HashTupleObject from FE_TupleObject
   %
   meth fE_Term(Term)
\ifdef DEBUG_Ob
      {Show 'FE_HashTupleObject'}
\endif
      Objs = <<getObjsList($)>> in
      Term = <<fE_setRef($)>>#<<fE_complexNode(type:Conj
                                         subTree:<<fE_edge(lab:'HASH'
                                                        tree:<<fE_complexNode(type:Disj
                                                                           subTree:<<fE_getSubTuples(Objs $)>>
                                                                           back:$)>>
                                                        back:$)>>
                                         back:$)>>
   end
   %
end






/*********************** LISTS *****************************/

class FE_ListObject from FE_TupleObject      %FE_Generic
   %
   meth fE_Term(Term)
\ifdef DEBUG_Ob
      {Show 'FE_ListObject'}
\endif
      Term = <<fE_setRef($)>>#<<fE_complexNode( type:Lst
                                          subTree:<<GetSubList($)>>
                                          back:$)>>
   end
   %
   meth GetSubList( ?X )
      Objs = <<getObjsList($)>> in
      X = <<fE_getSubTuples(Objs $)>>
   end
end



class FE_FListObject from  FE_ListObject %FE_TupleObject
   %
end


class FE_WFlistObject from FE_TupleObject
   %
   meth fE_Term(Term)
\ifdef DEBUG_Ob
      {Show 'FE_WFlistObject'}
\endif
      Nil=[create $ from !UrObject !FE_AtomObject   % Dummy nil-node
              feat
                 browserObj:self.browserObj
                 name: "nil"
              meth shrink true end
              meth expand true end
              meth zoom   true end
           end]
      Objs= <<getObjsList($)>>    in
      Term = <<fE_setRef($)>>#<<fE_complexNode( type:Lst
                                          subTree:<<fE_getSubTuples({Append Objs Nil} $)>>
                                          back:$)>>
   end
end






/****************************** RECORDS ******************/

class FE_GenericRecord from FE_Generic
   %

   meth fE_getSubRecords(Objs FeatureTuple ?X)
      X = {List.foldLInd Objs
           fun{$ I X Y}
              ' ( ' # {self fE_getName({self genFeatPrintName(FeatureTuple.I $)} $)} # ' ' # {Y fE_Term($)} #' ) '# X
           end   ''   $  }
   end

   meth hasPrivateFeatures(B)
      <<areSpecs(B)>>
      % in class RecordSubtermsStore in subterms.oz
   end
   %

   %
end


class FE_RecordObject from FE_GenericRecord
   %
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_RecordObject'}
      \endif
      Feat = @recFeatures    % Tuple  ..or self.recArity List
                               % kompatibel zu OFR
      Objs = <<getObjsList($)>>
   in
      case Objs of nil  then     % only private Features
         Term = <<fE_setRef($)>>#<<fE_complexNode(type:Conj
                                            subTree:<<fE_edge(lab:<<fE_getName(self.name $)>>
                                                           tree:<<fE_atomicNode(lab:' ? ' back:$)>>
                                                           back:$)>>
                                            back:$)>>
      else
         Add= case <<hasPrivateFeatures($)>> then '? '
              else ''
              end            in
         Term = <<fE_setRef($)>>#<<fE_complexNode(type:Conj
                                                  subTree:<<fE_edge(lab:<<fE_getName(self.name $)>>#Add
                                                                    tree:<<fE_complexNode(type:Disj
                                                                                          subTree:<<fE_getSubRecords(Objs Feat $)>>
                                                                                          back:$)>>
                                                                    back:$)>>
                                                  back:$)>>
      end
   end
   %
end


class FE_ORecord from FE_GenericRecord
   %
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_ORecord'}
      \endif
      case {self isProperOFS($)} then    % in terms.oz  relational !!!
         Term = {self fE_setRef($)}#{self GetSubOFS($)}
      else
         extern
            <<FE_RecordObject fE_Term(Term)>>
         end
      end
   end
   %
   meth GetSubOFS(?X)
      Feat = @recFeatures    % Tuple
      Objs = <<getObjsList($)>>
   in
      X =  case Objs of nil  then     % only private Features
              <<fE_complexNode(type:Conj
                            subTree:<<fE_edge(lab:<<fE_getName(self.name $)>>
                                           tree:<<fE_atomicNode(lab:'...? ' back:$)>>
                                           back:$)>>
                            back:$)>>
           else
              Add= case <<hasPrivateFeatures($)>> then '...? '
                   else '...'
                   end            in
              <<fE_complexNode(type:Conj
                            subTree:<<fE_edge(lab:<<fE_getName(self.name $)>>#Add
                                           tree:<<fE_complexNode(type:Disj
                                                              subTree:<<fE_getSubRecords(Objs Feat $)>>
                                                              back:$)>>
                                           back:$)>>
                            back:$)>>
           end
   end
   %
end





/************************** VARIABLES *********************/

class FE_VariableObject from FE_Generic
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_VariableObject'}
\endif
      Term = <<fE_setRef($)>>#<<fE_atomicNode( lab:<<fE_getName(self.name $)>> back:$)>>
   end
end

class FE_FDVariableObject from FE_Generic
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_FDVariableObject'}
      \endif
      Term = <<fE_setRef($)>>#<<fE_atomicNode( lab:<<fE_getName(self.name $)>> back:$)>>
   end
end






/********************* CHUNK   ***********************/

class FE_GenericChunk from FE_RecordObject FE_NameObject
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_GenericChunk'}
      \endif
      case  self.isCompound then
         <<FE_RecordObject fE_Term(Term)>>
      else
         <<FE_NameObject fE_Term(Term)>>
      end
   end
end

class FE_ProcedureObject from FE_GenericChunk
end

class FE_CellObject from FE_GenericChunk
end

class FE_ObjectObject from FE_GenericChunk
end

class FE_ClassObject from FE_GenericChunk
end







class FE_ShrunkenObject from FE_Generic
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_ShrunkenObject'}
      \endif
       Term = <<fE_atomicNode( lab:',,,' back:$)>>
   end
   %

end

class FE_ReferenceObject from FE_Generic
   meth fE_Term(Term)
      \ifdef DEBUG_Ob
      {Show 'FE_ReferenceObject'}
\endif
      Master = @master in
      case Master of !InitValue then
         %see line 481 in termObject.oz
         {Wait {Time.sleep 1000 go}}
         {self fE_Term(Term)}
      else
         %Term = Master.tag
         Term = {Master fE_getRef($)}
      end
   end

end
   %


class FE_UnknownObject from FE_Generic end






create FE_GenSym from UrObject
   attr I:1
   meth get(X)
      V = @I
   in
      X={Int.toString V}
      I <- V+1
   end
   meth reset
      I <- 1
   end
end
