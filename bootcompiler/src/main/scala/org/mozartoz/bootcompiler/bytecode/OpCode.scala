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
case class OpCallG(target: GReg, arity: ImmInt) extends OpCode

/** Tail-call the `target` whose arity is supposed to be `arity`
 *  Y registers must have been deallocated before this */
case class OpTailCallX(target: XReg, arity: ImmInt) extends OpCode
case class OpTailCallG(target: GReg, arity: ImmInt) extends OpCode

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
case class OpPatternMatch(value: XReg, patterns: KReg) extends OpCode

/** Unify `lhs` with `rhs`, i.e., `lhs = rhs` */
case class OpUnifyXX(lhs: XReg, rhs: XReg) extends OpCode
case class OpUnifyXY(lhs: XReg, rhs: YReg) extends OpCode
case class OpUnifyXG(lhs: XReg, rhs: GReg) extends OpCode
case class OpUnifyXK(lhs: XReg, rhs: KReg) extends OpCode

/** Create an abstraction with the given `body` (code area) and
 *  `globalCount` (number of G registers) and store it in `dest`
 *  G registers must be initialized with `SubOpArrayFill_` afterwards. */
case class OpCreateAbstractionStoreX(body: KReg,
    globalCount: ImmInt, dest: XReg) extends OpCode

/** Create a cons and store it in `dest`
 *  Elements must be initialized with `SubOpArrayFill_' afterwards. */
case class OpCreateConsStoreX(dest: XReg) extends OpCode {
  override def argumentCount = 3
  override def arguments = List(ImmInt(0), ImmInt(2), dest)
}

/** Create a tuple of given `label' and `width' and store it in `dest`
 *  Elements must be initialized with `SubOpArrayFill_' afterwards. */
case class OpCreateTupleStoreX(label: KReg, width: ImmInt,
    dest: XReg) extends OpCode

/** Create a record of given `arity' and `width' and  store it in `dest`
 *  Elements must be initialized with `SubOpArrayFill_' afterwards. */
case class OpCreateRecordStoreX(arity: KReg, width: ImmInt,
    dest: XReg) extends OpCode

/** Fill a newly created array */
case class SubOpArrayFillX(value: XReg) extends OpCode
case class SubOpArrayFillY(value: YReg) extends OpCode
case class SubOpArrayFillG(value: GReg) extends OpCode
case class SubOpArrayFillK(value: KReg) extends OpCode

// Special

/** Dummy used by `CodeArea.addHole()` (not a true opcode) */
case class OpHole(override val size: Int) extends OpCode
