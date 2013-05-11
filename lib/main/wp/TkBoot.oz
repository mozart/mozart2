functor

export
   AddSlave
   Batch
   Close
   GenFontName
   GenImageName
   GenTagName
   GenTopName
   GenVarName
   GenWidgetName
   Init
   Return
   ReturnMess
   Send
   SendFilter
   SendTagTuple
   SendTuple

define
   TkSlaves TkWidgetID TkStream TkReturnPort TkEvents

   proc {Init Stream Events Slaves WidgetID ReturnStream}
      TkStream     = Stream
      TkEvents     = Events
      TkSlaves     = Slaves
      TkWidgetID   = WidgetID
      TkReturnPort = {NewPort ReturnStream}
   end

   proc {AddSlave Slaves NewSlave}
      Slaves := NewSlave|@Slaves
   end

   proc {Batch TkCommands}
      {TkStream write(vs:{Intersperse {Map TkCommands FormatTk} ";"}#"\n")}
   end

   proc {Close A B}
      proc {CloseSlave S}
         if {IsInt S} then {Dictionary.remove TkEvents S}
         elseif {IsList S} then {CloseHierarchy S}
         end
      end
      proc {CloseHierarchy W}
         Slaves = {CondSelect W TkSlaves unit}
      in
         if {IsList Slaves} then {ForAll Slaves CloseSlave} end
      end
   in
      {Send A}
      {CloseHierarchy B}
   end

   fun {MakeTkCounter Letter}
      C = {NewCell ~1}
   in
      fun {$} C := @C + 1  Letter#@C end
   end

   GenFontName = {MakeTkCounter f}
   GenImageName = {MakeTkCounter i}
   GenTagName = {MakeTkCounter t}
   GenTopName = {MakeTkCounter '.'}
   GenVarName = {MakeTkCounter v}
   GenWidgetName = fun {$ P} A#C = {GenTopName} in P#A#C end

   proc {Return A B C}
      {Send ozr(l(A))}
      {Port.send TkReturnPort C|B}
   end

   proc {ReturnMess A B C D}
      {Send ozr(l(A B.1 C))}
      {Port.send TkReturnPort B.2|D}
   end

   proc {Send A}
      {TkStream write(vs:{FormatTk A}#"\n")}
   end

   proc {SendFilter A B C D E}
      {Send b([A B {ToOptions {Record.subtractList C D}} E])}
   end

   proc {SendTagTuple A B C}
      {Send b([A C.1 B {ToOptions {Record.subtract C 1}}])}
   end

   proc {SendTuple WidgetID TkArgs}
      {Send b([WidgetID {ToOptions TkArgs}])}
   end

%-------------------------------------------------------------------
%  Set of functions transforming an Oz description of Tk operations
%  into a virtual string describing the corresponding Tk command.
%-------------------------------------------------------------------

   local
      fun {FieldToV AI Tcl}
         if {IsInt AI} then '' else '-'#{Quote AI}#' ' end # {FormatTk Tcl}
      end
      fun {RecordToV R AIs}
         {FoldR AIs fun {$ AI V}
                       {FieldToV AI R.AI} # ' ' # V
                    end ''}
      end
   in
      fun {FormatTk Tcl}
         if {IsBool Tcl} then if Tcl then 1 else 0 end
         elseif {IsUnit Tcl} then ''
         elseif {IsVirtualString Tcl} then {Quote Tcl}
         elseif {IsObject Tcl} then Tcl.TkWidgetID
         else
           case {Label Tcl}
           of o then {RecordToV Tcl {Arity Tcl}}
           [] p then AI|AIs={Arity Tcl} in
              '{'#{FieldToV AI Tcl.AI}#'.'#{RecordToV Tcl AIs}#'}'
           [] b then {FoldR Tcl.1 fun {$ Tcl V}
                                     {FormatTk Tcl}#' '#V
                                  end ''}
           [] c then '#'#{Hex Tcl.1}#{Hex Tcl.2}#{Hex Tcl.3}
           [] v then Tcl.1
           [] s then '"'#{RecordToV Tcl {Arity Tcl}}#'"'
           [] l then '['#{RecordToV Tcl {Arity Tcl}}#']'
           [] q then '{'#{RecordToV Tcl {Arity Tcl}}#'}'
           else {Quote {Label Tcl}}#' '#{RecordToV Tcl {Arity Tcl}}
           end
         end
      end
   end

   fun {Quote V}
      case {VirtualString.toString V} of nil then "\"\""
      [] S then
         {FoldR S fun {$ I Ir}
                     if {Member I " {}[]\\$\";"} then &\\|I|Ir
                     elseif I < 33 orelse I > 127 then {Append {Octal I} Ir}
                     else I|Ir
                     end
                  end nil}
      end
   end

   local
      fun {HexDigit I}
         I + if I>9 then &a-10 else &0 end
      end
   in
      fun {Hex I}
         [{HexDigit I div 16} {HexDigit I mod 16}]
      end
   end

   fun {Octal I}
      [&\\ (I div 64 + &0) ((I mod 64) div 8 + &0) (I mod 8 + &0)]
   end

%-------------------------------------------------------------------
%  Utility functions
%-------------------------------------------------------------------
   fun {Intersperse Xs C}
      if {Width Xs} == 0 then Xs
      else {FoldL Xs.2 fun {$ X Y} X#C#Y end Xs.1}
      end
   end

   fun {ToOptions R}
      if {Width R} == 0 then unit
      else {Adjoin R o}
      end
   end
end
