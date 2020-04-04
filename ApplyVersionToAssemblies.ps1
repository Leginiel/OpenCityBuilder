##-----------------------------------------------------------------------
## <copyright file="ApplyVersionToAssemblies.ps1">(c) Microsoft Corporation. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
##-----------------------------------------------------------------------
# Look for a 0.0.0.0 pattern in the build number. 
# If found use it to version the assemblies.
#
# For example, if the 'Build number format' build process parameter 
# $(BuildDefinitionName)_$(Year:yyyy).$(Month).$(DayOfMonth)$(Rev:.r)
# then your build numbers come out like this:
# "Build HelloWorld_2013.07.19.1"
# This script would then apply version 2013.07.19.1 to your assemblies.

# Enable -Verbose option
[CmdletBinding()]

# Regular expression pattern to find the version in the build number 
# and then apply it to the assemblies
$VersionRegex = "\d+\.\d+\.\d+\.\d+"
$VersionRegexWithoutRevision = "\d+\.\d+\.\d+\."

# If this script is not running on a build server, remind user to 
# set environment variables so that this script can be debugged
if(-not ($Env:BUILD_SOURCESDIRECTORY -and $Env:BUILD_BUILDNUMBER))
{
		Write-Error "You must set the following environment variables"
		Write-Error "to test this script interactively."
		Write-Host '$Env:BUILD_SOURCESDIRECTORY - For example, enter something like:'
		Write-Host '$Env:BUILD_SOURCESDIRECTORY = "C:\code\FabrikamTFVC\HelloWorld"'
		Write-Host '$Env:BUILD_BUILDNUMBER - For example, enter something like:'
		Write-Host '$Env:BUILD_BUILDNUMBER = "Build HelloWorld_0000.00.00.0"'
		exit 1
}

# Make sure path to source code directory is available
if (-not $Env:BUILD_SOURCESDIRECTORY)
{
		Write-Error ("BUILD_SOURCESDIRECTORY environment variable is missing.")
		exit 1
}
elseif (-not (Test-Path $Env:BUILD_SOURCESDIRECTORY))
{
		Write-Error "BUILD_SOURCESDIRECTORY does not exist: $Env:BUILD_SOURCESDIRECTORY"
		exit 1
}
Write-Verbose "BUILD_SOURCESDIRECTORY: $Env:BUILD_SOURCESDIRECTORY"

# Make sure there is a build number
if (-not $Env:BUILD_BUILDNUMBER)
{
		Write-Error ("BUILD_BUILDNUMBER environment variable is missing.")
		exit 1
}
Write-Verbose "BUILD_BUILDNUMBER: $Env:BUILD_BUILDNUMBER"

# Apply the version to the assembly property files
$files = gci $Env:BUILD_SOURCESDIRECTORY -recurse | 
		?{ $_.PSIsContainer } | 
		foreach { gci -Path $_.FullName -Recurse -include *.csproj }
if($files)
{
		foreach ($file in $files) {
				$filecontent = Get-Content($file)
				$VersionData = [regex]::matches($filecontent,$VersionRegexWithoutRevision)
				$NewVersion = $VersionData[0]
				Write-Verbose "VersionData: $NewVersion"
				Write-Verbose "VersionDataxx: $Env:BUILD_BUILDNUMBER"
				$NewVersion = "$NewVersion$Env:BUILD_BUILDNUMBER"
				Write-Verbose "Version: $NewVersion"

				attrib $file -r
				$filecontent -replace $VersionRegex, $NewVersion | Out-File $file
				Write-Verbose "$file.FullName - version applied"
		}

		$Env:BUILD_BUILDNUMBER = $NewVersion
}
else
{
		Write-Warning "Found no files."
}
