name := "bootcompiler"

version := "2.0-SNAPSHOT"

scalaVersion := "2.13.8"

scalacOptions ++= Seq("-language:postfixOps", "-deprecation", "-optimize")

libraryDependencies += "org.scala-lang.modules" %% "scala-parser-combinators" % "2.1.1"
libraryDependencies += "com.github.scopt" %% "scopt" % "4.1.0"
libraryDependencies += "io.spray" %% "spray-json" % "1.3.6"

// Work around a bug that prevents generating documentation
unmanagedClasspath in Compile +=
    Attributed.blank(new java.io.File("doesnotexist"))

// Added during migration to the java 9 module system
Compile / packageBin / packageOptions +=
  Package.ManifestAttributes("Add-Exports" -> "java.base/jdk.internal.math")
