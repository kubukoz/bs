package com.example.bs

import cats.data.Validated
import cats.data.ValidatedNel
import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp
import cats.syntax.all.*
import com.monovore.decline.*
import com.monovore.decline.effect.*
import decline_derive.CommandApplication
import decline_derive.Positional
import os.FilePath

given Argument[FilePath] =
  new Argument[FilePath] {
    def read(string: String): ValidatedNel[String, FilePath] =
      Validated
        .catchNonFatal(os.FilePath(string))
        .leftMap(_.getMessage)
        .toValidatedNel

    def defaultMetavar: String = "path"
  }

enum Command derives CommandApplication {
  case Build(@Positional("path") path: FilePath)
  case Dev(@Positional("path") path: FilePath)
  case Run(@Positional("path") path: FilePath)
}

case class Foo(s: String)

object Main
  extends CommandIOApp(
    name = "bs",
    header = "Build system CLI tool",
    version = "0.1.0",
  ) {

  override def main: Opts[IO[ExitCode]] = {
    // todo: support actually generating code so that this builds
    println(bs.LibraryDependency("test-dep"))
    assert(
      Foo("AAA").toString() == """Foo(s = AAA)""",
      "Foo should have a modified toString, but it's: " + Foo("AAA").toString(),
    )

    val pathArg = Opts
      .argument[FilePath]("path")
      .withDefault(os.pwd)

    val buildCommand =
      Opts.subcommand("build", "Build the project") {
        pathArg.map(Command.Build.apply)
      }

    val devCommand =
      Opts.subcommand("dev", "Run in development mode") {
        pathArg.map(Command.Dev.apply)
      }

    val runCommand =
      Opts.subcommand("run", "Run the project") {
        pathArg.map(Command.Run.apply)
      }

    // Default to build command when no subcommand is provided
    val defaultBuild = pathArg.map(Command.Build.apply)

    val command =
      buildCommand <+>
        devCommand <+>
        runCommand <+>
        defaultBuild

    command.map(executeCommand)
  }

  private def executeCommand(command: Command): IO[ExitCode] =
    command match {
      case Command.Build(path) => BuildCommand.run(path)
      case Command.Dev(path)   => DevCommand.run(path)
      case Command.Run(path)   => RunCommand.run(path)
    }

}

object BuildCommand {

  def run(path: FilePath): IO[ExitCode] = IO
    .println(s"Build command - path: $path")
    .as(ExitCode.Success)

}

object DevCommand {

  def run(path: FilePath): IO[ExitCode] = IO
    .println(s"Dev command - path: $path")
    .as(ExitCode.Success)

}

object RunCommand {

  def run(path: FilePath): IO[ExitCode] = IO
    .println(s"Run command - path: $path")
    .as(ExitCode.Success)

}
