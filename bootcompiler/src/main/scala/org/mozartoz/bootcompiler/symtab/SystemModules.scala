package org.mozartoz.bootcompiler
package symtab

object SystemModules {
  /** Consider all functors as "system" modules */
  def isSystemModule(module: String) = true
}
