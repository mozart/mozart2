package org.mozartoz.bootcompiler
package symtab

object SystemModules {
  /** An amazingly hard-coded list of modules considered as "system" modules */
  val isSystemModule = Set(
      "Application", "Module", "Search", "FD", "Schedule", "FS", "RecordC",
      "Combinator", "Space", "Connection", "Remote", "URL", "Resolve", "Fault",
      "Open", "OS", "Pickle", "Property", "Error", "Finalize", "System",
      "Tk", "TkTools", "Browser", "Panel", "Explorer", "Ozcar", "Profiler",
      "ObjectSupport",

      "CompilerSupport", "DefaultURL", "ErrorFormatters", "ZlibIO"
  )
}
