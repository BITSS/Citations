*Why aren't we doing diff-n-diff?


ivregress 2sls citation ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first
	
ivregress 2sls lncite ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012), first
	
*SIMPLIFY A LITTLE, JUST ONE INSTRUMENT
ivregress 2sls lncite ajps post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2012), first
	

*DO THAT IN DIFF-N-DIFF

reg lncite ajps post2012 ajpsXpost2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu

	
*SIMPLIFY A LOT--NO CONTROLS
ivregress 2sls lncite ajps post2012 (avail_yn = ajpsXpost2012), first
reg  lncite ajps post2012 ajpsXpost2012
