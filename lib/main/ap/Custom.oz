functor
import
   Property(get)
   OS(getEnv)
   Pickle(load save)
export
   Get CondGet Save
define
   OptionMap = {Dictionary.new}
   OptionSav = {Dictionary.new}
   OptionMod = {Dictionary.new}
   %%
   %% Load user's customizations if any
   %%
   CUSTOM_FILE =
   case {Property.condGet 'user.custom.file' unit} of unit then
      case {OS.getEnv 'MOZART_CUSTOM_FILE'} of false then
         '~/.oz/CUSTOM'
      elseof X then X end
   elseof X then X end
   {ForAll
    try {Pickle.load CUSTOM_FILE} catch _ then custom end
    proc {$ Key#Value}
       {Dictionary.put OptionMap Key Value}
       {Dictionary.put OptionSav Key true }
    end}
   %%
   proc {Save}
      if {Dictionary.keys OptionMod}==nil then skip
      else
         {Pickle.save
          {Map {Dictionary.keys OptionSav}
           proc {$ Key} Key#{Dictionary.get Key OptionMap} end}
          CUSTOM_FILE}
      end
   end
   %%
   OptionDefs = {Dictionary.new}
   GroupDefs  = {Dictionary.new}
   GroupDefaults  = group( doc:unit group:unit)
   OptionDefaults = option(doc:unit group:unit)
   %%
   proc {Define What}
      case What
      of group(...) then
         {DefineGroup {Adjoin GroupDefaults What}}
      elseof option(...) then
         {DefineOption {Adjoin OptionDefaults What}}
      end
   end