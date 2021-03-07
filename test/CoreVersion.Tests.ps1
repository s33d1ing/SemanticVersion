# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
using namespace System.Management.Automation
using namespace System.Management.Automation.Language


#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.4" }

$ModuleManifestName = "SemanticVersion.psd1"
$ModuleManifestPath = "$PSScriptRoot\..\SemanticVersion\$ModuleManifestName"

Import-Module -FullyQualifiedName $ModuleManifestPath -Force


Describe "CoreVersion api tests" -Tags "CI" {
    Context "Constructing valid versions" {
        It "String argument constructor" {
            $v = [CoreVersion]::new("1.2.3")
            $v.Major | Should -Be 1
            $v.Minor | Should -Be 2
            $v.Patch | Should -Be 3
            $v.ToString() | Should -Be "1.2.3"

            $v = [CoreVersion]::new("1.0.0")
            $v.Major | Should -Be 1
            $v.Minor | Should -Be 0
            $v.Patch | Should -Be 0
            $v.ToString() | Should -Be "1.0.0"

            $v = [CoreVersion]::new("3.0")
            $v.Major | Should -Be 3
            $v.Minor | Should -Be 0
            $v.Patch | Should -Be 0
            $v.ToString() | Should -Be "3.0.0"

            $v = [CoreVersion]::new("2")
            $v.Major | Should -Be 2
            $v.Minor | Should -Be 0
            $v.Patch | Should -Be 0
            $v.ToString() | Should -Be "2.0.0"
        }

        # After the above test, we trust the properties and rely on ToString for validation

        It "Int args constructor" {
            $v = [CoreVersion]::new(1, 0, 0)
            $v.ToString() | Should -Be "1.0.0"

            $v = [CoreVersion]::new(3, 1)
            $v.ToString() | Should -Be "3.1.0"

            $v = [CoreVersion]::new(3)
            $v.ToString() | Should -Be "3.0.0"
        }

        It "Version arg constructor" {
            $v = [CoreVersion]::new([Version]::new(1, 2))
            $v.ToString() | Should -Be '1.2.0'

            $v = [CoreVersion]::new([Version]::new(1, 2, 3))
            $v.ToString() | Should -Be '1.2.3'
        }

        It "Can covert to 'Version' type" {
            $v1 = [CoreVersion]::new(3, 2, 1)
            $v2 = [Version]$v1
            $v2.GetType() | Should -BeExactly "version"
            $v2.PSobject.TypeNames[0] | Should -Be "System.Version"
            $v2.Major | Should -Be 3
            $v2.Minor | Should -Be 2
            $v2.Build | Should -Be 1
            $v2.ToString() | Should -Be "3.2.1"
        }

        It "Core version can round trip through version" {
            $v1 = [CoreVersion]::new(3, 2, 1)
            $v2 = [CoreVersion]::new([Version]$v1)
            $v2.ToString() | Should -Be "3.2.1"
        }
    }

    Context "Comparisons" {
        BeforeAll {
            $v1_0_0 = [CoreVersion]::new(1, 0, 0)
            $v1_1_0 = [CoreVersion]::new(1, 1, 0)
            $v1_1_1 = [CoreVersion]::new(1, 1, 1)
            $v2_1_0 = [CoreVersion]::new(2, 1, 0)

            $testCases = @(
                @{ lhs = $v1_0_0; rhs = $v1_1_0 }
                @{ lhs = $v1_0_0; rhs = $v1_1_1 }
                @{ lhs = $v1_1_0; rhs = $v1_1_1 }
                @{ lhs = $v1_0_0; rhs = $v2_1_0 }
                @{ lhs = $v2_1_0; rhs = "3.0" }
                @{ lhs = "1.5"; rhs = $v2_1_0 }
            )
        }

        It "<lhs> less than <rhs>" -TestCases $testCases {
            param($lhs, $rhs)
            $lhs -lt $rhs | Should -BeTrue
            $rhs -lt $lhs | Should -BeFalse
        }

        It "<lhs> less than or equal <rhs>" -TestCases $testCases {
            param($lhs, $rhs)
            $lhs -le $rhs | Should -BeTrue
            $rhs -le $lhs | Should -BeFalse
            $lhs -le $lhs | Should -BeTrue
            $rhs -le $rhs | Should -BeTrue
        }

        It "<lhs> greater than <rhs>" -TestCases $testCases {
            param($lhs, $rhs)
            $lhs -gt $rhs | Should -BeFalse
            $rhs -gt $lhs | Should -BeTrue
        }

        It "<lhs> greater than or equal <rhs>" -TestCases $testCases {
            param($lhs, $rhs)
            $lhs -ge $rhs | Should -BeFalse
            $rhs -ge $lhs | Should -BeTrue
            $lhs -ge $lhs | Should -BeTrue
            $rhs -ge $rhs | Should -BeTrue
        }

        It "Equality <operand>" -TestCases @(
            # @{ operand = $v1_0_0 }
            @{ operand = [CoreVersion]::new(1, 0, 0) }
        ) {
            param($operand)
            $operand -eq $operand | Should -BeTrue
            $operand -ne $operand | Should -BeFalse
            $null -eq $operand | Should -BeFalse
            $operand -eq $null | Should -BeFalse
            $null -ne $operand | Should -BeTrue
            $operand -ne $null | Should -BeTrue
        }

        It "comparisons with null" {
            $v1_0_0 -lt $null | Should -BeFalse
            $null -lt $v1_0_0 | Should -BeTrue
            $v1_0_0 -le $null | Should -BeFalse
            $null -le $v1_0_0 | Should -BeTrue
            $v1_0_0 -gt $null | Should -BeTrue
            $null -gt $v1_0_0 | Should -BeFalse
            $v1_0_0 -ge $null | Should -BeTrue
            $null -ge $v1_0_0 | Should -BeFalse
        }
    }

    Context "Error handling" {

        It "<name>: '<version>'" -TestCases @(
            @{ name = "Missing parts: 'null'"; errorId = "*ArgumentNullException*"; expectedResult = $false; version = $null }
            # @{ name = "Missing parts: 'NullString'"; errorId = "*ArgumentNullException*"; expectedResult = $false; version = [NullString]::Value }
            @{ name = "Missing parts: 'NullString'"; errorId = "*FormatException*"; expectedResult = $false; version = [NullString]::Value }
            @{ name = "Missing parts: 'EmptyString'"; errorId = "*FormatException*"; expectedResult = $false; version = "" }
            @{ name = "Missing parts"; errorId = "*FormatException*"; expectedResult = $false; version = "1..0" }
            @{ name = "Missing parts"; errorId = "*FormatException*"; expectedResult = $false; version = "1.0." }
            @{ name = "Missing parts"; errorId = "*FormatException*"; expectedResult = $false; version = "1.0.." }
            @{ name = "Missing parts"; errorId = "*FormatException*"; expectedResult = $false; version = ".0.0" }
            @{ name = "Range check of versions"; errorId = "*FormatException*"; expectedResult = $false; version = "-1.0.0" }
            @{ name = "Range check of versions"; errorId = "*FormatException*"; expectedResult = $false; version = "1.-1.0" }
            @{ name = "Range check of versions"; errorId = "*FormatException*"; expectedResult = $false; version = "1.0.-1" }
            @{ name = "Format errors"; errorId = "*FormatException*"; expectedResult = $false; version = "aa.0.0" }
            @{ name = "Format errors"; errorId = "*FormatException*"; expectedResult = $false; version = "1.bb.0" }
            @{ name = "Format errors"; errorId = "*FormatException*"; expectedResult = $false; version = "1.0.cc" }
        ) {
            param($version, $expectedResult, $errorId)
            { [CoreVersion]::new($version) } | Should -Throw -ErrorId $errorId
            if ($version -eq $null) {
                # PowerShell convert $null to Empty string
                { [CoreVersion]::Parse($version) } | Should -Throw -ErrorId "*FormatException*"
            } else {
                { [CoreVersion]::Parse($version) } | Should -Throw -ErrorId $errorId
            }
            $coreVer = $null
            [CoreVersion]::TryParse($_, [ref]$coreVer) | Should -Be $expectedResult
            $coreVer | Should -BeNullOrEmpty
        }

        It "Negative version arguments" {
            { [CoreVersion]::new(-1, 0) } | Should -Throw -ErrorId "*ArgumentException*"
            { [CoreVersion]::new(1, -1) } | Should -Throw -ErrorId "*ArgumentException*"
            { [CoreVersion]::new(1, 1, -1) } | Should -Throw -ErrorId "*ArgumentException*"
        }

        It "Incompatible 'Version' throws" {
            # Revision isn't supported
            { [CoreVersion]::new([Version]::new(0, 0, 0, 4)) } | Should -Throw -ErrorId "*ArgumentException*"
            { [CoreVersion]::new([Version]::new("1.2.3.4")) } | Should -Throw -ErrorId "*ArgumentException*"
        }
    }

    Context "Serialization" {
        $testCases = @(
            @{ errorId = "*ArgumentException*"; expectedResult = "1.0.0"; corever = [CoreVersion]::new(1, 0, 0) }
            @{ errorId = "*ArgumentException*"; expectedResult = "1.0.1"; corever = [CoreVersion]::new(1, 0, 1) }
        )
        It "Can round trip: <corever>" -TestCases $testCases {
            param($corever, $expectedResult)

            $ser = [PSSerializer]::Serialize($corever)
            $des = [PSSerializer]::Deserialize($ser)

            $des | Should -BeOfType System.Object
            $des.ToString() | Should -Be $expectedResult
        }
    }
}
