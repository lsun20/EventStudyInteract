{smcl}
{* *! version 0.0  2apr2020}{...}
{viewerjumpto "Syntax" "eventstudyinteract##syntax"}{...}
{viewerjumpto "Description" "eventstudyinteract##description"}{...}
{viewerjumpto "Options" "eventstudyinteract##options"}{...}
{viewerjumpto "Examples" "eventstudyinteract##examples"}{...}
{viewerjumpto "Saved results" "eventstudyinteract##saved_results"}{...}
{viewerjumpto "Author" "eventstudyinteract##author"}{...}
{viewerjumpto "Acknowledgements" "eventstudyinteract##acknowledgements"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:eventstudyinteract} {hline 2}}
implements the interaction weighted (IW) estimator for estimating dynamic treatment effects. Sun and Abraham (2020) propose this estimator as an alternative to the canonical two-way fixed effects regressions 
with relative time indicators. The estimator is implemented in three steps.  First, estimate the interacted regression with {helpb reghdfe}, where the interactions are between relative time indicators and cohort indicators.
 Second, estimate the cohort shares underlying each relative time.  Third, take the weighted average of estimates from the first step, with weights set to the estimated cohort shares.
{p_end}
{p2colreset}{...}
 
{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:eventstudyinteract}
{y} {rel_time_list} {ifin}
{weight}
[{cmd:,} {it:options}]
 
{pstd}
where {it:rel_time_list} is the list of relative time indicators as you would have included in the canonical two-way fixed effects regression, e.g.,
{p_end} 
		{it:rel_time_1} [{it:rel_time_2} [...]]  

{synoptset 26 tabbed}{...}
{pstd}
The syntax is similar to {helpb reghdfe} in specifying fixed effects (with {help reghdfe##opt_absorb:absorb}) 
and the type of standard error reported (with {help reghdfe##opt_vce:vcetype}).  Regressors other than the relative time indicators need to be specified separately in {opth covariate:s(varlist)}.
Furthermore, it also requires the user to specify the cohort categories as well as which cohort is the control control (see {help eventstudyinteract##by_notes:important notes below}).  
Note that Sun and Abraham (2020) only establish the validity of the IW estimators for balanced panel data. {opt eventstudyinteract} evaluates the IW estimators for unbalanced panel data as well.  


{pstd}
{opt eventstudyinteract} requires {helpb avar} (Baum and Schaffer, 2013) and {helpb reghdfe} (Sergio, 2017) to be installed.
Installation of {opt eventstudyinteract} will install{helpb avar} and {helpb reghdfe} (and its dependencies) from ssc if necessary. {p_end}

{synopthdr :options}
{synoptline}
{syntab :Options}
{synopt :{opth cohort(varname)}}categorical variable that corresponds to cohort (see {help eventstudyinteract##by_notes:important notes below}){p_end}
{synopt :{opth control_cohort(varname)}}binary variable that corresponds to the control cohort, which can be never-treated units or last-treated units.
If using last-treated unit as control cohort, exclude the time periods when the last cohort receives treatment. {p_end}
{synopt :{opth absorb(varlist)}}specifies unit and time fixed effects.{p_end}

{synopt :{opth covariate:s(varlist)}}specify covariates that lend validity to the parallel trends assumption, i.e. covariates you would have included in the canonical two-way fixed effects regressions. {p_end}

{syntab :VCE}
{synopt :{opt vce}{cmd:(}{help reghdfe##opt_vce:vcetype} [{cmd:,}{it:opt}]{cmd:)}}{it:vcetype}
may be {opt un:adjusted} (default), {opt r:obust} or {opt cl:uster} {help fvvarlist} (allowing two- and multi-way clustering){p_end}
{synopt :}suboptions {opt bw(#)}, {opt ker:nel(str)}, {opt dkraay(#)} and {opt kiefer} allow for AC/HAC estimates; see the {help avar} package{p_end}

{syntab :Saved Output}
{pstd}
{opt eventstudyinteract} reports the IW estimates and standard error.  
Since the interacted regression is performed by {helpb reghdfe}, it keeps all e() results from  {helpb reghdfe}.  
In addition, it stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}

{syntab:Matrices}
{synopt:{cmd:e(b_iw)}}IW estimate vector{p_end}
{synopt:{cmd:e(V_iw)}}pointwise variance estimate of the IW estimators{p_end}
{synopt:{cmd:e(ff_w)}} Each column vector contains estimates of cohort shares underlying the given relative time. {p_end}
{synopt:{cmd:e(Sigma_l)}}variance estimate of the cohort share estimators{p_end}

{synoptline}
{p 4 6 2}
{opt aweight}s and {opt fweight}s are allowed;
see {help weight}.
{p_end}
 
{marker description}{...}
{title:Description}

{pstd}
To estimate the dynamic effects of an absorbing treatment, researchers often use two-way fixed effects regressions that include leads and lags of the treatment (event study specification). Units are categorized into different cohorts based on their initial treatment timing. Sun and Abraham (2020) show the coefficients in this event study specification can be written as a linear combination of cohort-specific effects from both its own relative period and other relative periods.  
They show this specification is not robust to treatment effects heterogeneity and propose the interaction weighted estimator.

{pstd}
{opt eventstudyinteract} implements the interaction weighted estimators for event studies, 
It is optimized for speed in large panel datasets thanks to {helpb reghdfe}.

{pstd}
For each relative time indicator specified in {it:rel_time_list}, {opt eventstudyinteract} estimates the IW estimator for the treatment effect associated with the given relative time. It provides built-in options to control for fixed effects and covariates
(see {help eventstudyinteract##syntax:Controls}).    

{dlgtab:Main}

{marker by_notes}{...}
{phang}{opth cohort(varname)} is a categorical varaible that contains the initial treatment timing of each unit.

{phang}{opth control_cohort(varname)} is an indicator varaible that is equal to one if the cohort is last treated or never treated.

{pmore}
Users should shape their dataset to a long format where each observation is at the unit-time level. Users should prepare the cohort and control cohort variables as illustrated in the example. 
 
{marker examples}{...}
{title:Examples}

{pstd}Load the 1968 extract of the National Longitudinal Survey of Young Women and Mature Women.{p_end}
{phang2}. {stata webuse nlswork, clear}{p_end}

{pstd}Code the cohort categorical variable based on when the individual first joined the union.{p_end}
{phang2}. {stata gen union_year = year if union == 1 }{p_end}
{phang2}. {stata "bysort idcode: egen first_union = min(union_year)"}{p_end}
{phang2}. {stata drop union_year }{p_end}
 
{pstd}Code the relative time categorical variable.{p_end}
{phang2}. {stata gen ry = year - first_union}{p_end}

{pstd}Suppose we will later use a specification with lead=2 and lag=0,1,2 to estimate the dynamic effect of union status on income.  We first generate these relative time indicators.{p_end}
{phang2}. {stata gen g_2 = ry == -2}{p_end}
{phang2}. {stata gen g0 = ry == 0}{p_end}
{phang2}. {stata gen g1 = ry == 1}{p_end}
{phang2}. {stata gen g2 = ry == 2}{p_end}

{pstd} We form the control cohort with individuals that never unionized.{p_end}
{phang2}. {stata gen never_union = (first_union == .)}{p_end}

{pstd} We estimate the dynamic effect on log wage associated with each relative time.{p_end}
{phang2}. {stata eventstudyinteract ln_wage g_2 g0 g1 g2, cohort(first_union) control_cohort(never_union) covariates(collgrad south) absorb(i.idcode i.year) vce(cluster idcode) }{p_end}


{pstd} Alternatively, we form the control cohort with individuals that were unionized last.{p_end}
{phang2}. {stata gen last_union = (first_union == 88)}{p_end}

{pstd} We estimate the dynamic effect on log wage associated with each relative time.{p_end}
{phang2}. {stata eventstudyinteract ln_wage g_2 g0 g1 g2 if first_union != . & year < 88, cohort(first_union) control_cohort(last_union) covariates(collgrad south) absorb(i.idcode i.year) vce(cluster idcode) }{p_end}


{marker acknowledgements}{...}
{title:Acknowledgements}
  
{pstd}Thank you to the users of early versions of the program who devoted time to reporting
the bugs that they encountered.
 
{marker references}{...}
{title:References}
 
{marker BS2013}{...}
{phang}
Baum, C. and Schaffer, M. 2013. 
AVAR: Stata module to perform asymptotic covariance estimation for iid and non-iid data robust to heteroskedasticity, autocorrelation, 1- and 2-way clustering, and common cross-panel autocorrelated disturbances.
Statistical Software Components S457689, Boston College Department of Economics.
{browse "https://ideas.repec.org/c/boc/bocode/s457689.html":https://ideas.repec.org/c/boc/bocode/s457689.html}
{p_end}
 
{marker SC2017}{...}
{phang}
Correia, S. 2017. 
REGHDFE: Stata module for linear and instrumental-variable/gmm regression absorbing multiple levels of fixed effects. 
Statistical Software Components s457874, Boston College Department of Economics. 
{browse "https://ideas.repec.org/c/boc/bocode/s457874.html":https://ideas.repec.org/c/boc/bocode/s457874.html}
{p_end}

{marker SA2020}{...}
{phang}
Sun, L. and Abraham, S. 2020.
Estimating Dynamic Treatment Effects in Event Studies with
Heterogeneous Treatment Effects
{p_end}

{marker citation}{...}
{title:Citation and Installation of eventstudyinteract}

{pstd}{opt eventstudyinteract} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{phang}Sun, L., 2021.
eventstudyinteract: interaction weighted estimator for event study.
{browse "https://github.com/lsun20/eventstudyinteract":https://github.com/lsun20/eventstudyinteract}.

{pstd}{opt eventstudyinteract} can be installed easily via the {helpb github} package, which is available on 
{browse "https://github.com/haghish/github":https://github.com/haghish/github}. {p_end}

{phang2}. {stata github install lsun20/eventstudyinteract }{p_end}
{phang2}. {stata github update eventstudyinteract }{p_end}

{marker author}{...}
{title:Author}

{pstd}Liyang Sun{p_end}
{pstd}lsun20@mit.edu{p_end}
