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


class Frame

   feat Init Children

   meth init(M)
      if {IsFree self.Init} then self.Init=unit else
         raise error(frameAlreadyInitialized) end
      end
      Row
      Column
      % keep just interesting informations
      Horiz={Label M}==lr
      Data={Record.toList
            {Record.filterInd M
             fun{$ I R} {Int.is I} end}}
      % creates and assign objects to features
      Objects={List.map Data
               fun{$ Re}
                  O
                  R={Record.adjoinAt Re parent self}
               in
                  case {Label R}
                  of newline then skip
                  [] empty then skip
                  [] continue then skip
                  else
                     O={MapLabelToObject R}
                  end
                  if {IsFree O} then Re
                  else
%                    if {HasFeature R feature} then
%                       F=R.feature
%                    in
%                       self.F=O
%                    else skip end
%                    if {HasFeature R handle} then
%                       R.handle=O
%                    else skip end
                     {Record.adjoinAt R obj O}
                  end
               end}
      if Horiz then Row=row Column=column else Row=column Column=row end
      % remember all created objects
      self.Children={List.map
                     {List.filter Objects
                      fun{$ R} {IsRecord R} andthen {HasFeature R obj} end}
                     fun{$ R} R.obj end}
      % decompose in lines
      Lines
      local
         fun{Loop L}
            fun{Parse L R}
               case L
               of newline(...)|Ls then
                  R=Ls
                  nil
               [] nil then
                  R=nil
                  nil
               [] X|Xs then
                  X|{Parse Xs R}
               end
            end
            Ls Line
         in
            Line={Parse L Ls}
            if Ls\=nil then
               Line|{Loop Ls}
            else
               Line|nil
            end
         end
      in
         Lines={Loop Objects}
      end
      % grid everything on odd lines and columns only
      Rowspan={VirtualString.toAtom if Row==row then column else row end#span}
      {List.forAllInd Lines
       proc{$ Y Line}
          proc{Loop X Line}
             case Line of L|Ls then
                case {Label L}
                of continue then {Loop X+1 Ls}
                [] empty then {Loop X+1 Ls}
                else
%                  L1 L2
%                  {List.takeDropWhile Ls fun{$ C} C==continue end L1 L2}
%                  Span={Length L1}*2+1
%               in
%                  {Tk.send grid(L.obj Row:Y+Y-1 Column:X+X-1 Rowspan:Span sticky:{CondFeat L glue ""}
%                                padx:{CondFeat L padx 0} pady:{CondFeat L pady 0})}
%                  {Loop X+{Length L1}+1 L2}
                   L1
                   {List.takeWhile Ls fun{$ C} {Label C}==continue end L1}
                   Span={Length L1}*2+1
                in
                   {Tk.send grid(L.obj Row:Y+Y-1 Column:X+X-1 Rowspan:Span sticky:{CondFeat L glue ""}
                                 padx:{CondFeat L padx 0} pady:{CondFeat L pady 0})}
                   {Loop X+1 Ls}
                end
             else skip end
          end
       in
          {Loop 1 Line}
       end}
      % calculates the dependencies in X axes
      N S W E
      if Row==row then
         N=110 S=115 W=119 E=101
      else
         N=119 S=101 W=110 E=115
      end
      proc{Test Left Right V L R}
         Sticky={VirtualString.toString {CondFeat V glue ""}}
      in
         case {Label V}
         of continue then skip
         else
            if {Member Left Sticky} then L=unit else skip end
            if {Member Right Sticky} then R=unit else skip end
         end
      end
      XDep={List.map Lines
            fun{$ Line}
               L R
            in
               {ForAll Line
                proc{$ V}
                   {Test N S V L R}
                end}
               r({IsDet L} {IsDet R})
            end}
      % calculates the dependencies in Y axes
      fun{CalcYDep I}
         L R Elem
      in
         {ForAll Lines
          proc{$ Line}
             if I=<{Length Line} then
                V={List.nth Line I}
             in
                {Test W E V L R}
                Elem=unit
             else skip end
          end}
         if {IsDet Elem} then
            r({IsDet L} {IsDet R})|{CalcYDep I+1}
         else
            nil
         end
      end
      YDep={CalcYDep 1}
      Rows Columns
      if Row==row then
         Rows=XDep Columns=YDep
      else
         Rows=YDep Columns=XDep
      end
      % creates an array to store each elements
   in
      if {List.some Columns fun{$ R} R.1 andthen R.2 end} then
          % place le poids sur tous les we de la grille
         {List.forAllInd Columns
          proc{$ I R}
             if R.1 andthen R.2 then
                {Tk.send grid(columnconfigure self I*2-1 weight:1)}
             else skip end
          end}
      else
         % place le poids sur toutes les colonnes qui sont entouree par des false
         proc{Loop I}
            L R
         in
            if I==1 then
               L=r(false false)
            else
               L={List.nth Columns I-1}
            end
            if I>{Length Columns} then
               R=r(false false)
            else
               R={List.nth Columns I}
            end
            if L.2==false andthen R.1==false then
               {Tk.send grid(columnconfigure self (I-1)*2 weight:1)}
            else skip end
            if I=<{Length Columns} then {Loop I+1}
            else skip end
         end
      in
         {Loop 1}
      end
      if {List.some Rows fun{$ R} R.1 andthen R.2 end} then
         % place le poids sur tous les we de la grille
         {List.forAllInd Rows
          proc{$ I R}
             if R.1 andthen R.2 then
                {Tk.send grid(rowconfigure self I*2-1 weight:1)}
             else skip end
          end}
      else
         % place le poids sur toutes les colonnes qui sont entouree par des false
         proc{Loop I}
            L R
         in
            if I==1 then
               L=r(false false)
            else
               L={List.nth Rows I-1}
            end
            if I>{Length Rows} then
               R=r(false false)
            else
               R={List.nth Rows I}
            end
            if L.2==false andthen R.1==false then
               {Tk.send grid(rowconfigure self (I-1)*2 weight:1)}
            else skip end
            if I=<{Length Rows} then {Loop I+1}
            else skip end
         end
      in
         {Loop 1}
      end
   end

   meth lr(...)=M
      {self init(M)}
   end

   meth td(...)=M
      {self init(M)}
   end

   meth getChildren(C)
      C=self.Children
   end

end
