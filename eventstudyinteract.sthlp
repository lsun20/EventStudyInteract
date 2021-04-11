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
implements the interaction weighted (IW) estimator and constructs pointwise confidence interval for the estimation of dynamic treatment effects. 
To estimate the dynamic effects of an absorbing treatment, researchers often use two-way fixed effects (TWFE) regressions that include leads and lags of the treatment (event study specification). 
Units are categorized into different cohorts based on their initial treatment timing.  
Sun and Abraham (2020) proposes this estimator as an alternative to the TWFE regression in the presence of treatment effects heterogeneous across cohorts. 
Under treatment effects heterogeneity, the TWFE regression can result in estimates with uninterpretable weights, which can be assessed by the Stata module {helpb eventstudyweights}.
The IW estimator is implemented in three steps.  
First, estimate the interacted regression with {helpb reghdfe}, where the interactions are between relative time indicators and cohort indicators.
Second, estimate the cohort shares underlying each relative time.  
Third, take the weighted average of estimates from the first step, with weights set to the estimated cohort shares.
{p_end}
{p2colreset}{...}
 
{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:eventstudyinteract}
{y} {rel_time_list} {ifin}
{weight} {cmd:,} {opth a:bsorb(reghdfe##absvar:absvars)} {opth c:ohort(eventstudyinteract##cohort:variable)}
            {opth c:ontrol_cohort(eventstudyinteract##cohort:variable)} 
 [{it:options} {opth c:ovariates(eventstudyinteract##cohort:varlist)}]
 
{pstd}
where {it:rel_time_list} is the list of relative time indicators as you would have included in the canonical two-way fixed effects regression, e.g.,
{p_end} 
		{it:rel_time_1} [{it:rel_time_2} [...]]  

{synoptset 26 tabbed}{...}


{pstd}
Users should shape their dataset to a long format where each observation is at the unit-time level. 
See {help eventstudyinteract##examples:an illustration} to the syntax.
The syntax is similar to {helpb reghdfe} in specifying fixed effects (with {help reghdfe##opt_absorb:absorb}) 
and the type of standard error reported (with {help reghdfe##opt_vce:vcetype}).  
Relative times is definited relative to the initial treatment, and can be missing for never treated units. 
Regressors other than the relative time indicators need to be specified separately in {opth covariate:s(varlist)}.
Furthermore, it also requires the user to specify the cohort categories as well as which cohort is the control control (see {help eventstudyinteract##by_notes:important notes below}).  
Note that Sun and Abraham (2020) only establishes the validity of the IW estimators for balanced panel data without covariates. {opt eventstudyinteract} evaluates the IW estimators for unbalanced panel data as well.  


{pstd}
{opt eventstudyinteract} requires {helpb avar} (Baum and Schaffer, 2013) and {helpb reghdfe} (Sergio, 2017) to be installed.
Installation of {opt eventstudyinteract} will install {helpb avar} and {helpb reghdfe} (and its dependencies) from ssc if necessary. {p_end}

{synopthdr :options}
{synoptline}
{syntab :Must specify}
{marker cohort}{...}
{synopt :{opth cohort(varname)}}categorical variable that corresponds that contains the initial treatment timing of each unit.
If there are units that receive multiple treatments, Sun and Abraham (2020) defines the initial treatment timing to be based on the first treatment.
Cohort can be missing for never treated units.{p_end}
{synopt :{opth control_cohort(varname)}}binary variable that corresponds to the control cohort, which can be never-treated units or last-treated units.
If using last-treated unit as control cohort, exclude the time periods when the last cohort receives treatment. {p_end}
{synopt :{opth absorb(varlist)}}specifies unit and time fixed effects.{p_end}

{syntab :Optional}
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
{synopt:{cmd:e(b_interact)}} Each column vector contains estimates of cohort-specific effect for the given relative time. {p_end}
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
For each relative time indicator specified in {it:rel_time_list}, {opt eventstudyinteract} estimates the IW estimator for the treatment effect associated with the given relative time. 
It provides built-in options to control for fixed effects and covariates
(see {help eventstudyinteract##syntax:covariates}).    


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

{pstd} We take the control cohort to be individuals that never unionized.{p_end}
{phang2}. {stata gen never_union = (first_union == .)}{p_end}

{pstd} Check if there is a sufficient number of treated units for each relative time. 
With very few units it might be better to bin the relative times and assume constant treatment effects within the bin. {p_end}
{phang2}. {stata tab ry}{p_end}

{pstd}We will consider the dynamic effect of union status on income. 
We first generate these relative time indicators, and leave out the distant leads due to few observations.  
Implicitly this assumes that effects outside the lead windows are zero.  {p_end}
	{cmd:forvalues k = 18(-1)2 {c -(}}
	{cmd:   gen g_`k' = ry == -`k'}
	{cmd:{c )-}}
	{cmd:forvalues k = 0/18 {c -(}}
	{cmd:     gen g`k' = ry == `k'}
	{cmd:{c )-}}
	
{pstd} We use the IW estimator to estimate the dynamic effect on log wage associated with each relative time.{p_end}
{pstd} With many leads and lags, we need a large matrix size to hold intermediate estimates.{p_end}
{phang2}. {stata set matsize 800 }{p_end}
{phang2}. {stata eventstudyinteract ln_wage g_* g0-g18, cohort(first_union) control_cohort(never_union) covariates(south) absorb(i.idcode i.year) vce(cluster idcode) }{p_end}

{pstd} Pre-treatment effects seem relatively constant, which might suggest binning the many leads. 
TODO: current implementation of bins does not follow Sun and Abraham (2020) exactly due to coding challenge.  
But it is valid if effects in the bin are constant for each cohort.{p_end}
{phang2}. {stata gen g_l4 = ry <= -4}{p_end}

{pstd} Alternatively, we can take the control cohort to be individuals that were unionized last.{p_end}
{phang2}. {stata gen last_union = (first_union == 88)}{p_end}

{pstd} If using the last-treated cohort as the control, be sure to restrict the analysis sample to be before 
the treated periods for the last-treated cohort.{p_end}
{phang2}. {stata eventstudyinteract ln_wage g_l4 g_3 g_2 g0-g18 if first_union != . & year < 88, cohort(first_union) control_cohort(last_union) covariates(south) absorb(i.idcode i.year) vce(cluster idcode) }{p_end}

{pstd} We can look at the share of cohorts underlying the IW estimates for each relative time.{p_end}
{phang2}. {stata matrix list e(ff_w) }{p_end}

{pstd} We can look at the cohort-specific treatment effect estimates for each relative time.{p_end}
{phang2}. {stata matrix list e(b_interact) }{p_end}

{pstd} We can check that the IW estimates are weighted averages of the cohort-specific dynamic effect estimate 
, weighted by the corresponding cohort share estimates.  For example, the IW estimate associated with g_l4 is {p_end}
{phang2}. {stata matrix list e(b_iw)}{p_end}
{pstd} which is the weighted average of cohort-specific treatment effect estimates, 
with weights corresponding to the cohort share estimates: {p_end}
{phang2}. {stata matrix delta = e(b_interact)}{p_end}
{phang2}. {stata matrix weight = e(ff_w)}{p_end}
{phang2}. {stata matrix nu = delta[1...,1]'*weight[1...,1]}{p_end}
{phang2}. {stata matrix list nu}{p_end}



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
