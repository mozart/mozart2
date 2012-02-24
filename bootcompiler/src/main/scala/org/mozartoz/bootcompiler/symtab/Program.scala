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

  def produceCC(implicit out: Output) {
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
       |""".stripMargin \\
  }
}
