functor
import
   CustomGroup(register)
   CustomOption(register get)
   CustomEdit(editOption)
export
   Register Get EditOption
define
   proc {Register What}
      case {Label What}
      of     group  then {CustomGroup.register  What}
      elseof option then {CustomOption.register What}
      end
   end
   Get = CustomOption.get
   EditOption = CustomEdit.editOption
end
