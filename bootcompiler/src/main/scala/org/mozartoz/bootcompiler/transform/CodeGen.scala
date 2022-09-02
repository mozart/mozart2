package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import bytecode._
import symtab._

object CodeGen extends Transformer with TreeDSL {
  def code = abstraction.codeArea

  private implicit def symbol2reg(symbol: Symbol) =
    code.registerFor(symbol)

  private implicit def varorconst2reg(expr: VarOrConst) =
    code.registerFor(expr)

  private implicit def reg2ops[A <: Register](self: A) = new {
    def := (source: Register)(implicit ev: A <:< XOrYReg): Unit = {
      code += OpMove(source, self)
    }

    def === (rhs: Register): Unit = {
      code += OpUnify(self, rhs)
    }
  }

  private implicit def symbol2ops2(self: Symbol) = new {
    def toReg = symbol2reg(self)
  }

  private implicit def value2ops(self: OzValue) = new {
    def toReg = code.registerFor(self)
  }

  def initArrayWith(values: List[Expression]): Unit = {
    for (value <- values) {
      varorconst2reg(value.asInstanceOf[VarOrConst]) match {
        case v:XReg => code += SubOpArrayFillX(v)
        case v:YReg => code += SubOpArrayFillY(v)
        case v:GReg => code += SubOpArrayFillG(v)
        case v:KReg => code += SubOpArrayFillK(v)
      }
    }
  }

  override def applyToAbstraction(): Unit = {
    // Allocate local variables
    val localCount = abstraction.formals.size + abstraction.locals.size
    if (localCount != 0)
      code += OpAllocateY(localCount)

    // Save formals in local variables
    for ((formal, index) <- abstraction.formals.zipWithIndex)
      code += OpMove(XReg(index), formal.toReg.asInstanceOf[XOrYReg])

    // Create new variables for the other locals
    for (local <- abstraction.locals)
      code += OpCreateVarY(local.toReg.asInstanceOf[YReg])

    // Actual codegen
    generate(abstraction.body)

    // Return
    code += OpReturn()
  }

  def generate(statement: Statement): Unit = {
    statement match {
      case SkipStatement() =>
        // skip

      case CompoundStatement(statements) =>
        for (stat <- statements)
          generate(stat)

      case Variable(lhs) === Variable(rhs) =>
        lhs.toReg === rhs.toReg

      case Variable(lhs) === Constant(rhs) =>
        lhs.toReg === rhs.toReg

      case Variable(lhs) === (rhs @ Record(_, fields)) if rhs.isCons =>
        val List(RecordField(_, head:VarOrConst),
            RecordField(_, tail:VarOrConst)) = fields

        code += OpCreateConsUnify(lhs)
        initArrayWith(List(head, tail))

      case Variable(lhs) === (rhs @ Record(Constant(label), fields))
      if rhs.isTuple =>
        code += OpCreateTupleUnify(label.toReg, fields.size, lhs)
        initArrayWith(fields map (_.value))

      case Variable(lhs) === (rhs @ Record(_, fields))
      if rhs.hasConstantArity =>
        code += OpCreateRecordUnify(rhs.getConstantArity.toReg,
            fields.size, lhs)
        initArrayWith(fields map (_.value))

      case Variable(lhs) === (rhs @ CreateAbstraction(
          Constant(body), globals)) =>
        code += OpCreateAbstractionUnify(body.toReg, globals.size, lhs)
        initArrayWith(globals)

      case IfStatement(cond:Variable, trueStat, falseStat) =>
        XReg(0) := cond.symbol
        val condBranchHole = code.addHole()
        var branchHoleInFalseBranch: CodeArea#Hole = null
        var branchHoleInTrueBranch: CodeArea#Hole = null

        val trueBranchSize = code.counting {
          generate(trueStat)
          branchHoleInTrueBranch = code.addHole(2)
        }

        val falseBranchSize = code.counting {
          generate(falseStat)
          branchHoleInFalseBranch = code.addHole(2)
        }

        val errorSize = code.counting {
          // TODO generate proper error code
          code += OpMove(code.registerFor(OzAtom("condBranchError")), XReg(0))
          code += OpCallBuiltin(
              code.registerFor(OzBuiltin(program.builtins.raiseError)),
              1, List(XReg(0)))
        }

        condBranchHole fillWith OpCondBranch(XReg(0),
            trueBranchSize, trueBranchSize + falseBranchSize)

        branchHoleInTrueBranch fillWith OpBranch(falseBranchSize + errorSize)
        branchHoleInFalseBranch fillWith OpBranch(errorSize)

      case MatchStatement(Variable(value), clauses, elseStat) =>
        val matchHole = code.addHole()

        val clauseCount = clauses.size
        val patterns = new Array[OzValue](clauseCount)
        val branchToAfterHoles = new Array[CodeArea#Hole](clauseCount+1)
        val jumpOffsets = new Array[Int](clauseCount+1)

        jumpOffsets(0) = code.counting {
          generate(elseStat)
          if (clauseCount > 0)
            branchToAfterHoles(0) = code.addHole(2)
        }

        for ((clause, index) <- clauses.zipWithIndex) {
          // Pattern, which must be constant at this point
          val Constant(pattern) = clause.pattern
          patterns(index) = OzSharp(List(
              pattern, OzInt(jumpOffsets(index))))

          // The guard must be empty at this point
          assert(clause.guard.isEmpty)

          // Body
          jumpOffsets(index+1) = jumpOffsets(index) + code.counting {
            // Captures
            var captureIndex = 0
            def walk(value: OzValue): Unit = value match {
              case OzPatMatCapture(symbol) =>
                captureIndex += 1
                symbol.captureIndex = captureIndex
                val reg = code.registerFor(symbol).asInstanceOf[YReg]
                reg := XReg(captureIndex)

              case OzRecord(label, fields) =>
                for (OzRecordField(_, fieldValue) <- fields)
                  walk(fieldValue)

              case OzPatMatOpenRecord(label, fields) =>
                for (OzRecordField(_, fieldValue) <- fields)
                  walk(fieldValue)

              case OzPatMatConjunction(parts) =>
                parts foreach walk

              case _ => ()
            }

            walk(pattern)

            // Actual body
            generate(clause.body)
            if (index+1 < clauseCount)
              branchToAfterHoles(index+1) = code.addHole(2)
          }
        }

        val totalSize = jumpOffsets(clauseCount)
        val patternsInfo = OzSharp(patterns.toList)

        matchHole fillWith OpPatternMatch(value, patternsInfo.toReg)

        for (index <- 0 until clauseCount) {
          branchToAfterHoles(index) fillWith OpBranch(
              totalSize - jumpOffsets(index))
        }

      case TryStatement(body, Variable(exceptionVar), catchBody) =>
        val setupHandlerHole = code.addHole()
        var branchHole: CodeArea#Hole = null

        val catchSize = code.counting {
          exceptionVar.toReg.asInstanceOf[YReg] := XReg(0)
          generate(catchBody)
          branchHole = code.addHole(2)
        }

        val bodySize = code.counting {
          generate(body)
          code += OpPopExceptionHandler()
        }

        setupHandlerHole fillWith OpSetupExceptionHandler(catchSize)

        branchHole fillWith OpBranch(bodySize)

      case CallStatement(Constant(callable @ OzBuiltin(builtin)), args) =>
        val argCount = args.size

        if (argCount != builtin.arity) {
          program.reportError(
              "Wrong arity for builtin application of " + builtin +
              " (%d expected but %d found)".format(builtin.arity, argCount),
              statement.pos)
        } else {
          val paramKinds = builtin.paramKinds
          val argsWithKindAndIndex = args.zip(paramKinds).zipWithIndex

          for {
            ((arg:VarOrConst, kind), index) <- argsWithKindAndIndex
            if kind == Builtin.ParamKind.In
          } {
            XReg(index) := arg
          }

          val argsRegs = (0 until argCount).toList map XReg

          if (builtin.inlineable)
            code += OpCallBuiltinInline(builtin.inlineOpCode, argsRegs)
          else {
            val builtinReg = code.registerFor(callable)
            code += OpCallBuiltin(builtinReg, argCount, argsRegs)
          }

          for {
            ((arg:VarOrConst, kind), index) <- argsWithKindAndIndex
            if kind == Builtin.ParamKind.Out
          } {
            XReg(index) === arg
          }
        }

      case CallStatement(Variable(target), args) =>
        for ((arg:VarOrConst, index) <- args.zipWithIndex)
          XReg(index) := arg

        code += OpCall(target, args.size)
    }
  }
}
