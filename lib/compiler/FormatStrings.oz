%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1996-1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%   $LICENSEURL$
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
      attr
         MaxWidth: unit     % width of the screen (characters per line)
         TabSize: unit      % number of characters to use in format(indent)
         Stack: unit        % stack of indentations; the topmost element
                            % is used when outputting a newline
         Line: unit         % preliminary output
         Len: unit          % length of virtual string in @Line
         VS: unit           % finished output
         Col: unit          % column number arrived to at the end of @VS
         GlueItem: unit     % what to insert between @VS and @Line if it
                            % fits on the same line as the end of @VS
         GlueIndent: unit   % how much to indent @Line if it does not fit
                            % on the same line as the end of @VS
         PrintDepth: unit   % used by oz(...)
         PrintWidth: unit   % used by oz(...)
         StackOpsHd: unit   % difference list of pending stack operations
         StackOpsTl: unit

      meth init(width: W <= 80 tabsize: T <= 3 indent: N <= 0
                printDepth: PD <= unit printWidth: PW <= unit)
         MaxWidth <- W
         TabSize <- T
         Stack <- [N]
         Line <- ""
         Len <- 0
         VS <- {Indent N}
         Col <- N
         GlueIndent <- N
         GlueItem <- ""
         PrintDepth <- case PD of unit then {Property.get print}.depth
                       else PD
                       end
         PrintWidth <- case PW of unit then {Property.get print}.width
                       else PW
                       end
         @StackOpsHd = @StackOpsTl
      end
      meth append(FS)
         case FS of '#' then skip
         [] nil then skip
         [] _|_ then
            Len <- @Len + {VirtualString.length FS}
            Line <- @Line#FS
         elsecase {IsAtom FS} orelse {IsNumber FS} then
            Len <- @Len + {VirtualString.length FS}
            Line <- @Line#FS
         elsecase {IsTuple FS} andthen {Label FS} == '#' then
            Formatter, AppendTuple(FS 1 {Width FS})
         elsecase FS of pn(PrintName) then
            Formatter, append({PrintNameToVirtualString PrintName})
         [] oz(X) then
            Formatter, append({System.valueToVirtualString X
                               @PrintDepth @PrintWidth})
         [] list(Elems Sep) then
            Formatter, AppendSeparated(Elems Sep)
         [] format(X) then
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
            end
         end
      end
      meth get(ResVS)
         % this implicitly appends a `format(glue(""))' to the end of the input
         Formatter, FormatLine()
         ResVS = (VS <- "")
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
         case @Col + N + @Len =< @MaxWidth orelse @Col =< @GlueIndent then
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
                          (TheStack.1 + @TabSize)|TheStack.2
                       [] exdent then
                          (TheStack.1 - @TabSize)|TheStack.2
                       end
            Formatter, ExecStackOps(Sr NewStack $)
         [] nil then TheStack
         end
      end
   end
in
   fun {FormatStringToVirtualString FS} O in
      % we use a width of 79 to avoid `\'-line breaks in Emacs
      O = {New Formatter init(width: 79)}
      {O append(FS)}
      {O get($)}
   end
end
