package org.mozartoz.bootcompiler
package ast

trait StatOrExpr extends Node

trait LocalCommon extends StatOrExpr {
  protected val declarations: List[Declaration]
  protected val body: StatOrExpr

  def syntax(indent: String) = {
    val subIndent = indent + "   "

    val head :: tail = declarations.toList
    val declsSyntax = tail.foldLeft(head.syntax(subIndent)) {
      _ + "\n" + subIndent + _.syntax(subIndent)
    }

    val bodySyntax = "in\n" + subIndent + body.syntax(subIndent)

    ("local\n" + subIndent + declsSyntax + "\n" + indent +
        bodySyntax + "\n" + indent + "end")
  }
}

trait ProcFunExpression extends StatOrExpr {
  protected val keyword: String

  protected val args: List[FormalArg]
  protected val body: StatOrExpr
  protected val flags: List[String]

  def syntax(indent: String) = {
    val flagsSyntax = flags.foldLeft("") { _ + " " + _ }
    val argsSyntax = args.foldLeft("") { _ + " " + _.syntax(indent) }

    val header0 = keyword + flagsSyntax + " {$"
    val header = header0 + argsSyntax + "}"

    val bodyIndent = indent + "   "
    val bodySyntax = bodyIndent + body.syntax(bodyIndent)

    header + "\n" + bodySyntax + "\n" + indent + "end"
  }
}

trait CallCommon extends StatOrExpr {
  protected val callable: Expression
  protected val args: List[Expression]

  def syntax(indent: String) = args match {
    case Nil => "{" + callable.syntax() + "}"

    case firstArg :: otherArgs => {
      val prefix = "{" + callable.syntax() + " "
      val subIndent = indent + " " * prefix.length

      val firstLine = prefix + firstArg.syntax(subIndent)

      otherArgs.foldLeft(firstLine) {
        _ + "\n" + subIndent + _.syntax(subIndent)
      } + "}"
    }
  }
}

trait IfCommon extends StatOrExpr {
  protected val condition: Expression
  protected val truePart: StatOrExpr
  protected val falsePart: StatOrExpr

  def syntax(indent: String) = {
    val subIndent = indent + "   "

    val condSyntax = "if " + condition.syntax(subIndent) + " then"
    val thenSyntax = "\n" + subIndent + truePart.syntax(subIndent)
    val elseSyntax = ("\n" + indent + "else\n" + subIndent +
        falsePart.syntax(subIndent))

    condSyntax + thenSyntax + elseSyntax + "\n" + indent + "end"
  }
}

trait MatchCommon extends StatOrExpr {
  protected val value: Expression
  protected val clauses: List[MatchClauseCommon]
  protected val elsePart: StatOrExpr

  def syntax(indent: String) = {
    val header = "case " + value.syntax(indent + "     ")

    val untilClauses = clauses.foldLeft(header) { (prev, clause) =>
      prev + "\n" + indent + clause.syntax(indent)
    }

    val untilElse = untilClauses + "\n" + indent + "else"
    val untilElseBody =
      untilElse + "\n" + indent + "   " + elsePart.syntax(indent + "   ")

    untilElseBody + "\n" + indent + "end"
  }
}

trait MatchClauseCommon extends Node {
  val pattern: Expression
  protected val guard: Option[Expression]
  protected val body: StatOrExpr

  def syntax(indent: String) = {
    val subIndent = indent + "   "

    val untilPattern = "[] " + pattern.syntax(subIndent)
    val untilGuard =
      if (guard.isDefined) untilPattern + " if " + guard.get.syntax(subIndent)
      else untilPattern
    val allButBody = untilGuard + " then\n" + subIndent

    allButBody + body.syntax(subIndent)
  }
}

trait ThreadCommon extends StatOrExpr {
  protected val body: StatOrExpr

  def syntax(indent: String) = {
    val subIndent = indent + "   "

    "thread\n" + subIndent + body.syntax(subIndent) + "\n" + indent + "end"
  }
}
