# Cattle-data
R code and cattle weight longitudinal dataset from my MSc Statistics dissertation (Chen Ling, ID: 11619845). Includes GEE analysis of 60 cattle across 11 time points under two treatments.

## Data Description 
The cattle dataset includes repeated weight measurements for each subject across 11 time points, along with treatment group assignment and measurement days. Each subject corresponds to a unique cattle identifier, and the primary variables are body weight (response), treatment group (A or B), and measurement days (ranging from day 0 to day 133).  

To explore the longitudinal nature of the data and illustrate within-subject correlation and temporal variation, the following figure presents a plot of weight changes over time by treatment group.

## Model Fitting and Correlation Structure Comparison
We fitted GEE models with four different working correlation structures—Independent, Exchangeable, AR(1), and Unstructured—assuming a Gaussian distribution and identity link function.  
The estimated coefficients and corresponding model fit (QIC) are summarized below.

### Marginal model (without interaction)
$$
\text{weight}_{ij} = \beta_0 + \beta_1 \cdot \text{days}_{ij} + \beta_2 \cdot \text{treatment}_i + \varepsilon_{ij}
$$

**Table: GEE estimates under different correlation structures (without interaction)**

|                         | Independent | Exchangeable | AR(1)  | Unstructured |
|-------------------------|-------------|--------------|--------|--------------|
| Intercept (Estimate)    | 226.339     | 226.339      | 225.479| 230.581      |
| Std. Error              | 2.307       | 2.307        | 2.228  | 2.409        |
| p-value                 | < 2 × 10⁻¹⁶ | < 2 × 10⁻¹⁶ | < 2 × 10⁻¹⁶ | < 2 × 10⁻¹⁶ |
| days (Estimate)         | 0.812       | 0.812        | 0.759  | 0.708        |
| Std. Error              | 0.017       | 0.017        | 0.019  | 0.024        |
| p-value                 | < 2 × 10⁻¹⁶ | < 2 × 10⁻¹⁶ | < 2 × 10⁻¹⁶ | < 2 × 10⁻¹⁶ |
| treatmentA (Estimate)   | 1.661       | 1.661        | 2.590  | 2.793        |
| Std. Error              | 3.667       | 3.667        | 3.607  | 3.194        |
| p-value                 | 0.651       | 0.650        | 0.470  | 0.380        |

**Table: QIC values under different working correlation structures**

| Correlation Structure | QIC    |
|-----------------------|--------|
| Independent           | 203856 |
| Exchangeable          | 203856 |
| AR(1)                 | 218156 |
| Unstructured          | 221320 |

Although the independent and exchangeable structures yield the same (lowest) QIC values, the estimated correlation parameter under the exchangeable structure is α̂ = 0.618, which is substantially greater than zero.  
This indicates significant within-cluster correlation in the data.  
Therefore, the exchangeable structure is preferred as the final working correlation structure.

## Wald Test for Interaction Term
To examine whether treatment modifies the rate of weight change over time, we consider the following model with an interaction term between days and treatment:

$$
\text{weight}_{ij} = \beta_0 + \beta_1 \cdot \text{days}_{ij} + \beta_2 \cdot \text{treatment}_i + \beta_3 \cdot (\text{days}_{ij} \times \text{treatment}_i) + \varepsilon_{ij}
$$

**Table: Wald test for model comparison (with vs without interaction)**

| Hypothesis                              | p-value |
|-----------------------------------------|---------|
| H₀: No interaction effect (β₃ = 0)      | 0.383   |

Since the p-value is greater than 0.05, the interaction term is not statistically significant.  
This indicates that the rate of weight change over time does not significantly differ between treatment groups.  
The simpler model without interaction is thus preferred.

**Table: Estimated coefficients from the selected GEE model (Exchangeable structure, without interaction)**

|                | Intercept | days   | treatmentA |
|----------------|-----------|--------|------------|
| Estimate       | 226.3390  | 0.8117 | 1.6606     |
| Std. Error     | 2.3075    | 0.0174 | 3.6670     |
| Wald Statistic | 9621.54   | 2165.70| 0.21       |
| p-value        | < 2e⁻¹⁶   | < 2e⁻¹⁶| 0.650      |
| Signif. Code   | ***       | ***    |            |

## Interpretation of Results
- The coefficient for days is statistically significant (estimate = 0.8117, p < 2 × 10⁻¹⁶).  
  → This indicates a consistent increase in cattle weight by approximately 0.81 kg per day, regardless of treatment.  

- The coefficient for treatmentA is 1.6606, but with a p-value of 0.650, suggesting no significant difference in average weight between the treatment and control groups.  

- **Conclusion**: The weight gain trend is primarily explained by time rather than treatment type.
