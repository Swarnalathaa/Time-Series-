# Time-Series-

Project for my Masters course - Time series analysis.

This exercise illustrates how to use PROC ARIMA, PROC FORECAST, and PROC ESM to derive a forecast model for the U.S. Department of Transportation airline data, 1990–2000. The time series before the events of September 11, 2001, is used for the examination.

data work.Air1990_2000;
   set LWFETSP.usairlines
       (where=(Date<='31DEC2000'd));
run;

Exercise 1:

Obtain diagnostic plots from PROC TIMESERIES. You can save the OUTDECOMP table in a table named WORK.OUTDECOMP also.

Check that 
•	the airline passengers’ time series clearly has strong trend and seasonal components.
•	The autocorrelation plots support the finding of trend and seasonality
•	The decomposition plots propose model components for handling trend and seasonality
•	The seasonal components plot is difficult to interpret because it spans all years in the series.

One strategy for overcoming this high-density plot problem is to restrict the seasonal values to few years. 
From the work.OUTDECOMP take the observations for years greater than 1998 and make a SGPLOT with x=Date and y=SC. Optionally add a REFLINE option at the graduation 1 in the Y.

Now the plot of the multiplicative seasonal components for the past three years follows. Of course, the components are constant for each month and thus are identical across all years:
 

 
Question: 
Does the above plot makes it very clear that peak travel occurs in August, and February is the lowest travel month?

Exercise 2:
As we did in the previous exercise make a SPECTRA analysis with Parzen methodology and plot the series with x=PERIOD y=S_01 for 2<=PERIOD<=20.
The data should reflect sinusoidal behavior with periods 12, 4, and 2.4, add REFLINES at the datapoints.

Exercise 3:
The evidence for trend and seasonality is strong enough to forego the Dickey-Fuller tests. 
The following DATA step adds candidate trend and seasonal terms to the data.
Question: 
Through this dataset
•	How many forecasting periods will be extrapolated?
•	Do the code create dummies for months?
•	Do the code create time index?

      data work.Air1990_2000;
            set work.Air1990_2000 end=lastobs;
            array Seas{*} MON1-MON11;
            retain TwoPi . Time 0 MON1-MON11 .;
            if (TwoPi=.) then TwoPi=2*constant("pi");
            if (MON1=.) then do index=1 to 11;
                 Seas[index]=0;
        end;
        Time+1;
        S2p4=sin(TwoPi*Time/2.4);
        C2p4=cos(TwoPi*Time/2.4);
        S4=sin(TwoPi*Time/4);
        C4=cos(TwoPi*Time/4);
        S12=sin(TwoPi*Time/12);
        C12=cos(TwoPi*Time/12); 
        if (month(Date)<12) then do;
            Seas[month(Date)]=1;
            output;
            Seas[month(Date)]=0;
        end;
       else output;
       if (lastobs) then do;
             Passengers=.;
       do index=1 to 24;
             Time+1;
             Date=intnx("month",Date,1);
             S2p4=sin(TwoPi*Time/2.4);
             C2p4=cos(TwoPi*Time/2.4);
             S4=sin(TwoPi*Time/4);
             C4=cos(TwoPi*Time/4);
             S12=sin(TwoPi*Time/12);
             C12=cos(TwoPi*Time/12);
             if (month(Date)<12) then do;
                Seas[month(Date)]=1;
                output;
                Seas[month(Date)]=0;
             end;
           else output; 
         end;
       end;
      drop index TwoPi;
    run;


Exercise 4:
The classic airline model proposed by Box and Jenkins for the international airline passengers data from 1948 to 1960 uses a log transformation and fits an ARIMA(0,1,1)(0,1,1)12 model to the transformed series. 
•	At time, the log transformation was primarily used as a variance stabilizing transformation. 
•	Your modern airline data does not exhibit increasing variance as a function of time, so the log transformation will not be considered.

Fit the model on Passengers variable from the Air1990_2000 dataset.
Question:
Check the Ljung-Box statistics. Is the right model?

Box and Jenkins recommend that models with difference orders 1 and 12 use corresponding MA subset factors. This is consistent with the classic airline model. 
But the addition of P=1 will be tested to improve the fitted statistics.
Fit the suggested model.

Question:
Check the Ljung-Box statistics. Is the right model?
It seems (on your behalf) that the autocorrelation plots suggest white noise, but the Ljung-Box test for lags 3 through 6 rejects white noise so we decide to test one additional model.

Exercise 5:
Make a ARMA model with linear trend and seasonal dummies (defined in the CROSS=()) option 
Make a ARMA(0,0,1) model with linear trend and seasonal dummies (defined in the CROSS=() option) and forecast it to 24 periods.

Exercise 6: 
To compete with PROC ARIMA, consider fitting a seasonal exponential smoothing model by using PROC ESM. 
The macro %AutoESM fits all seven supported models and compiles statistics on each model.
Select the model to forecast with the smallest goodness-of-fit statistic and make a dedicated proc ESM with this method on the work.Air1990_2000 where Date<='31DEC2000'd. 
The WHERE clause removes the data added to the end. Otherwise, PROC ESM would forecast 24 months beyond the end of the extended data, which would be 48 months into the future.
 

Exercise 7:
Compare the AIC and MAPE… for the following models
1.	ARIMA(1,1,1)(0,1,1)12
2.	ARIMA(0,1,1)(0,1,1)12
3.	Winter additive
4.	Lienar+SeasDummies

As stated elsewhere, the SSE versions of AIC and SBC must be used. 
While the last two models in the table are competitive based on MAPE, the MAPE values are too close to provide compelling evidence for choosing any model. On the other hand, the information criteria favor the ARIMA models. Then it illustrates the idea that you should consider more than just a single goodness-of-fit statistic when selecting a model

For the purposes of this exercise, which model would appear to be a good choice?
