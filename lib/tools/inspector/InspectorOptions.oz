%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% Inspector Options Functor
%%%

functor $

import
   Property(get)
   Tk(localize)
   SupportNodes(options)

export
   configure : Configure

define
   OpMan = SupportNodes.options

   %% Dummy Proc to enforce body evaluation

   proc {Configure}
      skip
   end

   %% Configure Inspector Options

   local
      InspWidth  = 500
      InspHeight = 350
   in
      {OpMan set(inspectorWidth  InspWidth)}
      {OpMan set(inspectorHeight InspHeight)}
   end

   %% Configure TreeWidget Options

   local
      TreeWidth       = 10
      TreeDepth       = 10
      TreeDisplayMode = normal
   in
      {OpMan set(treeWidth TreeWidth)}
      {OpMan set(treeDepth TreeDepth)}
      {OpMan set(treeDisplayMode TreeDisplayMode)}
   end

   %% Configure TreeWidget Datatype Color Options

   local
      Color1 = '#a020f0'
      Color2 = '#bc8f8f'
      Color3 = black
   in
      {OpMan set(intColor Color1)}
      {OpMan set(floatColor Color1)}
      {OpMan set(atomColor Color2)}
      {OpMan set(boolColor Color1)}
      {OpMan set(nameColor Color3)}
      {OpMan set(procedureColor Color3)}
      {OpMan set(freeVarColor Color1)}
      {OpMan set(classChunkColor Color3)}
      {OpMan set(objectChunkColor Color3)}
      {OpMan set(arrayChunkColor Color3)}
      {OpMan set(dictionaryChunkColor Color3)}
      {OpMan set(portChunkColor Color3)}
      {OpMan set(spaceChunkColor Color3)}
      {OpMan set(genericChunkColor Color3)}
   end

   %% Configure Canvas Options

   local
      MyFont      = font(fontName: '7x13'
                         xDim:     7
                         yDim:     13)
      fun {Root X}
         {Tk.localize {Property.get 'oz.home'}#'/share/images/inspector/'#X}
      end
      WidthBitmap = {Root 'width.xbm'}
      DepthBitmap = {Root 'depth.xbm'}
      ScrollMode  = true %% Setting is currently ignored
   in
      {OpMan set(canvasBackground  ivory)}
      {OpMan set(canvasFont        MyFont)}
      {OpMan set(canvasWidthBitmap WidthBitmap)}
      {OpMan set(canvasDepthBitmap DepthBitmap)}
      {OpMan set(canvasScrollbar   ScrollMode)}
   end

   %% Configure Menu Global Options

   local
      MenuFont = '-adobe-helvetica-bold-r-*-*-*-100-*'
   in
      {OpMan set(menuFont             MenuFont)}
      {OpMan set(menuActiveBackground '#d9d9d9')}
   end

   %% Configure type dependant Menu Options

   %% Normal Tuple

   {OpMan set(labelTuple false#_#[title('Tuple Actions')
                                  'Width +1'(expandWidth(1))
                                  'Width +2'(expandWidth(2))
                                  'Width +5'(expandWidth(5))
                                  separator
                                  'Width -1'(expandWidth(~1))
                                  'Width -2'(expandWidth(~2))
                                  'Width -5'(expandWidth(~5))
                                  separator
                                  'Depth +1'(expandDepth(1))
                                  'Depth +2'(expandDepth(2))
                                  'Depth +5'(expandDepth(5))
                                  separator
                                  'Depth -1'(expandDepth(~1))
                                  'Depth -2'(expandDepth(~2))
                                  'Depth -5'(expandDepth(~5))])}

   %% Record und Feature Constraints

   local
      RecShared = ['Width +1'(expandWidth(1))
                   'Width +2'(expandWidth(2))
                   'Width +5'(expandWidth(5))
                   separator
                   'Width -1'(expandWidth(~1))
                   'Width -2'(expandWidth(~2))
                   'Width -5'(expandWidth(~5))
                   separator
                   'Depth +1'(expandDepth(1))
                   'Depth +2'(expandDepth(2))
                   'Depth +5'(expandDepth(5))
                   separator
                   'Depth -1'(expandDepth(~1))
                   'Depth -2'(expandDepth(~2))
                   'Depth -5'(expandDepth(~5))]
      Auto = false
   in
      {OpMan set(record       Auto#_#title('Record Options')|RecShared)}
      {OpMan set(kindedRecord Auto#_#title('Feature Options')|RecShared)}
   end

   %% Array

   local
      local
         fun {CreateList Low High AL}
            if Low > High
            then AL
            else {CreateList (Low + 1) High Low|AL}
            end
         end

         fun {FillRecord Low High R V}
            if Low > High
            then R
            else
               R.Low = {Get V Low}
               {FillRecord (Low + 1) High R V}
            end
         end
      in
         fun {CreateContents V}
            Low    = {Array.low V}
            High   = {Array.high V}
            NewVal = {Record.make 'array_contents' {CreateList Low High nil}}
         in
            {FillRecord Low High NewVal V}
         end
      end

      Auto = false
   in
      {OpMan set(array Auto#CreateContents
                 #[title('Array Actions')
                   'View Contents'(expand(CreateContents))])}
   end

   %% Dictionary

   local
      fun {DictKeys D}
         {List.toTuple dict_keys {Dictionary.keys D}}
      end

      fun {DictEntries D}
         {List.toTuple dict_entries {Dictionary.entries D}}
      end

      fun {DictToRecord D}
         {Dictionary.toRecord 'converted_dict' D}
      end

      Auto = false
   in
      {OpMan set(dictionary Auto#DictToRecord
                 #[title('Dictionary Actions')
                   'View Keys'(expand(DictKeys))
                   'View Entries'(expand(DictEntries))
                   separator
                   'to Record'(expand(DictToRecord))])}
   end

   %% Classes

   local
      fun {GetParents C}
         nil
      end

      fun {GetMethods C}
         nil
      end

      Auto = false
   in
      {OpMan set('class' Auto#GetMethods
                 #[title('Class Actions')
                   'View Parents'(expand(GetParents))
                   separator
                   'View Methods'(expand(GetMethods))])}
   end

   %% Overall Width Expansion

   {OpMan set(width false#_#[title('Width Expansion')
                             'Width +1'(expandWidth(1))
                             'Width +2'(expandWidth(2))
                             'Width +5'(expandWidth(5))
                             separator
                             'Width -1'(expandWidth(~1))
                             'Width -2'(expandWidth(~2))
                             'Width -5'(expandWidth(~5))])}

   %% Overall Depth Expansion

   {OpMan set(depth false#_#[title('Depth Expansion')
                             'Depth +1'(expandDepth(1))
                             'Depth +2'(expandDepth(2))
                             'Depth +5'(expandDepth(5))
                             separator
                             'Depth -1'(expandDepth(~1))
                             'Depth -2'(expandDepth(~2))
                             'Depth -5'(expandDepth(~5))])}
end
