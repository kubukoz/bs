{ callPackage }:

let
  bs = (callPackage ./bs.nix { });
  scalaVersion = "3.7.2-RC2";

in bs.build {
  pname = "bs";
  version = "0.0.1";
  src = ./src/main/scala;
  inherit scalaVersion;

  libraryDependencies = [
    "org.scala-lang::scala3-library:${scalaVersion}"
    "com.monovore::decline:2.4.1"
    "com.monovore::decline-effect:2.4.1"
    "com.indoorvivants::decline-derive:0.3.1"
    "org.typelevel::cats-effect:3.5.4"
    "com.lihaoyi::os-lib:0.10.7"
    "com.disneystreaming.smithy4s::smithy4s-core:0.18.40"
    "io.get-coursier:interface:1.0.28"
  ];

  compilerPlugins = [ "org.polyvariant:::better-tostring:0.3.17" ];
}
