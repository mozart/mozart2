declare
NoDefault = {NewName}

%% An OptionManager corresponds to one specific option
%% (1) it has the option spec
%% (2) it is responsible for creating and keeping track of
%%     rows corresponding to this option

class OptionManager
   feat
      parent                    % OptionSheetFrame
      spec option text occ type default optional alias
      editorClass initArgs
   attr
      optionRows:nil
   meth init(Spec index:I parent:P)
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
      {TypeToEditor self.type self.editor self.init}
      local Row = {New OptionRow init(manager:self)} in
         {Row setRowIndex(I)}
         optionRows <- [Row]
      end
   end
   meth get($)
      case self.occ of multiple then
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
      {Tk.batch [grid(self.label  row:V column:0 sticky:nw)
                 grid(self.editor row:V column:1
                      sticky:self.editor.sticky)]}
   end
   meth get($) {self.editor get($)} end
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
      else raise bad end end
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

class AtomOptionEditor from StringEditor
   meth getLocalValue($)
      {String.toAtom StringEditor,getLocalValue($)}
   end
end

class IntOptionEditor from TkTools.numberentry OptionEditor
   meth init(row:Row)
      OptionEditor,init(row:Row)
      TkTools.numberentry,tkInit(parent: P
                                 min   : {CondSelect
                                          Row.manager.type min unit}
                                 max   : {CondSelect
                                          Row.manager.type max unit}
                                 action: self#userModified)
      {self reset}
   end
   meth getLocalValue($) TkTools.numberentry,tkGet($) end
   meth setLocalValue(V)
      TkTools.numberentry,tkSet(0)
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
   meth setLocalValue($)
      Tk.entry,tk(delete 0 'end')
      if {IsNumber V} then Tk.entry,tk(insert 0 V) end
   end
   meth get($)
      try Editor,get($)
      catch E then
         state <- bad
         {self stateFeedback}
         raise E end
      end
   end
end

class AtomChoiceOptionEditor from Tk.frame OptionEditor
   feat Choices Box
   attr UsrChoice:unit
   meth init(row:Row)
      OptionEditor,init(row:Row)
      Tk.frame,tkInit(parent:Row.manager.parent)
      Size   = {Length L}
      Max    = 5
      Height = {Min Max Size}
   in
      self.Box     = {New Tk.listbox tkInit(parent:self height:Height)}
      self.Choices = {Record.toList Row.manager.type}
      {ForAll self.Choices
       proc {$ A} {self.Box tk(insert 'end' A)} end}
      if Size>Max then
         Bar = {New Tk.scrollbar tkInit(parent:self)}
      in
         {Tk.addYScrollbar self.Box Bar}
         {Tk.send pack(self.Box Bar fill:y side:left)}
      else
         {Tk.send pack(self.Box fill:y side:left)}
      end
      {self.Box tkBind(event:'<KeyPress>' action:self#userModified)}
      {self reset}
   end
   meth getLocalValue($)
      {Nth self.Choices 1+{self.Box tkReturnInt(curselection $)}}
   end
   meth setLocalValue(V)
      {self.Box tk(selection clear 0 'end')}
      try
         {List.forAllInd self.Choice
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
   meth set(...)          =M raise bad(M) end end
   meth getLocalValue(...)=M raise bad(M) end end
   meth setLocalValue(...)=M raise bad(M) end end
end

%%

proc {TypeToEditor Type Class Init}
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
      {List.mapInd {Filter {Record.toListInd Specs}
                    fun {$ K#_} {IsInt K} end}
       fun {$ I _#Spec}
          {New OptionManager init(Spec index:I-1 parent:self)}
       end}
      self.managerMap =
      {List.toRecord o
       {Map self.managerList fun {$ M} M.option # M end}}
   end
   meth get($)
      try {Filter {Map self.managerList
                   fun {$ M} {M get($)} end}
           fun {$ X} X\=none end}
      catch _ then false end
   end
end
