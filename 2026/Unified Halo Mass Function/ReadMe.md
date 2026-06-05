This folder contains parameter files for the paper:

* Title: _"A Unified Halo Mass Function Across Dark Matter Models from High-Resolution Multi-Scale Simulations"_
* Author(s): Benson, Nadler, Du & Gluscevic
* Publication year: 2026
* URLs:
  * [arXiv]()
  * [NASA ADS]()
* Galacticus commit hash: [0240b78c4372937b619af2788d309452d6fe9f07](https://github.com/galacticusorg/galacticus/commit/0240b78c4372937b619af2788d309452d6fe9f07)
* Datasets commit hash: [cc089afd9e3e12b0c969ff200de34e8facdcb445](https://github.com/galacticusorg/datasets/commit/cc089afd9e3e12b0c969ff200de34e8facdcb445)

The MCMC analysis in this paper was run using the command:
```
./constraints/pipelines/darkMatter/pipeline.pl --outputDirectory mcmc --generateContent yes --updateResults no --waitSleepDuration 5 --submitSleepDuration 1 --slurmJobMaximum 500 --haloMassFunction:nodes 5 --haloMassFunction:ppn 32 --binAverage false --removeAccelerator true --removeErrorConvolved false --removeDetectionEfficiency false --removeSimulationVariance false --removeMultiplier false --includeCorrelations false --heatRepeats false --countParticlesMinimum 300 --select Symphony::LMC,MilkyWay,Group::best::CDM::*::* --select COZMIC::MilkyWay::best::*::*::* --select MDPL::*::resolutionX1::CDM::*::*
```
which will generate the relevant parameter files, submit a MCMC job (assuming a SLURM queue manager), and generate the final halo mass function models.
