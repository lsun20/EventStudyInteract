*! version 0.0  31mar2021  Liyang Sun, lsun20@mit.edu
capture program drop eventstudyinteract
program define eventstudyinteract, eclass sortpreserve
	version 13 
	syntax varlist(min=1 numeric) [if] [in] [aweight fweight], cohort(varname) ///
		control_cohort(varname) ///
		[COVARIATEs(varlist numeric ts fv) absorb(varlist numeric ts fv) vce(string)   ///
		]
	set more off
	
	* Mark sample (reflects the if/in conditions, and includes only nonmissing observations)
	marksample touse
	markout `touse' `by' `xq' `covariates' `absorb', strok
	* Parse the dependent variable
	local lhs: word 1 of `varlist'
	local rel_time_list: list varlist - lhs
	* Convert the varlist of relative time indicators to nvarlist 
	local nvarlist "" // copies of relative time indicators with control cohort set to zero
	local dvarlist "" // for display
	foreach l of varlist `rel_time_list' {
		local dvarlist "`dvarlist' `l'"
		tempname n`l'
		qui gen `n`l'' = `l'
		qui replace `n`l'' = 0 if  `control_cohort' == 1
		local nvarlist "`nvarlist' `n`l''"
	}	

	* Get cohort count  and count of relative time
	qui levelsof `cohort', local(cohort_list) 
 	local nrel_times: word count `nvarlist' 
	local ncohort: word count `cohort_list'  
	
	* Initiate empty matrix for weights 
	* ff_w stores the cohort shares (rows) for relative time (cols)
	tempname bb ff_w
	
	* Loop over cohort and get cohort shares for relative times
	local nresidlist ""
	foreach yy of local cohort_list {
		tempvar cohort_ind resid`yy'
		qui gen `cohort_ind'  = (`cohort' == `yy') 
		qui regress `cohort_ind' `nvarlist'  `wt' if `touse' & `control_cohort' == 0 , nocons
		mat `bb' = e(b)
		matrix `ff_w'  = nullmat(`ff_w') \ `bb'
		qui predict double `resid`yy'', resid
		local nresidlist "`nresidlist' `resid`yy''"
	}
 	matrix rownames `ff_w' = `cohort_list'
	matrix colnames `ff_w' =  `nvarlist'
	
	* Check if use has avar installed
	capture avar, version 
	if _rc != 0 {
		di as err "Error: must have avar installed"
		di as err "To install, from within Stata type " _c
		di in smcl "{stata ssc install avar :ssc install avar}"
					exit 601
	}
	
	* Get VCV estimate for the cohort shares using avar
	* In case users have not set relative time indicators to zero for control cohort
	* Manually restrict the sample to non-control cohort
	tempname XX Sxx Sxxi S KSxxi Sigma_ff
	mat accum `XX' = `nvarlist' if  `touse' & `control_cohort' == 0, nocons
	mat `Sxx' = `XX'*1/r(N)
    mat `Sxxi' = syminv(`Sxx')
	qui avar (`nresidlist') (`nvarlist')  if `touse' & `control_cohort' == 0, nocons robust
	mat `S' = r(S)
    mat `KSxxi' = I(`ncohort')#`Sxxi'
    mat `Sigma_ff' = `KSxxi'*`S'*`KSxxi'*1/r(N)
	// Note that the normalization is slightly different from the paper
	// The scaling factor is 1/N for N the obs of cross-sectional units
	// But here estimates are on the panel, which is why it is 1/NT instead
	// Should cancel out for balanced panel, but unbalanced panel is a TODO
	
	* Prepare interaction terms for the interacted regression
	local cohort_rel_varlist ""
	foreach l of varlist `nvarlist' {
		foreach yy of local cohort_list {
			tempvar n`l'_`yy'
			qui gen `n`l'_`yy''  = (`cohort' == `yy') * `l'
			local cohort_rel_varlist "`cohort_rel_varlist' `n`l'_`yy''"
		}
	}

	* Check if use has reghdfe installed
	capture reghdfe, version 
	if _rc != 0 {
		di as err "Error: must have reghdfe installed"
		di as err "To install, from within Stata type " _c
		di in smcl "{stata ssc install reghdfe :ssc install reghdfe}"
					exit 601
	}
	
	* Estimate the interacted regression
	tempname evt_bb b V
	qui reghdfe `lhs'  `cohort_rel_varlist'  `covariates' `wt' if `touse', absorb(`absorb') vce(`vce')
	mat `b' = e(b)
	mat `V' = e(V)
	* Convert the delta estimate vector to a matrix where each column is a relative time
	local end = 0
	forval i = 1/`nrel_times' {
		local start = `end'+1
		local end = `start'+`ncohort'-1
		mat `b'`i' = `b'[.,`start'..`end']
		mat `evt_bb'  = nullmat(`evt_bb') \ `b'`i'

	}
	mat `evt_bb' = `evt_bb''
	matrix colnames `evt_bb' =  `nvarlist'

	* Take weighted average for IW estimators
	tempname w delta b_iw nc nr
	mata: `w' = st_matrix("`ff_w'")
	mata: `delta' = st_matrix("`evt_bb'")
	mata: `b_iw' = colsum(`w':* `delta')
	mata: st_matrix("`b_iw'", `b_iw')
	mata: `nc' = rows(`w')
	mata: `nr' = cols(`w')
	
	* Ptwise variance from cohort share estimation and interacted regression
	tempname VV  wlong V_iw V_iw_diag 
	
	* VCV from the interacted regression
	mata: `VV' = st_matrix("`V'")
	mata: `VV' = `VV'[1..`nr'*`nc',1..`nr'*`nc'] // in case reghdfe reports _cons
	mata: `wlong' = `w'':*J(1,`nc',e(1,`nr')') // create a "Toeplitz" matrix convolution
	forval i=2/`nrel_times' {
		mata: `wlong' = (`wlong', `w'':*J(1,`nc',e(`i',`nr')'))
	}
	mata: `V_iw' = diagonal(`wlong'*`VV'*`wlong'')
	
	* VCV from cohort share estimation
	tempname Vshare Vshare_evt share_idx Sigma_l
	mata: `Vshare' = st_matrix("`Sigma_ff'")
	mata: `Sigma_l' = J(0,0,.)
	mata: `share_idx' = range(0,(`nc'-1)*`nr',`nr')
	forval i=1/`nrel_times' {
		mata: `Vshare_evt' = `Vshare'[`share_idx':+`i', `share_idx':+`i']
		mata: `V_iw'[`i'] = `V_iw'[`i'] + (`delta'[,`i'])'*`Vshare_evt'*(`delta'[,`i'])
		mata: `Sigma_l' = blockdiag(`Sigma_l',`Vshare_evt')
	}
	mata: `V_iw' = `V_iw''
	mata: st_matrix("`Sigma_l'", `Sigma_l')
	mata: st_matrix("`V_iw'", `V_iw')
	
	mata: `V_iw_diag' = diag(`V_iw')
	mata: st_matrix("`V_iw_diag'", `V_iw_diag')
	mata: mata drop `b_iw' `VV' `nc' `nr' `w' `wlong' `Vshare' `share_idx' `delta' `Vshare_evt' `Sigma_l' `V_iw' `V_iw_diag' 
	
	matrix colnames `b_iw' =  `dvarlist'
	matrix colnames `V_iw' =  `dvarlist'

	ereturn matrix b_iw  `b_iw' 
	ereturn matrix V_iw `V_iw'
	ereturn matrix ff_w `ff_w'
	ereturn matrix Sigma_l `Sigma_l'
	* Display results	
	_coef_table , bmatrix(e(b_iw)) vmatrix(`V_iw_diag')

end	
//
// * Load the HRS sample
// use HRS_long.dta, clear
// drop if wave < 7 // keep a balanced sample for wave 7-11
// bys hhidpn: gen N = _N
// keep if N == 5
// bys hhidpn: egen flag = min(evt_time)
// drop if flag >= 0 & flag != . // drop those first hospitalization happened before or during wave 7
// drop if flag == . 
// drop flag
// bys hhidpn: egen wave_hosp_copy = min(wave_hosp) // fill in the wave of index hosp within an hhidpn
// replace wave_hosp = wave_hosp_copy
// drop wave_hosp_copy
// keep if ever_hospitalized // keep a sample of individuals who were ever hospitalized wave 8-11
// * Generate calendar and event time and cohort dummies
// xi i.wave
// tab evt_time, gen(evt_time_)
// tab wave_hosp, gen(wave_hosp_)
//
// keep if age_hosp <= 59
//
// * Exclude the last cohort because it will be used as the control units
// gen wave_hosp_11 = wave_hosp == 11
//
//
// // Replicate HRS example
// eventstudyinteract oop_spend evt_time_2-evt_time_3 evt_time_5-evt_time_8 if ever_hospitalized & wave < 11, ///
// 	cohort(wave_hosp) control_cohort(wave_hosp_11) absorb(_Iwave_* hhidpn) vce(cluster hhidpn)
//
// eventstudyinteract riearnsemp evt_time_2-evt_time_3 evt_time_5-evt_time_8 if ever_hospitalized & wave < 11, ///
// 	cohort(wave_hosp) control_cohort(wave_hosp_11) absorb(_Iwave_* hhidpn) vce(cluster hhidpn)
