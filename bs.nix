{ openjdk, makeWrapper, stdenv }:
let
  mkClasspathFrom = lockFile: key:
    let
      json = builtins.fromJSON (builtins.readFile lockFile);
      files = builtins.map (dep: builtins.fetchurl dep) json.${key};
    in builtins.concatStringsSep ":" files;
in {
  wrap = { mainClass, libraryDependencies, lockFile, ... }@args:
    let
      classpathFrom = mkClasspathFrom lockFile;
      myArgs = {
        classpath = classpathFrom "libraryDependencies";
        dontUnpack = true;

        buildInputs = [ openjdk makeWrapper ];

        installPhase = ''
          makeWrapper ${openjdk}/bin/java $out/bin/$pname --add-flags "-cp $classpath $mainClass"
        '';

        meta.buildDefinition = { inherit libraryDependencies; };
      };
      finalArgs = (builtins.removeAttrs args [
        "buildInputs"
        "buildPhase"
        "installPhase"
        "libraryDependencies"
        "lockfile"
      ]) // myArgs;
    in stdenv.mkDerivation finalArgs;
  build = { srcs, lockFile ? ./bs-lock.json, scalaVersion
    , libraryDependencies ? [ ], compilerPlugins ? [ ], mainClass ? "", ...
    }@args:
    let
      classpathFrom = mkClasspathFrom lockFile;
      compilerInterface = ''
        public class CompilerInterface {
          public static void main(String[] args) {
            new dotty.tools.dotc.Driver().main(args);
          }
        }'';
      myArgs = {
        classpath = classpathFrom "libraryDependencies";
        compilerClasspath = classpathFrom "compiler";
        pluginsClasspath = classpathFrom "compilerPlugins";
        inherit srcs;

        dontUnpack = true;
        buildInputs = [ openjdk makeWrapper ];
        buildPhase = ''
          # set -x
          echo "${compilerInterface}" > CompilerInterface.java
          javac -cp $compilerClasspath CompilerInterface.java

          scala_files=$(find $srcs -name "*.scala" | tr '\n' ' ')

          mkdir -p $out/bin
          java -cp $compilerClasspath:. CompilerInterface -cp $classpath $scala_files -Xplugin:$pluginsClasspath -d $out/bin/bs.jar
        '';

        installPhase = ''
          jar xf $out/bin/bs.jar META-INF/MANIFEST.MF
          mainClass=$(cat META-INF/MANIFEST.MF | grep Main-Class | cut -d' ' -f2 | tr -d '\r')
          makeWrapper ${openjdk}/bin/java $out/bin/$pname --add-flags "-cp $classpath:$out/bin/bs.jar $mainClass"
        '';

        meta.buildDefinition = {
          inherit scalaVersion libraryDependencies compilerPlugins;
        };
      };
      finalArgs = (builtins.removeAttrs args [
        "srcs"
        "buildInputs"
        "buildPhase"
        "installPhase"
        "scalaVersion"
        "libraryDependencies"
        "compilerPlugins"
        "lockfile"
      ]) // myArgs;
    in stdenv.mkDerivation finalArgs;
}
