# Semantic Version

An port of PowerShell Core's implementation of semantic versioning (<https://semver.org>) that can be converted to/from System.Version.

When converting to System.Version using the ToVersion() method, a PSNoteProperty is added to the instance to store the
semantic version prerelease and metadata labels so that they can be recovered when creating a new SemanticVersion.
