import bs.*
import cats.effect.unsafe.implicits.*
import cats.syntax.all.*
import com.example.bs.Main
import coursierapi.*
import smithy4s.Blob
import smithy4s.json.Json
import smithy4s.schema.Schema

import scala.jdk.CollectionConverters.*
Main.sandbox.unsafeRunSync()

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
