package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.{ ListBuffer, ArrayBuffer }
import scala.util.parsing.input.{ Position, NoPosition, Positional }

import ast._
import util._

class Program(var rawCode: Statement) {
  def isRawCode = rawCode ne null

  val builtins = new Builtins

  val topLevelAbstraction = new Abstraction(NoAbstraction, "<TopLevel>")

  val abstractions = new ListBuffer[Abstraction]
  abstractions += topLevelAbstraction

  val errors = new ArrayBuffer[(String, Position)]

  def hasErrors = !errors.isEmpty

  def reportError(message: String, pos: Position = NoPosition) {
    errors += ((message, pos))
  }

  def reportError(message: String, positional: Positional) {
    reportError(message, positional.pos)
  }

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

  def produceCC(out: Output) {
    import Output._

    val codeAreas = abstractions map (_.codeArea)

    out << """
       |#include "mozart.hh"
       |
       |#include <iostream>
       |
       |using namespace mozart;
       |
       |bool simplePreemption(void* data) {
       |  static int count = 3;
       |
       |  if (--count == 0) {
       |    count = 3;
       |    return true;
       |  } else {
       |    return false;
       |  }
       |}
       |""".stripMargin

    out << """
       |class Program {
       |public:
       |  Program();
       |
       |  void run();
       |private:
       |  VirtualMachine virtualMachine;
       |  VM vm;
       |  UnstableNode* topLevelAbstraction;
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
       |Program::Program() : virtualMachine(simplePreemption),
       |  vm(&virtualMachine) {
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
       |  vm->run();
       |}
       |""".stripMargin % topLevelAbstraction.codeArea.ccCodeArea

    for (codeArea <- codeAreas)
      codeArea.produceCC(out)
  }
}
