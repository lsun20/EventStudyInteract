# EventStudyInteract

**eventstudyinteract** is a Stata package that implements the interaction weighted estimator for an event study.  Sun and Abraham (2020) propose this estimator as an alternative to the canonical two-way fixed effects regressions with relative time indicators.  Sun and Abraham (2020) prove this estimator is consistent even under heterogeneous treatment effects.  A similar estimator is proposed by Callaway and Sant'Anna (2020) and can potentially be more efficient. Therefore one can also use the R package `did` developed by [Callaway and Sant'Anna (2020)](https://bcallaway11.github.io/did/) to form the IW estimator.

## Installation
**eventstudyinteract** can be installed easily via the `github` package, which is available on [https://github.com/haghish/github](https://github.com/haghish/github).  Specifically execute the following code in Stata:

`net install github, from("https://haghish.github.io/github/")`

To install the **eventstudyinteract** package , execute the following in Stata:

`github install lsun20/eventstudyinteract`

To update the **eventstudyinteract**  package, execute the following in Stata:

`github update eventstudyinteract`

Documentation is included in the Stata help file that is installed along with the package.  An empirical example is included.

## Authors and acknowledgment
Liyang Sun

Preprint is available on [my personal website](http://economics.mit.edu/files/14964).