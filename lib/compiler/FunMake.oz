declare
local
   Load = {`Builtin` 'URL.load' 2}
in
FunCode = {Load './compiler/FunCode.ozc'}
FunCore = {Load './compiler/FunCore.ozc'}
FunEnd  = {Load './compiler/FunEnd.ozc'}
FunMisc = {Load './compiler/FunMisc.ozc'}
FunStat = {Load './compiler/FunStat.ozc'}
end
