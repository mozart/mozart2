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

fun {Create CurValue Visual Depth}
   MaxDepth = {Visual getDepth($)}
in
   case Depth =< MaxDepth
   then
      case {Value.status CurValue}
      of kinded(Type) then
         case Type
         of int    then
            {New TreeNodes.fDIntTreeNode       create(CurValue Visual Depth)}
         [] fset   then
            {New TreeNodes.fSSetTreeNode       create(CurValue Visual Depth)}
         [] record then
            {New TreeNodes.kindedRecordTreeNode create(CurValue Visual Depth)}
         [] other  then
            {New TreeNodes.atomTreeNode
             create('<unknown other non-determined value>' Visual Depth)}
         end
      [] free      then
         {New TreeNodes.freeTreeNode create(CurValue Visual Depth)}
      [] det(Type) then
         case Type
         of int    then
            {New TreeNodes.intTreeNode   create(CurValue Visual Depth)}
         [] fset then
            {New TreeNodes.fSSetTreeNode create(CurValue Visual Depth)}
         [] float  then
            {New TreeNodes.floatTreeNode create(CurValue Visual Depth)}
         [] atom   then
            {New TreeNodes.atomTreeNode  create(CurValue Visual Depth)}
         [] name   then
            case {IsBool CurValue}
            then {New TreeNodes.boolTreeNode create(CurValue Visual Depth)}
            else {New TreeNodes.nameTreeNode create(CurValue Visual Depth)}
            end
         [] procedure then
            {New TreeNodes.procedureTreeNode create(CurValue Visual Depth)}
         [] tuple     then
            case {Label CurValue}
            of '#' then
               {New TreeNodes.hashTupleTreeNode  create(CurValue Visual Depth)}
            [] '|' then
               {New TreeNodes.pipeTupleTreeNode  create(CurValue Visual Depth)}
            else
               {New TreeNodes.labelTupleTreeNode create(CurValue Visual Depth)}
            end
         [] record then
            {New TreeNodes.recordTreeNode create(CurValue Visual Depth)}
         [] space  then
            {New TreeNodes.spaceTreeNode create(CurValue Visual Depth)}
         [] 'class' then
            {New TreeNodes.classTreeNode create(CurValue Visual Depth)}
         [] object then
            {New TreeNodes.objectTreeNode create(CurValue Visual Depth)}
         [] array  then
            {New TreeNodes.arrayTreeNode create(CurValue Visual Depth)}
         [] dictionary then
            {New TreeNodes.dictionaryTreeNode create(CurValue Visual Depth)}
         [] port then
            {New TreeNodes.portTreeNode create(CurValue Visual Depth)}
         [] chunk then
            {New TreeNodes.chunkTreeNode create(CurValue Visual Depth)}
         end
      end
   else
      Node = {New BitmapTreeNode create(depth Visual Depth)}
   in
      {Node setRescueValue(CurValue)}
      Node
   end
end

%% Cycle Create Function

fun {CycleCreate CurValue Visual CycleMan Depth}
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
               {New TreeNodes.fDIntTreeNode  create(CurValue Visual Depth)}
            [] fset   then
               {New TreeNodes.fSSetTreeNode  create(CurValue Visual Depth)}
            [] record then
               {New TreeNodes.kindedRecordCycleTreeNode
                create(CurValue Visual CycleMan Depth)}
            [] other  then
               {New TreeNodes.atomTreeNode
             create('<unknown other non-determined value>' Visual Depth)}
            end
         [] free      then
            {New TreeNodes.freeTreeNode create(CurValue Visual Depth)}
         [] det(Type) then
            case Type
            of int    then
               {New TreeNodes.intTreeNode   create(CurValue Visual Depth)}
            [] fset then
               {New TreeNodes.fSSetTreeNode  create(CurValue Visual Depth)}
            [] float  then
               {New TreeNodes.floatTreeNode create(CurValue Visual Depth)}
            [] atom   then
               {New TreeNodes.atomTreeNode  create(CurValue Visual Depth)}
            [] name   then
               case {IsBool CurValue}
               then {New TreeNodes.boolTreeNode create(CurValue Visual Depth)}
               else {New TreeNodes.nameTreeNode create(CurValue Visual Depth)}
               end
            [] procedure then
               {New TreeNodes.procedureTreeNode create(CurValue Visual Depth)}
            [] tuple     then
               case {Label CurValue}
               of '#' then
                  {New TreeNodes.hashTupleCycleTreeNode
                   create(CurValue Visual CycleMan Depth)}
               [] '|' then
                  {New TreeNodes.pipeTupleCycleTreeNode
                   create(CurValue Visual CycleMan Depth)}
               else
                  {New TreeNodes.labelTupleCycleTreeNode
                   create(CurValue Visual CycleMan Depth)}
               end
            [] record then
               {New TreeNodes.recordCycleTreeNode
                create(CurValue Visual CycleMan Depth)}
            [] space  then
               {New TreeNodes.spaceTreeNode create(CurValue Visual Depth)}
            [] 'class' then
               {New TreeNodes.classTreeNode create(CurValue Visual Depth)}
            [] object then
               {New TreeNodes.objectTreeNode create(CurValue Visual Depth)}
            [] array  then
               {New TreeNodes.arrayTreeNode create(CurValue Visual Depth)}
            [] dictionary then
               {New TreeNodes.dictionaryTreeNode create(CurValue Visual Depth)}
            [] port then
               {New TreeNodes.portTreeNode create(CurValue Visual Depth)}
            [] chunk then
               {New TreeNodes.chunkTreeNode create(CurValue Visual Depth)}
            end
         end
      else
         SNode|Val = Ret
         Node      = {New InternalAtomNode create(Val Visual Depth)}
      in
         {Node setTellNode(SNode)}
         Node
      end
   else
      Node = {New BitmapTreeNode create(depth Visual Depth)}
   in
      {Node setRescueValue(CurValue)}
      Node
   end
end
