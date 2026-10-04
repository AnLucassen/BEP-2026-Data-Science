# subgroupsem: Subgroup Discovery in Structural Equation Models
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

subgroupsem is an R package for discovering interesting subgroups with distinct sets of parameters in structural equation models (SEM). It can be installed via GitHub.

## Install `subgroupsem`
`subgroupsem` is currently not on CRAN. The development version of `subgroupsem` can be installed directly from this GitHub repository using the additional package `devtools`. Under Windows, please make sure Rtools (http://cran.r-project.org/bin/windows/Rtools) is installed and no older version of `subgroupsem` is currently loaded. Also, make sure that the packages `lavaan` (structural equation modeling) and `reticulate` (python interface) are installed.

```
# install reticulate
install.packages("reticulate")
# install lavaan
install.packages("lavaan")
# install devtools
install.packages("devtools")

# install subgroupsem
devtools::install_github("langenberg/subgroupsem")
```

## Install Python

Please make sure that you installed a python distribution. Python is not included in the `subgroupsem` package. You can either install python separately or use `miniconda` which can be installed using the `reticulate` package:

```
reticulate::install_miniconda()
```

For more information, we would like to refer the reader to [`reticulate`](https://rstudio.github.io/reticulate/reference/install_miniconda.html) website.

## Install Python Module `pysubgroup`

Lastly, you need to install the python module `pysubgroup`. You can either do this yourself using `reticulate`:

```
reticulate::py_install("pysubgroup==0.7.2", pip = T)
```

Or you can have `subgroupsem` install the python module for you. When you run the `subgroupsem()` function (or one of the wrapper function, e.g., `subsem()`) and `pysubgroup` is not installed, you will be asked to install the module:

```
Python module 'pysubgroup' not installed. Do you want to install now? (y/n) 
```

Simply confirm by typing `y`.


## Run subgroupsem

The main function of the package is `subgroupsem()`. The documentation of this function helps to introduce you to its functionality.

 If you decided to use `miniconda`, do not forget to run the command `use_miniconda()` after you loaded `subgroupsem`. This has to be done again every time you loaded `subgroupsem`.
