{ stdenv, openjdk, makeWrapper }:

let
  bs = {
    build = { src, scalaVersion, libraryDependencies ? [ ]
      , compilerPlugins ? [ ], ... }@args:
      let
        classpathFrom = key:
          let
            json = builtins.fromJSON (builtins.readFile (./bs-lock.json));
            files = builtins.map (dep: builtins.fetchurl dep) json.${key};
          in builtins.concatStringsSep ":" files;
        compilerInterface = ''
          public class CompilerInterface {
            public static void main(String[] args) {
              new dotty.tools.dotc.Driver().main(args);
            }
          }'';
      in stdenv.mkDerivation ((builtins.removeAttrs args [
        "buildInputs"
        "buildPhase"
        "installPhase"
        "scalaVersion"
        "libraryDependencies"
        "compilerPlugins"
      ]) // {
        classpath = classpathFrom "libraryDependencies";
        compilerClasspath = classpathFrom "compiler";
        pluginsClasspath = classpathFrom "compilerPlugins";

        buildInputs = [ openjdk makeWrapper ];
        buildPhase = ''
          # set -x
          echo $depDerivations
          echo "${compilerInterface}" > CompilerInterface.java
          javac -cp $compilerClasspath CompilerInterface.java
          mkdir -p $out/bin
          java -cp $compilerClasspath:. CompilerInterface -cp $classpath $src/*.scala -Xplugin:$pluginsClasspath -d $out/bin/bs.jar
        '';

        installPhase = ''
          jar xf $out/bin/bs.jar META-INF/MANIFEST.MF
          mainClass=$(cat META-INF/MANIFEST.MF | grep Main-Class | cut -d' ' -f2 | tr -d '\r')
          makeWrapper ${openjdk}/bin/java $out/bin/bs --add-flags "-cp $classpath:$out/bin/bs.jar $mainClass"
        '';

        meta.buildDefinition = {
          inherit scalaVersion libraryDependencies compilerPlugins;
        };
      });
  };

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
