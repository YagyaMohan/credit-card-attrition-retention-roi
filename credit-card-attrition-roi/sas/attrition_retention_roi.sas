%let interchange_rate = 0.015;   /* ASSUMED */
%let cost_per_customer = 10;     /* ASSUMED */

proc import datafile="/home/u64618582/Project 1/BankChurners.csv"
    out=work.churn
    dbms=csv
    replace;
    getnames=yes;
run;

proc freq data=work.churn nlevels;
    tables CLIENTNUM / noprint;
run;
proc freq data=work.churn;
    tables Attrition_Flag;
run;
proc freq data=work.churn;
    tables Income_Category*Attrition_Flag / nopercent nocol;
run;
proc freq data=work.churn;
    tables Card_Category*Attrition_Flag / nopercent nocol;
run;
proc freq data=work.churn;
    tables Months_Inactive_12_mon*Attrition_Flag / nopercent nocol;
run;

proc sql;
    create table work.band_summary as
    select case when Months_Inactive_12_mon = 0 then '0 months inactive'
                when Months_Inactive_12_mon between 1 and 2 then '1-2 months inactive'
                when Months_Inactive_12_mon between 3 and 4 then '3-4 months inactive'
                when Months_Inactive_12_mon between 5 and 6 then '5-6 months inactive'
           end as Band,
           count(*) as n_customers,
           sum(case when Attrition_Flag = 'Attrited Customer' then 1 else 0 end) as n_left,
           sum(case when Attrition_Flag = 'Attrited Customer' then Total_Trans_Amt else 0 end) as spend_of_leavers,
           calculated spend_of_leavers * &interchange_rate as revenue_at_risk,
           calculated n_left / calculated n_customers as attrition_rate
    from work.churn
    group by calculated Band
    order by Band;
quit;

proc print data=work.band_summary;
    format attrition_rate percent8.1 spend_of_leavers revenue_at_risk comma12.;
run;
data work.roi_scenarios;
    set work.band_summary;
    do success_rate = 0.10, 0.20, 0.30;
        campaign_cost = n_customers * &cost_per_customer;
        revenue_saved = revenue_at_risk * success_rate;
        net_gain = revenue_saved - campaign_cost;
        roi = net_gain / campaign_cost;
        output;
    end;
run;

proc print data=work.roi_scenarios;
    format success_rate percent8. roi percent8.1
           revenue_at_risk revenue_saved campaign_cost net_gain comma12.;
run;
proc export data=work.roi_scenarios
    outfile="/home/u64618582/Project 1/roi_scenarios.csv"
    dbms=csv replace;
run;
proc export data=work.band_summary
    outfile="/home/u64618582/Project 1/band_summary.csv"
    dbms=csv replace;
run;