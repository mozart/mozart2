proc
   %instantiate
   {$ IMPORTS}
   \insert SP.env
   = IMPORTS.'SP'
   \insert CP.env
   = IMPORTS.'CP'
   \insert Common.env
   = IMPORTS.'Common'
in
   \insert POTypes
   \insert StaticAnalysis
end
