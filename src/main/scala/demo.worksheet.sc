import bs.*
import cats.effect.unsafe.implicits.*
import cats.syntax.all.*
import com.example.bs.Main
import com.example.bs.Main.lock
import coursierapi.*
import smithy4s.Blob
import smithy4s.json.Json
import smithy4s.schema.Schema

import scala.jdk.CollectionConverters.*

Main.sandbox.unsafeRunSync()

val parseDep = Dependency.parse(_, ScalaVersion.of("3.7.2-RC2"))

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
          .unsafeRunSync()
      )
    ),
  )
