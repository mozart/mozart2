package org.mozartoz.bootcompiler
package ast

/** Base class for ASTs that represent statements */
sealed abstract class Statement extends StatOrExpr with RawDeclaration

/** Sequential composition of several statements */
case class CompoundStatement(statements: List[Statement]) extends Statement {
  def syntax(indent: String) = {
    val head :: tail = statements.toList
    tail.foldLeft(head.syntax(indent)) {
      _ + "\n" + indent + _.syntax(indent)
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

/** Assign statement
 *
 *  {{{
 *  <left> := <right>
 *  }}}
 */
case class AssignStatement(left: Expression,
    right: Expression) extends Statement with InfixSyntax {
  protected val opSyntax = " := "
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
