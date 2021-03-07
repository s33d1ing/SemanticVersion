# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
using namespace System.Management.Automation

# Base class for creating the core component of a semantic version.
class CoreVersion : System.IComparable, System.IEquatable[System.Object] {
    [int]$Major
    [int]$Minor
    [int]$Patch

    # hidden static [string]$VersionRegEx = '^(?<Major>0|[1-9]\d*)(?:\.(?<Minor>0|[1-9]\d*))?(?:\.(?<Build>0|[1-9]\d*))?(?:\.(?<Revision>0|[1-9]\d*))?$'
    hidden static [string]$VersionRegEx = '^(?<Major>0|[1-9]\d*)(?:\.(?<Minor>0|[1-9]\d*))?(?:\.(?<Patch>0|[1-9]\d*))?$'

    #region Constructors

        # Construct a CoreVersion from a string.
        CoreVersion([string]$Version) {
            $core = [CoreVersion]::Parse($Version)

            $this.Major = $core.Major
            $this.Minor = $core.Minor
            $this.Patch = $core.Patch
        }

        # Construct a CoreVersion from a System.Version.
        CoreVersion([version]$Version) {
            if ($null -eq $Version) { throw [PSArgumentNullException] }
            if ($Version.Revision -gt 0) { throw [PSArgumentException] }

            $this.Major = $Version.Major
            $this.Minor = $Version.Minor

            if ($Version.Build -eq -1) { $this.Patch = 0 }
            else { $this.Patch = $Version.Build }
        }

        # Construct a CoreVersion.
        CoreVersion([int]$Major, [int]$Minor, [int]$Patch) {
            if ($Major -eq -1) { throw [PSArgumentException] }
            if ($Minor -eq -1) { throw [PSArgumentException] }
            if ($Patch -eq -1) { throw [PSArgumentException] }

            $this.Major = $Major
            $this.Minor = $Minor
            $this.Patch = $Patch
        }

        # Construct a CoreVersion.
        CoreVersion([int]$Major, [int]$Minor) {
            if ($Major -eq -1) { throw [PSArgumentException] }
            if ($Minor -eq -1) { throw [PSArgumentException] }

            $this.Major = $Major
            $this.Minor = $Minor
        }

        # Construct a CoreVersion.
        CoreVersion([int]$Major) {
            if ($Major -eq -1) { throw [PSArgumentException] }

            $this.Major = $Major
        }

        # Construct a CoreVersion.
        CoreVersion() { }

    #endregion

    #region Methods

        # Convert the CoreVersion to System.Version.
        static [version] op_Implicit([CoreVersion]$Version) {
            $result = New-Object -TypeName Version -ArgumentList ($Version.Major, $Version.Minor, $Version.Patch)

            return $result
        }

        # Parse version and return the result if it is a valid CoreVersion, otherwise throws an exception.
        static [CoreVersion] Parse([string]$Version) {
            if ($null -eq $Version) { throw [PSArgumentNullException] }
            if ([string]::Empty -eq $Version) { throw [FormatException] }

            $parsed = $null

            [CoreVersion]::TryParseVersion($Version, [ref]$parsed, $true)

            return $parsed
        }

        # Parse version and return true if it is a valid CoreVersion, otherwise return false.
        static [bool] TryParse([string]$Version, [ref]$Result) {
            if ($null -ne $Version) {
                $parsed = $null

                if ([CoreVersion]::TryParseVersion($Version, [ref]$parsed, $false)) {
                    $Result.Value = $parsed
                    return $true
                }
            }

            $Result.Value = $null
            return $false
        }

        hidden static [bool] TryParseVersion([string]$Version, [ref]$Result, [bool]$CanThrow) {
            if ([regex]::IsMatch($Version, [CoreVersion]::VersionRegEx)) {
                $match = [regex]::Match($Version, [CoreVersion]::VersionRegEx)

                $core = [CoreVersion]::new(
                    $match.Groups['Major'].Value,
                    $match.Groups['Minor'].Value,
                    $match.Groups['Patch'].Value
                )

                $Result.Value = $core
                return $true
            }
            elseif ($CanThrow) { throw [FormatException] }
            else {
                $Result.Value = $null
                return $false
            }
        }

        # Implement ToString()
        [string] ToString() { return $this.ToString(3) }

        # Implement ToString()
        [string] ToString([int]$Fields) {
            if ($Fields -notin 1..3) { throw [PSArgumentOutOfRangeException] }

            $version = [string]::Empty

            if ($Fields -ge 1) { $version = $this.Major }
            if ($Fields -ge 2) { $version = $version, $this.Minor -join '.' }
            if ($Fields -eq 3) { $version = $version, $this.Patch -join '.' }

            return $version
        }

        #region Comparisons

            # Implement Compare.
            static [int] Compare([CoreVersion]$VersionA, [CoreVersion]$VersionB) {
                if ($null -ne $VersionA) { return $VersionA.CompareTo($VersionB) }
                if ($null -ne $VersionB) { return -1 }

                return 0
            }

            # Implement IComparable.CompareTo[System.Object]
            [int] CompareTo([object]$Version) {
                if ($null -eq $Version) { return 1 }
                if ($null -eq [CoreVersion]$Version) { return 1 }

                return $this.CompareTo($Version -as [CoreVersion])
            }

            # Implement IComparable.CompareTo[CoreVersion]
            [int] CompareTo([CoreVersion]$Version) {
                if ($null -eq [object]$Version) { return 1 }

                if ($this.Major -ne $Version.Major) {
                    if ($this.Major -gt $Version.Major) { return 1 } else { return -1 }
                }

                if ($this.Minor -ne $Version.Minor) {
                    if ($this.Minor -gt $Version.Minor) { return 1 } else { return -1 }
                }

                if ($this.Patch -ne $Version.Patch) {
                    if ($this.Patch -gt $Version.Patch) { return 1 } else { return -1 }
                }

                return 0
            }

            # Override System.Object.Equals[System.Object]
            [bool] Equals([object]$Version) {
                $core = $Version -as [CoreVersion]

                return (
                    ($null -ne $core) -and ($this.Major -eq $core.Major) -and
                    ($this.Minor -eq $core.Minor) -and ($this.Patch -eq $core.Patch)
                )
            }

            # Override System.Object.GetHashCode
            [int] GetHashCode() { return $this.ToString().GetHashCode() }

        #endregion

        # Increments the Major component by one.
        [void] IncrementMajor() { $this.IncrementMajor(1) }

        # Increments the Minor component by one.
        [void] IncrementMinor() { $this.IncrementMinor(1) }

        # Increments the Patch component by one.
        [void] IncrementPatch() { $this.IncrementPatch(1) }

        # Increments the Major component.
        [void] IncrementMajor([int]$By) {
            if ($By -lt 0) { throw [PSArgumentException] }

            $this.Major = $this.Major + $By
            $this.Minor = 0
            $this.Patch = 0
        }

        # Increments the Minor component.
        [void] IncrementMinor([int]$By) {
            if ($By -lt 0) { throw [PSArgumentException] }

            $this.Minor = $this.Minor + $By
            $this.Patch = 0
        }

        # Increments the Patch component.
        [void] IncrementPatch([int]$By) {
            if ($By -lt 0) { throw [PSArgumentException] }

            $this.Patch = $this.Patch + $By
        }

    #endregion
}

# An implementation of semantic versioning.
class SemanticVersion : CoreVersion, System.IComparable, System.IEquatable[System.Object] {
    [string]$PreReleaseLabel
    [string]$BuildLabel

    hidden static [string]$SemanticRegEx = (
        '^(?<Major>0|[1-9]\d*)(?:\.(?<Minor>0|[1-9]\d*))?(?:\.(?<Patch>0|[1-9]\d*))?' +
         '(?:-(?<Prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?' +
         '(?:\+(?<Metadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
    )

    hidden static [string]$LabelRegEx = (
        '^(?:-?(?<Prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?' +
         '(?:\+(?<Metadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
    )

    hidden static [string]$PrereleaseRegEx = '^-?(?<Prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)$'
    hidden static [string]$MetadataRegEx = '^\+?(?<Metadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*)$'

    hidden [string]$PreLabelPropertyName = 'PSSemVerPreReleaseLabel'
    hidden [string]$BuildLabelPropertyName = 'PSSemVerBuildLabel'
    hidden [string]$TypeNameForVersionWithLabel = 'System.Version#IncludeLabel'

    #region Constructors

        # Construct a SemanticVersion from a string.
        SemanticVersion([string]$Version) {
            $semver = [SemanticVersion]::Parse($Version)

            $this.Major = $semver.Major
            $this.Minor = $semver.Minor
            $this.Patch = $semver.Patch

            $this.PreReleaseLabel = $semver.PreReleaseLabel
            $this.BuildLabel = $semver.BuildLabel
        }

        # Construct a SemanticVersion.
        SemanticVersion([int]$Major, [int]$Minor, [int]$Patch, [string]$Prerelease, [string]$Metadata) : base($Major, $Minor, $Patch) {
            if ($Prerelease.EndsWith('-') -or $Metadata.EndsWith('-')) { throw [FormatException] }

            if (-not [string]::IsNullOrWhiteSpace($Prerelease)) {
                if ([regex]::IsMatch($Prerelease, [SemanticVersion]::PrereleaseRegEx)) {
                    $this.PreReleaseLabel = $Prerelease -replace '^-'
                }
                else { throw [FormatException] }
            }

            if (-not [string]::IsNullOrWhiteSpace($Metadata)) {
                if ([regex]::IsMatch($Metadata, [SemanticVersion]::MetadataRegEx)) {
                    $this.BuildLabel = $Metadata -replace '^\+'
                }
                else { throw [FormatException] }
            }
        }

        # Construct a SemanticVersion.
        SemanticVersion([int]$Major, [int]$Minor, [int]$Patch, [string]$Label) : base($Major, $Minor, $Patch) {
            if ($Label.EndsWith('-')) { throw [FormatException] }

            if (-not [string]::IsNullOrWhiteSpace($Label)) {
                if ([regex]::IsMatch($Label, [SemanticVersion]::LabelRegEx)) {
                    $match = [regex]::Match($Label, [SemanticVersion]::LabelRegEx)

                    $this.PreReleaseLabel = $match.Groups['Prerelease'].Value
                    $this.BuildLabel = $match.Groups['Metadata'].Value
                }
                else { throw [FormatException] }
            }
        }

        # Construct a SemanticVersion.
        SemanticVersion([int]$Major, [int]$Minor, [int]$Patch) : base($Major, $Minor, $Patch) { }

        # Construct a SemanticVersion.
        SemanticVersion([int]$Major, [int]$Minor) : base($Major, $Minor) { }

        # Construct a SemanticVersion.
        SemanticVersion([int]$Major) : base($Major) { }

        # Construct a SemanticVersion.
        SemanticVersion() : base() { }

        # Construct a SemanticVersion from a System.Version copying the NoteProperty storing the labels if the expected properties exist.
        SemanticVersion([version]$Version) : base($Version) {
            $object = New-Object -TypeName PSObject -ArgumentList $Version

            $label = $object.PSObject.Properties[$this.PreLabelPropertyName]
            if ($null -ne $label) { $this.PreReleaseLabel = $label.Value -as [string] }

            $label = $object.PSObject.Properties[$this.BuildLabelPropertyName]
            if ($null -ne $label) { $this.BuildLabel = $label.Value -as [string] }
        }

    #endregion

    #region Methods

        # Convert a SemanticVersion to System.Version preserving the prerelease and metadata labels.
        static [version] op_Implicit([SemanticVersion]$Version) {
            $result = New-Object -TypeName Version -ArgumentList ($Version.Major, $Version.Minor, $Version.Patch)

            if ($Version.PreReleaseLabel -or $Version.PreReleaseLabel) {
                $object = New-Object -TypeName PSObject -ArgumentList $result

                if (-not [string]::IsNullOrWhiteSpace($Version.PreReleaseLabel)) {
                    $object.PSObject.Properties.Add((
                        New-Object -TypeName PSNoteProperty -ArgumentList (
                            $Version.PreLabelPropertyName, $Version.PreReleaseLabel
                        )
                    ))
                }

                if (-not [string]::IsNullOrWhiteSpace($Version.PreReleaseLabel)) {
                    $object.PSObject.Properties.Add((
                        New-Object -TypeName PSNoteProperty -ArgumentList (
                            $Version.BuildLabelPropertyName, $Version.BuildLabel
                        )
                    ))
                }

                $object.PSObject.TypeNames.Insert(0, $Version.TypeNameForVersionWithLabel)
            }

            return $result
        }

        # Parse version and return the result if it is a valid SemanticVersion, otherwise throws an exception.
        static [SemanticVersion] Parse([string]$Version) {
            if ($null -eq $Version) { throw [PSArgumentNullException] }
            if ([string]::Empty -eq $Version) { throw [FormatException] }

            $canthrow = $true
            $parsedVersion = $null

            [SemanticVersion]::TryParseVersion($Version, [ref]$parsedVersion, $canThrow)

            return $parsedVersion
        }

        # Parse version and return true if it is a valid SemanticVersion, otherwise return false.
        static [bool] TryParse([string]$Version, [ref]$Result) {
            if ($null -ne $Version) {

                $canThrow = $false
                $parsedVersion = $null

                if ([SemanticVersion]::TryParseVersion($Version, [ref]$parsedVersion, $canThrow)) {
                    $Result.Value = $parsedVersion
                    return $true
                }
            }

            $Result.Value = $null
            return $false
        }

        hidden static [bool] TryParseVersion([string]$Version, [ref]$Result, [bool]$CanThrow) {
            if ($Version.EndsWith('-') -or $Version.EndsWith('+') -or $Version.EndsWith('.')) {
                if ($CanThrow) { throw [FormatException] }
                else {
                    $Result.Value = $null
                    return $false
                }
            }

            if ([regex]::IsMatch($Version, [SemanticVersion]::SemanticRegEx)) {
                $match = [regex]::Match($Version, [SemanticVersion]::SemanticRegEx)

                $semver = [SemanticVersion]::new(
                    $match.Groups['Major'].Value,
                    $match.Groups['Minor'].Value,
                    $match.Groups['Patch'].Value
                )

                $semver.PreReleaseLabel = $match.Groups['Prerelease'].Value
                $semver.BuildLabel = $match.Groups['Metadata'].Value

                $Result.Value = $semver
                return $true
            }
            elseif ($CanThrow) { throw [FormatException] }
            else {
                $Result.Value = $null
                return $false
            }
        }

        # Implement ToString()
        [string] ToString() { return $this.ToString(5) }

        # Implement ToString()
        [string] ToString([int]$Fields) {
            if ($Fields -notin 1..5) { throw [PSArgumentOutOfRangeException] }

            $version = [string]::Empty

            if ($Fields -ge 1) { $version = $this.Major }
            if ($Fields -ge 2) { $version = $version, $this.Minor -join '.' }
            if ($Fields -ge 3) { $version = $version, $this.Patch -join '.' }

            if (($Fields -ge 4) -and $this.PreReleaseLabel) {
                $version = $version, $this.PreReleaseLabel -join '-'
            }

            if (($Fields -eq 5) -and $this.BuildLabel) {
                $version = $version, $this.BuildLabel -join '+'
            }

            return $version
        }

        #region Comparisons

            # Implement Compare.
            static [int] Compare([SemanticVersion]$VersionA, [SemanticVersion]$VersionB) {
                if ($null -ne $VersionA) { return $VersionA.CompareTo($VersionB) }
                if ($null -ne $VersionB) { return -1 }

                return 0
            }

            # Implement IComparable.CompareTo[System.Object]
            [int] CompareTo([object]$Version) {
                if ($null -eq $Version) { return 1 }
                if ($null -eq [SemanticVersion]$Version) { return 1 }

                return $this.CompareTo($Version -as [SemanticVersion])
            }

            # Implement IComparable.CompareTo[CoreVersion]
            [int] CompareTo([SemanticVersion]$Version) {
                if ($null -eq [object]$Version) { return 1 }

                if ($this.Major -ne $Version.Major) {
                    if ($this.Major -gt $Version.Major) { return 1 } else { return -1 }
                }

                if ($this.Minor -ne $Version.Minor) {
                    if ($this.Minor -gt $Version.Minor) { return 1 } else { return -1 }
                }

                if ($this.Patch -ne $Version.Patch) {
                    if ($this.Patch -gt $Version.Patch) { return 1 } else { return -1 }
                }

                return [SemanticVersion]::ComparePrerelease($this.PreReleaseLabel, $Version.PreReleaseLabel)
            }

            # Override System.Object.Equals[System.Object]
            [bool] Equals([object]$Version) {
                $semver = $Version -as [CoreVersion]

                return (
                    ($null -ne $Version) -and ($this.Major -eq $semver.Major) -and
                    ($this.Minor -eq $semver.Minor) -and ($this.Patch -eq $semver.Patch) -and
                    [string]::Equals($this.PreReleaseLabel, $semver.PreReleaseLabel, [System.StringComparison]::Ordinal)
                )
            }

            # Override System.Object.GetHashCode
            [int] GetHashCode() { return $this.ToString().GetHashCode() }

        #endregion

        hidden static [int] ComparePrerelease([string]$PrereleaseA, [string]$PrereleaseB) {
            <#
                Pre-release versions have a lower precedence than the associated normal version.
                Comparing each dot separated identifier from left to right until a difference is found as follows:

                    identifiers consisting of only digits are compared numerically and
                    identifiers with letters or hyphens are compared lexically in ASCII sort order.

                Numeric identifiers always have lower precedence than non-numeric identifiers.
                A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal.
            #>

            if ([string]::IsNullOrWhiteSpace($PrereleaseA)) {
                if ([string]::IsNullOrWhiteSpace($PrereleaseB)) { return 0 } else { return 1 }
            }

            if ([string]::IsNullOrWhiteSpace($PrereleaseB)) { return -1 }

            $unitsA = $PrereleaseA.Split('.')
            $unitsB = $PrereleaseB.Split('.')

            if ($unitsA.Length -lt $unitsB.Length) {
                $minimumLength = $unitsA.Length
            }
            else {
                $minimumLength = $unitsB.Length
            }

            for ($i = 0; $i -lt $minimumLength; $i++) {
                $componentA = $unitsA[$i]
                $componentB = $unitsB[$i]

                $numberA = [int]::empty
                $numberB = [int]::empty

                $isNumberA = [int]::TryParse($componentA, [ref]$numberA)
                $isNumberB = [int]::TryParse($componentB, [ref]$numberB)

                if ($isNumberA -and $isNumberB) {
                    if ($numberA -ne $numberB) {
                        if ($numberA -lt $numberB) { return -1 } else { return 1 }
                    }
                }
                else {
                    if ($isNumberA) { return -1 }
                    if ($isNumberB) { return 1 }

                    $result = [string]::CompareOrdinal($componentA, $componentB)

                    if ($result -ne 0) { return $result }
                }
            }

            return $unitsA.Length.CompareTo($unitsB.Length)
        }

    #endregion
}
