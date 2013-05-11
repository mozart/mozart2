package org.mozartoz.bootcompiler
package ast

import oz._
import symtab._

/** Base class for ASTs that represent expressions */
sealed abstract class Expression extends StatOrExpr

// Compound expressions

/** Sequential composition of a statement and an expression
 *
 *  {{{
 *  (<statement> <expression>)
 *  }}}
 *
 *  The value of this expression is the value of the underlying `expression`
 *  after execution of the `statement`.
 */
case class StatAndExpression(statement: Statement,
    expression: Expression) extends Expression {
  def syntax(indent: String) = {
    statement.syntax(indent) + "\n" + indent + expression.syntax(indent)
  }
}

/** Raw local declaration expression (before naming)
 *
 *  {{{
 *  local
 *     <declarations>
 *  in
 *     <expression>
 *  end
 *  }}}
 */
case class RawLocalExpression(declarations: List[RawDeclaration],
    expression: Expression) extends Expression with LocalCommon {
  protected val body = expression
}

/** Local declaration expression
 *
 *  {{{
 *  local
 *     <declarations>
 *  in
 *     <expression>
 *  end
 *  }}}
 */
case class LocalExpression(declarations: List[Variable],
    expression: Expression) extends Expression with LocalCommon {
  protected val body = expression
}

// Complex expressions

/** Expression that creates a procedure abstraction
 *
 *  {{{
 *  proc <flags> {$ <args>...}
 *     <body>
 *  end
 *  }}}
 */
case class ProcExpression(name: String, args: List[VariableOrRaw],
    body: Statement, flags: List[String]) extends Expression
    with ProcFunExpression {
  protected val keyword = "proc"
}

/** Expression that creates a function abstraction
 *
 *  {{{
 *  fun <flags> {$ <args>...}
 *     <body>
 *  end
 *  }}}
 */
case class FunExpression(name: String, args: List[VariableOrRaw],
    body: Expression, flags: List[String]) extends Expression
    with ProcFunExpression {
  protected val keyword = "fun"
}

/** Call expression
 *
 *  {{{
 *  {<callable> <args>...}
 *  }}}
 */
case class CallExpression(callable: Expression,
    args: List[Expression]) extends Expression with CallCommon

/** If expression
 *
 *  {{{
 *  if <condition> then
 *     <trueExpression>
 *  else
 *     <falseExpression>
 *  end
 *  }}}
 */
case class IfExpression(condition: Expression,
    trueExpression: Expression,
    falseExpression: Expression) extends Expression with IfCommon {
  protected val truePart = trueExpression
  protected val falsePart = falseExpression
}

/** Pattern matching expression
 *
 *  {{{
 *  case <value>
 *  of <clauses>...
 *  else
 *     <elseExpression>
 *  end
 *  }}}
 */
case class MatchExpression(value: Expression,
    clauses: List[MatchExpressionClause],
    elseExpression: Expression) extends Expression with MatchCommon {
  protected val elsePart = elseExpression
}

/** Clause of a pattern matching expression
 *
 *  {{{
 *  [] <pattern> andthen <guard> then
 *     <body>
 *  }}}
 */
case class MatchExpressionClause(pattern: Expression, guard: Option[Expression],
    body: Expression) extends MatchClauseCommon {
  def hasGuard = guard.isDefined
}

/** Special node to mark that there is no else expression */
case class NoElseExpression() extends Expression {
  def syntax(indent: String) = "<noelse>"
}

/** Thread expression
 *
 *  {{{
 *  thread
 *     <expression>
 *  end
 *  }}}
 */
case class ThreadExpression(
    expression: Expression) extends Expression with ThreadCommon {
  protected val body = expression
}

/** Lock expression
 *
 *  {{{
 *  lock <lock> in
 *     <expression>
 *  end
 *  }}}
 */
case class LockExpression(lock: Expression,
    expression: Expression) extends Expression with LockCommon {
  protected val body = expression
}

/** Lock object expression
 *
 *  {{{
 *  lock
 *     <expression>
 *  end
 *  }}}
 */
case class LockObjectExpression(
    expression: Expression) extends Expression with LockObjectCommon {
  protected val body = expression
}

/** Try-catch expression
 *
 *  {{{
 *  try
 *     <body>
 *  catch <exceptionVar> then
 *     <catchBody>
 *  end
 *  }}}
 */
case class TryExpression(body: Expression, exceptionVar: VariableOrRaw,
    catchBody: Expression) extends Expression with TryCommon {
}

/** Try-finally expression
 *
 *  {{{
 *  try
 *     <body>
 *  finally
 *     <finallyBody>
 *  end
 *  }}}
 */
case class TryFinallyExpression(body: Expression,
    finallyBody: Statement) extends Expression with TryFinallyCommon {
}

/** Raise expression
 *
 *  {{{
 *  raise <exception> end
 *  }}}
 */
case class RaiseExpression(
    exception: Expression) extends Expression with RaiseCommon {
}

/** Bind expression
 *
 *  {{{
 *  <left> = <right>
 *  }}}
 */
case class BindExpression(left: Expression,
    right: Expression) extends Expression with InfixSyntax {
  protected val opSyntax = " = "
}

/** Dot-assign expression
 *
 *  {{{
 *  <left> . <center> := <right>
 *  }}}
 */
case class DotAssignExpression(left: Expression, center: Expression,
    right: Expression) extends Expression with MultiInfixSyntax {
  protected val operands = Seq(left, center, right)
  protected val operators = Seq(".", " := ")
}

// Functors

/** Feature of an imported functor, with an optional import alias */
case class AliasedFeature(feature: Constant,
    alias: Option[VariableOrRaw]) extends Node {
  def syntax(indent: String) = {
    feature.syntax() + (alias map (":" + _.syntax()) getOrElse (""))
  }
}

/** Import item of a functor (require or import)
 *
 *  {{{
 *  [import]
 *     <module>(<aliases>...) at <location>
 *  }}}
 */
case class FunctorImport(module: VariableOrRaw, aliases: List[AliasedFeature],
    location: Option[String]) extends Node {
  def syntax(indent: String) = {
    val aliasesSyntax = aliases map (_.syntax(indent)) mkString " "
    val locationSyntax = location map (" at '"+_+"'") getOrElse ("")
    module.syntax(indent) + "(" + aliasesSyntax + ")" + locationSyntax
  }
}

/** Export item of a functor (export)
 *
 *  {{{
 *  [export]
 *     <feature>:<value>
 *  }}}
 */
case class FunctorExport(feature: Expression,
    value: Expression) extends Node {
  def syntax(indent: String) = {
    feature.syntax(indent) + ":" + value.syntax(indent)
  }
}

/** Expression that creates a functor
 *
 *  {{{
 *  functor
 *  require
 *     <require>...
 *  prepare
 *     <prepare>
 *  import
 *     <imports>...
 *  export
 *     <exports>...
 *  define
 *     <define>
 *  end
 *  }}}
 */
case class FunctorExpression(name: String,
    require: List[FunctorImport], prepare: Option[LocalStatementOrRaw],
    imports: List[FunctorImport], define: Option[LocalStatementOrRaw],
    exports: List[FunctorExport]) extends Expression {

  def syntax(indent: String) = {
    val subIndent = indent + "   "

    def sectionSyntax(sectionKw: String, elems: Traversable[Node]) = {
      if (elems.isEmpty) ""
      else {
        (("\n\n" + indent + sectionKw) /: elems) {
          (prev, elem) => prev + "\n" + subIndent + elem.syntax(subIndent)
        }
      }
    }

    val firstLine = "functor % " + name
    val untilRequire = firstLine + sectionSyntax("require", require)
    val untilPrepare = untilRequire + sectionSyntax("prepare", prepare)
    val untilImports = untilPrepare + sectionSyntax("import", imports)
    val untilExports = untilImports + sectionSyntax("export", exports)
    val untilDefine = untilExports + sectionSyntax("define", define)

    untilDefine + "\n\n" + indent + "end"
  }
}

// Operations

/** Unary operation */
case class UnaryOp(operator: String, operand: Expression) extends Expression {
  def syntax(indent: String) =
    operator + operand.syntax(indent + " "*operator.length)
}

/** Binary operation */
case class BinaryOp(left: Expression, operator: String,
    right: Expression) extends Expression with InfixSyntax {
  protected val opSyntax = " " + operator + " "
}

/** Boolean binary operation with short-circuit semantics */
case class ShortCircuitBinaryOp(left: Expression, operator: String,
    right: Expression) extends Expression with InfixSyntax {
  protected val opSyntax = operator
}

// Trivial expressions

/** Variable or constant (elementary things that can reach the codegen) */
trait VarOrConst extends Expression

/** Variable or raw variable */
trait VariableOrRaw extends Expression

/** Raw variable (unnamed) */
case class RawVariable(name: String) extends VariableOrRaw with RawDeclaration {
  def syntax(indent: String) =
    name
}

/** Variable */
case class Variable(symbol: Symbol) extends VarOrConst with VariableOrRaw
    with RawDeclarationOrVar {
  def syntax(indent: String) =
    symbol.fullName
}

/** Factory for Variable */
object Variable extends (Symbol => Variable) {
  /** Returns a Variable for a new synthetic Symbol */
  def newSynthetic(name: String = "", formal: Boolean = false,
      capture: Boolean = false) = {
    Variable(new Symbol(name,
        formal = formal, capture = capture, synthetic = true))
  }
}

/** Escaped variable (that is not declared when in an lhs) */
case class EscapedVariable(variable: RawVariable) extends Expression {
  def syntax(indent: String) = "!" + variable.syntax(indent+"  ")
}

/** Wildcard `_` */
case class UnboundExpression() extends Expression {
  def syntax(indent: String) = "_"
}

/** Constant value */
case class Constant(value: OzValue) extends VarOrConst {
  def syntax(indent: String) = value.syntax()
}

/** Dummy placeholder for an implicit feature of a record field */
case class AutoFeature() extends Expression {
  def syntax(indent: String) = ""
}

/** Nexting marker $ */
case class NestingMarker() extends Expression {
  def syntax(indent: String) = "$"
}

/** self */
case class Self() extends Expression {
  def syntax(indent: String) = "self"
}

// Records

/** Record field
 *
 *  {{{
 *  <feature>:<value>
 *  }}}
 *
 *  `feature` can be an [[org.mozartoz.bootcompiler.ast.AutoFeature]], in which
 *  case it is implicit.
 */
case class RecordField(feature: Expression, value: Expression) extends Node {
  def syntax(indent: String) = {
    val featSyntax = feature.syntax(indent)
    featSyntax + ":" + value.syntax(indent + " " + " "*featSyntax.length())
  }

  /** Returns true if the feature is an auto feature */
  def hasAutoFeature =
    feature.isInstanceOf[AutoFeature]

  /** Returns true if the feature is constant
   *
   *  Note that auto features are constant, since they are desugared into
   *  constant integers during `Desugar`.
   */
  def hasConstantFeature =
    feature.isInstanceOf[Constant] || hasAutoFeature

  /** Returns true if the feature and value are both constant */
  def isConstant =
    feature.isInstanceOf[Constant] && value.isInstanceOf[Constant]

  /** Returns this record field as a constant
   *
   *  @require `this.isConstant`
   */
  def getAsConstant = {
    require(isConstant)
    val RecordField(Constant(feature:OzFeature), Constant(value)) = this
    OzRecordField(feature, value)
  }
}

/** Abstract base class for Record and OpenRecord */
abstract sealed class BaseRecord extends Expression {
  val label: Expression
  val fields: List[RecordField]
  val isOpen: Boolean

  def syntax(indent: String) = fields.toList match {
    case Nil => label.syntax() + (if (isOpen) "(...)" else "()")

    case firstField :: otherFields => {
      val prefix = label.syntax() + "("
      val subIndent = indent + " " * prefix.length

      val firstLine = prefix + firstField.syntax(subIndent)

      otherFields.foldLeft(firstLine) {
        _ + "\n" + subIndent + _.syntax(subIndent)
      } + (if (isOpen) " ...)" else ")")
    }
  }

  /** Returns true if the arity of the record is a compile-time constant */
  lazy val hasConstantArity =
    label.isInstanceOf[Constant] && (fields forall (_.hasConstantFeature))

  /** Returns the arity of this record as a compile-time constant
   *
   *  @require `this.hasConstantArity`
   */
  lazy val getConstantArity: OzArity = {
    require(hasConstantArity)

    val Constant(ozLabel:OzLiteral) = label
    val ozFeatures =
      for (RecordField(Constant(feature:OzFeature), _) <- fields)
        yield feature

    OzArity(ozLabel, ozFeatures)
  }
}

/** Record builder
 *
 *  {{{
 *  <label>(<fields>...)
 *  }}}
 */
case class Record(label: Expression,
    fields: List[RecordField]) extends BaseRecord {
  val isOpen = false

  /** Returns true if this record should be optimized as a tuple */
  def isTuple = hasConstantArity && getConstantArity.isTupleArity

  /** Returns true if this record should be optimized as a cons */
  def isCons = hasConstantArity && getConstantArity.isConsArity

  /** Returns true if this record is a compile-time constant */
  def isConstant =
    label.isInstanceOf[Constant] && (fields forall (_.isConstant))

  /** Returns this record as a compile-time constant
   *
   *  @require `this.isConstant`
   */
  def getAsConstant: OzValue = {
    require(isConstant)

    val Constant(ozLabel:OzLiteral) = label
    val ozFields = fields map (_.getAsConstant)

    OzRecord(ozLabel, ozFields)
  }
}

/** Open record pattern
 *
 *  {{{
 *  <label>(<fields>... ...)
 *  }}}
 */
case class OpenRecordPattern(label: Expression,
    fields: List[RecordField]) extends BaseRecord {
  val isOpen = true

  /** Returns true if this pattern is a compile-time constant */
  def isConstant =
    label.isInstanceOf[Constant] && (fields forall (_.isConstant))

  /** Returns this pattern as a compile-time constant
   *
   *  @require `this.isConstant`
   */
  def getAsConstant: OzValue = {
    require(isConstant)

    val Constant(ozLabel:OzLiteral) = label
    val ozFields = fields map (_.getAsConstant)

    OzPatMatOpenRecord(ozLabel, ozFields)
  }
}

/** Factory and pattern-matching against Tuple-like records */
object Tuple extends ((Expression, List[Expression]) => Record) {
  def apply(label: Expression, fields: List[Expression]) = {
    val recordFields =
      for ((value, index) <- fields.zipWithIndex)
        yield RecordField(Constant(OzInt(index+1)), value)
    Record(label, recordFields)
  }

  def unapply(record: Record) = {
    if (record.isTuple) Some((record.label, record.fields map (_.value)))
    else None
  }
}

/** Factory and pattern-matching against Cons-like records */
object Cons extends ((Expression, Expression) => Record) {
  def apply(head: Expression, tail: Expression) =
    Tuple(Constant(OzAtom("|")), List(head, tail))

  def unapply(record: Record) = {
    if (record.isCons) Some((record.fields(0).value, record.fields(1).value))
    else None
  }
}

/** Pattern conjunction
 *
 *  {{{
 *  <left> = <right>
 *  }}}
 */
case class PatternConjunction(parts: List[Expression]) extends Expression {
  def syntax(indent: String) = {
    parts.tail.foldLeft(parts.head.syntax(indent)) {
      (prev, part) => prev + " = " + part.syntax(indent)
    }
  }
}

// Classes

case class FeatOrAttr(name: Expression,
    value: Option[Expression]) extends Node with InfixSyntax {
  protected val left = name
  protected val right = value getOrElse AutoFeature()
  protected val opSyntax = ":"

  override def syntax(indent: String) = {
    if (value.isEmpty) name.syntax(indent)
    else super.syntax(indent)
  }
}

case class MethodParam(feature: Expression, name: Expression,
    default: Option[Expression]) extends Node {
  def syntax(indent: String) = {
    feature.syntax(indent) + ":" + name.syntax(indent) + (
        if (default.isEmpty) ""
        else " <= " + default.get.syntax(indent)
    )
  }
}

case class MethodHeader(name: Expression, params: List[MethodParam],
    open: Boolean) extends Node {
  def syntax(indent: String) = {
    name.syntax(indent) + "(" + (
        params map (_.syntax(indent)) mkString " "
    ) + (if (open) " ...)" else ")")
  }
}

case class MethodDef(header: MethodHeader, messageVar: Option[VariableOrRaw],
    body: StatOrExpr) extends Node {
  def syntax(indent: String) = {
    val untilHeader = "meth " + header.syntax(indent+"     ")
    val firstLine =
      if (messageVar.isEmpty) untilHeader
      else untilHeader + " = " + messageVar.get.syntax(indent)
    val untilBody = firstLine + "\n   " + indent + body.syntax(indent+"   ")
    untilBody + "\n" + indent + "end"
  }
}

case class ClassExpression(name: String, parents: List[Expression],
    features: List[FeatOrAttr], attributes: List[FeatOrAttr],
    properties: List[Expression],
    methods: List[MethodDef]) extends Expression {

  def syntax(indent: String) = {
    val subIndent = indent + "   "
    val subsubIndent = subIndent + "   "

    def sectionSyntax(sectionKw: String, elems: Traversable[Node]) = {
      if (elems.isEmpty) ""
      else {
        (("\n\n" + subIndent + sectionKw) /: elems) {
          (prev, elem) => prev + "\n" + subsubIndent + elem.syntax(subsubIndent)
        }
      }
    }

    val firstLine = "class % " + name
    val untilParents = firstLine + sectionSyntax("from", parents)
    val untilFeatures = untilParents + sectionSyntax("feat", features)
    val untilAttributes = untilFeatures + sectionSyntax("attr", attributes)

    val untilMethods = (untilAttributes /: methods) {
      (prev, method) => prev + "\n\n" + subIndent + method.syntax(subIndent)
    }

    untilMethods + "\n\n" + indent + "end"
  }
}

// Synthetic-only expressions

/** Expressions that creates an abstraction from a code area and globals
 *
 *  This class has no correspondence in actual Oz code. It is internal only.
 */
case class CreateAbstraction(body: Expression,
    globals: List[Expression]) extends Expression {
  def syntax(indent: String) = {
    "{CreateAbstraction %s [%s]}" format (
        body.syntax(indent), globals mkString " ")
  }
}
