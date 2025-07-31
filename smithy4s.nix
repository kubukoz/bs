{ bs }:
let version = "0.18.41";
in bs.wrap {
  inherit version;
  pname = "smithy4s";
  libraryDependencies =
    [ "com.disneystreaming.smithy4s:smithy4s-codegen-cli_2.13:${version}" ];
  lockFile = ./smithy4s-lock.json;
}
