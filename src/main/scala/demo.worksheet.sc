import bs.*
import cats.syntax.all.*
import coursierapi.*
import smithy4s.Blob
import smithy4s.json.Json
import smithy4s.schema.Schema

import scala.jdk.CollectionConverters.*

val buildDefn =
  Json
    .read[BuildDefinition](
      Blob(
        os.proc("nix", "eval", ".#default.meta.buildDefinition", "--json")
          .call()
          .out
          .text()
      )
    )
    .toTry
    .get

val sv = ScalaVersion.of(buildDefn.scalaVersion)

def parseDep(s: String) = Dependency.parse(s, sv)

def lock(deps: List[Dependency]) =
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

os.write
  .over(
    os.pwd / "bs-lock.json",
    Json.writePrettyString(
      Lockfile(
        compiler = lock(List(parseDep(s"org.scala-lang::scala3-compiler:$sv"))),
        libraryDependencies = lock(buildDefn.libraryDependencies.map(parseDep.compose(_.value))),
        compilerPlugins = lock(buildDefn.compilerPlugins.map(parseDep.compose(_.value))),
      )
    ),
  )

val wrapDefn =
  Json
    .read[WrapDefinition](
      Blob(
        os.proc("nix", "eval", ".#smithy4s.meta.buildDefinition", "--json")
          .call()
          .out
          .text()
      )
    )
    .toTry
    .get

os.write
  .over(
    os.pwd / "smithy4s-lock.json",
    Json.writePrettyString(
      WrapLockfile(
        libraryDependencies = lock(wrapDefn.libraryDependencies.map(parseDep.compose(_.value)))
      )
    ),
  )
