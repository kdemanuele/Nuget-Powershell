get-childitem . -Path *.csproj | select -limit 1 | % {
  nuget spec -f  # The -f is to force file recreation
  $assemblyName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  $nuspec = "$assemblyName.nuspec"
  # Open nuspec file as an XML Document
  [xml]$nuspecXml = (Get-Content $nuspec)

  # Assumption 1 workaround
  $author = ($assemblyInfo -match 'AssemblyCompany\(".*"\)')
  $author = $author -split ('"')
  $author = $author[1]

  If ($author -eq "") {
    $authorNode = $nuspecXml.SelectSingleNode("//authors")
    $authorNode.InnerText = "Authors"

    $ownersNode = $nuspecXml.SelectSingleNode("//owners")
    $ownersNode.InnerText = "Owners"
  }

  $description = ($assemblyInfo -match 'AssemblyDescription\(".*"\)')
  $description = $description -split ('"')
  $description = $description[1]

  If ($description -eq "") {
    $descriptionNode = $nuspecXml.SelectSingleNode("//description")
    $descriptionNode.InnerText = "My Module Description"
  }

  # Assumption 2 workaround
  if (Test-Path ..\nonProjectFiles) {
    $filesNode = $nuspecXml.CreateNode("element", "files", "")
    $fileNode = $nuspecXml.CreateNode("element", "file", "")
    $fileSrcAttribute = $nuspecXml.CreateAttribute("src")
    $fileSrcAttribute.Value = "..\nonProjectFiles\**\*"
    $fileNode.SetAttributeNode($fileSrcAttribute)
    $fileTargetAttribute = $nuspecXml.CreateAttribute("target")
    $fileTargetAttribute.Value = "content\additionalFiles\$assemblyName"
    $fileNode.SetAttributeNode($fileTargetAttribute)
    $filesNode.AppendChild($fileNode)
    $nuspecXml.LastChild.AppendChild($filesNode)
  }

  $nuspecXml.Save($_.Directory.FullName + "\" + $nuspec)

  # Create the nuget package
  nuget pack $_.Name
}
