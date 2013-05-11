%%% Copyright © 2013, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice,
%%% this list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

functor

import
   Lexer(tokenizeVS:TokenizeVS)
   Open
   URL(make:URLMake resolve:URLResolve toAtom:URLToAtom)

export
   ReadSourceFile
   PreprocessTokens
   ReadAndPreprocessSourceFile
   ReadAndPreprocessVS

define

   /** Read a source file encoded in UTF-8 or latin1
    *  @param TheURL URL of the source file to read
    *  @return A string with the contents of the file
    */
   fun {ReadSourceFile TheURL}
      File = {New Open.file init(url:TheURL)}
      RawContents
   in
      try
         {File read(list:?RawContents size:all)}
      finally
         {File close}
      end

      try
         {Coders.decode RawContents [utf8]}
      catch system(unicode(...) ...) then
         {Coders.decode RawContents [latin1]}
      end
   end

   /** Read, tokenize, and preprocess recursively an Oz source file
    *  @param TheURL    URL of the source file
    *  @param Defines   A dictionary of the variable defines
    *  @return A reader of preprocessed tokens
    */
   fun {ReadAndPreprocessSourceFile TheURL0 Defines}
      TheURL = {URLMake TheURL0}
      Contents = {ReadSourceFile TheURL}
      Tokens = {TokenizeVS Contents {URLToAtom TheURL}}
   in
      {PreprocessTokens Tokens TheURL Defines}
   end

   /** Read, tokenize, and preprocess recursively an Oz source virtual string
    *  @param VS        The virtual string to read
    *  @param BaseURL   Base URL, for lookups of \insert's
    *  @param Defines   A dictionary of the variable defines
    *  @return A reader of preprocessed tokens
    */
   fun {ReadAndPreprocessVS VS BaseURL Defines}
      Tokens = {TokenizeVS VS 'top level'}
   in
      {PreprocessTokens Tokens BaseURL Defines}
   end

   proc {MakeEOFContext Token Offset Pos PrevPos LastNoSuccess ?EOFContext}
      EOFContext = ctx(valid:true
                       first:Token
                       cache:{NewDictionary}
                       offset:Offset
                       posbegin:Pos
                       posend:PrevPos
                       lastNoSuccess:LastNoSuccess
                       rest:EOFContext)
   end

   /** Preprocessing
    *
    *  Input: Reader[Token]
    *  BaseURL: URL
    *  FileStack: List[Reader[Token] # File]
    *  Offset: Int
    *  PrevPos: Position
    *  Defines: defines(VarAtom:true ...)
    *  LastNoSuccess: Cell
    */
   fun {Preprocess Input BaseURL FileStack Offset PrevPos Defines LastNoSuccess}
      reader(First Pos _ Rest) = Input
   in
      case First
      of tkEof then
         case FileStack
         of nil then
            % Totally the end
            {MakeEOFContext tkEof(Defines) Offset Pos.1 PrevPos LastNoSuccess}
         [] (NewIn#NewBaseURL)|NewStack then
            % Get out of one file
            {Preprocess NewIn NewBaseURL NewStack Offset PrevPos Defines LastNoSuccess}
         end
      [] tkPreprocessorDirective('define' Var) then
         {Preprocess Rest BaseURL FileStack Offset PrevPos
                     {AdjoinAt Defines Var true} LastNoSuccess}
      [] tkPreprocessorDirective('undef' Var) then
         {Preprocess Rest BaseURL FileStack Offset PrevPos
                     {Record.subtract Defines Var} LastNoSuccess}
      [] tkPreprocessorDirective('ifdef' Var) then
         if {HasFeature Defines Var} then
            {Preprocess Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess}
         else
            {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess 1}
         end
      [] tkPreprocessorDirective('ifndef' Var) then
         if {HasFeature Defines Var} then
            {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess 1}
         else
            {Preprocess Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess}
         end
      [] tkPreprocessorDirective('else') then
         {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess 1}
      [] tkPreprocessorDirective('endif') then
         {Preprocess Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess}
      [] tkPreprocessorDirective('insert' RelURL) then
         NewURL NewContents NewInput NewStack
      in
         try TryNewURL TryNewContents in
            TryNewURL = {URLResolve BaseURL {URLMake RelURL}}
            TryNewContents = {ReadSourceFile TryNewURL}
            NewURL = TryNewURL
            NewContents = TryNewContents
         catch OriginalError = error(url(open _) ...) then
            try
               NewURL = {URLResolve BaseURL {URLMake RelURL#'.oz'}}
               NewContents = {ReadSourceFile NewURL}
            catch error(url(open _) ...) then
               raise OriginalError end
            end
         end
         NewInput = {TokenizeVS NewContents {URLToAtom NewURL}}
         NewStack = Rest#BaseURL | FileStack
         {Preprocess NewInput NewURL NewStack Offset PrevPos Defines LastNoSuccess}
      else
         Cache = {NewDictionary}
         PosBegin = Pos.1
      in
         ctx(valid:true
             first:First
             cache:Cache
             offset:Offset
             posbegin:PosBegin
             posend:PrevPos
             lastNoSuccess:LastNoSuccess
             rest:{Preprocess Rest BaseURL FileStack Offset+1 Pos.2 Defines LastNoSuccess})
      end
   end

   fun {Skip Input BaseURL FileStack Offset PrevPos Defines LastNoSuccess SkipDepth}
      reader(First Pos _ Rest) = Input
   in
      case First
      of tkEof then
         % Reaching an EOF while skipping is an error
         ctx(valid:true
             first:tkParseError('Reached EOF while skipping')
             cache:{NewDictionary}
             offset:Offset
             posbegin:Pos.1
             posend:PrevPos
             lastNoSuccess:LastNoSuccess
             rest:{MakeEOFContext tkEof(Defines) Offset+1 Pos.2 Pos.2 LastNoSuccess})

      [] tkPreprocessorDirective('ifdef' _) then
         {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess SkipDepth+1}
      [] tkPreprocessorDirective('ifndef' _) then
         {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess SkipDepth+1}
      [] tkPreprocessorDirective('else') andthen SkipDepth == 1 then
         {Preprocess Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess}
      [] tkPreprocessorDirective('endif') then
         if SkipDepth == 1 then
            {Preprocess Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess}
         else
            {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess SkipDepth-1}
         end
      else
         {Skip Rest BaseURL FileStack Offset PrevPos Defines LastNoSuccess SkipDepth}
      end
   end

   fun {PreprocessTokens Input BaseURL Defines}
      LastNoSuccess = {NewCell ctx(valid:false offset:0)}
   in
      {Preprocess Input {URLMake BaseURL} nil 1 unit Defines LastNoSuccess}
   end

end
