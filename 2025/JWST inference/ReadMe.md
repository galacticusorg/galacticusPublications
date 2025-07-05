This folder contains parameter files for the paper:

* Title: _"Population synthesis and astrophysical inference for high-z JWST galaxies"_
* Author(s): Driskell et al.
* Publication year: 2025
* URLs:
  * [arXiv](https://arxiv.org/abs/2410.11680)
  * [NASA ADS](https://ui.adsabs.harvard.edu/abs/2024arXiv241011680D)
* Galacticus commit hash: [812c10821686ce406668e9e0d3b7e586b5cd8f6f](https://github.com/galacticusorg/galacticus/commit/812c10821686ce406668e9e0d3b7e586b5cd8f6f)

`template.xml` specifies the default values used for inference. `parameters.yaml` provides information about the four parameters which were varied. Three redshifts were used (8.0, 12.0, and 16.0). Each parameter in the yaml specifies the full parameter path, e.g. `starFormationRateDisks/starFormationTimescale/timescale`, sampling strategy (all linear), and min value, max value, and number of samples (min, max, and nv).
