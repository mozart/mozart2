package org.mozartoz.bootcompiler
package parser

import java.io.{ File, FileReader, BufferedReader }

import scala.util.parsing.input._
import scala.util.parsing.combinator.token._

import util.FilePosition

trait OzPreprocessor {
  val lexical = new OzLexical
  import lexical._

  /** Preprocessor state */
  private case class PreprocessorState(
      in: Reader[Token],
      currentFile: File,
      fileStack: List[(Reader[Token], File)] = Nil,
      offset: Int = 0,

      defines: Set[String] = Set.empty,
      skipping: Boolean = false,
      skipDepth: Int = 0
  ) {
    def pos = new PreprocessorPosition(offset)(in.pos, currentFile)
  }

  /** Preprocessor */
  class Preprocessor(state: PreprocessorState) extends Reader[Token] {
    def this(in: Reader[Token], file: File, defines: Set[String]) =
      this(PreprocessorState(in = in, currentFile = file, defines = defines))

    private val (_first, _rest0, _pos, _atEnd) =
      preprocess(state)

    private lazy val _rest = _rest0()

    def first = _first
    def rest = _rest
    def pos = _pos
    def atEnd = _atEnd
  }

  @scala.annotation.tailrec
  private def preprocess(state0: PreprocessorState):
      (Token, () => Reader[Token], Position, Boolean) = {
    import state0.{ in, pos }
    val state = state0.copy(in = in.rest)
    import state.{ in => _, pos => _, _ }

    if (in.atEnd) {
      if (fileStack.isEmpty) {
        // Totally the end
        (in.first, () => in, pos, true)
      } else {
        // Get out of one file
        val (newIn, newFile) :: newStack = fileStack
        preprocess(state.copy(in = newIn, currentFile = newFile,
            fileStack = newStack))
      }
    } else if (skipping) {
      in.first match {
        case PreprocessorDirectiveWithArg("ifdef" | "ifndef", _) =>
          preprocess(state.copy(skipDepth = skipDepth+1))

        case PreprocessorDirective("else" | "endif") if (skipDepth == 1) =>
          preprocess(state.copy(skipping = false, skipDepth = 0))

        case PreprocessorDirective("endif") =>
          preprocess(state.copy(skipDepth = skipDepth-1))

        case _ =>
          preprocess(state)
      }
    } else {
      in.first match {
        case PreprocessorDirectiveWithArg("define", name) =>
          preprocess(state.copy(defines = defines + name))

        case PreprocessorDirectiveWithArg("undef", name) =>
          preprocess(state.copy(defines = defines - name))

        case PreprocessorDirectiveWithArg("ifdef", name) =>
          if (defines contains name) {
            preprocess(state)
          } else {
            preprocess(state.copy(skipping = true, skipDepth = 1))
          }

        case PreprocessorDirectiveWithArg("ifndef", name) =>
          if (!(defines contains name)) {
            preprocess(state)
          } else {
            preprocess(state.copy(skipping = true, skipDepth = 1))
          }

        case PreprocessorDirective("else") =>
          preprocess(state.copy(skipping = true, skipDepth = 1))

        case PreprocessorDirective("endif") =>
          preprocess(state)

        case PreprocessorDirectiveWithArg("insert", fileName) =>
          val file0 = new File(currentFile.getParentFile, fileName)

          val file = {
            if (file0.exists()) file0
            else {
              val altFile = new File(currentFile.getParentFile, fileName+".oz")
              if (altFile.exists()) altFile
              else file0
            }
          }

          val reader = readerForFile(file)
          val scanner = new Scanner(reader)

          val newStack = (in.rest, currentFile) :: fileStack
          preprocess(state.copy(in = scanner, currentFile = file,
              fileStack = newStack))

        case _ =>
          val nextState = state.copy(offset = offset+1)
          (in.first, () => new Preprocessor(nextState), pos, false)
      }
    }
  }

  /** Builds a [[scala.util.parsing.input.PagedSeqReader]] for a file
   *
   *  @param file file to be read
   */
  private def readerForFile(file: File) = {
    new PagedSeqReader(PagedSeq.fromReader(
        new BufferedReader(new FileReader(file))))
  }

  private case class PreprocessorPosition(offset: Int)(
      underlying: Position, _file: File) extends FilePosition {
    def line = underlying.line
    def column = underlying.column

    def file = Some(_file)
    override def fileName = _file.getName

    protected def lineContents: String = "" // cheat

    override def toString =
      "line %d, column %d (in file %s)".format(line, column, fileName)

    override def longString = underlying.longString

    override def <(that: Position) = that match {
      case PreprocessorPosition(thatOffset) =>
        this.offset < thatOffset
      case _ =>
        super.<(that)
    }
  }
}
