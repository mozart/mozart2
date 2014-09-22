name := "bootcompiler"

version := "2.0-SNAPSHOT"

scalaVersion := "2.11.2"

scalacOptions ++= Seq("-deprecation", "-optimize")

libraryDependencies += "org.scala-lang.modules" %% "scala-parser-combinators" % "1.0.2"

libraryDependencies += "com.github.scopt" %% "scopt" % "3.2.0"

seq(com.github.retronym.SbtOneJar.oneJarSettings: _*)

// Work around a bug that prevents generating documentation
unmanagedClasspath in Compile +=
    Attributed.blank(new java.io.File("doesnotexist"))
