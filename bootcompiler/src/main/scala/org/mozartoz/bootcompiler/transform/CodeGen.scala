package org.mozartoz.bootcompiler
package transform

import ast._
import bytecode._
import symtab._

object CodeGen extends Transformer with TreeDSL {
  def code = abstraction.codeArea

  private implicit def symbol2reg(symbol: VariableSymbol) =
    code.registerFor(symbol)

  private implicit def symbol2reg(symbol: BuiltinSymbol) =
    code.registerFor(symbol)

  private implicit def symbol2reg(symbol: Symbol) =
    code.registerFor(symbol)

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
      for ((value:Variable, index) <- values.zipWithIndex)
        array(index) := value.symbol
    }
  }

  private implicit def symbol2ops2(self: Symbol) = new {
    def toReg = symbol2reg(self)
  }

  override def applyToAbstraction() {
    // Allocate local variables
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
    code += OpDeallocateY()
    code += OpReturn()
  }

  def generate(statement: Statement) {
    statement match {
      case CompoundStatement(statements) =>
        for (stat <- statements)
          generate(stat)

      case ((lhs:Variable) === (rhs:Variable)) =>
        XReg(0) := lhs.symbol
        XReg(0) === rhs.symbol

      case ((lhs:Variable) === (rhs:Constant)) =>
        XReg(0) := code.registerFor(rhs)
        XReg(0) === lhs.symbol

      case ((lhs:Variable) === (rhs @ Record(label:Variable, fields))) =>
        val fieldCount = fields.size
        val dest = XReg(0)

        code.registerFor(label.symbol) match {
          case reg:XReg =>
            code += OpCreateTupleX(reg, fieldCount, dest)
          case reg:KReg => reg
            code += OpCreateTupleK(reg, fieldCount, dest)
          case reg =>
            XReg(1) := reg
            code += OpCreateTupleX(XReg(1), fieldCount, dest)
        }

        dest.initArrayWith(fields)
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

      case CallStatement(callable:Variable, args) =>
        val argCount = args.size

        (callable.symbol: @unchecked) match {
          case symbol:VariableSymbol =>
            for ((arg:Variable, index) <- args.zipWithIndex)
              XReg(index) := arg.symbol

            symbol.toReg match {
              case reg:XReg => code += OpCallX(reg, argCount)
              case reg:GReg => code += OpCallG(reg, argCount)
              case _ =>
                val reg = XReg(argCount)
                reg := symbol
                code += OpCallX(reg, argCount)
            }

          case symbol:BuiltinSymbol =>
            if (argCount != symbol.arity)
              throw new IllegalArgumentException(
                  "Wrong arity for builtin application of %s" format symbol)

            for {
              (arg:Variable, index) <- args.zipWithIndex
              if index < symbol.inputArity
            } {
              XReg(index) := arg.symbol
            }

            val reg = code.registerFor(symbol)

            code += OpCallBuiltin(reg, argCount,
                (0 until argCount).toList map XReg)

            for {
              (arg:Variable, index) <- args.zipWithIndex
              if index >= symbol.inputArity
            } {
              XReg(index) === arg.symbol
            }
        }
    }
  }
}
