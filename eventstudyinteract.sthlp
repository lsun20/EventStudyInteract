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
implements the interaction weighted estimator for an event study as an alternative to the canonical two-way fixed effects regressions 
with relative time indicators (event study specifications) 
{p_end}
{p2colreset}{...}
 
{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:eventstudyinteract}
{y} {rel_time_list} {ifin}
{weight}
[{cmd:,} {it:options}]
 
{pstd}
where {it:rel_time_list} is the list of relative time indicators as specified in your two-way fixed effects regression
{p_end}
		{it:rel_time_1} [{it:rel_time_2} [...]]  

{synoptset 26 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{pstd}
Specify the last period to exclude in {opth if} when all cohorts have been treated during the panel (see {help eventstudyinteract##by_notes:important notes below})
The syntax is similar to {helpb reghdfe} such as absorb and vce, but controls other than the relative time indicators need to be specified separately

{synopt :{opth cohort(varname)}}numerical variable that corresponds to cohort (see {help eventstudyinteract##by_notes:important notes below}){p_end}
{synopt :{opth control_cohort(varname)}}numerical variable that corresponds to last cohort{p_end}

{pstd}
{opt eventstudyinteract} requires {helpb reghdfe} (Sergio 2015) to be installed to partial out controls and fixed effects from the relative time indicators.
{opt eventstudyinteract} will prompt the user for installation of
{helpb hdfe} if necessary.
  
{syntab :Controls}
{synopt :{opth covariate:s(varlist)}}residualize the relative time indicators on covariates{p_end}
{synopt :{opth absorb(varlist)}} fixed effects {p_end}

{syntab :VCE}
{synopt :{opt vce}{cmd:(}{help reghdfe##opt_vce:vcetype} [{cmd:,}{it:opt}]{cmd:)}}{it:vcetype}
may be {opt un:adjusted} (default), {opt r:obust} or {opt cl:uster} {help fvvarlist} (allowing two- and multi-way clustering){p_end}
{synopt :}suboptions {opt bw(#)}, {opt ker:nel(str)}, {opt dkraay(#)} and {opt kiefer} allow for AC/HAC estimates; see the {help avar} package{p_end}

{syntab :Save Output}
{synopt :{opt saveweights(filename)}}save weights to {it:filename}.xlsx along with cohort and relative time, using Stata's built-in {helpb putexcel} {p_end}
{synoptline}
{p 4 6 2}
{opt aweight}s and {opt fweight}s are allowed;
see {help weight}.
{p_end}
 
{marker description}{...}
{title:Description}

{pstd}
{opt eventstudyinteract} estimate weights underlying two-way fixed effects regressions with relative time indicators, 
It is optimized for speed in large panel datasets thanks to {helpb hdfe}.

{pstd}
To estimate the dynamic effects of an absorbing treatment, researchers often use two-way fixed effects regressions that include leads and lags of the treatment (event study specification). Units are categorized into different cohorts based on their initial treatment timing. Sun and Abraham (2020) show the coefficients in this event study specification can be written as a linear combination of cohort-specific effects from both its own relative period and other relative periods. 
{opt eventstudyinteract} is a Stata module that estimates these weights for any given event study specification.  

{pstd}
For each relative time indicator specified in {it:rel_time_list}, {opt eventstudyinteract} estimates the weights 
underlying the linear combination of treatment effects in its associated coefficients using
an auxiliary regression. It provides built-in options to control for fixed effects and covariates
(see {help eventstudyinteract##syntax:Controls}).    {cmd:eventstudyinteract} exports these weights to a spreadsheet that can be analyzed separately.
 This spreadsheet also contains the cohort and relative time each weight corresponds to, with headers as specified in {opt cohort()} and {opt rel_time()}.


{dlgtab:Main}

{marker by_notes}{...}
{phang}{opth cohort(varname)} is a categorical varaible that contains the   initial treatment timing of each unit.

{phang}{opth rel_time(varname)} is a categorical varaible that contains the the relative time for each unit at each calendar time.

{pmore}
Users should shape their dataset to a long format where each observation is at the unit-time level. Users should prepare the cohort and relative time variables as illustrated in the example. 
 
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

{pstd} For the coefficient associate with each of the above relative time indicators in a two-way fixed effects regression, we can estimate the weights and export to a spreadsheet "weights.xlsx".{p_end}
{phang2}. {stata eventstudyinteract g_2 g0 g1 g2, controls(i.idcode i.year) cohort(first_union) rel_time(ry) saveweights("weights") }{p_end}
 
 
{pstd} To plot the weights underlying the coefficient associate with, e.g.,  relative time indicator lead=2, you may try {p_end}
{phang2}. {stata import excel "weights.xlsx", clear firstrow}{p_end}
{phang2}. {stata keep g_2 first_union ry}{p_end}
{phang2}. {stata reshape wide g_2, i(ry) j(first_union)}{p_end}
{phang2}. {stata graph twoway line g_2* ry}{p_end}

{pstd} You may also check the weights have properties discussed in the paper: {p_end}
{phang2}. {stata egen w_sum = rowtotal(g_2*)}{p_end}
 
{marker acknowledgements}{...}
{title:Acknowledgements}
  
{pstd}Thank you to the users of early versions of the program who devoted time to reporting
the bugs that they encountered.
 
{marker references}{...}
{title:References}
 
{marker SC2015}{...}
{phang}
Correia, S. 2015.
HDFE: Stata module to partial out variables with respect to a set of fixed effects
{browse "https://ideas.repec.org/c/boc/bocode/s457985.html":https://ideas.repec.org/c/boc/bocode/s457985.html
{p_end}

{marker SA2020}{...}
{phang}
Sun, L. and Abraham, S. 2020.
Estimating Dynamic Treatment Effects in Event Studies with
Heterogeneous Treatment Effects
{p_end}

{marker citation}{...}
{title:Citation of eventstudyinteract}

{pstd}{opt eventstudyinteract} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{phang}Sun, L., 2020.
eventstudyinteract: weights underlying two-way fixed effects event studies regressions.
{browse "https://github.com/lsun20/eventstudyinteract":https://github.com/lsun20/eventstudyinteract}.
 
{marker author}{...}
{title:Author}

{pstd}Liyang Sun{p_end}
{pstd}lsun20@mit.edu{p_end}
