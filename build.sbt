ThisBuild / scalaVersion := "3.7.2-RC2"
ThisBuild / organization := "com.example"

lazy val root = (project in file("."))
  .enablePlugins(Smithy4sCodegenPlugin, JavaAppPackaging)
  .settings(
    name := "bs",
    libraryDependencies ++= Seq(
      // Compiler plugins
      compilerPlugin("org.polyvariant" % "better-tostring" % "0.3.17" cross CrossVersion.full),

      // CLI dependencies
      "com.monovore" %% "decline" % "2.4.1",
      "com.monovore" %% "decline-effect" % "2.4.1",
      "com.indoorvivants" %% "decline-derive" % "0.3.1",
      "org.typelevel" %% "cats-core" % "2.13.0",
      "org.typelevel" %% "cats-effect" % "3.6.3",

      // File system operations
      "com.lihaoyi" %% "os-lib" % "0.11.4",

      // Smithy4s
      "com.disneystreaming.smithy4s" %% "smithy4s-json" % smithy4sVersion.value,
      "io.get-coursier" % "interface" % "1.0.28",

      // Testing
      "org.typelevel" %% "weaver-cats" % "0.9.3" % Test,
      "org.typelevel" %% "weaver-scalacheck" % "0.9.3" % Test,
    ),
    Compile / run / fork := true,
  )
