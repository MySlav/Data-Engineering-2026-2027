# Exercise 5 – Handling missing values

Related to the Week 5 videos: types of missing data (MCAR, MAR, MNAR), deletion and basic imputation, forward/backward fill, interpolation and missing indicators.
Duration: 80 minutes. Environment: [Jupyter pod](../environment/README.md).

## After this exercise you will be able to

* find missing values that `isna()` does not see (placeholder numbers, text codes) and tell **unknown** values from **not applicable** ones,
* collect evidence about the missingness mechanism (rates by group, chi-square and t-tests, a model that predicts the gaps) and explain why MNAR cannot be proven from data,
* show with a simulation how the mechanism decides which method is biased (deletion, mean imputation, regression and stochastic regression imputation),
* compare imputation methods by hiding known values (median, group median, KNN with scaling, iterative imputation / MICE),
* impute inside a scikit-learn `Pipeline` with missing indicators, and recognise data leakage – including target leakage,
* fill time series within each series and with a limit, and compare `ffill` with interpolation,
* write a Bronze → Silver cleaning function with a decision log and validation rules.

## Folder contents

| File / folder | Description |
|---|---|
| `EX_5_Handling_Missing_Values.ipynb` | notebook with theory, demo code and tasks |
| `checks.py` | task checks the notebook calls in the ✅ cells (no need to open or change it) |
| `data/titanic/train.csv` | Titanic passengers |
| `data/air-quality-data-in-india/city_day.csv` | daily air quality in 26 Indian cities, 2015–2020 |
| `data/cars.csv` | technical data and prices of cars |
| `images/` | overview diagram of missing-value methods |

## How to start

1. Pull the news (`git pull`) – see the [main README](../README.md#before-every-lab-pull-the-news).
2. Open `EX_5_Handling_Missing_Values.ipynb` and save it right away as **`EX_5_my_work.ipynb`** (File → Save Notebook As…).
3. Run the cells of section 0 – they install the `missingno` library and load the data.
4. Run the cells in order. The notebook marks:
   * 📖 theory,
   * ▶️ demo,
   * 🧩 task – replace `...` with your code,
   * ✅ check – prints ✅ or explains what is wrong,
   * ✏️ answer in a markdown cell,
   * ⭐ optional task.

## Sections

| # | Section | Data | ≈ min |
|---|---|---|---|
| 0 | Setup | – | 5 |
| 1 | Missing values you cannot see | cars | 9 |
| 2 | Why is it missing? Testing MCAR, MAR and MNAR with data | Titanic | 14 |
| 3 | Why the mechanism matters: a simulation with known truth | synthetic | 12 |
| 4 | Comparing imputation methods by hiding known values | Titanic | 16 |
| 5 | Missing indicators and data leakage in a pipeline | Titanic | 10 |
| 6 | Time series: fill within each series, and not too far | air quality | 11 |
| 7 | ⭐ Final task: Bronze → Silver cleaning as code | cars | 3 + home |

Tasks marked ⭐ are optional in class. **The final task (section 7)** is started in class and finished at home.
Whatever you don't finish in class, finish at home. The notebook is not submitted or graded – the check cells tell you whether each step is right.
The graded Week 5 assignment is on Moodle; the notebook ends with tips for it.

## Data sources

* Titanic – [Kaggle: Titanic – Machine Learning from Disaster](https://www.kaggle.com/c/titanic)
* Air quality – [Kaggle: Air Quality Data in India (2015–2020)](https://www.kaggle.com/datasets/rohanrao/air-quality-data-in-india), Vopani (Rohan Rao)
* Cars – [Kaggle: Car Features and MSRP](https://www.kaggle.com/datasets/CooperUnion/cardataset), CooperUnion
* The diagram in `images/` is adapted from the Kaggle notebook *A Guide to Handling Missing values in Python* (Parul Pandey).
