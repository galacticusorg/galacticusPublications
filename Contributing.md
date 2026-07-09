# Contributing

Have you written a paper that uses [Galacticus](https://github.com/galacticusorg/galacticus)? We'd love to include it here! Adding your paper lets others find the exact version of Galacticus and the parameter files you used, making your results easy to reproduce and build upon.

Contributing takes just a pull request. Here's how.

## What to add

Each publication lives in its own subfolder, organized by publication year (e.g. `2026/My Paper Short Title/`). To add yours, create a new folder and include:

1. **A `ReadMe.md` page** giving the paper's metadata and links, following one of the existing templates (see, for example, [`2026/Stellar Mass Growth in the First Galaxies/ReadMe.md`](2026/Stellar%20Mass%20Growth%20in%20the%20First%20Galaxies/ReadMe.md) or [`2025/Testing WDM with Kinematics of Smallest Galaxies/ReadMe.md`](2025/Testing%20WDM%20with%20Kinematics%20of%20Smallest%20Galaxies/ReadMe.md)). A typical page looks like:

   ```markdown
   This folder contains parameter files for the paper:

   * Title: _"Your Paper Title"_
   * Author(s): Smith & Jones
   * Publication year: 2026
   * URLs:
     * [arXiv](https://arxiv.org/abs/XXXX.XXXXX)
     * [NASA ADS](https://ui.adsabs.harvard.edu/abs/YYYYJJJJJVVVVMPPPPA)
     * [Journal](https://...)
     * [DOI](https://doi.org/XX.XXXX/XXXXX)
   * Galacticus commit hash: [<hash>](https://github.com/galacticusorg/galacticus/commit/<hash>)
   * Datasets commit hash: [<hash>](https://github.com/galacticusorg/datasets/commit/<hash>)

   <A short description of the parameter files below, and any notes on how to run them.>
   ```

   Include whichever URLs are available (arXiv, NASA ADS, journal, and/or DOI), the [Galacticus](https://github.com/galacticusorg/galacticus) commit hash used to run your models, and — if applicable — the [`galacticusorg/datasets`](https://github.com/galacticusorg/datasets) commit hash.

2. **The parameter files** you used to run your models, placed in the same folder. Feel free to add a short note in the `ReadMe.md` describing what each file does and how they should be combined (as some of the existing pages do).

## Adding your entry to `publications.xml`

The [`publications.xml`](publications.xml) file at the repository root holds the same information in machine-readable form and is the source of truth used by our automation. Add a `<publication>` element for your paper. The supported attributes are described in the [ReadMe](ReadMe.md#L9); at minimum you must provide `title`, `author`, `year`, and `commit`. For example:

```xml
<publication title="Your Paper Title" author="Smith &amp; Jones" year="2026"
             commit="<galacticus-commit-hash>"
             arXiv="XXXX.XXXXX" bibCode="YYYYJJJJJVVVVMPPPPA"
             doi="XX.XXXX/XXXXX" journalURL="https://..." />
```

Use `&amp;` to encode any `&` in the author list. If you're unsure of the bibcode, DOI, or journal URL, provide what you have — our automation periodically refreshes NASA ADS bibcodes to their canonical form and fills in DOIs and journal URLs automatically.

## We'll tag your commit in the Galacticus repo

Once your entry is in `publications.xml`, our automation will **tag the Galacticus commit you used** in the [Galacticus repository](https://github.com/galacticusorg/galacticus). This means anyone can find the exact version of the code behind your paper by its tag, using whichever identifier is available:

* [arXiv](https://arxiv.org/) number: `publication/arXiv/XXXX.XXXXX`
* [NASA ADS](https://ui.adsabs.harvard.edu/) [bibcode](https://ui.adsabs.harvard.edu/help/actions/bibcode): `publication/bibcode/YYYYJJJJJVVVVMPPPPA` (note that `git` tags do not allow consecutive `.`s, which can appear in bibcodes, so `.` is replaced by `_` in these tags)
* [DOI](https://www.doi.org/): `publication/doi/XX.XXXX/XXXXX`

There's nothing you need to do for this — just make sure the `commit` hash in your entry is correct.

## Opening the pull request

1. [Fork](https://github.com/galacticusorg/galacticusPublications/fork) this repository and create a branch for your change.
2. Add your subfolder (with its `ReadMe.md` and parameter files) and your `<publication>` entry in `publications.xml`.
3. Open a pull request describing your paper.

We'll review it and merge it in. Thank you for contributing!
