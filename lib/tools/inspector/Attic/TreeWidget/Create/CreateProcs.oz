%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% CreateProcs
%%%

%% Normal Create Function

fun {Create CurValue Parent Index Visual Depth}
   MaxDepth = {Visual getDepth($)}
in
   case Depth =< MaxDepth
   then
      case {Value.status CurValue}
      of kinded(Type) then
         case Type
         of int    then
            {New TreeNodes.fDIntTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] fset   then
            {New TreeNodes.fSSetTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] record then
            {New TreeNodes.kindedRecordTreeNode
             create(CurValue Parent Index Visual Depth)}
         else
            {New GenericNode
             create(CurValue Parent Index Visual Depth Type)}
         end
      [] free      then
         {New TreeNodes.freeTreeNode
          create(CurValue Parent Index Visual Depth)}
      [] det(Type) then
         case Type
         of int    then
            {New TreeNodes.intTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] fset then
            {New TreeNodes.fSSetTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] float  then
            {New TreeNodes.floatTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] atom   then
            {New TreeNodes.atomTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] name   then
            case {IsBool CurValue}
            then {New TreeNodes.boolTreeNode
                  create(CurValue Parent Index Visual Depth)}
            else {New TreeNodes.nameTreeNode
                  create(CurValue Parent Index Visual Depth)}
            end
         [] procedure then
            {New TreeNodes.procedureTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] tuple     then
            case {Label CurValue}
            of '#' then
               {New TreeNodes.hashTupleTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] '|' then
               {New TreeNodes.pipeTupleTreeNode
                create(CurValue Parent Index Visual Depth)}
            else
               {New TreeNodes.labelTupleTreeNode
                create(CurValue Parent Index Visual Depth)}
            end
         [] record then
            {New TreeNodes.recordTreeNode
             create(CurValue Parent Index Visual Depth)}
         else
            {New GenericNode
             create(CurValue Parent Index Visual Depth Type)}
%        [] space  then
%           {New TreeNodes.spaceTreeNode
%            create(CurValue Parent Index Visual Depth)}
%        [] 'class' then
%           {New TreeNodes.classTreeNode
%            create(CurValue Parent Index Visual Depth)}
%        [] object then
%           {New TreeNodes.objectTreeNode
%            create(CurValue Parent Index Visual Depth)}
%        [] array  then
%           {New TreeNodes.arrayTreeNode
%            create(CurValue Parent Index Visual Depth)}
%        [] dictionary then
%           {New TreeNodes.dictionaryTreeNode
%            create(CurValue Parent Index Visual Depth)}
%        [] port then
%           {New TreeNodes.portTreeNode
%            create(CurValue Parent Index Visual Depth)}
%        [] chunk then
%           {New TreeNodes.chunkTreeNode
%            create(CurValue Parent Index Visual Depth)}
         end
      end
   else
      Node = {New BitmapTreeNode
              create(depth Parent Index Visual Depth)}
   in
      {Node setRescueValue(CurValue)}
      Node
   end
end

%% Cycle Create Function

fun {CycleCreate CurValue Parent Index Visual CycleMan Depth}
   MaxDepth = {Visual getDepth($)}
in
   case Depth =< MaxDepth
   then
      Ret = {CycleMan get(CurValue $)}
   in
      case Ret
      of nil then
         case {Value.status CurValue}
         of kinded(Type) then
            case Type
            of int    then
               {New TreeNodes.fDIntTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] fset   then
               {New TreeNodes.fSSetTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] record then
               {New TreeNodes.kindedRecordCycleTreeNode
                create(CurValue Parent Index Visual CycleMan Depth)}
            [] other  then
               {New TreeNodes.atomTreeNode
                create('<unknown other non-determined value>'
                       Parent Index Visual Depth)}
            end
         [] free      then
            {New TreeNodes.freeTreeNode
             create(CurValue Parent Index Visual Depth)}
         [] det(Type) then
            case Type
            of int    then
               {New TreeNodes.intTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] fset then
               {New TreeNodes.fSSetTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] float  then
               {New TreeNodes.floatTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] atom   then
               {New TreeNodes.atomTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] name   then
               case {IsBool CurValue}
               then {New TreeNodes.boolTreeNode
                     create(CurValue Parent Index Visual Depth)}
               else {New TreeNodes.nameTreeNode
                     create(CurValue Parent Index Visual Depth)}
               end
            [] procedure then
               {New TreeNodes.procedureTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] tuple     then
               case {Label CurValue}
               of '#' then
                  {New TreeNodes.hashTupleCycleTreeNode
                   create(CurValue Parent Index Visual CycleMan Depth)}
               [] '|' then
                  {New TreeNodes.pipeTupleCycleTreeNode
                   create(CurValue Parent Index Visual CycleMan Depth)}
               else
                  {New TreeNodes.labelTupleCycleTreeNode
                   create(CurValue Parent Index Visual CycleMan Depth)}
               end
            [] record then
               {New TreeNodes.recordCycleTreeNode
                create(CurValue Parent Index Visual CycleMan Depth)}
            [] space  then
               {New TreeNodes.spaceTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] 'class' then
               {New TreeNodes.classTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] object then
               {New TreeNodes.objectTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] array  then
               {New TreeNodes.arrayTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] dictionary then
               {New TreeNodes.dictionaryTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] port then
               {New TreeNodes.portTreeNode
                create(CurValue Parent Index Visual Depth)}
            [] chunk then
               {New TreeNodes.chunkTreeNode
                create(CurValue Parent Index Visual Depth)}
            end
         end
      else
         SNode|Val = Ret
         Node      = {New InternalAtomNode
                      create(Val Parent Index Visual Depth)}
      in
         {Node setTellNode(SNode)}
         Node
      end
   else
      Node = {New BitmapTreeNode
              create(depth Parent Index Visual Depth)}
   in
      {Node setRescueValue(CurValue)}
      Node
   end
end
