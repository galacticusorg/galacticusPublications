# Galacticus Publications

This repo contains parameter files and commit details for Galaticus models used in published papers. 

Subfolders (organized by publication year) contain a readme file that specifies the name, author, and year of the publication, URLs to arXiv, NASA ADS, and journal copies of the paper, the Galacticus commit hash that was used to run models, and any other pertinent information. Any parameter files used to run the models are also included in the subfolder.

The `publications.xml` file contains the same information in machine readable form.

The commit used to run models in a given paper is also tagged in the [Galacticus repo](https://github.com/galacticusorg/galacticus), as follows:
* [arXiv](https://arxiv.org/) number: `publication/arXiv/XXXX.XXXXX`
* [NASA ADS](https://ui.adsabs.harvard.edu/) [bibcode](https://ui.adsabs.harvard.edu/help/actions/bibcode): `publication/bibcode/YYYYJJJJJVVVVMPPPPA`
  * Note that `git` tags do not allow consecutive `.`s, which can appear in NASA ADS bibcodes. Therefore, `.` is replaced by `_` in these tags.
* [Digital Object Identifier](https://www.doi.org/) (DOI): `publication/doi/XX.XXXX/XXXXX`
thereby allowing the relevant commit to be found easily.
