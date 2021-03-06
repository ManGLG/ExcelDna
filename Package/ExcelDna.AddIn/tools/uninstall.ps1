param($installPath, $toolsPath, $package, $project)
    Write-Host "Starting ExcelDna.AddIn uninstall script"

    $dteVersion = $project.DTE.Version
    $isFSharpProject = ($project.Type -eq "F#")
    $projectName = $project.Name

    # Rename .dna file
    $dnaFileName = "${projectName}-AddIn.dna"
    $dnaFileItem = $project.ProjectItems | Where-Object { $_.Name -eq $dnaFileName }
    if ($null -ne $dnaFileItem)
    {
        Write-Host "`tRenaming -AddIn.dna file"
        # Try to rename the file
        if ($null -eq ($project.ProjectItems | Where-Object { $_.Name -eq "_UNINSTALLED_${dnaFileName}" }))
        {
            $dnaFileItem.Name = "_UNINSTALLED_${dnaFileName}"
        }
        else
        {
            $suffix = 1
            while ($null -ne ($project.ProjectItems | Where-Object { $_.Name -eq "_UNINSTALLED_${suffix}_${dnaFileName}" }))
            {
                $suffix++
            }
            $dnaFileItem.Name = "_UNINSTALLED_${suffix}_${dnaFileName}"
        }
    }

    Write-Host "`Removing build targets from the project"
    
    # Need to load MSBuild assembly if it's not loaded yet
    Add-Type -AssemblyName 'Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'
    
    # Grab the loaded MSBuild project for the project
    $msbuild = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($project.FullName) | Select-Object -First 1
    
    # Find all the imports and targets added by this package
    $itemsToRemove = @()
    
    # Allow many in case a past package was incorrectly uninstalled
    $itemsToRemove += $msbuild.Xml.Imports | Where-Object { $_.Project.EndsWith('ExcelDna.AddIn.targets') }
    $itemsToRemove += $msbuild.Xml.Targets | Where-Object { $_.Name -eq "EnsureExcelDnaTargetsImported" }
    
    # Remove the elements and save the project
    if ($itemsToRemove -and $itemsToRemove.length)
    {
       foreach ($itemToRemove in $itemsToRemove)
       {
           $msbuild.Xml.RemoveChild($itemToRemove) | out-null
       }
       
        if ($isFSharpProject)
        {
            $project.Save("")
        }
        else
        {
            $project.Save()
        }
    }

    Write-Host "Completed ExcelDna.AddIn uninstall script"
