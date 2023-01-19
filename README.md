## Frugivore DB Geodiv Model - code refactor

This is a temporary repository to hold modified scripts. 

The original code is from Beth Gerstner's GeoDiv repository : https://github.com/bgerstner90/geodiv

The file `geodiv_model_eval.R` is a refactor of [chapter_1 test_model_evaluation.R](https://github.com/bgerstner90/geodiv/blob/master/chapter_1/rcode/test_model_evaluation.R#L91)

### Status

- The data reading and processing functions are working independent of species and tested
- start on documentation (this readme)
- the main model run function is written but untested
- needs to be adapted to accept different radii
- main function to set the species, the radius and run all the steps needs to be written and tested

### Requirements

#### **Java **

**MacOS:**  On M1 mac you must compile java, and so it's recommended to use the homebrew package manager which sets all system variables correctly, installs the many other things required by Java, and will pickup the correct version for your Mac.  Current version as of this is 19

 `brew install openjdk@19  # which takes a long time`

On ARM/Apple Silicon and because Mac, that's still not enough.  Then you need to have administrator privileges on the mac, and in the terminal run the following I had to also to the following: 

```Bash
# add it to the path
echo 'export PATH="/opt/homebrew/opt/openjdk/bin:$PATH" >> ~/.zshrc
# tell mac to use it 
sudo ln -sfn $(brew --prefix)/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
# tell mac to find it
echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >> ~/.zshrc
```

On Intel Mac, you may be able to just install the standard version of Java which sets these things automatically. 


**Windows:**  go to https://learn.microsoft.com/en-us/java/openjdk/download and download the latest "MSI" version available.  Currently that's

`Windows 	x64 	msi 	microsoft-jdk-17.0.5-windows-x64.msi`


double click the MSI to install it

**HPCC:**  Java is installed on the HPCC and RJava is also installed with several of the versions of R, vesion 4.0.2 for sure. 

#### **R Libs:** This script requires the following R libs to be installed: 

 - rJava
 - dismo
 - [ENMeval](https://jamiemkass.github.io/ENMeval/index.html)
 - wallace
 - Maxent Java jar file,latest version avaiable for download on https://biodiversityinformatics.amnh.org/open_source/maxent/  
     - ENMeval does not seem to have directions for installing this, but see this post: https://stackoverflow.com/questions/44813048/maxent-rjava-situation-1001
     - the download above will download a zip file.  Unzip teh file and find the `maxent.jar` file inside the zip folder.   
  
Test that you can use Java properly in R

In the R console: 

```R  
requireNamespace('rJava')
# should be no error
rJava::.jpackage('dismo')
# also no error message. 
```

To run the model code you must

1. install packages, you may try to use the `renv` package for that: 
   ```R
   install.packages('renv')
   renv::init()
   ```
1. copy the file `maxent.jar` to the place it needs to be.  Make sure dismo is installed first and Java is working
    1. find the folder where dismo uses for Java.  In the R console use the command `system.file("java", package="dismo")`
    1. copy the file `maxent.jar` (out of the zip file if necessary) to the folder list above.  You can copy/paste the folder into windows explorer bar or using the mac terminal
1. get the CHELSA and pre-thinned rasters files accessible to your computer ( currently on ) 
1. edit the file `.Renviron` and change the path for the 'base_path' to match where the data is
    1. current location on the MSU HPCC is /mnt/research/plz-lab/DATA/bg_geodiversity
    1. if mounted on your computer use /Volumes/plz-lab/DATA/bg_geodiversity or ? for PC
1. Restart R if necessary to re-read the changes in `.Renviron`

There are unit tests for functions in the `/tests` folder.  To run the tests : 


1. install the testing package `install.packages('testthat')`
1. ensure the .Renviron file has the correct BASE_PATH set ( for my laptop, after mounting HPC drive this is `BASE_PATH="/Volumes/plz-lab/DATA/bg_geodiversity"` )
1. in the R console, use `testthat::test_file('tests/test_geodiv_model_eval.R')` or in Rstudio, open the file [tests/test_geodiv_model_eval.R] and click 'run tests' at the top. 
1. if the data files are not accessible to the program there will many errors


