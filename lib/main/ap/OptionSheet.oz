declare
NoDefault = {NewName}

proc {Bad} {Exception.raiseError bad} end

%% An OptionManager corresponds to one specific option
%% (1) it has the option spec
%% (2) it is responsible for creating and keeping track of
%%     rows corresponding to this option

class OptionManager
   feat
      parent                    % OptionSheetFrame
      spec option text occ type default optional alias
      editorClass initArgs multiple baseType collecting
   attr
      optionRows:nil
   meth init(Spec parent:P)
      self.parent       = P
      self.spec         = Spec
      self.option       = {Label Spec}
      self.text         =
      if {HasFeature Spec text} then Spec.text
      else '--'#self.option end
      self.occ          = {CondSelect Spec 1 single}
      self.type         =
      if {HasFeature Spec alias} then alias
      else {CondSelect Spec type string} end
      self.default      = {CondSelect Spec default NoDefault}
      self.optional     =
      if {HasFeature Spec option} then Spec.optional
      else
         {HasFeature Spec default} orelse
         {HasFeature Spec alias}
      end
      self.alias        = {CondSelect Spec alias nil}
      self.multiple     = case {Label self.type}
                          of multiple then true
                          [] list     then true
                          else false end
      self.collecting   = (self.occ\=multiple andthen
                           {Label self.type}==list)
      self.baseType     = case self.type
                          of list(T) then T
                          [] T then T end
      {TypeToEditor self.baseType self.editorClass#self.initArgs}
   end
   meth isFirstRow(R1 $)
      I = {R1 getRowIndex($)}
   in
      try
         {ForAll @optionRows
          proc {$ R2}
             if {R2 getRowIndex($)}<I then
                raise ok end
             end
          end}
         true
      catch ok then false end
   end
   meth createRow(Row)
      %if {Not self.multiple} then {Bad} end
      Row = {New OptionRow init(manager:self)}
      optionRows <- Row|@optionRows
   end
   meth collect($)
      case {FoldR {Sort {Map @optionRows
                         fun {$ R} {R getRowIndex($)}#R end}
                   fun {$ I1#_ I2#_} I1<I2 end}
            fun {$ _#R L}
               case {R get($)} of none then L
               [] some(V) then V|L end
            end nil}
      of nil then none
      [] L   then self.option#L
      end
   end
end

%% An OptionRow is the graphical interface for an occurrence of an
%% option.  All OptionRows for the same option are managed by the
%% same OptionManager.  Each OptionRow contains widgets to be inserted
%% in the vaious columns of a row of a PropSheetFrame.

class OptionRow
   feat manager label editor
   attr rowIndex
   meth init(manager:M)
      self.manager = M
      self.label   = {New OptionLabel   init(row:self)}
      self.editor  = {New M.editorClass init(row:self)}
   end
   meth setRowIndex(I)
      rowIndex <- I
      {Tk.batch [grid(self.label  row:I column:0 sticky:nw)
                 grid(self.editor row:I column:1
                      sticky:self.editor.sticky)]}
   end
   meth getRowIndex($) @rowIndex end
   meth get($) {self.editor get($)} end
   %% an option which is not multiple but has type list(T)
   %% may have many rows, but they should all be collected
   %% together rather than individually: only the first
   %% row for this option returns a value and this value
   %% is computed by invoking the collect method of the
   %% option manager.
   meth collect($)
      if self.manager.collecting then
         if {self.manager isFirstRow(self $)} then
            {self.manager collect($)}
         else none end
      elsecase {self get($)}
      of some(V) then self.manager.option#V
      else none end
   end
   meth stateFeedback(S)
      {self.label
       tk(configure
          fg:case S
             of default then black
             [] usr     then blue
             [] bad     then red
             else green end)}
   end
end

%%

class OptionLabel from Tk.label
   feat row
   meth init(row:Row)
      self.row = Row
      Tk.label,tkInit(parent: Row.manager.parent
                      text  : Row.manager.text)
   end
end

%%

class OptionEditor
   feat sticky:nw row
   attr state                   % default, usr, set(Value)
   meth init(row:Row)
      self.row=Row
   end
   meth reset
      {self setLocalValue(self.row.manager.default)}
      state <- default
      {self stateFeedback}
   end
   meth stateFeedback
      {self.row stateFeedback(@state)}
   end
   meth userModified(...)
      state <- usr
      {self stateFeedback}
   end
   meth get($)
      case @state
      of default then none
      [] usr     then some({self getLocalValue($)}={Wait})
      [] set(V)  then some(V)
      else {Bad} unit end
   end
   meth set(V)
      {self setLocalValue(V)}
      state <- set(V)
      {self stateFeedback}
   end
end

class BoolOptionEditor from Tk.checkbutton OptionEditor
   feat Var
   meth init(row:Row)
      OptionEditor,init(row:Row)
      self.Var = {New Tk.variable tkInit}
      Tk.checkbutton,tkInit(parent   : Row.manager.parent
                            variable : self.Var)
      Tk.checkbutton,tkAction(action : self#userModified)
      {self reset}
   end
   meth getLocalValue($) {self.Var tkReturnInt($)}==1 end
   meth setLocalValue(V) {self.Var tkSet({IsBool V} andthen V)} end
end

class StringOptionEditor from Tk.entry OptionEditor
   feat sticky:nwe
   meth init(row:Row)
      OptionEditor,init(row:Row)
      Tk.entry,tkInit(parent:Row.manager.parent)
      Tk.entry,tkBind(event :'<KeyPress>'
                      append:true
                      action:self#userModified)
      Tk.entry,tkBind(event :'<Control-r>'
                      action:self#reset)
      {self reset}
   end
   meth getLocalValue($) Tk.entry,tkReturn(get $) end
   meth setLocalValue(V)
      Tk.entry,tk(delete 0 'end')
      if {IsVirtualString V} then Tk.entry,tk(insert 0 V) end
   end
end

class AtomOptionEditor from StringOptionEditor
   meth getLocalValue($)
      {String.toAtom StringOptionEditor,getLocalValue($)}
   end
end

class IntOptionEditor from TkTools.numberentry OptionEditor
   meth init(row:Row)
      OptionEditor,init(row:Row)
      TkTools.numberentry,tkInit(parent: Row.manager.parent
                                 min   : {CondSelect
                                          Row.manager.type min unit}
                                 max   : {CondSelect
                                          Row.manager.type max unit}
                                 action: self#userModified)
      {self reset}
   end
   meth getLocalValue($) TkTools.numberentry,tkGet($) end
   meth setLocalValue(V)
      {self.entry tk(delete 1 'end')}
      if {IsInt V} then TkTools.numberentry,tkSet(V) end
   end
end

class FloatOptionEditor from Tk.entry OptionEditor
   feat sticky:nwe
   meth init(row:Row)
      OptionEditor,init(row:Row)
      Tk.entry,tkInit(parent:Row.manager.parent)
      Tk.entry,tkBind(event :'<KeyPress>'
                      append:true
                      action:self#userModified)
      Tk.entry,tkBind(event :'<Control-r>'
                      action:self#reset)
      {self reset}
   end
   meth getLocalValue($)
      S = {self tkReturn(get $)}
   in
      try {String.toFloat S}
      catch _ then {Int.toFloat {String.toInt S}} end
   end
   meth setLocalValue(V)
      Tk.entry,tk(delete 0 'end')
      if {IsNumber V} then Tk.entry,tk(insert 0 V) end
   end
   meth get($)
      try OptionEditor,get($)
      catch E then
         state <- bad
         {self stateFeedback}
         raise E end
      end
   end
end

class AtomChoiceOptionEditor from Tk.frame OptionEditor
   feat Choices Box
   meth init(row:Row)
      OptionEditor,init(row:Row)
      Tk.frame,tkInit(parent:Row.manager.parent)
      L      = {Record.toList Row.manager.type}
      Size   = {Length L}
      Max    = 5
      Height = {Min Max Size}
   in
      self.Box     = {New Tk.listbox tkInit(parent:self height:Height)}
      self.Choices = L
      {ForAll L
       proc {$ A} {self.Box tk(insert 'end' A)} end}
      if Size>Max then
         Bar = {New Tk.scrollbar tkInit(parent:self)}
      in
         {Tk.addYScrollbar self.Box Bar}
         {Tk.send pack(self.Box Bar fill:y side:left)}
      else
         {Tk.send pack(self.Box fill:y side:left)}
      end
      {self.Box tkBind(event:'<1>' action:self#userModified)}
      {self reset}
   end
   meth getLocalValue($)
      {Nth self.Choices 1+{self.Box tkReturnInt(curselection $)}}
   end
   meth setLocalValue(V)
      {self.Box tk(selection clear 0 'end')}
      try
         {List.forAllInd self.Choices
          proc {$ I A}
             if V==A then raise ok(I) end end
          end}
      catch ok(I) then
         {self.Box tk(selection set I-1)}
      end
   end
end

class AliasOptionEditor from Tk.frame OptionEditor
   meth init(row:Row)
      OptionEditor,init(row:Row)
      Tk.frame,tkInit(parent:Row.manager.parent)
   end
   meth get($) default end
   meth set(...)          =M {Bad} end
   meth getLocalValue(...)=M {Bad} end
   meth setLocalValue(...)=M {Bad} end
end

%%

fun {TypeToEditor Type}
   case Type
   of bool       then       BoolOptionEditor # init
   [] string     then     StringOptionEditor # init
   [] atom       then       AtomOptionEditor # init
   [] int(...)   then        IntOptionEditor # {Adjoin Type init}
   [] float(...) then      FloatOptionEditor # {Adjoin Type init}
   [] atom(...)  then AtomChoiceOptionEditor #
      init(choices:{Record.toList Type})
   end
end

%%

class OptionSheetFrame from Tk.frame
   feat managerList managerMap
   attr optionRows:nil
   meth init(Specs parent:P)
      Tk.frame,tkInit(parent:P)
      {Tk.send grid(columnconfigure self 1 weight:1)}
      self.managerList =
      {Map {Filter {Record.toListInd Specs}
            fun {$ K#_} {IsInt K} end}
       fun {$ _#Spec}
          {New OptionManager init(Spec parent:self)}
       end}
      self.managerMap =
      {List.toRecord o
       {Map self.managerList fun {$ M} M.option # M end}}
      optionRows <-
      {List.mapInd self.managerList
       proc {$ I M R}
          {M createRow(R)}
          {R setRowIndex(I-1)}
       end}
   end
   meth collect($)
      try {Filter {Map @optionRows
                   fun {$ M} {M collect($)} end}
           fun {$ X} X\=none end}
      catch _ then false end
   end
end

/*

declare
PS = {proc {$ PS}
         T = {New Tk.toplevel tkInit}
      in
         PS = {New OptionSheetFrame
               init(record(foo(single type:int(min:2))
                           bar(single type:string text:'Hello World')
                           baz(single type:float)
                           qqq(single type:atom(one two three))
                          )
                    parent:T)}
         {Tk.send pack(PS)}
      end}

{Show {PS collect($)}}

*/
