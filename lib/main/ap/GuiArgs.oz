functor
import
   Tk TkTools
export
   OptionEditor Parse
define
   %% Editors

   class BoolEditor from Tk.checkbutton
      feat sticky:nw
      attr Var
      meth init(parent:P default:D<=false)
         Var<-{New Tk.variable tkInit(D)}
         Tk.checkbutton,tkInit(parent:P variable:@Var)
      end
      meth get($)
         {@Var tkReturnInt($)}==1
      end
   end

   class StringEditor from Tk.entry
      feat sticky:nwe
      meth init(parent:P default:D<=unit)
         Tk.entry,tkInit(parent:P)
         if D\=unit then
            {self tk(insert 0 D)}
         end
      end
      meth get($)
         {self tkReturn(get $)}
      end
   end

   class IntEditor from TkTools.numberentry
      feat sticky:nw
      meth init(parent:P default:D<=unit)
         TkTools.numberentry,tkInit(parent:P)
         if D\=unit then
            TkTools.numberentry,tkSet(D)
         end
      end
      meth get($)
         TkTools.numberentry,tkGet($)
      end
   end

   %%
   NoDefault = {NewName}
   fun {TypeToEditor Type Default Parent}
      Msg = if Default==NoDefault then init(parent:Parent)
            else init(parent:Parent default:Default) end
   in
      {New
       case Type
       of bool   then BoolEditor
       [] int    then IntEditor
       [] string then StringEditor
       end Msg}
   end
   %%
   class OptionEditor from Tk.toplevel
      attr row:0 rows
      meth init(Specs Result ...)=M
         InitMsg = {List.toRecord tkInit
                    {Filter {Record.toListInd M}
                     fun {$ K#_} {Not {IsInt K}} end}}
         Accept Abort Frame
      in
         Tk.toplevel,InitMsg
         rows <-
         {Map {Filter {Record.toListInd Specs}
               fun {$ Key#_} {IsInt Key} end}
          fun {$ _#Spec}
             Key   = {Label Spec}
             Title = if {HasFeature Spec title} then Spec.title
                     else '--'#Key end
             Type  = Spec.type
          in
             row(label :{New Tk.label tkInit(parent:self text:Title)}
                 editor:{TypeToEditor Type NoDefault self}
                 key   :Key)
          end}
         Frame  = {New Tk.frame tkInit(parent:self)}
         Accept = {New Tk.button tkInit(parent:Frame
                                        text:'Accept'
                                        action:
                                           proc{$}
                                              {self Get(Result)}
                                              try {self tkClose}
                                              catch _ then skip end
                                           end)}
         Abort  = {New Tk.button tkInit(parent:Frame
                                        text:'Abort'
                                        action:
                                           proc{$}
                                              try {self tkClose}
                                              catch _ then skip end
                                              raise abort end
                                           end)}
         {Tk.batch
          pack(Accept Abort side:left) |
          grid(Frame column:1 row:0 sticky:ne) |
          {List.foldRInd @rows
           fun {$ I Row L}
              grid(Row.label  column:0 row:I sticky:nw) |
              grid(Row.editor column:1 row:I
                   sticky:Row.editor.sticky) | L
           end nil}}
         row <- {Length @rows}+1
      end
      meth Get($)
         {Map @rows
          fun {$ Row}
             Val = {Row.editor get($)}
          in
             {Wait Val}
             Row.key#Val
          end}
      end
   end

   %%

   proc {Parse OptRec Result}
      Title = {CondSelect OptRec title 'Option Editor'}
   in
      {New OptionEditor init(OptRec Result title:Title) _}
   end
end
