$version: "2"

namespace bs

structure BuildDefinition {
    @required
    scalaVersion: String

    @required
    libraryDependencies: LibraryDependencies

    @required
    compilerPlugins: LibraryDependencies
}

structure WrapDefinition {
    @required
    libraryDependencies: LibraryDependencies
}

list LibraryDependencies {
    member: LibraryDependency
}

string LibraryDependency

structure Lockfile {
    @required
    compiler: LockedLibraryDependencies

    @required
    libraryDependencies: LockedLibraryDependencies

    @required
    compilerPlugins: LockedLibraryDependencies
}

structure WrapLockfile {
    @required
    libraryDependencies: LockedLibraryDependencies
}

list LockedLibraryDependencies {
    member: LockedLibraryDependency
}

structure LockedLibraryDependency {
    @required
    url: String

    @required
    sha256: String
}
