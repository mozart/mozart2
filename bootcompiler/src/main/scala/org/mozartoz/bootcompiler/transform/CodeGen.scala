package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import bytecode._
import symtab._

object CodeGen extends Transformer with TreeDSL {
  def code = abstraction.codeArea

  private implicit def symbol2reg(symbol: VariableSymbol) =
    code.registerFor(symbol)

  private implicit def symbol2reg(symbol: Symbol) =
    code.registerFor(symbol)

  private implicit def varorconst2reg(expr: VarOrConst) =
    code.registerFor(expr)

  private implicit def reg2ops[A <: Register](self: A) = new {
    def := (source: Register)(implicit ev: A <:< XOrYReg) {
      (source, self:XOrYReg) match {
        case (src:XReg, dest:XReg) => code += OpMoveXX(src, dest)
        case (src:XReg, dest:YReg) => code += OpMoveXY(src, dest)
        case (src:YReg, dest:XReg) => code += OpMoveYX(src, dest)
        case (src:YReg, dest:YReg) => code += OpMoveYY(src, dest)
        case (src:GReg, dest:XReg) => code += OpMoveGX(src, dest)
        case (src:GReg, dest:YReg) => code += OpMoveGY(src, dest)
        case (src:KReg, dest:XReg) => code += OpMoveKX(src, dest)
        case (src:KReg, dest:YReg) => code += OpMoveKY(src, dest)
      }
    }

    def === (rhs: Register)(implicit ev: A <:< XReg) {
      rhs match {
        case right:XReg => code += OpUnifyXX(self, right)
        case right:YReg => code += OpUnifyXY(self, right)
        case right:GReg => code += OpUnifyXG(self, right)
        case right:KReg => code += OpUnifyXK(self, right)
      }
    }

    def array(index: ImmInt)(implicit ev: A <:< XReg) = new {
      def := (value: Register) {
        value match {
          case v:XReg => code += OpArrayInitElementX(self, index, v)
          case v:YReg => code += OpArrayInitElementY(self, index, v)
          case v:GReg => code += OpArrayInitElementG(self, index, v)
          case v:KReg => code += OpArrayInitElementK(self, index, v)
        }
      }
    }

    def initArrayWith(values: List[Expression])(implicit ev: A <:< XReg) {
      for ((value:VarOrConst, index) <- values.zipWithIndex)
        array(index) := value
    }
  }

  private implicit def symbol2ops2(self: Symbol) = new {
    def toReg = symbol2reg(self)
  }

  override def applyToAbstraction() {
    // Allocate local variables
    val localCount = abstraction.formals.size + abstraction.locals.size
    if (localCount != 0)
      code += OpAllocateY(abstraction.formals.size + abstraction.locals.size)

    // Save formals in local variables
    for ((formal, index) <- abstraction.formals.zipWithIndex)
      code += OpMoveXY(XReg(index), formal.toReg.asInstanceOf[YReg])

    // Create new variables for the other locals
    for (local <- abstraction.locals)
      code += OpCreateVarY(local.toReg.asInstanceOf[YReg])

    // Actual codegen
    generate(abstraction.body)

    // Deallocate local variables and return
    if (localCount != 0)
      code += OpDeallocateY()
    code += OpReturn()
  }

  def generate(statement: Statement) {
    statement match {
      case SkipStatement() =>
        // skip

      case CompoundStatement(statements) =>
        for (stat <- statements)
          generate(stat)

      case ((lhs:Variable) === (rhs:Variable)) =>
        XReg(0) := lhs.symbol
        XReg(0) === rhs.symbol

      case ((lhs:Variable) === (rhs:Constant)) =>
        XReg(0) := code.registerFor(rhs.value)
        XReg(0) === lhs.symbol

      case ((lhs:Variable) === (rhs @ Record(_, fields))) if rhs.isCons =>
        val List(RecordField(_, head:VarOrConst),
            RecordField(_, tail:VarOrConst)) = fields

        XReg(0) := code.registerFor(head)
        XReg(1) := code.registerFor(tail)
        code += OpCreateConsXX(XReg(0), XReg(1), XReg(2))
        XReg(2) === lhs.symbol

      case ((lhs:Variable) === (rhs @ Record(Constant(label), fields)))
      if rhs.isTuple =>
        val labelReg = code.registerFor(label)
        val fieldCount = fields.size
        val dest = XReg(0)

        code += OpCreateTupleK(labelReg, fieldCount, dest)

        dest.initArrayWith(fields map (_.value))
        dest === lhs.symbol

      case ((lhs:Variable) === (rhs @ Record(_, fields)))
      if rhs.hasConstantArity =>
        val fieldCount = fields.size
        val dest = XReg(0)

        val arityReg = code.registerFor(rhs.getConstantArity)

        code += OpCreateRecordK(arityReg, fieldCount, dest)

        dest.initArrayWith(fields map (_.value))
        dest === lhs.symbol

      case ((lhs:Variable) === (rhs @ CreateAbstraction(abs, globals))) =>
        val dest = XReg(0)

        val bodyReg = code.registerFor(abs.codeArea)
        code += OpCreateAbstractionK(abs.arity, bodyReg, globals.size, dest)

        dest.initArrayWith(globals)
        dest === lhs.symbol

      case IfStatement(cond:Variable, trueStat, falseStat) =>
        XReg(0) := cond.symbol
        val condBranchHole = code.addHole()
        var branchHole: CodeArea#Hole = null

        val errorSize = code.counting {
          // TODO generate error code
        }

        val trueBranchSize = code.counting {
          generate(trueStat)
          branchHole = code.addHole(2)
        }

        val falseBranchSize = code.counting {
          generate(falseStat)
        }

        condBranchHole fillWith OpCondBranch(XReg(0),
            errorSize + trueBranchSize, errorSize, 0)

        branchHole fillWith OpBranch(falseBranchSize)

      case MatchStatement(value:Variable, clauses, elseStat) =>
        XReg(0) := value.symbol
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
            generate(clause.body)
            if (index+1 < clauseCount)
              branchToAfterHoles(index+1) = code.addHole(2)
          }
        }

        val totalSize = jumpOffsets(clauseCount)
        val patternsInfo = OzSharp(patterns.toList)

        matchHole fillWith OpPatternMatch(
            XReg(0), code.registerFor(patternsInfo))

        for (index <- 0 until clauseCount) {
          branchToAfterHoles(index) fillWith OpBranch(
              totalSize - jumpOffsets(index))
        }

      case CallStatement(Constant(callable @ OzBuiltin(builtin)), args) =>
        val argCount = args.size

        if (argCount != builtin.arity)
          throw new IllegalArgumentException(
              "Wrong arity for builtin application of %s" format builtin)

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

      case CallStatement(callable:Variable, args) =>
        val argCount = args.size

        (callable.symbol: @unchecked) match {
          case symbol:VariableSymbol =>
            for ((arg:VarOrConst, index) <- args.zipWithIndex)
              XReg(index) := arg

            symbol.toReg match {
              case reg:XReg => code += OpCallX(reg, argCount)
              case reg:GReg => code += OpCallG(reg, argCount)
              case _ =>
                val reg = XReg(argCount)
                reg := symbol
                code += OpCallX(reg, argCount)
            }
        }
    }
  }
}
