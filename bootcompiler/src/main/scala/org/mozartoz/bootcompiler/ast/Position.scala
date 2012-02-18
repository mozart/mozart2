package org.mozartoz.bootcompiler.ast

abstract class Position {
  def isDefined: Boolean
}

object NoPosition extends Position {
  def isDefined = false
}
