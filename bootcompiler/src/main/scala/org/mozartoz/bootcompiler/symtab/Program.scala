package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.{ ListBuffer, ArrayBuffer, HashMap }
import scala.util.parsing.input.{ Position, NoPosition, Positional }

import ast._
import util._

/** Program to be compiled */
class Program {
  /** Before flattening, abstract syntax tree of the whole program */
  var rawCode: Statement = SkipStatement()

  /** Returns `true` if the program is currently represented as a full AST */
  def isRawCode = rawCode ne null

  /** Builtin manager */
  val builtins = new Builtins

  /** Base environment */
  val baseEnvironment = new HashMap[String, Symbol]

  /** Implicit top-level abstraction */
  val topLevelAbstraction = new Abstraction(NoAbstraction, "<TopLevel>")

  /** After flattening, list of the abstractions */
  val abstractions = new ListBuffer[Abstraction]
  abstractions += topLevelAbstraction

  /** Compile errors */
  val errors = new ArrayBuffer[(String, Position)]

  /** Returns `true` if at least one compile error was reported */
  def hasErrors = !errors.isEmpty

  /** Reports a compile error
   *  @param message error message
   *  @param pos position of the error
   */
  def reportError(message: String, pos: Position = NoPosition) {
    errors += ((message, pos))
  }

  /** Reports a compile error
   *  @param message error message
   *  @param positional positional that holds the position of the error
   */
  def reportError(message: String, positional: Positional) {
    reportError(message, positional.pos)
  }

  /** Dumps the program on standard error */
  def dump() {
    if (isRawCode)
      println(rawCode)
    else {
      for (abstraction <- abstractions) {
        abstraction.dump()
        println()
      }
    }
  }

  /** Produces the C++ code that will execute the program */
  def produceCC(out: Output) {
    import Output._

    val codeAreas = abstractions map (_.codeArea)

    out << """
       |#include <mozart.hh>
       |#include <boostenv.hh>
       |
       |using namespace mozart;
       |""".stripMargin

    out << """
       |class Program {
       |public:
       |  Program();
       |
       |  void run();
       |private:
       |  boostenv::BoostBasedVM boostBasedVM;
       |  VM vm;
       |""".stripMargin

    for (codeArea <- codeAreas) {
      out << """
         |  UnstableNode* %s;
         |  void %s();
         |""".stripMargin % (codeArea.ccCodeArea, codeArea.ccCreateMethodName)
    }

    out << """
       |};
       |
       |int main(int argc, char** argv) {
       |  Program program;
       |  program.run();
       |}
       |
       |Program::Program(): vm(boostBasedVM.vm) {
       |
       |""".stripMargin

    for (codeArea <- codeAreas.reverse)
      out << "  %s();\n" % codeArea.ccCreateMethodName

    out << """
       |}
       |
       |void Program::run() {
       |  UnstableNode topLevelAbstraction;
       |  topLevelAbstraction.make<Abstraction>(vm, 0, 0, *%s);
       |
       |  UnstableNode* initialThreadParams[] = { &topLevelAbstraction };
       |  builtins::ModThread::Create::builtin().call(vm, initialThreadParams);
       |
       |  boostBasedVM.run();
       |}
       |""".stripMargin % topLevelAbstraction.codeArea.ccCodeArea

    for (codeArea <- codeAreas)
      codeArea.produceCC(out)
  }
}
