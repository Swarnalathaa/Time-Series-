/*
Name : Swarnalathaa PANNEERSELVAN
*/
data work.Air1990_2000;
	set LWFETSP.usairlines
       (where=(Date<='31DEC2000'd));
run;

/*Exercise 1
Obtain diagnostic plots from PROC TIMESERIES. You can save the OUTDECOMP table in a table named WORK.OUTDECOMP also.
*/
title1 "Excercise 1";
proc timeseries data=work.Air1990_2000 outdecomp=work.outdecomp plot=(series 
		corr acf pacf iacf wn decomp tc sc) seasonality=12;
	id Date interval=month;
	var Passengers;
	decomp tcc sc / mode=mult;
run;

/*
Check that
•	the airline passengers’ time series clearly has strong trend and seasonal components.
Ans :Yes, From the time series plot we can see that data has linear upward trend and seasonality over year.
•	The autocorrelation plots support the finding of trend and seasonality
Ans:Yes, in the autocorrelation graph we can notice the spikes at the lags in the seasonal fashion.
•	The decomposition plots propose model components for handling trend and seasonality
Ans:Yes, Decomposition procedures are used to identify the trend and sesonality in the time series.
•	The seasonal components plot is difficult to interpret because it spans all years in the series

*/
proc sgplot data=work.outdecomp(where=(year(Date)>=1998));
	series x=Date y=sc;
	refline 1;
run;

/*
•   Does the above plot makes it very clear that peak travel occurs in August, and February is the lowest travel month?
Ans: yes
*/
/*Excercise 2
As we did in the previous exercise make a SPECTRA analysis with Parzen methodology and plot the series with x=PERIOD y=S_01 for 2<=PERIOD<=20.
The data should reflect sinusoidal behavior with periods 12, 4, and 2.4, add REFLINES at the datapoints.
*/
title1 "Excercise 2";
proc spectra data=work.Air1990_2000 out=work.spectral_analysis s;
	var Passengers;
	weights Parzen;
run;

proc sgplot data=work.spectral_analysis(where=(2<=Period<=20));
	series x=Period y=S_01;
	refline 2.4 4 12/axis=x;
run;

/*Excercise 3
The evidence for trend and seasonality is strong enough to forego the Dickey-Fuller tests.
The following DATA step adds candidate trend and seasonal terms to the data.
*/
title1 "Excercise 3";
proc arima data=work.Air1990_2000 plots=all;
	identify var=Passengers stationarity=(ADF=(0 1 2 3));
quit;

data work.Air1990_2000;
	set work.Air1990_2000 end=lastobs;
	array Seas{*} MON1-MON11;
	retain TwoPi . Time 0 MON1-MON11 .;

	if (TwoPi=.) then
		TwoPi=2*constant("pi");

	if (MON1=.) then
		do index=1 to 11;
			Seas[index]=0;
		end;
	Time+1;
	S2p4=sin(TwoPi*Time/2.4);
	C2p4=cos(TwoPi*Time/2.4);
	S4=sin(TwoPi*Time/4);
	C4=cos(TwoPi*Time/4);
	S12=sin(TwoPi*Time/12);
	C12=cos(TwoPi*Time/12);

	if (month(Date)<12) then
		do;
			Seas[month(Date)]=1;
			output;
			Seas[month(Date)]=0;
		end;
	else
		output;

	if (lastobs) then
		do;
			Passengers=.;

			do index=1 to 24;
				Time+1;
				Date=intnx("month", Date, 1);
				S2p4=sin(TwoPi*Time/2.4);
				C2p4=cos(TwoPi*Time/2.4);
				S4=sin(TwoPi*Time/4);
				C4=cos(TwoPi*Time/4);
				S12=sin(TwoPi*Time/12);
				C12=cos(TwoPi*Time/12);

				if (month(Date)<12) then
					do;
						Seas[month(Date)]=1;
						output;
						Seas[month(Date)]=0;
					end;
				else
					output;
			end;
		end;
	drop index TwoPi;
run;

/*
•	How many forecasting periods will be extrapolated?
Ans : Forcasting is done for future 24 months
•	Do the code create dummies for months?
Ans : Yes, Dummies are created for months (MON1-MON11)
•	Do the code create time index?
Ans : Yex, time index is created by the code (Time)

*/
/*Excercise 4
The classic airline model proposed by Box and Jenkins for the international airline passengers data from 1948 to 1960 uses a log transformation and fits an ARIMA(0,1,1)(0,1,1)12 model to the transformed series.
•	At time, the log transformation was primarily used as a variance stabilizing transformation.
•	Your modern airline data does not exhibit increasing variance as a function of time, so the log transformation will not be considered.

Fit the model on Passengers variable from the Air1990_2000 dataset.
*/
title1 "Excercise 4";
title1 "ARIMA(0,1,1)(0,1,1)";
proc arima data=work.Air1990_2000 out=work.arima4_1;
	identify var=Passengers(1, 12);
	estimate q=(1)(12) method=ml;
	forecast id=date interval=month;
run;

/*
•  Check the Ljung-Box statistics. Is the right model?
Ans : No, the p-values of the first 6 lags is >0.05. so, the residuals shows significant autocorrelation.
	
Box and Jenkins recommend that models with difference orders 1 and 12 use corresponding MA subset factors. This is consistent with the classic airline model.
But the addition of P=1 will be tested to improve the fitted statistics.
Fit the suggested model.
	
*/
title1 "ARIMA(1,1,1)(0,1,1)12";
proc arima data=work.Air1990_2000 out=work.arima4_2;
	identify var=Passengers(1, 12);
	estimate p=1 q=(1)(12) method=ml;
	forecast id=date interval=month;
run;

/*
•  Check the Ljung-Box statistics. Is the right model?
Ans: cant be sure as the p.value plots of the residuals sees good but the ACF plot has a significant spike.

It seems (on your behalf) that the autocorrelation plots suggest white noise, but the Ljung-Box test for lags 3 through 6 rejects white noise so we decide to test one additional model.

*/

/*Excercise 5
Make a ARMA model with linear trend and seasonal dummies (defined in the CROSS=()) option
Make a ARMA(0,0,1) model with linear trend and seasonal dummies (defined in the CROSS=() option) and forecast it to 24 periods.
*/
title1 "Excercise 5";
proc arima data=work.Air1990_2000 out=work.arma5_1a;
	identify var=Passengers crosscorr=(Time MON1 MON2 MON3 MON4 MON5 MON6 MON7 
		MON8 MON9 MON10 MON11);
	estimate input=(Time MON1 MON2 MON3 MON4 MON5 MON6 MON7 MON8 MON9 MON10 MON11);
	forecast id=Date interval=month;
run;

/*ARMA(0,0,1) model*/
proc arima data=work.Air1990_2000 out=work.arma5_1b;
	identify var=Passengers crosscorr=(Time MON1 MON2 MON3 MON4 MON5 MON6 MON7 
		MON8 MON9 MON10 MON11);
	estimate input=(Time MON1 MON2 MON3 MON4 MON5 MON6 MON7 MON8 MON9 MON10 MON11) 
		q=1 p=0;
	forecast id=Date interval=month lead=24;
run;

/*Excercise 6
To compete with PROC ARIMA, consider fitting a seasonal exponential smoothing model by using PROC ESM.
The macro %AutoESM fits all seven supported models and compiles statistics on each model.
Select the model to forecast with the smallest goodness-of-fit statistic and make a dedicated proc ESM with this method on the work.Air1990_2000 where Date<='31DEC2000'd.
*/
title1 "Excercise 6";
%AutoESM(work.Air1990_2000, work.smoothing, Passengers, Date);

	/*Print the table with the models sorted based on MAPE value */
proc print ;
proc sort data=work.smoothing;
	by MAPE;
run;

run;

/*From the above table we can see that addwinter model have smallest good-fit statistics*/
proc esm data=work.Air1990_2000(where=(Date<='31DEC2000'd)) 
		outstat=work.goodfit;
	id Date interval=month;
	forecast Passengers / model=addwinters;
run;

/*Excercise 7
Compare the AIC and MAPE… for the following models
1.	ARIMA(1,1,1)(0,1,1)12
2.	ARIMA(0,1,1)(0,1,1)12
3.	Winter additive
4.	Lienar+SeasDummies

As stated elsewhere, the SSE versions of AIC and SBC must be used.
While the last two models in the table are competitive based on MAPE, the MAPE values are too close to provide compelling evidence for choosing any model. On the other hand, the information criteria favor the ARIMA models. Then it illustrates the idea that you should consider more than just a single goodness-of-fit statistic when selecting a model
*/
title1 "Excercise 7";
%GOFstats(ModelName=ARIMA(0, 1, 1)(0, 1, 1)12, DSName=work.arima4_1, 
	OutDS=work.arima4_11, NumParms=8, ActualVar=Passengers, ForecastVar=Forecast);
%GOFstats(ModelName=ARIMA(1, 1, 1)(0, 1, 1)12, DSName=work.arima4_2, 
	OutDS=work.arima4_21, NumParms=8, ActualVar=Passengers, ForecastVar=Forecast);
%GOFstats(ModelName=WinterAdditive, DSName=work.goodfit, OutDS=work.goodfit_1, 
	NumParms=8, ActualVar=Passenger, ForecastVar=Forecast);
%GOFstats(ModelName=Linera_SeasDummies, DSName=work.arma5_1b, 
	OutDS=work.lin_ses, NumParms=8, ActualVar=Passengers, ForecastVar=Forecast);

data work.compare;
	set work.arima4_11 work.arima4_21 work.goodfit_1 work.lin_ses;
run;

proc sort data=work.compare out=work.aic;
	by AIC_SSE;
run;

proc print data=work.aic noobs;
	var Model MAPE AIC_SSE;
run;

/*
•  For the purposes of this exercise, which model would appear to be a good choice?
Ans :  Based on the AIC and SBC criterias ARIMA(1,1,1)*(0,1,1)12 has the lowest good-fit statistics.
whereas, when we consider the MAPE value then Winter Additive model is good.
*/

