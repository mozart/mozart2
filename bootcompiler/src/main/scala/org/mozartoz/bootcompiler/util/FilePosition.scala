package org.mozartoz.bootcompiler
package util

import java.io.File

import scala.util.parsing.input._

trait FilePosition extends Position {
  def file: Option[File]

  def fileName = file map (_.getName) getOrElse FilePosition.NoFileName
}

object FilePosition {
  val NoFileName = "<unknown-file>"

  def fileOf(position: Position) = position match {
    case filePos: FilePosition => filePos.file
    case _ => None
  }

  def fileNameOf(position: Position, default: String = NoFileName) =
    fileOf(position) map (_.getName) getOrElse default
}
