This folder contains parameter files for the paper:

* Title: _"Testing warm dark matter with kinematics of the smallest galaxies"_
* Author(s): Delos, Ahvazi & Benson
* Publication year: 2025
* URLs:
  * [arXiv](https://arxiv.org/abs/2512.04156)
  * [NASA ADS](https://ui.adsabs.harvard.edu/abs/2025arXiv251204156D)
  * [Journal](https://iopscience.iop.org/article/10.3847/1538-4357/ae7bed)
  * [DOI](https://doi.org/10.3847/1538-4357/ae7bed)
* Galacticus commit hash: [0925ee9aae2d06dbe86d1f4dee29e93087f62dcf](https://github.com/galacticusorg/galacticus/commit/0925ee9aae2d06dbe86d1f4dee29e93087f62dcf)
* Datasets commit hash: [6cadb6487cd1d3ee531088862493ef12f2cfd407](https://github.com/galacticusorg/datasets/commit/6cadb6487cd1d3ee531088862493ef12f2cfd407)

This directory contains the Galacticus parameter `.xml` files used to produce the model datasets analyzed in the paper.

To run one model copy the template parameter file, set a seed and output filename, then call Galacticus with the changes files in order. Example:

```bash
# run Galacticus with changes files (power-spectrum changes and WDM particle changes)
./Galacticus.exe ./m1e12_WDM_res7_noSatelliteDestruction_1mergerTree.xml ./powerSpectraSuppressed.xml ./warmDarkMatter_cuspUpdate.xml
```

