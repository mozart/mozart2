proc
   %instantiate
   {$ IMPORTS}
   \insert SP.env
   = IMPORTS.'SP'
   \insert CP.env
   = IMPORTS.'CP'
   \insert Common.env
   = IMPORTS.'Common'
   \insert Gump.env
   = IMPORTS.'Gump'
in
   \insert compiler-Version
   \insert FormatStrings
   \insert Reporter
   \insert ParseOz
   \insert TupleSyntax
   \insert BindingAnalysis
   \insert UnnestFD
   \insert Unnester
   \insert Interface
end
