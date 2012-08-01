package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.{ ListBuffer, ArrayBuffer, HashMap }
import scala.util.parsing.input.{ Position, NoPosition, Positional }

import ast._
import util._

/** Program to be compiled */
class Program(val isBaseEnvironment: Boolean = false) {
  /** Before flattening, abstract syntax tree of the whole program */
  var rawCode: Statement = SkipStatement()

  /** Returns `true` if the program is currently represented as a full AST */
  def isRawCode = rawCode ne null

  /** Builtin manager */
  val builtins = new Builtins

  /** Variables declared by the base environment */
  val baseDeclarations = new ArrayBuffer[String]

  /** Outer-global Base environment variable */
  val baseEnvSymbol = new Symbol("<Base>", synthetic = true, global = true)

  /** Outer-global BootMM variable */
  val bootMMSymbol = new Symbol("<BootMM>", synthetic = true, global = true)

  /** All the outer-global variables */
  val outerGlobalSymbols = Seq(baseEnvSymbol, bootMMSymbol)

  /** Map of base symbols (only in base environment mode) */
  val baseSymbols = new HashMap[String, Symbol]

  /** Implicit top-level abstraction */
  val topLevelAbstraction =
    new Abstraction(NoAbstraction, "<TopLevel>", NoPosition)

  {
    // Impose the globals of the top-level abstraction to be the outer-globals
    for (sym <- outerGlobalSymbols)
      topLevelAbstraction.acquire(sym)
  }

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
  def produceCC(out: Output, mainProcName: String,
      headers: TraversableOnce[String] = List("mozart.hh")) {
    import Output._

    val codeAreas = abstractions map (_.codeArea)

    for (header <- headers)
      out << "#include <%s>\n" % header

    out << """
       |using namespace mozart;
       |
       |namespace {
       |
       |class Program {
       |public:
       |  Program(VM vm);
       |
       |  void createRunThread(RichNode baseEnv, RichNode bootMM);
       |private:
       |  VM vm;
       |""".stripMargin

    for (codeArea <- codeAreas) {
      out << """
         |  UnstableNode %s;
         |  void %s();
         |""".stripMargin % (codeArea.ccCodeArea, codeArea.ccCreateMethodName)
    }

    out << """
       |};
       |
       |Program::Program(VM vm): vm(vm) {
       |
       |""".stripMargin

    for (codeArea <- codeAreas.reverse)
      out << "  %s();\n" % codeArea.ccCreateMethodName

    out << """
       |}
       |
       |void Program::createRunThread(RichNode baseEnv, RichNode bootMM) {
       |  UnstableNode topLevelAbstraction = Abstraction::build(vm, 2, %s);
       |  auto globalsArray =
       |    RichNode(topLevelAbstraction).as<Abstraction>().getElementsArray();
       |
       |  globalsArray[0].init(vm, baseEnv);
       |  globalsArray[1].init(vm, bootMM);
       |
       |  auto thread = new (vm) Thread(vm, vm->getTopLevelSpace(),
       |                                topLevelAbstraction);
       |  thread->setRaiseOnBlock(%s);
       |}
       |""".stripMargin % (
           topLevelAbstraction.codeArea.ccCodeArea,
           if (isBaseEnvironment) "true" else "false")

    for (codeArea <- codeAreas)
      codeArea.produceCC(out)

    out << """
       |} // namespace
       |
       |void %s(VM vm, RichNode baseEnv, RichNode bootMM) {
       |  Program program(vm);
       |  program.createRunThread(baseEnv, bootMM);
       |}
       |""".stripMargin % mainProcName
  }
}
