package org.mozartoz.bootcompiler
package ast

/** Base class for ASTs that represent statements */
sealed abstract class Statement extends StatOrExpr with RawDeclaration

/** Sequential composition of several statements */
case class CompoundStatement(statements: List[Statement]) extends Statement {
  def syntax(indent: String) = {
    if (statements.isEmpty) "skip"
    else {
      statements.tail.foldLeft(statements.head.syntax(indent)) {
        _ + "\n" + indent + _.syntax(indent)
      }
    }
  }
}

trait LocalStatementOrRaw extends Statement

/** Raw local declaration statement (before naming)
 *
 *  {{{
 *  local
 *     <declarations>
 *  in
 *     <statement>
 *  end
 *  }}}
 */
case class RawLocalStatement(declarations: List[RawDeclaration],
    statement: Statement) extends LocalStatementOrRaw with LocalCommon {
  protected val body = statement
}

/** Local declaration statement
 *
 *  {{{
 *  local
 *     <declarations>
 *  in
 *     <statement>
 *  end
 *  }}}
 */
case class LocalStatement(declarations: List[Variable],
    statement: Statement) extends LocalStatementOrRaw with LocalCommon {
  protected val body = statement
}

/** Call statement
 *
 *  {{{
 *  {<callable> <args>...}
 *  }}}
 */
case class CallStatement(callable: Expression,
    args: List[Expression]) extends Statement with CallCommon

/** If statement
 *
 *  {{{
 *  if <condition> then
 *     <trueStatement>
 *  else
 *     <falseStatement>
 *  end
 *  }}}
 */
case class IfStatement(condition: Expression,
    trueStatement: Statement,
    falseStatement: Statement) extends Statement with IfCommon {
  protected val truePart = trueStatement
  protected val falsePart = falseStatement
}

/** Pattern matching statement
 *
 *  {{{
 *  case <value>
 *  of <clauses>...
 *  else
 *     <elseStatement>
 *  end
 *  }}}
 */
case class MatchStatement(value: Expression,
    clauses: List[MatchStatementClause],
    elseStatement: Statement) extends Statement with MatchCommon {
  protected val elsePart = elseStatement
}

/** Clause of a pattern matching statement
 *
 *  {{{
 *  [] <pattern> andthen <guard> then
 *     <body>
 *  }}}
 */
case class MatchStatementClause(pattern: Expression, guard: Option[Expression],
    body: Statement) extends MatchClauseCommon {
  def hasGuard = guard.isDefined
}

/** Special node to mark that there is no else statement */
case class NoElseStatement() extends Statement {
  def syntax(indent: String) = "<noelse>"
}

/** Thread statement
 *
 *  {{{
 *  thread
 *     <statement>
 *  end
 *  }}}
 */
case class ThreadStatement(
    statement: Statement) extends Statement with ThreadCommon {
  protected val body = statement
}

/** Fail statement
 *
 *  {{{
 *  fail
 *  }}}
 */
case class FailStatement() extends Statement {
  def syntax(indent: String) = "fail"
}

/** Lock statement
 *
 *  {{{
 *  lock <lock> in
 *     <statement>
 *  end
 *  }}}
 */
case class LockStatement(lock: Expression,
    statement: Statement) extends Statement with LockCommon {
  protected val body = statement
}

/** Lock object statement
 *
 *  {{{
 *  lock
 *     <statement>
 *  end
 *  }}}
 */
case class LockObjectStatement(
    statement: Statement) extends Statement with LockObjectCommon {
  protected val body = statement
}

/** Try-catch statement
 *
 *  {{{
 *  try
 *     <body>
 *  catch <exceptionVar> then
 *     <catchBody>
 *  end
 *  }}}
 */
case class TryStatement(body: Statement, exceptionVar: VariableOrRaw,
    catchBody: Statement) extends Statement with TryCommon {
}

/** Try-finally statement
 *
 *  {{{
 *  try
 *     <body>
 *  finally
 *     <finallyBody>
 *  end
 *  }}}
 */
case class TryFinallyStatement(body: Statement,
    finallyBody: Statement) extends Statement with TryFinallyCommon {
}

/** Raise statement
 *
 *  {{{
 *  raise <exception> end
 *  }}}
 */
case class RaiseStatement(
    exception: Expression) extends Statement with RaiseCommon {
}

/** Bind statement
 *
 *  {{{
 *  <left> = <right>
 *  }}}
 */
case class BindStatement(left: Expression,
    right: Expression) extends Statement with InfixSyntax {
  protected val opSyntax = " = "
}

/** Binary operator statement
 *
 *  {{{
 *  <left> <operator> <right>
 *  }}}
 */
case class BinaryOpStatement(left: Expression, operator: String,
    right: Expression) extends Statement with InfixSyntax {
  protected val opSyntax = " " + operator + " "
}

/** Dot-assign statement
 *
 *  {{{
 *  <left> . <center> := <right>
 *  }}}
 */
case class DotAssignStatement(left: Expression, center: Expression,
    right: Expression) extends Statement with MultiInfixSyntax {
  protected val operands = Seq(left, center, right)
  protected val operators = Seq(".", " := ")
}

/** Skip statement
 *
 *  {{{
 *  skip
 *  }}}
 */
case class SkipStatement() extends Statement {
  def syntax(indent: String) = "skip"
}
