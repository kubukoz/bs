{ openjdk, makeWrapper, stdenv }:

{
  build = { src, scalaVersion, libraryDependencies ? [ ], compilerPlugins ? [ ]
    , mainClass ? "", ... }@args:
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
      myArgs = {
        classpath = classpathFrom "libraryDependencies";
        compilerClasspath = classpathFrom "compiler";
        pluginsClasspath = classpathFrom "compilerPlugins";
        inherit src;

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
      };
      finalArgs = (builtins.removeAttrs args [
        "src"
        "buildInputs"
        "buildPhase"
        "installPhase"
        "scalaVersion"
        "libraryDependencies"
        "compilerPlugins"
      ]) // myArgs;
    in stdenv.mkDerivation finalArgs;
}
