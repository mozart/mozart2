%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1996, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% The procedures in this file transform a format string (a virtual
%% string with additional embedded formatting information) into a
%% virtual string.
%%

local
   local
      fun {IndentSub N VS}
         case N >= 8 then {IndentSub N - 8 VS#'\t'}
         elsecase N > 0 then {IndentSub N - 1 VS#' '}
         else VS
         end
      end
   in
      fun {Indent N}
         {IndentSub N ""}
      end
   end

   class Formatter
      prop final
      feat MaxWidth TabSize
      % `MaxWidth' contains the width of the screen (maximum number of
      % characters per line); `TabSize' is the number of characters to add
      % to indentation when a tab is encountered.

      attr Stack Line Len VS Col GlueIndent GlueItem StackOpsHd StackOpsTl
      % `Stack' is the stack of indentations.  The topmost element
      % is the current indentation to use when a newline is output.
      % Output is first written to `Line', completely formatted output
      % to `VS'.  `Len' counts the number of characters in `Line' and
      % `Col' stores the column number of the next character appended to `VS'.
      % When a glue is encountered, it is checked whether `Line' would still
      % fit on the current line; if it doesn't, a newline is inserted.

      meth init(width: W <= 80 tabsize: T <= 3 indent: N <= 0)
         self.MaxWidth = W
         self.TabSize = T
         Stack <- [N]
         Line <- ""
         Len <- 0
         VS <- {Indent N}
         Col <- N
         GlueIndent <- N
         GlueItem <- ""
         @StackOpsHd = @StackOpsTl
      end
      meth append(FS)
         case FS of '#' then skip
         [] nil then skip
         [] _|_ then
            Len <- @Len + {VirtualString.length FS}
            Line <- @Line#FS
         elsecase {IsAtom FS} then
            Len <- @Len + {VirtualString.length FS}
            Line <- @Line#FS
         elsecase {IsInt FS} then
            Len <- @Len + {VirtualString.length FS}
            Line <- @Line#FS
         elsecase {IsFloat FS} then
            Len <- @Len + {VirtualString.length FS}
            Line <- @Line#FS
         elsecase {IsTuple FS} andthen {Label FS} == '#' then
            Formatter, AppendTuple(FS 1 {Width FS})
         elsecase FS of format(X) then
            case X of break then I in
               Formatter, FormatLine()
               I = @Stack.1
               VS <- @VS#'\n'#{Indent I}
               Col <- I
            [] glue(X) then
               Formatter, FormatLine()
               GlueItem <- X
            [] indent then Tl in
               @StackOpsTl = indent|Tl
               StackOpsTl <- Tl
            [] exdent then Tl in
               @StackOpsTl = exdent|Tl
               StackOpsTl <- Tl
            [] push then Tl in
               @StackOpsTl = push(@Len)|Tl
               StackOpsTl <- Tl
            [] pop then Tl in
               @StackOpsTl = pop|Tl
               StackOpsTl <- Tl
            [] list(Elems Sep) then
               Formatter, AppendSeparated(Elems Sep)
            end
         end
      end
      meth get($)
         % this implicitly appends a `format(glue(""))' to the end of the input
         Formatter, FormatLine()
         @VS
      end
      meth AppendTuple(T I N)
         case I =< N then
            Formatter, append(T.I)
            Formatter, AppendTuple(T I + 1 N)
         else skip
         end
      end
      meth AppendSeparated(Xs Sep)
         case Xs of X|Xr then
            Formatter, append(X)
            case Xr of _|_ then
               Formatter, append(Sep)
               Formatter, AppendSeparated(Xr Sep)
            [] nil then skip
            end
         [] nil then skip
         end
      end
      meth FormatLine() N X in
         N = {Length @GlueItem}
         case @Col + N + @Len =< self.MaxWidth orelse @Col =< @GlueIndent then
            VS <- @VS#@GlueItem#@Line
            Col <- @Col + N
         else
            VS <- @VS#'\n'#{Indent @GlueIndent}#@Line
            Col <- @GlueIndent
         end
         @StackOpsTl = nil
         Stack <- Formatter, ExecStackOps(@StackOpsHd @Stack $)
         StackOpsHd <- X
         StackOpsTl <- X
         Col <- @Col + @Len
         Line <- ""
         Len <- 0
         GlueIndent <- @Stack.1
         GlueItem <- ""
      end
      meth ExecStackOps(StackOps TheStack $)
         case StackOps of Op|Sr then NewStack in
            NewStack = case Op of pop then
                          TheStack.2
                       [] push(Len) then
                          (@Col + Len)|TheStack
                       [] indent then
                          (TheStack.1 + self.TabSize)|TheStack.2
                       [] exdent then
                          (TheStack.1 - self.TabSize)|TheStack.2
                       end
            Formatter, ExecStackOps(Sr NewStack $)
         [] nil then TheStack
         end
      end
   end
in
   fun {FormatStringToVirtualString FS} O in
      O = {New Formatter init(width: 79)}   % to avoid `\'-line break in emacs
      {O append(FS)}
      {O get($)}
   end
end
