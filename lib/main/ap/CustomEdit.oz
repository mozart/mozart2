%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import System(show)
   Tk TkTools(dialog error)
   CustomOption(get spec set)
export
   Editor RegisterSimpleEditor EditOption

prepare
   Bad = {NewName}

   fun {Identity V} V end

define
   class Editor from TkTools.dialog
      feat validate GET SET
      meth init(title    : Title    <='Customizer'
                validate : Validate <=Identity
                doc      : Doc      <=unit
                label    : Label
                set      : Set
                value    : Value
               )
         self.validate = Validate
         self.SET      = Set
         TkTools.dialog
         ,tkInit(title  : Title
                 buttons:
                    ['Apply'  # (self#Apply)
                     'Cancel' # (self#tkClose) ])
         L={New Tk.label tkInit(parent:self text:Label)}
         E={New Tk.entry tkInit(parent:self)}
      in
         {System.show inserting(Value)}
         {E tk(insert 1 Value)}
         {System.show inserted}
         self.GET = fun {$} {E tkReturn(get $)} end
         if Doc\=unit then
            {Tk.send
             pack({New Tk.message
                   tkInit(parent:self text:Doc aspect:400)}
                  side:bottom)}
         end
         {Tk.batch [pack(L side:left)
                    pack(E side:left fill:x expand:true padx:2#m)
                    focus(E)]}
      end
      meth Apply
         V = try {self.validate {self.GET $}}
             catch _ then Bad end
      in
         if V==Bad then
            {New TkTools.error
             tkInit(master:self text: 'illegal value') _}
         else
            {self.SET V} {self tkClose}
         end
      end
   end
   %%
   StringToInt = String.toInt
   %%
   local
      CharToLower = Char.toLower
      fun {ToLowerAtom S}
         {String.toAtom {Map S CharToLower}}
      end
      R = o('true'      : true
            't'         : true
            'yes'       : true
            'y'         : true
            'on'        : true
            'false'     : false
            'f'         : false
            'no'        : false
            'n'         : false
            'off'       : false)
   in
      fun {StringToBool S} R.{ToLowerAtom S} end
      fun {BoolToString B}
         case B of true then "true"
         [] false then "false"
         end
      end
   end
   %%
   Editors = {Dictionary.new}
   %%
   proc {RegisterSimpleEditor Type Decode Encode}
      proc {SimpleEditor Option Spec Value}
         {New Editor
          init(validate : Encode
               value    : try {Decode Value} catch _ then '' end
               doc      : {CondSelect Spec 'doc' unit}
               label    : {CondSelect Spec 'label' Option}
               set      : proc {$ V}
                             {System.show set(Option V)}
                             {CustomOption.set Option V}
                          end) _}
      end
   in
      {Dictionary.put Editors Type SimpleEditor}
   end
   %%
   {RegisterSimpleEditor int  IntToString StringToInt}
   %{RegisterSimpleEditor bool BoolToString StringToBool}
   {RegisterSimpleEditor string Identity Identity}
   %%
   proc {EditOption Option}
      Spec = {CustomOption.spec Option}
      Val  = {CustomOption.get  Option}
      Type = {CondSelect Spec 'type' string}
      Edit = {Dictionary.condGet Editors Type unit}
   in
      if Edit==unit then
         {Exception.raiseError custom(noEditor Spec)}
      else
         {Edit Option Spec Val}
      end
   end
   %%
   class BoolEditor from TkTools.dialog
      feat VAR SET
      meth init(title    : Title    <='Customizer'
                doc      : Doc      <=unit
                label    : Label
                set      : Set
                value    : Value
               )
         self.VAR = {New Tk.variable tkInit(Value)}
         self.SET = Set
         TkTools.dialog
         ,tkInit(title   : Title
                 buttons :
                 ['Apply'  # (self#Apply)
                  'Cancel' # (self#tkClose) ])
         C={New Tk.checkbutton
            tkInit(parent:self variable:self.VAR text:Label anchor:w)}
      in
         if Doc\=unit then
            {Tk.send
             pack({New Tk.message
                   tkInit(parent:self text:Doc aspect:400)}
                  side:bottom)}
         end
         {Tk.batch [pack(C anchor:c) focus(C)]}
      end
      meth Apply
         {self.SET {self.VAR tkReturnInt($)}==1} {self tkClose}
      end
   end
   proc {EditBool Option Spec Val}
      {New BoolEditor init(doc   : {CondSelect Spec 'doc' unit}
                           label : {CondSelect Spec 'label' Option}
                           set   : proc {$ V}
                                      {System.show set(Option V)}
                                      {CustomOption.set Option V}
                                   end
                           value : Val==true) _}
   end
   {Dictionary.put Editors bool EditBool}
end
