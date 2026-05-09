# Galacticus Publications

This repo contains parameter files and commit details for Galacticus models used in published papers.

Subfolders (organized by publication year) contain a `ReadMe.md` file that specifies the name, author, and year of the publication, URLs to arXiv, NASA ADS, and journal copies of the paper, the Galacticus commit hash that was used to run models, and any other pertinent information. Any parameter files used to run the models are also included in the subfolder.

The `publications.xml` file contains the same information in machine-readable form, and is the source of truth used by automation (see `scripts/updatePublications.pl`). Each `<publication>` element supports the following attributes:

| Attribute | Required | Description |
| --- | --- | --- |
| `title` | yes | Publication title. |
| `author` | yes | Author list (e.g. `Smith et al.`, `Smith & Jones`). Use `&amp;` to encode `&`. |
| `year` | yes | Publication year (journal year if available, otherwise arXiv year). |
| `commit` | yes | Galacticus commit hash used to run the models. |
| `arXiv` | optional | arXiv identifier (`YYMM.NNNNN`). |
| `bibCode` | optional | NASA ADS bibcode. |
| `doi` | optional | DOI of the published version. |
| `journalURL` | optional | URL of the published version on the journal site. |
| `datasetsCommit` | optional | Commit hash of [`galacticusorg/datasets`](https://github.com/galacticusorg/datasets) used to run the models. |

Folder names under each year directory are free-form (e.g. the paper's short title); the year directory itself is the publication year recorded in `publications.xml`.

The commit used to run models in a given paper is also tagged in the [Galacticus repo](https://github.com/galacticusorg/galacticus), as follows:
* [arXiv](https://arxiv.org/) number: `publication/arXiv/XXXX.XXXXX`
* [NASA ADS](https://ui.adsabs.harvard.edu/) [bibcode](https://ui.adsabs.harvard.edu/help/actions/bibcode): `publication/bibcode/YYYYJJJJJVVVVMPPPPA`
  * Note that `git` tags do not allow consecutive `.`s, which can appear in NASA ADS bibcodes. Therefore, `.` is replaced by `_` in these tags.
* [Digital Object Identifier](https://www.doi.org/) (DOI): `publication/doi/XX.XXXX/XXXXX`
thereby allowing the relevant commit to be found easily.
