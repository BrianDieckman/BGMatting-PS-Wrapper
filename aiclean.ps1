<#
.Synopsis
   Images are masked via AI assisted cleanplating.
.DESCRIPTION
   A source background image, a source subject image and a background to be composed
   are provided via command line arguments. A composed image is output.
.EXAMPLE
   powershell.exe aiclean.ps -Plate "C:\images\bg.png" -Subject "C:\photos\sally.jpg" -Background "\\production\backgrounds\bg003.jpg" -Output "C:\images\output\filename.png"
#>
param ([string]$Plate,
       [string]$Subject,
       [string]$Background,
       [string]$Output,
       [string]$Jobfolder)

function Clean-Plate
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Provide a path to a plate image. (Background with no subject)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='ParamSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Plate")] 
        [System.IO.FileInfo]$P,

        # Provide a path to a subject image. (On the same plate)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='ParamSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Subject")] 
        [System.IO.FileInfo]$S,

        # Provide a path to a background image. (The image onto which the subject should be composed)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2,
                   ParameterSetName='ParamSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Background")] 
        [System.IO.FileInfo]$B,

        # Provide a path to output. (Composed image and other)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3,
                   ParameterSetName='ParamSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Output")] 
        [System.IO.FileInfo]$O,

        # Job folder support (all files in one spot)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4,
                   ParameterSetName='ParamSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Jobfolder")] 
        [System.IO.FileInfo]$J
    )

    Begin
    {

        # Globals
        [System.IO.DirectoryInfo]$appPath = if ($psISE) { Split-Path -Path $psISE.CurrentFile.FullPath } else { $PSScriptRoot }
        [System.IO.DirectoryInfo]$tmpPath = "$($appPath.FullName)\TMP"
        [string]$platefilter = "*_plate.*"
        [string]$subjectfilter = "*.*"
        [string]$backgroundfilter = "*_background.*"

        # Prepare workspace
        if (Test-Path $tmpPath) {
            Write-Host "Cleaning up TMP directory..."
            Get-ChildItem -Path $tmpPath.FullName -Include *.* -Recurse | Remove-Item
        } else {
            Write-Host "Creating TMP directory..."
            New-Item -Path $tmpPath -ItemType "directory"
            New-Item -Path "$($tmpPath)\bg" -ItemType "directory"
            New-Item -Path "$($tmpPath)\plt" -ItemType "directory"
            New-Item -Path "$($tmpPath)\out" -ItemType "directory"

        }
        
        # Check output directory
        if (-Not $(Test-Path $Output)) {
            Write-Host "Creating output directory"
            New-Item -Path $Output -ItemType "directory"
        } else {
            if ([System.IO.Directory]::GetFiles("$Output","*.*").Count -gt 0) {Throw "Output directory must be empty. Aborting."}
        }

        # Check plate file (or directory)
        if (Test-Path $Plate) {
            # Path exists
            if (Test-Path $Plate -PathType Container) {
                # Plate path is a directory. Look for a file named ..._plate.*
                Write-Host "$($Plate) is a directry. Looking for one _plate.* file."
                $PlateFiles = [System.IO.Directory]::GetFiles("$Plate","$platefilter").Count
                if ($plateFiles -eq 1) {
                    # There's only one plate file. Set the $Plate variable to that path
                    $Plate = Get-ChildItem -Path $Plate -Filter $platefilter
                } else {
                    # Zero or more than one plate file found in the directory
                    Throw "Zero or more than one plate files found in the directory. Exactly one _plate.* file must be present."
                }
            }

            # Store the plate file in the temp directory 
            Write-Host "Using $($Plate) as plate."
            $plateFile = $Plate

        } else {
            Throw "File $($Plate) does not exist. Aborting."
        }

        # Handle subject file (or directory)
        if (Test-Path $Subject) {
            # Path exists
            if (Test-Path $Subject -PathType Container) {
                # Subject path is a directory. Include all files.
                Write-Host "$($Subject) is a directry. Ignoring _plate.* files, including all others."
                $subjectFiles = [System.IO.Directory]::GetFiles("$Subject","$subjectfilter")

                # Ignore plates and backgrounds. (To support single-folder operation)
                $newSubjectFiles = @()
                foreach ($subjectFile in $subjectFiles)
                {
                    if ($subjectFile -NotLike "*_plate*" -And $subjectFile -NotLike "*_background*") {$newSubjectFiles += $subjectFile}
                }
                
                $subjectFiles = $newSubjectFiles                

                # Handle empty directory
                if ($subjectFiles.Count -lt 1) {Throw "Zero subject files found in the directory. One or more files must be present. (Files can not be named ..._plate or ..._background."}

                Write-Host "$($subjectFiles.Count) subject file(s) found."
            } else {
                # Subject path is a single file
                $subjectFiles = $Subject
                Write-Host "Using $($subjectFiles) as subject." 
            }
        } else {
            Throw "$($Subject) does not exist. Aborting."
        }

        # Check background file (or directory)
        if (Test-Path $Background) {
            # Path exists
            if (Test-Path $Background -PathType Container) {
                # Background path is a directory. Look for a file named ..._background.*
                Write-Host "$($Background) is a directry. Looking for one _background.* file."
                $backgroundFiles = [System.IO.Directory]::GetFiles("$Background","$backgroundfilter").Count
                if ($backgroundFiles -eq 1) {
                    # There's only one background file. Set the $Background variable to that path
                    $Background = Get-ChildItem -Path $Background -Filter $backgroundfilter
                } else {
                    # Zero or more than one plate file found in the directory
                    Throw "Zero or more than one background files found in the directory. Exactly one _background.* file must be present."
                }
            }

            # Store the plate file in the temp directory 
            Write-Host "Using $($Background) as background."
            $backgroundFile = $Background

        } else {
            Throw "File $($Background) does not exist. Aborting."
        }
     }   

    Process
    {
        Write-Host "Copying $($plateFile) to temporary storage."
        $plateFile = TMP-Image -inPath $Plate -outPath $tmpPath -imgType "plate"
        
        Foreach ($subjectFile in $subjectFiles) {
            [System.io.FileInfo]$subjectFile = $subjectFile
            Write-Host "Copying $($subjectFile.Name) to temporary storage."
            TMP-Image -inPath $subjectFile.FullName -outPath $tmpPath -imgType "subject"

            Write-Host "Creating corresponding plate in storage."
            $dest = ($tmpPath.FullName)+"\"+($subjectFile.Basename)+"_back.png"

            Copy-Item $plateFile -Destination $dest
        }

        Write-Host "Copying $($backgroundFile.Name) to temporary storage."
        $backgroundFile = TMP-Image -inPath $backgroundFile -outPath $tmpPath -imgType "background"

        # These are the commands that call the python scripts
        # Actions are carried out in the TMP directory.

        Set-Location -Path $appPath

        Write-Host "============== Creating segmentation mask =================="
        python test_segmentation_deeplab.py -i TMP
        Write-Host "============== Aligning plates to subjects ================="
        python test_pre_process.py -i TMP
        Write-Host "================= Composing new images ====================="
        python test_background-matting_image.py -m syn-comp-adobe -i TMP/ -o TMP/out/ -tb $backgroundFile

    }


    End
    {
            
        # Move stuff
        
        Copy-Item -Path "$($tmpPath)\out\*.*" -Destination $Output

    }
}

function Test-Image($Path) {

    $knownHeaders = @{
        jpg = @( "FF", "D8" );
        bmp = @( "42", "4D" );
        gif = @( "47", "49", "46" );
        tif = @( "49", "49", "2A" );
        png = @( "89", "50", "4E", "47", "0D", "0A", "1A", "0A" );
        pdf = @( "25", "50", "44", "46" );
    }

    # read in the first 8 bits
    $bytes = Get-Content -LiteralPath $Path -Encoding Byte -ReadCount 1 -TotalCount 8 -ErrorAction Ignore
    $retval = $false

    foreach($key in $knownHeaders.Keys) {
        # make the file header data the same length and format as the known header
        $fileHeader = $bytes |
            Select-Object -First $knownHeaders[$key].Length |
            ForEach-Object { $_.ToString("X2") }

        if($fileHeader.Length -eq 0) {
            continue
        }

        # compare the two headers
        $diff = Compare-Object -ReferenceObject $knownHeaders[$key] -DifferenceObject $fileHeader
        if(($diff | Measure-Object).Count -eq 0) {
            $retval = $key
        }
    }
    return $retval
}

function TMP-Image($inPath, $outPath, $imgType) {
    Add-Type -AssemblyName system.drawing
    [System.io.FileInfo]$inputPath = $inPath
    
    [string]$imgFormat = Test-Image $inputPath.FullName
    if (-Not $imgFormat) {Throw "$inPath is not a reccognized image type. Aborting."}
    if ($imgFormat -ne "png") {Write-Host "Converting $($inputPath.Name) to PNG"}

    $imageFormat = “System.Drawing.Imaging.ImageFormat” -as [type]
    $image = [drawing.image]::FromFile($inputPath.FullName)

    if ($image.Width -gt $image.Height) {
        Write-Host "Vertical orientation selected. Rotating image."
        $image.RotateFlip("Rotate270FlipNone")
    }
    
    Switch ($imgType) {
        "plate" {$append = "_back"}
        "subject" {$append = "_img"}
        "background" {$append = ""}
    }

    Switch ($imgType) {
        "plate" {$subf = "plt\"}
        "subject" {$subf = ""}
        "background" {$subf = "bg\"}
    }

    $outPath = $outPath.FullName+"\"+($subf)+($inputPath.Basename )+$($append)+".png"

    $image.Save($outPath, $imageFormat::png)
    
    return $outPath
}

Function Get-FileName($initialDirectory) {  
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = “All files (*.*)| *.*”
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

Function Get-FolderName() {  
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
 Out-Null

 $ChooseFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
 $ChooseFolderDialog.RootFolder = "MyComputer"
 $ChooseFolderDialog.ShowDialog() | Out-Null
 $ChooseFolderDialog.SelectedPath
}

try {

    if (-Not $Jobfolder) {
        if (-Not $Plate) {
            Write-Host "No Plate file specified: please choose one."
            $Plate = Get-FileName -initialDirectory $appPath
        }
        if (-Not $Subject) {
            Write-Host "SINGLE IMAGE MODE. To process multiple images, specify a folder in the arguments when calling this script."
            Write-Host "No Subject file specified: please choose one."
            $Subject = Get-FileName -initialDirectory $appPath
        }
        if (-Not $Background) {
            Write-Host "No Background file specified: please choose one."
            $Background = Get-FileName -initialDirectory $appPath
        }
        if (-Not $Output) {
            Write-Host "No Output folder specified: please choose one."
            $Output = Get-FolderName
        }
    } else {
        $Plate = $Jobfolder
        $Subject = $Jobfolder
        $Background = $Jobfolder
        $Output = "$($Jobfolder)\output"
    }
    
    $t = Clean-Plate -Plate $Plate -Subject $Subject -Background $Background -Output $Output

} catch {

    # Fatal script error. Log it.
    Write-Host "Fatal error - stopping script: $_"

}

##########################################################################################
##
##
##  Changelog
##
## 6/01/2020 BD: Initial release
##
##########################################################################################