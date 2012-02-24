package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.ListBuffer

import ast._
import util._

class Program(var rawCode: Statement) {
  def isRawCode = rawCode ne null

  val builtins = new Builtins

  val topLevelAbstraction = new Abstraction(NoAbstraction, "<TopLevel>")

  val abstractions = new ListBuffer[Abstraction]
  abstractions += topLevelAbstraction

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
       |#include <iostream>
       |
       |#include "emulate.hh"
       |#include "vm.hh"
       |#include "smallint.hh"
       |#include "callables.hh"
       |#include "variables.hh"
       |#include "corebuiltins.hh"
       |#include "stdint.h"
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
       |  topLevelAbstraction.make<Abstraction>(vm, 0, 0, %s);
       |
       |  UnstableNode* initialThreadParams[] = { &topLevelAbstraction };
       |  builtins::createThread(vm, initialThreadParams);
       |
       |  vm->run();
       |}
       |""".stripMargin % topLevelAbstraction.codeArea.ccCodeArea

    for (codeArea <- codeAreas)
      codeArea.produceCC(out)
  }
}
