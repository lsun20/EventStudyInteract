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
	local nvarlist ""
	foreach l of varlist `rel_time_list' {
		local nvarlist "`nvarlist' `l'"
	}
//     dis "`nvarlist'"
//	qui capture drop  `nvarlist'
	
	* Get cohort count  and count of relative time
	qui levelsof `cohort', local(cohort_list) 
 	local nrel_times: word count `nvarlist' 
	local ncohort: word count `cohort_list'  
	dis `nrel_times' `ncohort'	
	
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
	
	* Get VCV estimate for the cohort shares
	tempname XX Sxx Sxxi S KSxxi Sigma_ff
	mat accum `XX' = `nvarlist' if  `touse' & `control_cohort' == 0 , nocons
	mat `Sxx' = `XX'*1/r(N)
    mat `Sxxi' = syminv(`Sxx')
	qui avar (`nresidlist') (`nvarlist')  if `touse' & `control_cohort' == 0 , nocons robust
	mat `S' = r(S)
    mat `KSxxi' = I(`ncohort')#`Sxxi'
    mat `Sigma_ff' = `KSxxi'*`S'*`KSxxi'*1/r(N)
// 	local cn : colfullnames `S'
//     mat colnames `Sigma_ff' = `cn'
//     mat rownames `Sigma_ff' = `cn'

//  	mat list `ff_w'
// 	mat list `Sigma_ff'
	
	* Prepare interaction terms for the interacted regression
	local nrel_times: word count `nvarlist' 
	local ncohort: word count `cohort_list'  
	dis `nrel_times' `ncohort'
 
	* Prepare the list of relative time indicators for interactions
	local cohort_rel_varlist ""
	foreach l of varlist `rel_time_list' {
		foreach yy of local cohort_list {
			tempvar n`l'_`yy'
			qui gen `n`l'_`yy''  = (`cohort' == `yy') * `l'
			local cohort_rel_varlist "`cohort_rel_varlist' `n`l'_`yy''"
		}
	}
// 	dis "`cohort_rel_varlist'"
	
	capture reghdfe, version 
	if _rc != 0 {
		di as err "Error: must have reghdfe installed"
		di as err "To install, from within Stata type " _c
		di in smcl "{stata ssc install hdfe :ssc install reghdfe}"
					exit 601
	}
	tempname evt_bb b V

	qui reghdfe `lhs'  `cohort_rel_varlist' `wt' if `touse', absorb(`absorb') vce(`vce') nocons
	mat `b' = e(b)
	mat `V' = e(V)
	local end = 0
	forval i = 1/`nrel_times' {
		local start = `end'+1
		local end = `start'+`ncohort'-1
		mat `b'`i' = `b'[.,`start'..`end']
		mat `evt_bb'  = nullmat(`evt_bb') \ `b'`i'

	}
	mat `evt_bb' = `evt_bb''
	matrix colnames `evt_bb' =  `nvarlist'
// 	mat list `evt_bb'
// 	mat list `V'

	* Take weighted average
	tempname U w delta b_iw wlong VV V_iw se_iw nc nr
				* Append the variance from cohort share estimation
			tempname Vshare Vshare_evt share_idx Sigma_l ii
			mata: `w' = st_matrix("`ff_w'")
			mata: `delta' = st_matrix("`evt_bb'")
			mata: `b_iw' = colsum(`w':* `delta')
			mata: st_matrix("`b_iw'", `b_iw')
			* VCV from the interacted regression
			mata: `VV' = st_matrix("`V'")
			mata: `nc' = rows(`w')
			mata: `nr' = cols(`w')
			* Initialize the VCV
			mata: `wlong' = `w'':*J(1,`nc',e(1,`nr')')
			mata: `wlong'
			forval i=2/`nrel_times' {
			display `i'
				mata: `wlong' = (`wlong', `w'':*J(1,`nc',e(`i',`nr')'))
			}
// 			mata: for (i=2; i<=`nrel_times' ; i++) {`wlong' = (`wlong', `w'':*J(1,`ncohort',e(i,`nrel_times')'))}
// 			mata: `wlong'
// 			mata: `VV'
			mata: `V_iw' = diagonal(`wlong'*`VV'*`wlong'')
			mata: `Vshare' = st_matrix("`Sigma_ff'")
			mata: `Sigma_l' = J(0,0,.)
			mata: `share_idx' = range(0,(`nc'-1)*`nr',`nr')
// 			mata: `delta'
// 			mata: `share_idx'
// 			mata: `Vshare'
			forval i=1/`nrel_times' {
						display `i'

				mata: `Vshare_evt' = `Vshare'[`share_idx':+`i', `share_idx':+`i']
				mata: `Vshare_evt'
				mata: (`delta'[,`i'])'*`Vshare_evt'*(`delta'[,`i'])
				mata: `V_iw'[`i'] = `V_iw'[`i'] + (`delta'[,`i'])'*`Vshare_evt'*(`delta'[,`i'])
				mata: `Sigma_l' = blockdiag(`Sigma_l',`Vshare_evt')
			}
			mata: `Sigma_l'
			mata: st_matrix("`Sigma_l'", `Sigma_l')
			mata: st_matrix("`V_iw'", `V_iw')
// 			mata: `se_iw'
			mata: `se_iw' = sqrt(`V_iw')'
			mata: st_matrix("`se_iw'", `se_iw')
	
	matrix colnames `b_iw' =  `nvarlist'
	matrix colnames `se_iw' =  `nvarlist'

	ereturn matrix b_iw  `b_iw' 
	ereturn matrix V_iw `V_iw' 
	ereturn matrix ff_w `ff_w'
	ereturn matrix Sigma_l `Sigma_l'
	* Display results	
	mat list e(b_iw)
	mat list `se_iw'
	
end	


// exclude the last cohort because it will be used as the control units
// foreach vv of varlist evt_time_* {
// 	replace `vv' = 0 if wave_hosp == 11
// }
// gen wave_hosp_11 = wave_hosp == 11

// Can replicate point estimates
eventstudyinteract oop_spend evt_time_2-evt_time_3 evt_time_5-evt_time_8 if ever_hospitalized & wave < 11, ///
	cohort(wave_hosp) control_cohort(wave_hosp_11) absorb(_Iwave_* hhidpn) vce(cluster hhidpn)

eventstudyinteract riearnsemp evt_time_2-evt_time_3 evt_time_5-evt_time_8 if ever_hospitalized & wave < 11, ///
	cohort(wave_hosp) control_cohort(wave_hosp_11) absorb(_Iwave_* hhidpn) vce(cluster hhidpn)
