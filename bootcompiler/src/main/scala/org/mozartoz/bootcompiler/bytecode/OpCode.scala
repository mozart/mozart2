package org.mozartoz.bootcompiler
package bytecode

/**
 * Base class for opcodes
 */
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

/** Do nothing */
case class OpSkip() extends OpCode

/** Copy source register into destination register */
case class OpMoveXX(source: XReg, dest: XReg) extends OpCode
case class OpMoveXY(source: XReg, dest: YReg) extends OpCode
case class OpMoveYX(source: YReg, dest: XReg) extends OpCode
case class OpMoveYY(source: YReg, dest: YReg) extends OpCode
case class OpMoveGX(source: GReg, dest: XReg) extends OpCode
case class OpMoveGY(source: GReg, dest: YReg) extends OpCode
case class OpMoveKX(source: KReg, dest: XReg) extends OpCode
case class OpMoveKY(source: KReg, dest: YReg) extends OpCode

object OpMove {
  def apply(source: Register, dest: XOrYReg) = (source, dest) match {
    case (s:XReg, d:XReg) => OpMoveXX(s, d)
    case (s:XReg, d:YReg) => OpMoveXY(s, d)
    case (s:YReg, d:XReg) => OpMoveYX(s, d)
    case (s:YReg, d:YReg) => OpMoveYY(s, d)
    case (s:GReg, d:XReg) => OpMoveGX(s, d)
    case (s:GReg, d:YReg) => OpMoveGY(s, d)
    case (s:KReg, d:XReg) => OpMoveKX(s, d)
    case (s:KReg, d:YReg) => OpMoveKY(s, d)
  }
}

/** Allocate `count` local variables, i.e., Y registers */
case class OpAllocateY(count: ImmInt) extends OpCode
/** Deallocate the current Y registers */
case class OpDeallocateY() extends OpCode

/** Create a new Unbound variable and store it into `dest` */
case class OpCreateVarX(dest: XReg) extends OpCode
case class OpCreateVarY(dest: YReg) extends OpCode

/** Setup an exception handler */
case class OpSetupExceptionHandler(distance: ImmInt) extends OpCode

/** Pop an exception handler */
case class OpPopExceptionHandler() extends OpCode

/** Call the `builtin` whose arity is `arity` with the arguments `args` */
case class OpCallBuiltin(builtin: KReg, arity: ImmInt,
    args: List[XReg]) extends OpCode {
  private val argc = arity.value
  private val isSpec = argc <= 5

  override val name =
    if (isSpec) "OpCallBuiltin" + argc.toString()
    else "OpCallBuiltinN"

  override def argumentCount =
    if (isSpec) 1 + argc
    else 2 + argc

  override def arguments =
    if (isSpec) builtin :: args
    else builtin :: arity :: args
}

/** Call an inline builtin */
case class OpCallBuiltinInline(opCode: Int, args: List[XReg]) extends OpCode {
  private val argc = args.size

  override val name = opCode.toString()
  override def argumentCount = argc
  override def arguments = args
}

/** Call the `target` whose arity is supposed to be `arity`
 *  Upon return, all X registers are invalidated */
case class OpCallX(target: XReg, arity: ImmInt) extends OpCode
case class OpCallY(target: YReg, arity: ImmInt) extends OpCode
case class OpCallG(target: GReg, arity: ImmInt) extends OpCode
case class OpCallK(target: KReg, arity: ImmInt) extends OpCode

object OpCall {
  def apply(target: Register, arity: ImmInt) = target match {
    case t:XReg => OpCallX(t, arity)
    case t:YReg => OpCallY(t, arity)
    case t:GReg => OpCallG(t, arity)
    case t:KReg => OpCallK(t, arity)
  }

  def apply(target: Register, arity: ImmInt, isTailCall: Boolean): OpCode =
    if (isTailCall) OpTailCall(target, arity)
    else OpCall(target, arity)
}

/** Tail-call the `target` whose arity is supposed to be `arity`
 *  Y registers must have been deallocated before this */
case class OpTailCallX(target: XReg, arity: ImmInt) extends OpCode
case class OpTailCallY(target: YReg, arity: ImmInt) extends OpCode
case class OpTailCallG(target: GReg, arity: ImmInt) extends OpCode
case class OpTailCallK(target: KReg, arity: ImmInt) extends OpCode

object OpTailCall {
  def apply(target: Register, arity: ImmInt) = target match {
    case t:XReg => OpTailCallX(t, arity)
    case t:YReg => OpTailCallY(t, arity)
    case t:GReg => OpTailCallG(t, arity)
    case t:KReg => OpTailCallK(t, arity)
  }
}

/** Return
 *  Y registers must have been deallocated before this */
case class OpReturn() extends OpCode

/** Skip `distance` amount of bytecode */
case class OpBranch(distance: ImmInt) extends OpCode

/** Conditional branch
 *  If `test == false`, skip `falseDistance` amount of bytecode
 *  If `test == true`, skip `trueDistance` amount of bytecode
 *  Otherwise, skip `errorDistance` amount of bytecode
 */
case class OpCondBranch(test: XReg, falseDistance: ImmInt,
    trueDistance: ImmInt, errorDistance: ImmInt) extends OpCode

/** Pattern matching */
case class OpPatternMatchX(value: XReg, patterns: KReg) extends OpCode
case class OpPatternMatchY(value: YReg, patterns: KReg) extends OpCode
case class OpPatternMatchG(value: GReg, patterns: KReg) extends OpCode

object OpPatternMatch {
  def apply(value: NotKReg, patterns: KReg) = value match {
    case v:XReg => OpPatternMatchX(v, patterns)
    case v:YReg => OpPatternMatchY(v, patterns)
    case v:GReg => OpPatternMatchG(v, patterns)
  }
}

/** Unify `lhs` with `rhs`, i.e., `lhs = rhs` */
case class OpUnifyXX(lhs: XReg, rhs: XReg) extends OpCode
case class OpUnifyXY(lhs: XReg, rhs: YReg) extends OpCode
case class OpUnifyXG(lhs: XReg, rhs: GReg) extends OpCode
case class OpUnifyXK(lhs: XReg, rhs: KReg) extends OpCode
case class OpUnifyYY(lhs: YReg, rhs: YReg) extends OpCode
case class OpUnifyYG(lhs: YReg, rhs: GReg) extends OpCode
case class OpUnifyYK(lhs: YReg, rhs: KReg) extends OpCode
case class OpUnifyGG(lhs: GReg, rhs: GReg) extends OpCode
case class OpUnifyGK(lhs: GReg, rhs: KReg) extends OpCode
case class OpUnifyKK(lhs: KReg, rhs: KReg) extends OpCode

object OpUnify {
  def apply(lhs: Register, rhs: Register) = (lhs, rhs) match {
    case (l:XReg, r:XReg) => OpUnifyXX(l, r)
    case (l:XReg, r:YReg) => OpUnifyXY(l, r)
    case (l:XReg, r:GReg) => OpUnifyXG(l, r)
    case (l:XReg, r:KReg) => OpUnifyXK(l, r)
    case (l:YReg, r:YReg) => OpUnifyYY(l, r)
    case (l:YReg, r:GReg) => OpUnifyYG(l, r)
    case (l:YReg, r:KReg) => OpUnifyYK(l, r)
    case (l:GReg, r:GReg) => OpUnifyGG(l, r)
    case (l:GReg, r:KReg) => OpUnifyGK(l, r)
    case (l:KReg, r:KReg) => OpUnifyKK(l, r)

    case (l:YReg, r:XReg) => OpUnifyXY(r, l)
    case (l:GReg, r:XReg) => OpUnifyXG(r, l)
    case (l:GReg, r:YReg) => OpUnifyYG(r, l)
    case (l:KReg, r:XReg) => OpUnifyXK(r, l)
    case (l:KReg, r:YReg) => OpUnifyYK(r, l)
    case (l:KReg, r:GReg) => OpUnifyGK(r, l)
  }
}

/** Create an abstraction with the given `body` (code area) and
 *  `globalCount` (number of G registers) and unify it with `dest`
 *  G registers must be initialized with `SubOpArrayFill_` afterwards. */
case class OpCreateAbstractionUnifyX(body: KReg,
    globalCount: ImmInt, dest: XReg) extends OpCode
case class OpCreateAbstractionUnifyY(body: KReg,
    globalCount: ImmInt, dest: YReg) extends OpCode
case class OpCreateAbstractionUnifyG(body: KReg,
    globalCount: ImmInt, dest: GReg) extends OpCode
case class OpCreateAbstractionUnifyK(body: KReg,
    globalCount: ImmInt, dest: KReg) extends OpCode

object OpCreateAbstractionUnify {
  def apply(body: KReg, globalCount: ImmInt, dest: Register) = dest match {
    case d:XReg => OpCreateAbstractionUnifyX(body, globalCount, d)
    case d:YReg => OpCreateAbstractionUnifyY(body, globalCount, d)
    case d:GReg => OpCreateAbstractionUnifyG(body, globalCount, d)
    case d:KReg => OpCreateAbstractionUnifyK(body, globalCount, d)
  }
}

abstract sealed class OpCreateConsBase extends OpCode {
  protected val dest: Register
  override def argumentCount = 3
  override def arguments = List(ImmInt(0), ImmInt(2), dest)
}

/** Create a cons and unify it with `dest`
 *  Elements must be initialized with `SubOpArrayFill_' afterwards. */
case class OpCreateConsUnifyX(dest: XReg) extends OpCreateConsBase
case class OpCreateConsUnifyY(dest: YReg) extends OpCreateConsBase
case class OpCreateConsUnifyG(dest: GReg) extends OpCreateConsBase
case class OpCreateConsUnifyK(dest: KReg) extends OpCreateConsBase

object OpCreateConsUnify {
  def apply(dest: Register) = dest match {
    case d:XReg => OpCreateConsUnifyX(d)
    case d:YReg => OpCreateConsUnifyY(d)
    case d:GReg => OpCreateConsUnifyG(d)
    case d:KReg => OpCreateConsUnifyK(d)
  }
}

/** Create a tuple of given `label' and `width' and unify it with `dest`
 *  Elements must be initialized with `SubOpArrayFill_' afterwards. */
case class OpCreateTupleUnifyX(label: KReg, width: ImmInt,
    dest: XReg) extends OpCode
case class OpCreateTupleUnifyY(label: KReg, width: ImmInt,
    dest: YReg) extends OpCode
case class OpCreateTupleUnifyG(label: KReg, width: ImmInt,
    dest: GReg) extends OpCode
case class OpCreateTupleUnifyK(label: KReg, width: ImmInt,
    dest: KReg) extends OpCode

object OpCreateTupleUnify {
  def apply(label: KReg, width: ImmInt, dest: Register) = dest match {
    case d:XReg => OpCreateTupleUnifyX(label, width, d)
    case d:YReg => OpCreateTupleUnifyY(label, width, d)
    case d:GReg => OpCreateTupleUnifyG(label, width, d)
    case d:KReg => OpCreateTupleUnifyK(label, width, d)
  }
}

/** Create a record of given `arity' and `width' and  unify it with `dest`
 *  Elements must be initialized with `SubOpArrayFill_' afterwards. */
case class OpCreateRecordUnifyX(arity: KReg, width: ImmInt,
    dest: XReg) extends OpCode
case class OpCreateRecordUnifyY(arity: KReg, width: ImmInt,
    dest: YReg) extends OpCode
case class OpCreateRecordUnifyG(arity: KReg, width: ImmInt,
    dest: GReg) extends OpCode
case class OpCreateRecordUnifyK(arity: KReg, width: ImmInt,
    dest: KReg) extends OpCode

object OpCreateRecordUnify {
  def apply(arity: KReg, width: ImmInt, dest: Register) = dest match {
    case d:XReg => OpCreateRecordUnifyX(arity, width, d)
    case d:YReg => OpCreateRecordUnifyY(arity, width, d)
    case d:GReg => OpCreateRecordUnifyG(arity, width, d)
    case d:KReg => OpCreateRecordUnifyK(arity, width, d)
  }
}

/** Fill a newly created array */
case class SubOpArrayFillX(value: XReg) extends OpCode
case class SubOpArrayFillY(value: YReg) extends OpCode
case class SubOpArrayFillG(value: GReg) extends OpCode
case class SubOpArrayFillK(value: KReg) extends OpCode

object SubOpArrayFillValue {
  def apply(value: Register) = value match {
    case v:XReg => SubOpArrayFillX(v)
    case v:YReg => SubOpArrayFillY(v)
    case v:GReg => SubOpArrayFillG(v)
    case v:KReg => SubOpArrayFillK(v)
  }
}

// Special

/** Dummy used by `CodeArea.addHole()` (not a true opcode) */
case class OpHole(override val size: Int) extends OpCode
