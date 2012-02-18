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

  protected val args: FormalArgs
  protected val body: StatOrExpr
  protected val flags: List[Atom]

  def syntax(indent: String) = {
    val flagsSyntax = flags.foldLeft("") { _ + " " + _.syntax(indent) }
    val argsSyntax = args.args.foldLeft("") { _ + " " + _.syntax(indent) }

    val header0 = keyword + flagsSyntax + " {$"
    val header = header0 + argsSyntax + "}"

    val bodyIndent = indent + "   "
    val bodySyntax = bodyIndent + body.syntax(bodyIndent)

    header + "\n" + bodySyntax + "\n" + indent + "end"
  }
}

trait CallCommon extends StatOrExpr {
  protected val callable: Expression
  protected val args: ActualArgs

  def syntax(indent: String) = args.args match {
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

trait ThreadCommon extends StatOrExpr {
  protected val body: StatOrExpr

  def syntax(indent: String) = {
    val subIndent = indent + "   "

    "thread\n" + subIndent + body.syntax(subIndent) + "\n" + indent + "end"
  }
}
