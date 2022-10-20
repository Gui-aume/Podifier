Podifier for Perl
=================

Made by Gui-aume

## Description

This script build the HTML from POD of a Perl project with pod2html.

It builds the directories tree with the files for each module and a summary page to navigate through them.

```
Example with: myPackage::test::fcts.pm
Will create this path: html/myPackage/test/fcts.html
And an index: html/index.html
```

## Required

Perl  
pod2html

## Usage

./Podify.pl <path/to/project/modules>