%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Université catholique de Louvain
%
% Last change:
%   $Date$ by $Author$
%   $Revision$
%
% This file is part of Mozart, an implementation
% of Oz 3:
%   http://www.mozart-oz.org
%
% See the file "LICENSE" or
%   http://www.mozart-oz.org/LICENSE.html
% for information on usage and redistribution
% of this file, and for a DISCLAIMER OF ALL
% WARRANTIES.
%
%  The development of QTk is supported by the PIRATES project at
%  the Université catholique de Louvain.

% Load QTk graphic user interface package (in local directory)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Binary tree version of dictionary

declare
   fun {NewDictionary} leaf end
   fun {Put Ds Key Value}
      case Ds
      of leaf then
            tree(key:Key value:Value left:leaf right:leaf)
      [] tree(key:K left:L right:R ...) andthen Key==K then
            tree(key:K value:Value left:L right:R)
      [] tree(key:K value:V left:L right:R) andthen K>Key then
            tree(key:K value:V left:{Put L Key Value} right:R)
      [] tree(key:K value:V left:L right:R) andthen K<Key then
            tree(key:K value:V left:L right:{Put R Key Value})
      end
   end
   fun {CondGet Ds Key Default}
      case Ds
      of leaf then
            Default
      [] tree(key:K value:V ...) andthen Key==K then
            V
      [] tree(key:K left:L ...) andthen K>Key then
            {CondGet L Key Default}
      [] tree(key:K right:R ...) andthen K<Key then
            {CondGet R Key Default}
      end
   end
   fun {Domain Ds}
      proc {DomainD Ds S1 S0}
         case Ds
         of leaf then
            S1=S0
         [] tree(key:K left:L right:R ...) then S2 S3 in
            {DomainD L S1 S2}
            S2=K|S3
            {DomainD R S3 S0}
         end
      end
   in {DomainD Ds $ nil} end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fun {WordChar C}
   (&a=<C andthen C=<&z) orelse
   (&A=<C andthen C=<&Z) orelse (&0=<C andthen C=<&9)
end

fun {WordToAtom PW}
   {VirtualString.toAtom {Reverse PW}}
end

fun {IncWord D W}
   {Put D W {CondGet D W 0}+1}
end

fun {CharsToWords PW Cs}
   case Cs
   of nil andthen PW==nil then
      nil
   [] nil then
      [{WordToAtom PW}]
   [] C|Cr andthen {WordChar C} then
      {CharsToWords {Char.toLower C}|PW Cr}
   [] C|Cr andthen PW==nil then
      {CharsToWords nil Cr}
   [] C|Cr then
      {WordToAtom PW}|{CharsToWords nil Cr}
   end
end

fun {CountWords D Ws}
   case Ws
   of W|Wr then {CountWords {IncWord D W} Wr}
   [] nil then D
   end
end

fun {WordFreq Cs}
   {CountWords {NewDictionary} {CharsToWords nil Cs}}
end


declare
F={New Open.file init(name:'QTk.oz')}
L={F read(list:$ size:all)}
{F close}
{Show {OS.system "date"}}
D={WordFreq L}
{Show {OS.system "date"}}

{Show {Length {Domain D}}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Calculating the tree's position

declare
% Add x & y fields to the tree
fun {AddXY Tree}
   case Tree
   of tree(left:L right:R ...) then
      {Adjoin Tree tree(x:_ y:_ left:{AddXY L} right:{AddXY R})}
   [] leaf then
      leaf
   end
end

Scale=3.0

% Calculate positions
proc {DepthFirst Tree Level LeftLimit RootX RightLimit}
   case Tree
   of tree(x:X y:Y left:leaf right:leaf ...) then
      X=RootX=RightLimit=LeftLimit
      Y=Scale*Level*5.0
   [] tree(x:X y:Y left:L right:leaf ...) then
      X=RootX
      Y=Scale*Level*5.0
      {DepthFirst L Level+1.0 LeftLimit RootX RightLimit}
   [] tree(x:X y:Y left:leaf right:R ...) then
      X=RootX
      Y=Scale*Level*5.0
      {DepthFirst R Level+1.0 LeftLimit RootX RightLimit}
   [] tree(x:X y:Y left:L right:R ...) then
         LRootX LRightLimit RRootX RLeftLimit
      in
         Y=Scale*Level*5.0
         {DepthFirst L Level+1.0 LeftLimit LRootX LRightLimit}
         RLeftLimit=LRightLimit+5.0
         {DepthFirst R Level+1.0 RLeftLimit RRootX RightLimit}
         X=RootX=(LRootX+RRootX) / 2.0
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Drawing the tree

% Run {P X Y T Level} on all nodes, where (X,Y) is the node's
% coordinates, T is the subtree at that node, and Level is
% the depth in the tree.
proc {Traverse1 PosTree Level P}
   case PosTree
   of tree(x:X y:Y left:L right:R ...) then
      {P X Y PosTree Level}
      {Traverse1 L Level+1.0 P}
      {Traverse1 R Level+1.0 P}
   [] leaf then
      skip
   end
end

% Run {P X Y T SX SY ST Level} on all links parent-child.
proc {Traverse3 PosTree Level P}
   case PosTree
   of tree(x:X y:Y left:L=tree(x:LX y:LY ...) ...) then
      {P X Y PosTree LX LY L Level}
      {Traverse3 L Level+1.0 P}
   else skip end
   case PosTree
   of tree(x:X y:Y right:R=tree(x:RX y:RY ...) ...) then
      {P X Y PosTree RX RY R Level}
      {Traverse3 R Level+1.0 P}
   else skip end
end

% Create a window and return a function that can draw
% a tree in that window.
fun {MakeDrawTree Can}
   Des=td(canvas(handle:Can glue:nswe bg:white
                 width:400 height:300
                 scrollregion:q(0 0 10000 5000)
                 tdscrollbar:true lrscrollbar:true))
   Win={QTk.build Des}
   TagPtr={NewCell proc {$ _} skip end}
   {Win show}
in
   proc {$ PosTree}
      Tag={Can newTag($)}
   in
      {{Access TagPtr} delete}
      {Assign TagPtr Tag}
      {Traverse3 PosTree 0.0
       proc {$ X Y T AX AY AT L}
          {Can create(line
                      {FloatToInt X}
                      {FloatToInt Y}
                      {FloatToInt AX}
                      {FloatToInt AY} fill:black tags:Tag)}
       end}
      {Traverse1 PosTree 0.0
       proc {$ X Y T L}
          {Can create(rectangle
                      {FloatToInt X-1.0}
                      {FloatToInt Y-3.0}
                      {FloatToInt X+1.0}
                      {FloatToInt Y+3.0} fill:red width:0 tags:Tag)}
       end}
   end
end

Can
DrawTree={MakeDrawTree Can}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Execution with wordfreq tree

Tree2={AddXY D}
% {Browse Tree2}
{DepthFirst Tree2 1.0 Scale _ _}
{DrawTree Tree2}

{Can postscript(file:'tree.ps' width:10000)}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
