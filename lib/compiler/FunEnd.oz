proc
   %instantiate
   {$ IMPORTS}
   \insert SP.env
   = IMPORTS.'SP'
   \insert Common.env
   = IMPORTS.'Common'
   \insert Gump.env
   = IMPORTS.'Gump'
in
   \insert Assembler
   \insert CompilerClass
   \insert GenericInterface
   \insert QuietInterface
end
