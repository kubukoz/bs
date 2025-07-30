$version: "2"

namespace bs

structure BuildDefinition {
    @required
    libraryDependencies: LibraryDependencies
}

list LibraryDependencies {
    member: LibraryDependency
}

string LibraryDependency

structure Lockfile {
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
