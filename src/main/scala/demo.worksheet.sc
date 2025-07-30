import bs.BuildDefinition
import bs.LockedLibraryDependency
import bs.Lockfile
import cats.syntax.all.*
import coursierapi.*
import smithy4s.Blob
import smithy4s.json.Json

import scala.jdk.CollectionConverters.*

val buildDefn =
  Json
    .read[BuildDefinition](
      Blob(os.proc("nix", "eval", ".#default.meta.buildDefinition", "--json").call().out.text())
    )
    .toTry
    .get

val deps = buildDefn.libraryDependencies.map { dep =>
  Dependency.parse(dep.value, ScalaVersion.of("3.7.2-RC2"))
}

val pluginDeps = buildDefn
  .compilerPlugins
  .map { dep =>
    Dependency.parse(dep.value, ScalaVersion.of("3.7.2-RC2"))
  }

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

val lockfile = Lockfile(
  libraryDependencies = lock(deps),
  compilerPlugins = lock(pluginDeps),
)

os.write
  .over(
    os.pwd / "bs-lock.json",
    Json.writePrettyString(
      lockfile
    ),
  )
