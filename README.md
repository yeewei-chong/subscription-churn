# Customer Subscription Churn Analysis

This survival analysis project comparing the churn behaviours of different subscription tiers uses the raw datasets from the WSDM 2017 KKBox's Churn Prediction Challenge (link: https://www.kaggle.com/competitions/kkbox-churn-prediction-challenge/data), namely members_v3.csv for member data, and transactions.csv and transactions_v2.csv for transaction data. 

### **Key Results**
- The NT\$99 tier was associated with a 79.39% lower churn risk compared to the NT\\\$129 tier, 95% CI: (-80.05%, -78.69%), significance $\approx$ 0.00.
- The NT\\\$129 tier was associated with a 39.99% lower churn risk compared to the NT\\\$149 tier, 95% CI: (-41.89%, -38.03%), significance $\approx$ 0.00.
- Most cities did not show evidence for having different churn risks. Only city 13 was marginally associated with a 15.17% higher churn risk compared to city 1, 95% CI: (-2.06%, +35.42%), significance = 0.09.
- City 13 experienced an estimated 21.93% lower risk effect for the NT\\\$149 tier compared to city 1, 95% CI: (-33.66%, -8.13%), significance = 0.003, indicating that users registered in city 13 may be less adverse towards a price increase.
- Regardless, a price increase by NT\\\$20 from NT\\\$129 does not outweigh the churn risk, as the median lifetime value of NT\\\$129 tier customers is estimated to be NT\\\$32,895 - NT\\\$35,862, whereas for NT\\\$149 tier customers, it is estimated to be only NT\\\$18,178 - NT\\\$18,327.
- Even in city 13, where the churn risk for the higher tier is less prominent, the median lifetime value of NT\\\$129 tier customers is estimated to be NT\\\$22,446 - NT\\\$35,862, whereas for NT\\\$149 tier customers, it is estimated to be only NT\\\$20,860 - NT\\\$22,499.


### **Model**
$$
h(t) = h_0(t)\cdot\exp\bigl[\beta_1\cdot\mathrm{pricing\_tier} + \beta_2\cdot\text{city} + \beta_3\cdot(\mathrm{pricing\_tier}\cdot\text{city})\bigr]
$$
where


### **Overview**
The data was validated and loaded into a PostgreSQL database before event variables were derived using CTE and window functions. Finally, customer churn risk was analysed using Kaplan-Meier curves and a Cox Proportional Hazards model in R.
