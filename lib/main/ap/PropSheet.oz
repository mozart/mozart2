declare

Get = {NewName}
Set = {NewName}

class Editor
   feat sticky:nw default up
   attr state %% default, usr, set(Value)
   meth init(default:D up:U)
      state   <- default
      self.default = D
      self.up = U
   end
   meth reset
      {self Set(self.default)}
      state <- default
      {self stateMod}
   end
   meth get($)
      case @state
      of default then none
      [] usr     then some({self Get($)}={Wait})
      [] bad     then raise bad end
      [] set(V)  then some(V)
      end
   end
   meth set(V)
      {self Set(V)}
      state <- set(V)
      {self.up stateMod}
   end
   meth stateMod {self.up showState(@state)} end
   meth usrMod state<-usr {self stateMod} end
end

class BoolEditor from Tk.checkbutton Editor
   feat var
   meth init(parent:P default:D up:U)
      Editor,init(default:D up:U)
      self.var={New Tk.variable tkInit}
      Tk.checkbutton,tkInit(parent:P variable:self.var)
      Tk.checkbutton,tkAction(action:self#usrMod)
      {self reset}
   end
   meth !Get($) {self.var tkReturnInt($)}==1 end
   meth !Set(V) {self.var tkSet({IsBool V} andthen V)} end
end

class StringEditor from Tk.entry Editor
   feat sticky:nwe
   meth init(parent:P default:D up:U)
      Editor,init(default:D up:U)
      Tk.entry,tkInit(parent:P)
      {self tkBind(event :'<KeyPress>'
                   append:true
                   action:self#usrMod)}
      {self tkBind(event :'<Control-r>'
                   action:self#reset)}
      {self reset}
   end
   meth !Get($) {self tkReturn(get $)} end
   meth !Set(V)
      {self tk(delete 0 'end')}
      if {IsVirtualString V} then
         {self tk(insert 0 V)}
      end
   end
end

class AtomEditor from StringEditor
   meth !Get($)
      {String.toAtom StringEditor,Get($)}
   end
end

class IntEditor from TkTools.numberentry Editor
   meth init(parent:P default:D up:U)
      Editor,init(default:D up:U)
      TkTools.numberentry,tkInit(parent:P)
      {self tkAction(self#usrModArg)}
      {self reset}
   end
   meth !Get($) {self tkGet($)} end
   meth !Set(V)
      {self tkSet(0)}
      {self.entry tk(delete 0 'end')}
      if {IsInt V} then
         {self tkSet(V)}
      end
   end
   meth usrModArg(_) {self usrMod} end
end

class FloatEditor from Tk.entry Editor
   feat sticky:nwe
   meth init(parent:P default:D up:U)
      Editor,init(default:D up:U)
      Tk.entry,tkInit(parent:P)
      {self tkBind(event :'<KeyPress>'
                   append:true
                   action:self#usrMod)}
      {self tkBind(event :'<Control-r>'
                   action:self#reset)}
      {self reset}
   end
   meth !Get($)
      S = {self tkReturn(get $)}
   in
      try {String.toFloat S}
      catch _ then {Int.toFloat {String.toInt S}} end
   end
   meth get($)
      try Editor,get($)
      catch E then
         state<-bad
         {self stateMod}
         raise E end
      end
   end
   meth !Set(V)
      {self tk(delete 0 'end')}
      if {IsFloat V} then
         {self tk(insert 0 V)}
      end
   end
end

class AtomChoice from Tk.frame Editor
   feat choices box
   attr usrChoice:unit
   meth init(parent:P choices:L default:D up:U)
      Editor,init(default:D up:U)
      Tk.frame,tkInit(parent:P)
      Size = {Length L}
      Height = {Min 5 Size}
      Box = {New Tk.listbox tkInit(parent:self height:Height)}
      {ForAll L proc {$ A} {Box tk(insert 'end' A)} end}
   in
      self.choices=L self.box=Box
      if Size>5 then
         Bar = {New Tk.scrollbar tkInit(parent:self)}
      in
         {Tk.addYScrollbar Box Bar}
         {Tk.send pack(Box Bar fill:y side:left)}
      else
         {Tk.send pack(Box fill:y side:left)}
      end
      {Box tkBind(event:'<1>' action:self#usrMod)}
      {self reset}
   end
   meth !Get($)
      {Nth self.choices 1+{self.box tkReturnInt(curselection $)}}
   end
   meth !Set(V)
      {self.box tk(selection clear 0 'end')}
      try
         {List.forAllInd self.choices
          proc {$ I A}
             if V==A then raise ok(I) end end
          end}
      catch ok(I) then
         {self.box tk(selection set I-1)}
      end
   end
end

%%

EditorMap =
map(bool        : BoolEditor
    string      : StringEditor
    atom        : AtomEditor
    int         : IntEditor
    float       : FloatEditor
    atoms       : AtomChoice)

class PropLabel from Tk.label
   meth showState(S)
      {self tk(configure
               fg:case S of default then black
                  elseof usr then blue
                  elseof bad then red
                  else green end)}
   end
end

class PropObject
   feat text editor option
   attr row
   meth init(text    : Text
             option  : Option
             type    : Type
             default : Default
             parent  : Parent)
      InitMsg = init(parent:Parent default:Default up:self)
   in
      self.option = Option
      self.text   = {New PropLabel
                     tkInit(parent:Parent text:Text)}
      self.editor =
      case Type
      of bool then {New BoolEditor InitMsg}
      [] string then {New StringEditor InitMsg}
      [] atom then {New AtomEditor InitMsg}
      [] int  then {New IntEditor InitMsg}
      [] float then {New FloatEditor InitMsg}
      [] atom(...) then {New AtomChoice
                         {AdjoinAt InitMsg choices
                          {Record.toList Type}}}
      end
      {self.text tkBind(event:'<1>'
                        action:self.editor#reset)}
   end
   meth getRow($) @row end
   meth setRow(V)
      row<-V
      {Tk.batch [grid(self.text   row:V column:0 sticky:nw)
                 grid(self.editor row:V column:1
                      sticky: self.editor.sticky)]}
   end
   meth incrRow {self setRow(@row+1)} end
   meth decrRow {self setRow(@row-1)} end
   meth get($)
      case {self.editor get($)} of none then none
      elseof some(V) then self.option#V end
   end
   meth showState(S)
      {self.text showState(S)}
   end
end

class PropSheetFrame from Tk.frame
   attr props:nil size:0
   meth tkInit(...)=M
      Tk.frame,M
      {self confResize}
   end
   meth addProp(text    : Text
                option  : Option
                type    : Type
                default : Default
                row     : Row <= unit)
      {self addPropObject(
               {New PropObject
                init(text    : Text
                     option  : Option
                     type    : Type
                     default : Default
                     parent  : self)}
               row:Row)}
   end
   meth addPropObject(O row:Row<=unit)
      if Row==unit orelse Row==@size then
         {O setRow(@size)}
         props <- {Append @props [O]}
         size  <- @size+1
      elseif Row>@size orelse Row<0 then raise bad end
      else
         Prefix Suffix
      in
         {List.takeDrop @props Row Prefix Suffix}
         {ForAll {Reverse Suffix}
          proc {$ Prop} {Prop incrRow} end}
         {O setRow(Row)}
         props <- {Append Prefix O|Suffix}
         size  <- @size+1
      end
   end
   meth confResize
      {Tk.send grid(columnconfigure self 1 weight:1)}
   end
   meth get($)
      try {Filter {Map @props fun {$ P} {P get($)} end}
           fun {$ X} X\=none end}
      catch _ then false end
   end
end

/*

declare T = {New Tk.toplevel tkInit}
declare PS = {New PropSheetFrame tkInit(parent:T)}
{Tk.send pack(PS expand:true fill:x anchor:nw)}
{PS tk(configure width:100 height:200)}
{PS addProp(text:'--bool' option:bool type:bool default:true row:0)}
{PS addProp(text:'--string' option:string type:string default:nil)}
{PS addProp(text:'--atom' option:atom type:atom default:unit)}
{PS addProp(text:'--float' option:float type:float default:unit row:1)}
{PS addProp(text:'--int' option:int type:int default:89)}
{PS addProp(text:'--atoms' option:atoms type:atom(one two three four five six) default:two)}

{Show {PS get($)}}

*/
