# This is an example configuration file. 
# Note that all Keys are important and should not be removed.
# If not required, they may be left blank as @{}
@{
    ProgramSets = @(
        # Each of the hashtables below represents a single Set.
        # Each Set is set to be downloaded and installed in parallel
        # The Value 0, 1, 2 indicates the source of the Package. 
        # 0 -> Unpecified
        # 1 -> winget (Winget Repositories)
        # 2 -> msstore (Microsoft Store)

        @{
            "Program1" = 0
            "Program2" = 1
            "Program3" = 2
        },
        @{
            "Program4" = 1
            "Program5" = 2
            "Program6" = 0
            "Geogebra Classic" = 1
        }
    )
    DefaultOptions = @{
        # These Options are set to be run with each install command. 
        # The Values are the option parameters (if any, put empty string if not)
        '--accept-source-agreements'  = ""
        '--accept-package-agreements' = ""
        '-h' = ""
    }
    PackageParams = @{
        # Some programs require specific Parameters to be Uniquely Identified
        # These Parameters may be specified in this table
        # Note that the Program Name here should be the same as in the Program Set
        "Program4" = @{"--id" = "Program.4.dev"}
        "Geogebra Classic" = @{"--id" = "Geogebra.Classic"}
    }
    PythonLibs = @(
        # Each Library should be comma seperated. Pip will be used to install each library
        'numpy',
        'scipy'
    )
}