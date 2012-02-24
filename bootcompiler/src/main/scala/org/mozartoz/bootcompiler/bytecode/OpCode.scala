package org.mozartoz.bootcompiler
package bytecode

sealed abstract class OpCode extends Product {
  val name = getClass().getSimpleName()

  def argumentCount = productArity

  def arguments: List[OpCodeArg] = {
    for (item <- productIterator.toList)
      yield item.asInstanceOf[OpCodeArg]
  }

  def size = argumentCount + 1

  def code = {
    (name /: arguments) {
      (prev, arg) => prev + ", " + arg.code
    }
  }
}

case class OpSkip() extends OpCode

case class OpMoveXX(source: XReg, dest: XReg) extends OpCode
case class OpMoveXY(source: XReg, dest: YReg) extends OpCode
case class OpMoveYX(source: YReg, dest: XReg) extends OpCode
case class OpMoveYY(source: YReg, dest: YReg) extends OpCode
case class OpMoveGX(source: GReg, dest: XReg) extends OpCode
case class OpMoveGY(source: GReg, dest: YReg) extends OpCode
case class OpMoveKX(source: KReg, dest: XReg) extends OpCode
case class OpMoveKY(source: KReg, dest: YReg) extends OpCode

case class OpAllocateL(count: ImmInt) extends OpCode
case class OpDeallocateL() extends OpCode

case class OpCreateVarX(dest: XReg) extends OpCode
case class OpCreateVarY(dest: YReg) extends OpCode

case class OpCallBuiltin(builtin: KReg, arity: ImmInt,
    args: List[XReg]) extends OpCode {
  override def argumentCount = 2 + arity.value

  override def arguments = builtin :: arity :: args
}

case class OpCallX(target: XReg, arity: ImmInt) extends OpCode
case class OpCallG(target: GReg, arity: ImmInt) extends OpCode
case class OpTailCallX(target: XReg, arity: ImmInt) extends OpCode
case class OpTailCallG(target: GReg, arity: ImmInt) extends OpCode
case class OpReturn() extends OpCode

case class OpBranch(distance: ImmInt) extends OpCode
case class OpCondBranch(test: XReg, trueDistance: ImmInt,
    falseDistance: ImmInt, errorDistance: ImmInt) extends OpCode

case class OpUnifyXX(lhs: XReg, rhs: XReg) extends OpCode
case class OpUnifyXY(lhs: XReg, rhs: YReg) extends OpCode
case class OpUnifyXG(lhs: XReg, rhs: GReg) extends OpCode
case class OpUnifyXK(lhs: XReg, rhs: KReg) extends OpCode

case class OpArrayInitElementX(target: XReg,
    index: ImmInt, value: XReg) extends OpCode
case class OpArrayInitElementY(target: XReg,
    index: ImmInt, value: YReg) extends OpCode
case class OpArrayInitElementG(target: XReg,
    index: ImmInt, value: GReg) extends OpCode
case class OpArrayInitElementK(target: XReg,
    index: ImmInt, value: KReg) extends OpCode

case class OpCreateAbstractionX(arity: ImmInt, body: XReg,
    globalCount: ImmInt, dest: XReg) extends OpCode
case class OpCreateAbstractionK(arity: ImmInt, body: KReg,
    globalCount: ImmInt, dest: XReg) extends OpCode

// Special
case class OpHole() extends OpCode
