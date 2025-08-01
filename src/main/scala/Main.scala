package com.example.bs

import bs.BuildDefinition
import bs.LibraryDependency
import bs.LockedLibraryDependency
import bs.Lockfile
import cats.data.Validated
import cats.data.ValidatedNel
import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp
import cats.syntax.all.*
import com.monovore.decline.*
import com.monovore.decline.effect.*
import coursierapi.Dependency
import coursierapi.Fetch
import coursierapi.ScalaVersion
import decline_derive.CommandApplication
import decline_derive.Name
import decline_derive.Positional
import os.FilePath
import os.Shellable
import smithy4s.Blob
import smithy4s.json.Json

import scala.jdk.CollectionConverters.*

import _root_.os.Path

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
  case Sandbox()
}

case class Foo(s: String)

object Main
  extends CommandIOApp(
    name = "bs",
    header = "Build system CLI tool",
    version = "0.1.0",
  ) {

  override def main
    : Opts[IO[ExitCode]] = summon[CommandApplication[Command]].command.options.map(executeCommand)

  private def executeCommand(command: Command): IO[ExitCode] =
    command match {
      case Command.Build(path) => IO.stub
      case Command.Dev(path)   => IO.stub
      case Command.Run(path)   => IO.stub
      case Command.Sandbox()   => sandbox.as(ExitCode.Success)
    }

  def lock(deps: List[Dependency]) = IO.interruptibleMany {
    Fetch
      .create()
      .withDependencies(
        deps*
      )
      .fetchResult()
      .getArtifacts()
      .asScala
      .map { entry =>
        LockedLibraryDependency(
          url = entry.getKey().getUrl(),
          sha256 =
            os.proc("nix", "hash", "file", "--base64", entry.getValue().toString())
              .call()
              .out
              .text()
              .trim,
        )
      }
      .toList
  }

  def sandbox: IO[Unit] =
    for {
      _ <- IO.println("Loading build definition...")
      buildDefinition <- Nix
        .call("eval", ".#default.meta.buildDefinition", "--json")
        .map(Blob(_))
        .flatMap(Json.read[BuildDefinition](_).liftTo[IO])
      _ <- IO.println(s"Loaded: $buildDefinition")

      sv = ScalaVersion.of(buildDefinition.scalaVersion)
      parseDep = Dependency.parse(_, sv)

      _ <- IO.println("Building lockfile...")

      lockfile <- Lockfile
        .apply
        .parLiftN(
          lock(List(parseDep(s"org.scala-lang::scala3-compiler:$sv"))),
          lock(buildDefinition.libraryDependencies.map(parseDep.compose(_.value))),
          lock(buildDefinition.compilerPlugins.map(parseDep.compose(_.value))),
        )
      _ <- IO.println(s"Lockfile built: ${lockfile.hashCode()}")
      _ <- Lockfiles.write(os.pwd / "bs-lock.json", lockfile)
      _ <- Nix.call("build", "--print-build-logs")
    } yield ()

}

object Nix {

  def call(args: String*): IO[String] = IO
    .interruptibleMany {
      val p = os
        .proc("nix", args)
        .spawn(
          stdout = os.Pipe
        )

      p.waitFor()
      p.stdout.text()
    }

}

object Lockfiles {

  def write(file: os.Path, lf: Lockfile): IO[Unit] = IO.interruptibleMany {
    os.write.over(file, Json.writePrettyString(lf))
  }

}
