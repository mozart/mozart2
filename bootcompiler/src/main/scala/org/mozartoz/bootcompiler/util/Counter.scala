package org.mozartoz.bootcompiler
package util

/** Simple counter for generating unique IDs
 *
 *  @constructor creates a new counter with a given initial value
 *  @param start first value that will be returned by `next()`
 */
class Counter(start: Int = 1) {
  private var _last = start-1

  /** Returns the next generated ID.
   *
   *  The first time it is called it returns `start`. Subsequent calls return
   *  monotonically increasing values, if wrapping is not an issue.
   */
  def next() = {
    _last += 1
    _last
  }
}
