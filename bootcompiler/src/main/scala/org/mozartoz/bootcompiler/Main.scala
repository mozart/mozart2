package org.mozartoz.bootcompiler

import java.io.{ Console => _, _ }

import scala.collection.mutable.ListBuffer
import scala.collection.immutable.PagedSeq
import scala.util.parsing.combinator._
import scala.util.parsing.input._
import scala.util.parsing.json._

import oz._
import parser._
import ast._
import transform._
import symtab._
import util._

case class Config(
    fileNames: List[String] = Nil,
    outputStream: () => PrintStream = () => Console.out,
    baseModules: List[String] = Nil,
    moduleDefs: List[String] = Nil
)

/** Entry point for the Mozart2 bootstrap compiler */
object Main {
  /** Executes the Mozart2 bootstrap compiler */
  def main(args: Array[String]) {
    // Define command-line options
    val optParser = new scopt.immutable.OptionParser[Config]("scopt", "2.x") {
      def options = Seq(
        opt("o", "output", "output file") {
          (v: String, c: Config) => c.copy(
              outputStream = () => new PrintStream(v))
        },
        opt("m", "module", "module definition file") {
          (v: String, c: Config) => c.copy(moduleDefs = v :: c.moduleDefs)
        },
        opt("b", "base", "path to the base functor") {
          (v: String, c: Config) => c.copy(baseModules = v :: c.baseModules)
        },
        arglist("<files>", "input files (main file must be first)") {
          (v: String, c: Config) => c.copy(fileNames = v :: c.fileNames)
        }
      )
    }

    // Parse the options
    optParser.parse(args, Config()) map { config =>
      // OK, we're good to go
      import config._

      try {
        val baseFunctors =
          for (baseModule <- baseModules.reverse)
            yield parseExpression(readerForFile(baseModule),
                new File(baseModule))

        val functors =
          for (fileName <- fileNames.reverse)
            yield fileName -> parseExpression(readerForFile(fileName),
                new File(fileName))

        val program = buildProgram(moduleDefs, baseFunctors, functors)

        produce(program, outputStream)
      } catch {
        case th: Throwable =>
          th.printStackTrace()
          sys.exit(2)
      }
    } getOrElse {
      // Bad command-line arguments
      optParser.showUsage
      sys.exit(1)
    }
  }

  /** Parses an Oz statement from a reader
   *
   *  Upon lexical or syntactical error, displays a user-friendly error
   *  message on stderr and halts the program.
   *
   *  @param reader input reader
   *  @return The statement AST
   */
  private def parseStatement(reader: PagedSeqReader, file: File) =
    new ParserWrapper().parseStatement(reader, file)

  /** Parses an Oz expression from a reader
   *
   *  Upon lexical or syntactical error, displays a user-friendly error
   *  message on stderr and halts the program.
   *
   *  @param reader input reader
   *  @return The expression AST
   */
  private def parseExpression(reader: PagedSeqReader, file: File) =
    new ParserWrapper().parseExpression(reader, file)

  /** Utility wrapper for an [[org.mozartoz.bootcompiler.parser.OzParser]]
   *
   *  This wrapper provides user-directed error messages.
   */
  private class ParserWrapper {
    /** Underlying parser */
    private val parser = new OzParser()

    def parseStatement(reader: PagedSeqReader, file: File) =
      processResult(parser.parseStatement(reader, file))

    def parseExpression(reader: PagedSeqReader, file: File) =
      processResult(parser.parseExpression(reader, file))

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
  private def readerForFile(fileName: String) = {
    new PagedSeqReader(PagedSeq.fromReader(
        new BufferedReader(new FileReader(fileName))))
  }

  /** Builds a [[scala.util.parsing.input.PagedSeqReader]] for a resource
   *
   *  @param resourceName name of the resource to be read
   */
  private def readerForResource(resourceName: String) = {
    new PagedSeqReader(PagedSeq.fromSource(io.Source.fromInputStream(
        getClass.getResourceAsStream(resourceName))))
  }

  /** Builds a whole [[org.mozartoz.bootcompiler.symtab.Program]] from its parts
   *
   *  See [[org.mozartoz.bootcompiler.ProgramBuilder]] for details on the
   *  transformation performed.
   *
   *  @param moduleDefs list of files that define builtin modules
   *  @param baseFunctors ASTs of the base functors
   *  @param programFunctors File names to ASTs of the program functors
   */
  private def buildProgram(moduleDefs: List[String],
      baseFunctors: List[Expression],
      programFunctors: List[(String, Expression)]): Program = {
    val prog = new Program

    val bootModulesMap = loadModuleDefs(prog, moduleDefs)

    val programFunctorsWithURLs =
      for ((fileName, functorExpr) <- programFunctors)
        yield (fileNameToURL(fileName), functorExpr)

    val mainFunctorURL = programFunctorsWithURLs.head._1

    ProgramBuilder.build(prog, bootModulesMap, baseFunctors,
        programFunctorsWithURLs, mainFunctorURL)

    prog
  }

  /** Returns the appropriate URL for a file name */
  private def fileNameToURL(fileName: String) = {
    val nameAndExt = new File(fileName).getName
    val nameOnly =
      if (!(nameAndExt contains '.')) nameAndExt
      else nameAndExt.substring(0, nameAndExt.lastIndexOf('.'))

    if (!SystemModules.isSystemModule(nameOnly)) nameOnly + ".ozf"
    else "x-oz://system/" + nameOnly + ".ozf"
  }

  /** Compiles a program and produces the corresponding C++ code
   *
   *  @param prog program to compiler
   *  @param outputStream function returning the output stream
   */
  private def produce(prog: Program, outputStream: () => PrintStream) {
    applyTransforms(prog)

    if (prog.hasErrors) {
      for ((message, pos) <- prog.errors) {
        Console.err.println(
            "Error at %s\n".format(pos.toString) +
            message + "\n" +
            pos.longString)
      }

      sys.exit(2)
    } else {
      prog.produceCC(new Output(outputStream()))
    }
  }

  /** Loads the definitions of builtin modules
   *
   *  @param prog program in which the modules must be loaded
   *  @param moduleDefs list of files that define builtin modules
   */
  private def loadModuleDefs(prog: Program, moduleDefs: List[String]) = {
    JSON.globalNumberParser = (_.toInt)

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
  private def loadModuleDef(prog: Program, moduleDef: File) = {
    class CC[T] {
      def unapply(a: Any): Option[T] = Some(a.asInstanceOf[T])
    }

    object M extends CC[Map[String, Any]]
    object L extends CC[List[Any]]
    object S extends CC[String]
    object D extends CC[Double]
    object B extends CC[Boolean]

    val modules = JSON.parseFull(readFileToString(moduleDef)).toList

    for {
      M(module) <- modules
      S(modName) = module("name")
      L(builtins) = module("builtins")
    } yield {
      val exportFields = new ListBuffer[RecordField]

      for {
        M(bi) <- builtins
        S(biFullCppName) = bi("fullCppName")
        S(biName) = bi("name")
        B(inlineable) = bi("inlineable")
        L(params) = bi("params")
      } {
        val inlineAs =
          if (inlineable) Some(bi("inlineOpCode").asInstanceOf[Int])
          else None

        val paramKinds = for {
          M(param) <- params
          S(paramKind) = param("kind")
        } yield {
          Builtin.ParamKind.withName(paramKind)
        }

        val builtin = new Builtin(
            modName, biName, biFullCppName, paramKinds, inlineAs)

        prog.builtins.register(builtin)

        exportFields += RecordField(
            Constant(OzAtom(biName)), Constant(OzBuiltin(builtin)))
      }

      val moduleURL = "x-oz://boot/" + modName
      val moduleExport = Record(Constant(OzAtom("export")), exportFields.toList)

      moduleURL -> moduleExport
    }
  }

  /** Applies the successive transformation phases to a program */
  private def applyTransforms(prog: Program) {
    Namer(prog)
    DesugarFunctor(prog)
    DesugarClass(prog)
    Desugar(prog)
    ConstantFolding(prog)
    PatternMatcher(prog)
    Unnester(prog)
    Flattener(prog)
    CodeGen(prog)
  }

  /** Reads the contents of file
   *
   *  @param file file to read
   *  @return the contents of the file
   */
  private def readFileToString(file: File) = {
    val source = io.Source.fromFile(file)
    try source.mkString
    finally source.close()
  }
}
