{ callPackage, runCommandNoCC, smithy4s }:

let
  bs = (callPackage ./bs.nix { });
  smithy4sGenerate = { src }:
    runCommandNoCC "smithy4sGenerate" { buildInputs = [ smithy4s ]; } ''
      mkdir -p .coursier/cache
      export COURSIER_CACHE=.coursier/cache
      smithy4s generate ${src} --output $out
    '';

  scalaVersion = "3.7.2-RC2";
  smithy4sPlugin = buildDefinition:
    let inputDirAttr = "smithy4sInputDir";
    in (builtins.removeAttrs buildDefinition [ inputDirAttr ]) // {
      srcs = buildDefinition.srcs
        ++ [ (smithy4sGenerate { src = buildDefinition.${inputDirAttr}; }) ];
    };

in bs.build {
  pname = "bs";
  version = "0.0.1";
  srcs = [ ./src/main/scala ];
  smithy4sInputDir = ./src/main/smithy;
  plugins = [ smithy4sPlugin ];

  inherit scalaVersion;

  libraryDependencies = [
    "org.scala-lang::scala3-library:${scalaVersion}"
    "com.monovore::decline:2.4.1"
    "com.monovore::decline-effect:2.4.1"
    "com.indoorvivants::decline-derive:0.3.1"
    "org.typelevel::cats-effect:3.5.4"
    "com.lihaoyi::os-lib:0.11.4"
    "com.disneystreaming.smithy4s::smithy4s-core:${smithy4s.version}"
    "io.get-coursier:interface:1.0.28"
  ];

  compilerPlugins = [ "org.polyvariant:::better-tostring:0.3.17" ];
}
