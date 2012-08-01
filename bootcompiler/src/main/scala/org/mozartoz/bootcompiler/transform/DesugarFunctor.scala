package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import oz._
import ast._
import symtab._

object DesugarFunctor extends Transformer with TreeDSL {
  override def transformExpr(expression: Expression) = expression match {
    case functor @ FunctorExpression(name, require, prepare,
        imports, define, exports) if (!require.isEmpty || !prepare.isEmpty) =>
      /* In the boot compiler, require/prepare is no different than
       * import/define.
       * -> merge them
       */

      val mergedRequireImport = require ::: imports

      val mergedPrepareDefine = {
        if (prepare.isEmpty) define
        else if (define.isEmpty) prepare
        else {
          val LocalStatement(prepareDecls, prepareStat) = prepare.get
          val LocalStatement(defineDecls, defineStat) = define.get
          Some(LocalStatement(prepareDecls ::: defineDecls,
              prepareStat ~ defineStat))
        }
      }

      transformExpr {
        atPos(functor) {
          FunctorExpression(name, Nil, None, mergedRequireImport,
              mergedPrepareDefine, exports)
        }
      }

    case functor @ FunctorExpression(name, Nil, None,
        imports, define, exports) =>

      val importsRec = makeImportsRec(imports)
      val exportsRec = makeExportsRec(exports)
      val applyFun = makeApplyFun(define, imports, exports)

      val functorRec = atPos(functor) {
        Record(OzAtom("functor"), List(
            RecordField(OzAtom("import"), importsRec),
            RecordField(OzAtom("export"), exportsRec),
            RecordField(OzAtom("apply"), applyFun)))
      }

      transformExpr(functorRec)

    case _ =>
      super.transformExpr(expression)
  }

  def makeImportsRec(imports: List[FunctorImport]): Expression = {
    val resultFields = for {
      FunctorImport(Variable(module), aliases, location) <- imports
    } yield {
      val modName = module.name

      val typeField = {
        val requiredFeatures =
          for (AliasedFeature(feat, _) <- aliases)
            yield feat.value

        RecordField(OzAtom("type"), OzList(requiredFeatures))
      }

      val fromField = {
        val loc = {
          if (location.isDefined) location.get
          else if (!SystemModules.isSystemModule(modName)) modName + ".ozf"
          else "x-oz://system/" + modName + ".ozf"
        }
        RecordField(OzAtom("from"), OzAtom(loc))
      }

      val info = Record(OzAtom("info"), List(typeField, fromField))

      RecordField(OzAtom(modName), info)
    }

    Record(OzAtom("import"), resultFields)
  }

  def makeExportsRec(exports: List[FunctorExport]): Expression = {
    val resultFields = for {
      FunctorExport(Constant(feature:OzFeature), _) <- exports
    } yield {
      RecordField(feature, OzAtom("value"))
    }

    Record(OzAtom("export"), resultFields)
  }

  def makeApplyFun(define: Option[LocalStatementOrRaw],
      imports: List[FunctorImport],
      exports: List[FunctorExport]): Expression = {
    val importsParam = Variable.newSynthetic("<Imports>", formal = true)

    val importedDecls = extractAllImportedDecls(imports)

    val (definedDecls, defineStat) = define match {
      case Some(LocalStatement(decls, stat)) => (decls, stat)
      case None => (Nil, SkipStatement())
    }

    val (utilsDecls, importsDot) = {
      if (program.isBaseEnvironment) {
        val regularDot = Constant(OzBuiltin(builtins.binaryOpToBuiltin(".")))
        (None, regularDot)
      } else {
        val byNeedDot = Variable.newSynthetic("ByNeedDot")
        (Some(byNeedDot), byNeedDot)
      }
    }

    val allDecls = importedDecls ++ definedDecls ++ utilsDecls

    FUN("<Apply>", List(importsParam)) {
      LOCAL (allDecls:_*) IN {
        val statements = new ListBuffer[Statement]
        def exec(statement: Statement) = statements += statement

        if (!program.isBaseEnvironment)
          exec(importsDot === baseEnvironment("ByNeedDot"))

        for (FunctorImport(module:Variable, aliases, _) <- imports) {
          exec(module === (importsParam dot OzAtom(module.symbol.name)))

          for (AliasedFeature(feature, Some(variable:Variable)) <- aliases) {
            exec(variable === (importsDot callExpr (module, feature)))
          }
        }

        // Of course execute the actual define statements
        exec(defineStat)

        // Now compute the export record
        val exportFields = for {
          FunctorExport(feature, value) <- exports
        } yield {
          RecordField(feature, value)
        }

        val exportRec = Record(OzAtom("export"), exportFields)

        // Final body
        CompoundStatement(statements.toList) ~>
        exportRec
      }
    }
  }

  def extractAllImportedDecls(imports: List[FunctorImport]) = {
    val result = new ListBuffer[Variable]

    for (FunctorImport(module:Variable, aliases, _) <- imports) {
      result += module

      for (AliasedFeature(_, Some(variable:Variable)) <- aliases)
        result += variable
    }

    result.toList
  }
}
