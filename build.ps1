﻿properties {
    $ProductName = "NLog.Targets.Gelf"
    $BaseDir = Resolve-Path "."
    $SolutionFile = "$BaseDir\NLog.Targets.Gelf.sln"
    $OutputDir = "$BaseDir\Deploy\Package\"
    # Gets the number of commits since the last tag. 
    $Version = "0.2.1.0"
    $BuildConfiguration = "Release"
    
    $NuGetPackageName = "NLog.Targets.Gelf"
    $NuGetPackDir = "$OutputDir" + "Pack"
    $NuSpecFileName = "NLog.Targets.Gelf.nuspec"
    $NuGetPackagePath = "$OutputDir" + $NuGetPackageName + "." + $Version + ".nupkg"
    
    $ArchiveDir = "$OutputDir" + "Archive"
    $ToolsDir = "$BaseDir\Tools"
}

Framework '4.0'

task default -depends Pack

task Init {
}

task Clean -depends Init {
    if (Test-Path $OutputDir) {
        ri $OutputDir -Recurse
    }
    
    ri "$NuGetPackageName.*.nupkg"
    ri "$NuGetPackageName.zip" -ea SilentlyContinue
}

task Build -depends Init,Clean {
    exec { msbuild $SolutionFile "/p:OutDir=$OutputDir" "/p:Configuration=$BuildConfiguration" }
}

task ILRepack -depends Build {
    exec { & "$ToolsDir\ILRepack.exe" /t:library /log /internalize /out:$OutputDir\NLog.Targets.Gelf.dll $OutputDir\NLog.Targets.Gelf.dll $OutputDir\Newtonsoft.Json.dll $OutputDir\NLog.dll}
}

task Pack -depends ILRepack {
    mkdir $NuGetPackDir
    cp "$NuSpecFileName" "$NuGetPackDir"

    mkdir "$NuGetPackDir\lib\net40"
    cp "$OutputDir\NLog.Targets.Gelf.dll" "$NuGetPackDir\lib\net40"

    $Spec = [xml](get-content "$NuGetPackDir\$NuSpecFileName")
    $Spec.package.metadata.version = ([string]$Spec.package.metadata.version).Replace("{Version}",$Version)
    $Spec.Save("$NuGetPackDir\$NuSpecFileName")

    exec { .\.nuget\nuget pack "$NuGetPackDir\$NuSpecFileName" -OutputDirectory "$OutputDir" }
}

task Publish -depends Pack {
    exec { .\.nuget\nuget push $NuGetPackagePath }
}
