{ stdenv, scala-next }:

let
  bs = {
    build = { src, scala, libraryDependencies ? [ ], ... }@args:
      let
        depDerivations =
          let json = builtins.fromJSON (builtins.readFile (./bs-lock.json));
          in builtins.map (dep: builtins.fetchurl dep) json.libraryDependencies;
      in stdenv.mkDerivation
      ((builtins.removeAttrs args [ "buildInputs" "buildPhase" "installPhase" ])
        // {
          inherit depDerivations;

          buildInputs = [ scala ];
          buildPhase = ''
            echo $depDerivations
            classpath=$(echo ${builtins.concatStringsSep ":" depDerivations})
            scalac -cp $classpath $src/*.scala
            jar cf $out/bin/bs.jar com/example/bs/*.class
          '';

          installPhase = "";

          meta.buildDefinition = { inherit libraryDependencies; };
        });
  };

in bs.build {
  pname = "bs";
  version = "0.0.1";
  src = ./src/main/scala;

  scala = scala-next;

  libraryDependencies = [
    # "org.polyvariant:better-tostring:0.3.17"
    "com.monovore::decline:2.4.1"
    "com.monovore::decline-effect:2.4.1"
    "com.indoorvivants::decline-derive:0.3.1"
    "org.typelevel::cats-effect:3.5.4"
    "com.lihaoyi::os-lib:0.10.7"
    "com.disneystreaming.smithy4s::smithy4s-core:0.18.40"
    "io.get-coursier:interface:1.0.28"
  ];

}
