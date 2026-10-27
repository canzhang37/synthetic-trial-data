# Design: can synthetic copies of a clinical trial reproduce its findings?

Written before any synthetic data set was generated. Changes after that point go under Amendments, with the reason.

## Question

Synthetic patient data are proposed as a way to share or augment clinical data. For an analyst the first question is narrow: if the trial's main analyses are rerun on a synthetic copy, do they give the same answers? This project compares three generators, sequential CART, a Bayesian network and a conditional tabular GAN, with the classical benchmark for "another data set like this one", the nonparametric bootstrap, on a completed randomized trial with known results.

## Data

The colon cancer adjuvant chemotherapy trial in the R package survival (version 3.8.3, data set `colon`): patients with resected stage B or C colon cancer randomized to observation, levamisole, or levamisole plus fluorouracil (Laurie et al. 1989; Moertel et al. 1990). The data hold two records per patient, recurrence and death; they are reshaped to one row per patient. Patients missing the number of positive nodes or tumor differentiation are dropped, leaving 888 of 929.

Fifteen variables are synthesized: treatment arm (rx), sex, age, obstruction, perforation, adherence to nearby organs, differentiation (3 levels), extent of local spread (4 levels), time from surgery to registration (short or long), number of positive nodes, more than 4 positive nodes (node4, kept as recorded: it disagrees with the node count for 12 patients), recurrence time and status, and death time and status.

## Reference findings

Computed on the 888 patients before this design was written; they are the published findings the synthetic data should reproduce. All are Cox models, coefficients on the log hazard ratio scale with model-based standard errors.

| id | endpoint | model | contrast | HR | z |
|---|---|---|---|---|---|
| F1 | recurrence | rx | levamisole + fluorouracil vs observation | 0.59 | -4.32 |
| F2 | death | rx | levamisole + fluorouracil vs observation | 0.68 | -3.16 |
| F3 | recurrence | rx | levamisole vs observation (no effect) | 0.96 | -0.36 |
| F4 | death | rx + node4 + extent + obstruct + differ + age + sex | more than 4 positive nodes | 2.56 | 9.24 |

Extent and differentiation enter F4 as numeric scores, as in the published examples of this data set.

## Methods

Each method produces M = 100 data sets of 888 rows. Replicate m uses seed 2027 + m and refits the generator before drawing.

- **Bootstrap**: 888 rows drawn with replacement from the original.
- **CART**: synthpop `syn()` with method "cart" for every variable after the first, visit sequence in the order listed under Data, other settings at their defaults.
- **Bayesian network**: age is cut into quintiles, the node count into 0-1, 2, 3, 4, 5-8 and 9 or more, and each time into deciles; the other variables are already categorical. The structure is learned by hill climbing with BIC (bnlearn `hc()`, defaults), parameters by Bayesian estimation with imaginary sample size 1, and 888 rows are drawn with `rbn()`. Age and node count are then drawn from the original values inside the sampled bin, and times uniformly inside the sampled decile, rounded to whole days.
- **CTGAN**: the Python ctgan package at its default settings (300 epochs, batch size 500), with every variable except age, node count and the two times declared discrete. Continuous outputs are rounded to integers and clipped to the observed range.

The structural rules of the data are that recurrence cannot come after death, and that a patient with no recurrence is censored for recurrence at the death or last follow-up time. Before analysis every data set is repaired: recurrence time becomes min(recurrence time, death time), and becomes the death time when recurrence status is 0. Violations are counted before the repair.

## Measures

For every data set:

- F1 to F4 refitted: log HR, standard error, p value, 95% interval.
- Fidelity: standardized propensity mean squared error (S_pMSE, synthpop `utility.gen`, logistic model with two-way interactions); mean total variation distance over the categorical variables and mean Kolmogorov-Smirnov distance over the four continuous ones; largest vertical distance between the synthetic and original Kaplan-Meier curves, within arm, for both endpoints; mean absolute difference between the synthetic and original Spearman correlation matrices.
- Structural rules: share of rows with recurrence after death (V1), and share with recurrence status 0 and a recurrence time different from the death time (V2).
- Privacy: share of rows identical to an original row on all 15 variables, and median Gower distance from each synthetic row to its closest original row.

Augmentation, reported and not checked: each data set is stacked with the original (1,776 rows) and F1 to F4 are refitted, to show what adding generated rows does to the estimate and to the width of its interval.

## Checks and verdicts

A method reproduces a finding when C1 to C3 all hold for it; it reproduces the trial when that is true for all four findings. Bootstrap goes through C1 to C3 as the benchmark.

| id | check | rule |
|---|---|---|
| C1 | same conclusion | share of data sets with p < 0.05 and the original sign (F1, F2, F4) or p >= 0.05 (F3) is at least 80% |
| C2 | estimate | absolute difference between the median log HR and the original is at most half the original standard error |
| C3 | interval | the 95% interval covers the original log HR in at least 90% of data sets |
| C4 | stability | standard deviation of the log HR over the 100 data sets is at most 1.5 times the bootstrap's (generators only) |
| C5 | structural rules | V1 and V2 each at most 1% of rows, averaged over data sets (generators only) |
| C6 | privacy | rows identical to an original row at most 5%, averaged over data sets (generators only) |

Expectations written down in advance, not checks: CART will have the best fidelity, the Bayesian network will weaken the treatment effects because the arm is one node among fifteen, CTGAN will do worst at this sample size, and every generator will give more variable estimates than the bootstrap. Under the bootstrap, C1 for F2 is expected near 88%, because the original z of -3.16 is not far from the 1.96 cut-off.

A check that fails is reported as failed. Generator settings are not tuned on these results.

## Amendments

**Amendment 1, after a smoke test of the evaluation on two data sets per method, before the full evaluation.** The Kaplan-Meier distance is taken over the first five years (1,826 days) instead of the whole follow-up. In the smoke test, two data sets gave a distance of 0.40 that came from the last patient of one arm having an event, which drops the curve to zero where only a handful of patients remain at risk. Fidelity measures are descriptive and no check uses them.
