local
   StandardEnv = \insert compiler-Env
in
   functor prop once
   import
      Property(get condGet)
      System   %--**(gcDo printError)
      Error   %--**(formatPos msg formatLine formatExc dispatch format formatGeneric)
      ErrorRegistry(put)
      Type(ask)
      Debug
      Parser
      Misc(nameVariable isPrintName)
      Core
      Unnest(joinQueries makeExpressionQuery unnestQuery)
\ifndef OZM
      Gump(makeProductionTemplates)
      ProductionTemplates(default)
\endif
      Assembler(internalAssemble assemble: Assemble)
   export
      CompilerEngine
      ParseOzFile
      ParseOzVirtualString
      GenericInterface
      QuietInterface
      EvalExpression
      VirtualStringToValue
      Assemble
   define
      local
         \insert FormatStrings
         \insert Reporter
         \insert CheckTupleSyntax
      in
         \insert CompilerClass
         \insert ParseOz
         \insert GenericInterface
         \insert QuietInterface
         \insert Abstractions
         \insert Errors
      end
   end
end
