local
   % Misc
   PrintNameToVirtualString
   IsPrintName
   NameVariable
   NewNamedName
   GetProcInfo
   SetProcInfo
   IsBuiltin
   GetBuiltinName
   GenerateAbstractionTableID
   ConcatenateAtomAndInt

   % Builtins
   GetBuiltinInfo

   % CoreLanguage
   FlattenSequence
   Core
in
   \insert Misc
   \insert Builtins

   local
      ImAConstruction       = {NewName}
      ImAValueNode          = {NewName}
      ImAVariableOccurrence = {NewName}
      ImAToken              = {NewName}

      % Annotate
      Annotate

      % StaticAnalysis
      SA

      % CodeGen
      CodeGen
   in
      \insert Annotate

      local
         % POTypes
         OzTypes
         OzValueToType
      in
         \insert POTypes
         \insert StaticAnalysis
      end

      local
         % RegSet
         RegSet

         % CodeEmitter
         Emitter

         % CodeStore
         Continuations
         ShowVInstr
         CodeStore
      in
         \insert RegSet
         \insert CodeEmitter
         \insert CodeStore
         \insert CodeGen
      end

      \insert CoreLanguage
   end

   local
      SetSwitches          = {NewName}
      SetMaxNumberOfErrors = {NewName}
      ShowInfo             = {NewName}
      DisplaySource        = {NewName}
      ToTop                = {NewName}
      DisplayEnv           = {NewName}
      AskAbort             = {NewName}

      % Version
      OZVERSION
      DATE

      % FormatStrings
      FormatStringToVirtualString

      % Reporter
      Reporter

      % ParseOz
      ParseOzFile
      ParseOzVirtualString

      % Unnester
      Unnester

      % Interface
      Interface

      % Assembler
      Assemble

      % Compiler
      CompilerClass
   in
      \insert Version
      \insert FormatStrings
      \insert Reporter
      \insert ParseOz
      local
         % TupleSyntax
         CoordinatesOf
         VarListSub
         GetPatternVariablesStatement
         GetPatternVariablesExpression
         UniqueVariables
         PrivateAttrFeat
         PrivateMeth

         % BindingAnalysis
         BindingAnalysis

         % UnnestFD
         MakeFdCompareStatement
         MakeFdCompareExpression
         MakeCondis
      in
         \insert TupleSyntax
         \insert BindingAnalysis
         \insert UnnestFD
         \insert Unnester
      end
      \insert Interface
      \insert Assembler
      \insert Compiler
      \insert TkInterface
      \insert EmacsInterface
      \insert QuietInterface
   end
end
