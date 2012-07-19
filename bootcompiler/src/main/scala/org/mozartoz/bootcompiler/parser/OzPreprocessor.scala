package org.mozartoz.bootcompiler
package parser

import java.io.{ File, FileReader, BufferedReader }

import scala.collection.immutable.PagedSeq

import scala.util.parsing.input._
import scala.util.parsing.combinator.token._

trait OzPreprocessor {
  val lexical = new OzLexical
  import lexical._

  /** Preprocessor state */
  private case class PreprocessorState(
      in: Reader[Token],
      currentFile: File,
      fileStack: List[(Reader[Token], File)] = Nil,
      offset: Int = 0
  ) {
    def pos = new PreprocessorPosition(offset)(in.pos, currentFile)
  }

  /** Preprocessor */
  class Preprocessor(state: PreprocessorState) extends Reader[Token] {
    def this(in: Reader[Token], file: File) =
      this(PreprocessorState(in = in, currentFile = file))

    private val (_first, _rest0, _pos, _atEnd) =
      preprocess(state)

    private lazy val _rest = _rest0()

    def first = _first
    def rest = _rest
    def pos = _pos
    def atEnd = _atEnd
  }

  private def preprocess(state: PreprocessorState):
      (Token, () => Reader[Token], Position, Boolean) = {
    import state._

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
    } else {
      in.first match {
        // TODO Process a preprocessor token

        case PreprocessorDirectiveWithArg("insert", fileName) =>
          val subFile = new File(currentFile.getParentFile, fileName)
          val subReader = readerForFile(subFile)
          val subScanner = new Scanner(subReader)

          val subStack = (in.rest, currentFile) :: fileStack
          preprocess(state.copy(in = subScanner, currentFile = subFile,
              fileStack = subStack))

        case _ =>
          val nextState = state.copy(in = in.rest, offset = offset+1)
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
      underlying: Position, val file: File) extends Position {
    def line = underlying.line
    def column = underlying.column

    protected def lineContents: String = "" // cheat

    override def toString =
      "line %d, column %d (in file %s)".format(line, column, file.getName)

    override def longString = underlying.longString

    override def <(that: Position) = that match {
      case PreprocessorPosition(thatOffset) =>
        this.offset < thatOffset
      case _ =>
        super.<(that)
    }
  }
}
