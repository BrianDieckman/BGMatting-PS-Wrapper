# BGMatting-PS-Wrapper
A PowerShell script that wraps senguptaumd Background-Matting for easier use.

By Brian Dieckman

## Summary ##
- [What](#what)
- [Why](#why)
- [Installation](#install)
- [Use](#use)
- [Related](#related)

## What is this thing? ##
Just a PowerShell script... I'm a Windows user for the most part and more familiar with PS than Bash or Python. In order to use it you need PowerShell installed, allong with all the necessary components from [this excellent project](https://github.com/senguptaumd/Background-Matting). It makes use of the project easier by giving you several ways to organize your work.

## Why did you make it? ##
I wanted to experiment with the project and endlessly renaming files was becoming tiresome. I also wanted to be able to leave my source assets alone and still get good output. Also, the terminology used in the industry for this technique is reinforced by the script's conventions. Finally, orientation matters in segmentation and file format matters to the Python scripts. Both of these are solved via this script.

## Installation ##
Ensure PowerShell 4 or higher is installed on the machine where the matting project is configured. (The script was developed in V5.1) Copy the aiclean.ps1 powershell script into the root of the project folder. That's all. If you need instructions on installing the Background-Matting project on Windows, see the "Related" section below.

## Use ##
There are 3 ways to use the script:
### Prompt (most cumbersome) ###
  - First launch your Anaconda Environment into a Terminal.
  - At the command prompt, run:
```
powershell.exe aiclean.ps1
```
This will prompt you for all the necessary files. Watch the command window for prompts. SINGLE FILE MODE: only one subject image can be processed at a time using this method.
  
### Command Line Switches (most typing) ###
  - First launch your Anaconda Environment into a Terminal.
  - At the command prompt, run:
```
powershell.exe aiclean.ps1 -commandSwitches...
```
Supported command switches are:
- Plate ([Path] or [File]) This is the path to the plate. (Background or scene without the subject) If you specify a path, the path will be searched for a file with the name "\*\_plate.\*"
- Subject ([Path] or [File]) This is the path to your subject photo. If you specify a path, all files (except \_plate and \_background) will be used.
- Background ([Path] or [File]) This is the path to your desired background. If you specify a path, the path will be searched for a file with the name "\*\_background.\*"
- Output ([Path]) Where you want the output files to land.
- _One additional command line switch "Jobfolder" is supported; described in the next section._
    
### Job Folder (most convenient) ###
  - First launch your Anaconda Environment into a Terminal.
  - At the command prompt, run:
```
powershell.exe aiclean.ps1 -Jobfolder [Path]
```
The path specified will be searched for \*\_background.\* and \*\_plate.\* image files; all other image files will be used as subjects. The default output folder of [Path]\\output is used for output files. In this way you can put all your assets into one folder, rename only two of the files then specify just one folder in the argument to the script.
