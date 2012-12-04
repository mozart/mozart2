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
      {Send {Intersperse {Map TkCommands FormatTk} ";"}}
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
      {Send "ozr ["#A#"]"}
      {Port.send TkReturnPort C|B}
   end

   proc {ReturnMess A B C D}
      {Send "ozr ["#A#" "#B.1#" "#C#"]"}
      {Port.send TkReturnPort B.2|D}
   end

   proc {Send A}
      {TkStream write(vs:{FormatTk A}#"\n")}
   end

   proc {SendFilter A B C D E}
      {Send A#" "#B#" "#{RemoveFeatures C D}#" "#E}
   end

   proc {SendTagTuple A B C}
      {Send A#" "#C.1#" "#B#" "#{Record.subtract C 1}}
   end

   proc {SendTuple WidgetID TkArgs}
      {Send WidgetID#" "#TkArgs}
   end

%-------------------------------------------------------------------
%  Set of functions transforming an Oz description of Tk operations
%  into a virtual string describing the corresponding Tk command.
%-------------------------------------------------------------------
   fun {FormatTk OzDescr}
      case {Value.type OzDescr}
      of atom   then {FormatAtom OzDescr}
      [] int    then OzDescr
      [] name   then {FormatName OzDescr}
      [] object then OzDescr.TkWidgetID
      [] record then {FormatRecord OzDescr}
      [] tuple  then {FormatTuple OzDescr}
      end
   end

   fun {FormatAtom OzDescr}
      fun {EscapeSymbols S}
         case S
         of nil  then nil
         [] 32|R then {Append "\\ " {EscapeSymbols R}}
         [] 10|R then {Append "\\12" {EscapeSymbols R}}
         [] 91|R then {Append "\\[" {EscapeSymbols R}}
         [] 92|R then {Append "\\]" {EscapeSymbols R}}
         [] A|As then  A | {EscapeSymbols As}
         end
      end
   in
      {EscapeSymbols {Atom.toString OzDescr}}
   end

   fun {FormatName OzDescr}
      case OzDescr
      of false then 0
      [] true  then 1
      [] unit  then ''
      end
   end

   % s = TclString             q = TclQuote      b = TclBatch
   % v = TclVS                 o = TclOption     p = TclPosition
   % l = TclList
   fun {FormatRecord OzDescr}
      fun {Format A#B}
         if {IsInt A} then {FormatTk B}
         else '-'#A#" "#{FormatTk B}
         end
      end
      fun {ToVS Rec}
         {Intersperse {Map {Record.toListInd Rec} Format} " "}
      end
   in
      case {Label OzDescr}
      of b    then {Intersperse {List.map OzDescr.1 FormatTk} " "}
      [] l    then "["#{ToVS OzDescr}#"]"
      [] o    then {ToVS OzDescr}
      [] p    then "{"#{FormatTk OzDescr.1#"."#OzDescr.2}#"}"
      [] q    then "{"#{ToVS OzDescr}#"}"
      [] s    then '"'#{ToVS OzDescr}#'"'
      [] tk   then {ToVS OzDescr}
      [] tkInit then {ToVS OzDescr}
      [] tkWM then {ToVS OzDescr}
      [] v    then OzDescr.1
      else         {Label OzDescr}#" "#{ToVS OzDescr}
      end
   end

   fun {FormatTuple OzDescr}
      case {Label OzDescr}
      of '#' then {Record.map OzDescr FormatTk}  % actual tuple
      [] '|' then OzDescr                        % string
      else        {FormatRecord OzDescr}         % "real" record"
      end
   end

%-------------------------------------------------------------------
%  Utility functions
%-------------------------------------------------------------------
   fun {Intersperse Xs C}
      if {Width Xs} == 0 then Xs
      else {FoldL Xs.2 fun {$ X Y} X#C#Y end Xs.1}
      end
   end

   % same as Record.subtractList but return '' when result is empty
   fun {RemoveFeatures R L}
      N = {Record.subtractList R L}
   in
      if 0 == {Width N} then '' else N end
   end
end
