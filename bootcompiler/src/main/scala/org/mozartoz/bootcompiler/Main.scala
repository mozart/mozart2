package org.mozartoz.bootcompiler

import java.io.{ Console => _, _ }

import scala.collection.mutable.ListBuffer
import scala.util.parsing.input.PagedSeqReader
import scala.util.parsing.combinator._
import scala.util.parsing.input._

import scopt.{ OParser, OParserSetup, DefaultOParserSetup }
import spray.json._

import oz._
import parser._
import ast._
import transform._
import symtab._
import util._

/** Companion object for Config */
object Config {
  /** Mode */
  object Mode extends Enumeration {
    val Module, BaseEnv = Value
  }

  /** Mode */
  type Mode = Mode.Value
}

case class Config(
    mode: Config.Mode = Config.Mode.Module,
    outputStream: () => BufferedOutputStream = null,
    moduleDefs: List[String] = Nil,
    baseDeclsFileName: String = "",
    defines: Set[String] = Set.empty,
    fileName: String = ""
)

/** Entry point for the Mozart2 bootstrap compiler */
object Main {
  /** Executes the Mozart2 bootstrap compiler */
  def main(args: Array[String]): Unit = {
    // Define command-line options
    val optParser = new scopt.OptionParser[Config]("bootcompiler") {
      head("bootcompiler", "2.0.x")

      opt[Unit]("baseenv")
        .action((_, c) => c.copy(mode = Config.Mode.BaseEnv))
        .text("switch to base environment mode")

      opt[String]('o', "output")
        .action((v, c) =>
          c.copy(outputStream = () => new BufferedOutputStream(new FileOutputStream(v))))
        .text("output file")

      opt[String]('m', "module")
        .action((v, c) => c.copy(moduleDefs = v :: c.moduleDefs))
        .text("module definition file or directory")

      opt[String]('b', "base")
        .action((v, c) => c.copy(baseDeclsFileName = v))
        .text("path to the base declarations file")

      opt[String]('D', "define")
        .action((v, c) => c.copy(defines = c.defines + v))
        .text("add a symbol to the conditional defines")

      arg[String]("<file>")
        .action((v, c) => c.copy(fileName = v))
        .text("input file")
    }

    // Parse the options
    optParser.parse(args, Config()).foreach({ config =>
      try {
        config.mode match {
          case Config.Mode.Module =>
            mainModule(config)
          case Config.Mode.BaseEnv =>
            mainBaseEnv(config)
        }
      } catch {
        case th: Throwable =>
          Console.err.println(
              "Fatal error when called with:\n  %s" format args.mkString(" "))
          th.printStackTrace()
          sys.exit(2)
      }
    })
  }

  /** Performs the Module mode */
  private def mainModule(config: Config): Unit = {
    import config._

    val (program, _) = createProgram(moduleDefs, Some(baseDeclsFileName))

    val functor = parseExpression(readerForFile(fileName), new File(fileName),
        defines)

    ProgramBuilder.buildModuleProgram(program, functor)
    compile(program, fileName)

    Serializer.serialize(program, outputStream())
  }

  /** Performs the BaseEnv mode */
  private def mainBaseEnv(config: Config): Unit = {
    import config._

    val (program, bootModules) = createProgram(moduleDefs, None, true)

    val functor = parseExpression(readerForFile(fileName), new File(fileName),
        defines)

    ProgramBuilder.buildBaseEnvProgram(program, bootModules, functor)
    compile(program, "the base environment")

    Serializer.serialize(program, outputStream())

    writeFileLines(new File(baseDeclsFileName), program.baseDeclarations)
  }

  /** Creates a new Program */
  private def createProgram(
    moduleDefs: List[String],
    baseDeclsFileName: Option[String],
    isBaseEnvironment: Boolean = false): (Program, Map[String, Expression]) = {
    val program = new Program(isBaseEnvironment)
    val bootModules = loadModuleDefs(program, moduleDefs)

    baseDeclsFileName foreach { fileName =>
      program.baseDeclarations ++= readFileLines(new File(fileName))
    }

    (program, bootModules)
  }

  /** Parses an Oz statement from a reader
   *
   *  Upon lexical or syntactical error, displays a user-friendly error
   *  message on stderr and halts the program.
   *
   *  @param reader input reader
   *  @return The statement AST
   */
  private def parseStatement(
    reader: PagedSeqReader,
    file: File,
    defines: Set[String]): Statement =
    new ParserWrapper().parseStatement(reader, file, defines)

  /** Parses an Oz expression from a reader
   *
   *  Upon lexical or syntactical error, displays a user-friendly error
   *  message on stderr and halts the program.
   *
   *  @param reader input reader
   *  @return The expression AST
   */
  private def parseExpression(reader: PagedSeqReader, file: File,
      defines: Set[String]): Expression =
    new ParserWrapper().parseExpression(reader, file, defines)

  /** Utility wrapper for an [[org.mozartoz.bootcompiler.parser.OzParser]]
   *
   *  This wrapper provides user-directed error messages.
   */
  private class ParserWrapper {
    /** Underlying parser */
    private val parser = new OzParser()

    def parseStatement(reader: PagedSeqReader, file: File,
        defines: Set[String]): Statement =
      processResult(parser.parseStatement(reader, file, defines))

    def parseExpression(reader: PagedSeqReader, file: File,
        defines: Set[String]): Expression =
      processResult(parser.parseExpression(reader, file, defines))

    /** Processes a parse result
     *
     *  Upon success, returns the underlying AST. Upon failure, displays a
     *  user-friendly error message on stderr and halts the program.
     *
     *  @tparam A type of AST
     *  @param result parse result to be processed
     *  @return the underlying AST, upon success only
     */
    private def processResult[A](result: parser.ParseResult[A]): A = {
      result match {
        case parser.Success(rawCode, _) =>
          rawCode

        case parser.NoSuccess(msg, next) =>
          Console.err.println(
              "Parse error at %s\n".format(next.pos.toString) +
              msg + "\n" +
              next.pos.longString)
          sys.exit(2)
      }
    }
  }

  /** Builds a [[scala.util.parsing.input.PagedSeqReader]] for a file
   *
   *  @param fileName name of the file to be read
   */
  private def readerForFile(fileName: String): PagedSeqReader = {
    new PagedSeqReader(PagedSeq.fromReader(
        new BufferedReader(new FileReader(fileName))))
  }

  /** Loads the definitions of builtin modules
   *
   *  @param prog program in which the modules must be loaded
   *  @param moduleDefs list of files that define builtin modules
   */
  private def loadModuleDefs(prog: Program, moduleDefs: List[String]) = {
    val result = new scala.collection.mutable.HashMap[String, Expression]

    for (moduleDef <- moduleDefs) {
      val file = new File(moduleDef)

      if (file.isFile())
        result ++= loadModuleDef(prog, file)
      else {
        val pattern = """.*-builtin\.json$""".r
        for {
          f <- file.listFiles()
          if (pattern.findFirstIn(f.getName).isDefined)
        } {
          result ++= loadModuleDef(prog, f)
        }
      }
    }

    Map.empty ++ result
  }

  /** Loads one builtin module definition */
  private def loadModuleDef(prog: Program, moduleDef: File): List[(String, Record)] = {
    case class JsParameter(val kind: String)

    case class JsBuiltin(
      val name: String,
      val inlineable: Boolean,
      val inlineOpCode: Option[Int],
      val params: List[JsParameter]
    )

    case class JsModule(
      val name: String,
      val builtins: List[JsBuiltin]
    )

    object ModuleJsonProtocol extends DefaultJsonProtocol {
      implicit val parameterJsonFormat: RootJsonFormat[JsParameter] = jsonFormat1(JsParameter)
      implicit val builtinJsonFormat: RootJsonFormat[JsBuiltin] = jsonFormat4(JsBuiltin)
      implicit val moduleJsonFormat: RootJsonFormat[JsModule] = jsonFormat2(JsModule)
    }

    import ModuleJsonProtocol._

    val jsModule: JsModule =
      readFileToString(moduleDef)
        .parseJson
        .convertTo[JsModule]

    val exportFields = new ListBuffer[RecordField]

    for {
      jsBuiltin <- jsModule.builtins
    } yield {
      val inlineAs: Option[Int] =
        if (jsBuiltin.inlineable) jsBuiltin.inlineOpCode
        else None

      val paramKinds = for {
        jsParam <- jsBuiltin.params
      } yield {
        Builtin.ParamKind.withName(jsParam.kind)
      }

      val builtin = new Builtin(
        jsModule.name, jsBuiltin.name, paramKinds, inlineAs)

      prog.builtins.register(builtin)

      exportFields += RecordField(
          Constant(OzAtom(builtin.name)), Constant(OzBuiltin(builtin)))

      val moduleURL = "x-oz://boot/" + jsModule.name
      val moduleExport = Record(Constant(OzAtom("export")), exportFields.toList)

      moduleURL -> moduleExport
    }
  }

  /** Compiles a program
   *
   *  @param prog program to compile
   *  @param fileName top-level file that is being processed
   */
  private def compile(prog: Program, fileName: String): Unit = {
    applyTransforms(prog)

    if (prog.hasErrors) {
      Console.err.println(
          "There were errors while compiling %s" format fileName)
      for ((message, pos) <- prog.errors) {
        Console.err.println(
            "Error at %s\n".format(pos.toString) +
            message + "\n" +
            pos.longString)
      }

      sys.exit(2)
    }
  }

  /** Applies the successive transformation phases to a program */
  private def applyTransforms(prog: Program): Unit = {
    Namer(prog)
    DesugarFunctor(prog)
    DesugarClass(prog)
    Desugar(prog)
    PatternMatcher(prog)
    ConstantFolding(prog)
    Unnester(prog)
    Flattener(prog)
    CodeGen(prog)
  }

  /** Reads the contents of file
   *
   *  @param file file to read
   *  @return the contents of the file
   */
  private def readFileToString(file: File): String = {
    val source = io.Source.fromFile(file)
    try source.mkString
    finally source.close()
  }

  /** Reads the lines in a file
   *
   *  @param file file to read
   *  @return the lines in the file
   */
  private def readFileLines(file: File): List[String] = {
    val source = io.Source.fromFile(file)
    try source.getLines().toList
    finally source.close()
  }

  /** Writes lines in a file
   *
   *  @param file  file to write
   *  @param lines the lines to write
   */
  private def writeFileLines(file: File, lines: TraversableOnce[String]) = {
    val sink = new PrintWriter(file)
    try {
      for (line <- lines)
        sink.println(line)
    } finally {
      sink.close()
    }
  }
}
