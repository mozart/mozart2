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
  }

  private implicit def symbol2ops2(self: Symbol) = new {
    def toReg = symbol2reg(self)

    def := (source: Register) {
      toReg match {
        case xy:XOrYReg => xy := source
      }
    }
  }

  override def applyToAbstraction() {
    // Allocate local variables
    code += OpAllocateL(abstraction.formals.size + abstraction.locals.size)

    // Save formals in local variables
    for ((formal, index) <- abstraction.formals.zipWithIndex)
      code += OpMoveXY(XReg(index), formal)

    // Create new variables for the other locals
    for (local <- abstraction.locals)
      code += OpCreateVarY(local)

    // Actual codegen
    generate(abstraction.body)

    // Deallocate local variables and return
    code += OpDeallocateL()
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
        // TODO

      case ((lhs:Variable) === (rhs @ CreateAbstraction(abs, globals))) =>
        // TODO

      case IfStatement(cond:Variable, trueStat, falseStat) =>
        // TODO Branch distances
        XReg(0) := cond.symbol
        code += OpCondBranch(XReg(0), 0, 0, 0)
        generate(trueStat)
        code += OpBranch(0)
        generate(falseStat)

      case CallStatement(callable:Variable, args) =>
        for ((arg:Variable, index) <- args.zipWithIndex)
          XReg(index) := arg.symbol

        val callableReg = XReg(args.size)
        callableReg := callable.symbol

        code += OpCallX(callableReg, args.size)
    }
  }
}
