package org.mozartoz.bootcompiler
package util

class Counter(start: Int = 1) {
  private var _last = start-1

  def next() = {
    _last += 1
    _last
  }
}
