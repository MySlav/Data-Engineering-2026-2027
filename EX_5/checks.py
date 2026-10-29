"""Checks for Exercise 5 – Handling Missing Values.

The notebook calls the functions in this file in the "✅ Check" cells.
Expected results are stored as digests (hashes), not as numbers – you have to compute them yourself.
If you get a new version of this file after `git pull`, re-run the cells of section 0.
"""
import hashlib

import numpy as np
import pandas as pd

_EXPECTED = {'t1_n_missing': 'f06ed89fff0c3c32',
 't1_pct': '5b1839e9e06f57a1',
 't1_share': 'e1d19843ba307adc',
 't1_top': '9661c6ef7289115b',
 't1_unique': 'cdc2c2ee41f3284b',
 't1b_share': '8a9645514b5ed62d',
 't1b_unknown': 'fad647d54b440a2d',
 't1b_years': '33c4ad59be0d5f86',
 't2a_age_rates': '451324b1cd276c7a',
 't2a_cabin_rates': '82252adbad181450',
 't2a_sex_p': '0c6f67f5569485c0',
 't2b_fares': '671cd1454d2ecc66',
 't3_mar': 'd748b3a53c0fc98e',
 't3_mnar': '7e9eb9e245c7125d',
 't4a_rmse': '34c7c0b16372dc3a',
 't6a_left': '94251565f2235b06',
 't6b_ff1': 'a24fa42b08bca473',
 't6b_lin1': '6a53395e942e9197',
 't7_cyl': '69f8ce64007837d9',
 't7_doors': '67309a7696f71fa4',
 't7_hp': 'f06ed89fff0c3c32',
 't7_hp_el': '19a0d75fb780aeec',
 't7_market': 'b872414488e27d74',
 't7_msrp': '2fd47ddc551ec1bb',
 't7_raw_msrp': 'ab0c377f7956435c',
 't7_rows': '17c1d0acc8d78423',
 't7_trans': 'fad647d54b440a2d'}


# ---------------------------------------------------------------- helpers

def _norm(x):
    if isinstance(x, (list, tuple, np.ndarray, pd.Series)):
        return "(" + ",".join(_norm(v) for v in list(x)) + ")"
    if isinstance(x, (bool, np.bool_)):
        return str(bool(x))
    if isinstance(x, (int, float, np.integer, np.floating)):
        v = float(x)
        if v != v:
            return "nan"
        return f"{round(v, 3) + 0.0:.3f}"
    return str(x)


def _digest(x):
    return hashlib.sha256(("ex5en|" + _norm(x)).encode("utf-8")).hexdigest()[:16]


def _correct(key, value):
    try:
        return _digest(value) == _EXPECTED[key]
    except Exception:
        return False


def _unsolved(*values):
    if any(v is ... for v in values):
        raise AssertionError("❌ Not solved yet – replace `...` with your code and run the task cell again.")


def _check(condition, error_message, ok_message=None):
    if not condition:
        raise AssertionError("❌ " + error_message)
    if ok_message:
        print(ok_message)


def _safe(test):
    try:
        return bool(test())
    except Exception:
        return False


def _call(f, *args, **kwargs):
    """Calls a student function; turns `...` placeholders and crashes into readable messages."""
    try:
        result = f(*args, **kwargs)
    except Exception as e:
        if "ellipsis" in str(e).lower() or "not fitted" in str(e).lower():
            _unsolved(...)
        raise AssertionError(f"❌ Your function raised an error: {type(e).__name__}: {e}")
    if result is ... or (isinstance(result, tuple) and any(v is ... for v in result)):
        _unsolved(...)
    return result


def _rmse_mean(values):
    return float(np.mean(np.asarray(values, dtype=float)))


# ---------------------------------------------------------------- 1. hidden missing values

def task_1(profile, cars):
    prof = _call(profile, cars)
    if isinstance(prof, pd.DataFrame) and any(v is ... for v in prof.to_numpy().ravel()):
        _unsolved(...)
    needed = ["dtype", "n_missing", "pct_missing", "n_unique", "top_value", "top_share"]
    _check(isinstance(prof, pd.DataFrame) and all(c in prof.columns for c in needed) and len(prof) == cars.shape[1],
           "profile must return a DataFrame with one row per column of df and the columns " + ", ".join(needed) + ".")
    _check(_correct("t1_n_missing", prof.loc["Engine HP", "n_missing"]),
           "n_missing is wrong – count the True values of s.isna().")
    _check(_correct("t1_pct", prof.loc["Engine HP", "pct_missing"]),
           "pct_missing is wrong – it is a percentage (0–100) of ALL rows, not a share (0–1) and not of non-missing rows.")
    _check(_correct("t1_unique", prof.loc["Engine HP", "n_unique"]),
           "n_unique is wrong – count distinct NON-missing values (s.nunique()).")
    _check(_correct("t1_top", prof.loc["MSRP", "top_value"]),
           "top_value is wrong – it is the first index of `counts` (counts.index[0]).")
    _check(_correct("t1_share", prof.loc["MSRP", "top_share"]),
           "top_share is wrong – it is the first value of `counts` (counts.iloc[0]), a share between 0 and 1.",
           "✅ Correct! Look at MSRP: thousands of distinct prices, yet one exact value covers almost 9 % of all cars. "
           "A real measurement rarely repeats like that. (And Popularity has exactly as many distinct values as Make – "
           "it is a property of the make, not of the car.)")


def task_1b(year_range_2000, share_2000_old, n_unknown_transmission):
    _unsolved(year_range_2000, share_2000_old, n_unknown_transmission)
    _check(_safe(lambda: len(year_range_2000) == 2) and _correct("t1b_years", list(year_range_2000)),
           "1) Filter cars_dd with MSRP == 2000 and take (min, max) of Year.")
    _check(_correct("t1b_share", share_2000_old),
           "2) Filter cars_dd to Year <= 2000, then take the mean of (MSRP == 2000) – a share between 0 and 1.")
    _check(_correct("t1b_unknown", n_unknown_transmission),
           "3) Compare cars_dd['Transmission Type'] with the text 'UNKNOWN' and sum.",
           f"✅ Correct! No car newer than {year_range_2000[1]} has this 'price', and more than half of the old ones do: "
           "2000 means 'price unknown'. isna() sees none of these gaps – and the gap depends on Year, so it has a mechanism too.")


# ---------------------------------------------------------------- 2. mechanisms

def task_2a(missingness_test, titanic):
    rates, p = _call(missingness_test, titanic, "Age", "Pclass")
    _check(isinstance(rates, pd.Series) and len(rates) == 3,
           "rates must be a Series with one value per group – group df[col].isna() by df[by] and take the mean.")
    _check(_correct("t2a_age_rates", rates.sort_index()),
           "rates for Age by Pclass are wrong – they are shares between 0 and 1 (mean of isna()), as in the demo.")
    _check(_safe(lambda: float(p) < 1e-6),
           "p_value for Age by Pclass is wrong – take the second element of chi2_contingency(pd.crosstab(df[by], missing)).")
    rates_c, _ = _call(missingness_test, titanic, "Cabin", "Pclass")
    _check(_correct("t2a_cabin_rates", rates_c.sort_index()),
           "Your function seems to work only for Age – use the arguments col and by, not fixed column names.")
    _, p_sex = _call(missingness_test, titanic, "Age", "Sex")
    _check(_correct("t2a_sex_p", p_sex),
           "p_value for Age by Sex is wrong – use chi2_contingency with its default settings on the crosstab.",
           "✅ Correct! Evidence for Age – missing rate (%) by group and the chi-square p-value:")
    rows = []
    for by in ["Pclass", "Sex", "Embarked", "SibSp", "Parch"]:
        r, pv = missingness_test(titanic, "Age", by)
        rows.append({"variable": by, "missing % by group": {k: round(100 * v, 1) for k, v in r.items()},
                     "p-value": f"{pv:.1e}"})
    with pd.option_context("display.max_colwidth", 120):
        print(pd.DataFrame(rows).to_string(index=False))


def task_2b(fare_by_age_missing, fare_p):
    _unsolved(fare_by_age_missing, fare_p)
    _check(_safe(lambda: _correct("t2b_fares", [fare_by_age_missing.loc[False], fare_by_age_missing.loc[True]])),
           "1) Group titanic by titanic['Age'].isna() and take the mean of 'Fare'.")
    _check(_safe(lambda: float(fare_p) < 0.01) and _safe(lambda: float(fare_p) > 1e-6),
           "2) Use ttest_ind(fare_of_missing, fare_of_present, equal_var=False).pvalue.",
           "✅ Correct! Passengers without a recorded age paid clearly less on average – another sign that the gaps are not MCAR.")


def task_2c(auc_missing):
    _unsolved(auc_missing)
    _check(_safe(lambda: 0.65 < float(auc_missing) < 0.80),
           "Expected a mean ROC AUC from cross_val_score(LogisticRegression(max_iter=1000), X_m, age_missing, "
           "cv=StratifiedKFold(5, shuffle=True, random_state=0), scoring='roc_auc').",
           f"✅ Correct! AUC = {float(auc_missing):.3f}: clearly above 0.5, so the gaps are partly predictable from observed columns "
           "– MCAR is rejected. It is far from 1, so much of the missingness stays unexplained (it could still be partly MNAR).")


# ---------------------------------------------------------------- 3. simulation

def task_3(regression_impute, age, income, masks):
    y_mar = np.where(masks["MAR"], np.nan, income)
    filled = np.asarray(_call(regression_impute, age, y_mar), dtype=float)
    _check(filled.shape == income.shape and not np.isnan(filled).any(),
           "The result must have the same length as y and contain no NaN.")
    _check(np.allclose(filled[~masks["MAR"]], income[~masks["MAR"]]),
           "Known values must stay unchanged – only the NaN positions are filled.")
    _check(_correct("t3_mar", round(filled.mean(), 1)),
           "Deterministic regression is wrong – fit LinearRegression on the KNOWN rows only: model.fit(x[known].reshape(-1, 1), y[known]).")
    y_mnar = np.where(masks["MNAR"], np.nan, income)
    _check(_correct("t3_mnar", round(np.asarray(regression_impute(age, y_mnar)).mean(), 1)),
           "Your function works for MAR but not for MNAR – does it use the arguments x and y (not global variables)?")
    y_mcar = np.where(masks["MCAR"], np.nan, income)
    sd_ratio = np.asarray(_call(regression_impute, age, y_mcar, stochastic=True)).std() / income.std()
    _check(0.97 < sd_ratio < 1.04,
           "Stochastic version: resid_sd is the standard deviation of (y[known] - model.predict(x[known].reshape(-1, 1))).",
           "✅ Correct! Comparison with the truth (bias = imputed mean − true mean; SD = standard deviation of the completed column):")
    rows = {}
    for name, m in masks.items():
        y = np.where(m, np.nan, income)
        mean_imp = np.where(m, np.nanmean(y), y)
        reg = np.asarray(regression_impute(age, y))
        sto = np.asarray(regression_impute(age, y, stochastic=True))
        rows[name] = {"bias: mean imp.": mean_imp.mean() - income.mean(), "bias: regression": reg.mean() - income.mean(),
                      "bias: stochastic reg.": sto.mean() - income.mean(), "SD true": income.std(),
                      "SD mean imp.": mean_imp.std(), "SD regression": reg.std(), "SD stochastic reg.": sto.std()}
    print(pd.DataFrame(rows).T.round(1).to_string())


# ---------------------------------------------------------------- 4. comparing imputers

def task_4(impute_title_median, impute_knn_scaled, impute_iterative, evaluate, baseline):
    ok = []
    try:
        s = evaluate(lambda d: _call(impute_title_median, d))
        if _correct("t4a_rmse", round(s["RMSE"], 2)):
            print("✅ a) median by Title – correct.")
            ok.append(("median by Title", s))
        else:
            print("❌ a) median by Title – wrong result. Fill df['Age'] with df.groupby('Title')['Age'].transform('median').")
    except AssertionError as e:
        print("a)", e)

    try:
        s = evaluate(lambda d: _call(impute_knn_scaled, d))
        unscaled = baseline.loc["KNN, all columns, NOT scaled", "RMSE"]
        if not (15 < _rmse_mean(_call(impute_knn_scaled, _masked_example(evaluate))) < 45):
            print("❌ b) KNN scaled – the imputed ages are not in years. Did you inverse_transform back to the original scale?")
        elif s["RMSE"] < unscaled - 0.3 and s["RMSE"] < 13.2:
            print("✅ b) KNN with scaling – correct, and clearly better than without scaling.")
            ok.append(("KNN, scaled", s))
        else:
            print("❌ b) KNN scaled – the error is not lower than without scaling. Scale with StandardScaler BEFORE KNNImputer, "
                  "and return the Age column after inverse_transform.")
    except AssertionError as e:
        print("b)", e)

    try:
        s = evaluate(lambda d: _call(impute_iterative, d))
        if s["RMSE"] < baseline.loc["median by Pclass", "RMSE"] - 0.5:
            print("✅ c) IterativeImputer – correct.")
            ok.append(("IterativeImputer (MICE)", s))
        else:
            print("❌ c) IterativeImputer – the error is too high. Fit it on ALL columns of df and return the Age column.")
    except AssertionError as e:
        print("c)", e)

    if len(ok) < 3:
        raise AssertionError("❌ Not all parts are correct yet (see above).")
    table = pd.concat([baseline, pd.DataFrame({k: v for k, v in ok}).T.round(2)]).sort_values("RMSE")
    print("\nAll methods, sorted by RMSE (SD of the true hidden ages ≈ 14.5):")
    print(table.to_string())


def _masked_example(evaluate):
    # the masked frame of seed 0, taken from the notebook's own helper through evaluate's globals
    g = evaluate.__globals__
    masked, _ = g["mask_known"](g["known"], seed=0)
    return masked


# ---------------------------------------------------------------- 5. pipeline

def task_5(model, auc_pipeline):
    _unsolved(auc_pipeline)
    try:
        ct = model.steps[0][1]
        parts = {name: t for name, t, _ in ct.transformers}
        num, cat = parts["num"], parts["cat"]
        cat_imp = cat.steps[0][1] if hasattr(cat, "steps") else cat
    except Exception:
        raise AssertionError("❌ The pipeline structure is broken – keep the ColumnTransformer with the parts 'num' and 'cat'.")
    _check(type(num).__name__ == "SimpleImputer" and num.strategy == "median" and num.add_indicator,
           "'num' must be SimpleImputer(strategy='median', add_indicator=True).")
    _check(type(cat_imp).__name__ == "SimpleImputer" and cat_imp.strategy == "most_frequent",
           "'cat' must start with SimpleImputer(strategy='most_frequent').")
    _check(_safe(lambda: 0.84 < float(auc_pipeline) < 0.91),
           "auc_pipeline should be the MEAN of cross_val_score(model, X, y, cv=cv, scoring='roc_auc').",
           f"✅ Correct! ROC AUC = {float(auc_pipeline):.3f}. In every fold the medians were learned on the training folds only, "
           "and the indicator column for Age was added automatically.")


# ---------------------------------------------------------------- 6. time series

def task_6a(air, air_interp, cols):
    _unsolved(air_interp[cols[0]].iloc[0])
    before = air[cols].isna().sum().sum()
    after = air_interp[cols].isna().sum().sum()
    _check(after < before, "Nothing was filled – did you call interpolate?")
    first_before = air.groupby("City").head(1)[cols].isna().sum().sum()
    first_after = air_interp.groupby("City").head(1)[cols].isna().sum().sum()
    _check(first_after == first_before,
           "The first day of some city got a value – either it came from the PREVIOUS city (group by 'City' first) "
           "or you filled outside the known values (limit_area='inside').")
    _check(air_interp.loc[air_interp["City"] == "Aizawl", "Xylene"].isna().all(),
           "Aizawl should still have no Xylene at all.")
    _check(air_interp.loc[air_interp["City"] == "Mumbai", "AQI"].isna().sum() > 1000,
           "Mumbai's long AQI gap was filled – set limit=7.")
    _check(_correct("t6a_left", after),
           "Not quite – use air.groupby('City')[cols].transform(lambda s: s.interpolate(limit=7, limit_area='inside')).",
           f"✅ Correct! {before - after} gaps filled inside each city; {after} stay missing because they are too long or at the edges.")


def task_6b(gap_mae, delhi):
    lin1 = _call(gap_mae, delhi, 1, "linear")
    ff1 = _call(gap_mae, delhi, 1, "ffill")
    _check(_safe(lambda: np.isfinite(float(lin1)) and np.isfinite(float(ff1))),
           "gap_mae returned NaN – compute the error only on positions start:start + gap.")
    _check(_correct("t6b_lin1", round(float(lin1), 1)) and _correct("t6b_ff1", round(float(ff1), 1)),
           "The MAE is wrong – mean of |filled − s| on positions start:start + gap (use .iloc), "
           "and fill with masked.ffill() or masked.interpolate(method=method).")
    lin7, ff7 = gap_mae(delhi, 7, "linear"), gap_mae(delhi, 7, "ffill")
    _check(lin7 < ff7 and lin1 < ff1, "Unexpected result – check the fill line for both methods.",
           "✅ Correct! Linear interpolation wins at every gap length here, and the error of both grows with the gap.")


# ---------------------------------------------------------------- 7. final task

def task_7(cars, silver, decision_log, validate):
    def step(description, test):
        success = _safe(test)
        print(("✅ " if success else "❌ ") + description)
        return success

    el = silver["Engine Fuel Type"] == "electric"
    results = [
        step("0) the input table cars was not changed",
             lambda: cars.shape == (11914, 16) and _correct("t7_raw_msrp", (cars["MSRP"] == 2000).sum())),
        step("1) no full duplicates",
             lambda: _correct("t7_rows", len(silver))),
        step("2) no 'UNKNOWN' in Transmission Type, it is NaN instead",
             lambda: (silver["Transmission Type"] == "UNKNOWN").sum() == 0
                     and _correct("t7_trans", silver["Transmission Type"].isna().sum())),
        step("3) MSRP_unknown exists, no price 2000 left",
             lambda: _correct("t7_msrp", silver["MSRP_unknown"].astype(bool).sum())
                     and (silver["MSRP"] == 2000).sum() == 0
                     and silver["MSRP"].isna().sum() == silver["MSRP_unknown"].astype(bool).sum()),
        step("4) Engine Fuel Type is complete",
             lambda: silver["Engine Fuel Type"].notna().all()),
        step("5) electric cars have 0 cylinders, only rotary Mazdas stay NaN",
             lambda: silver.loc[el, "Engine Cylinders"].eq(0).all()
                     and silver.loc[silver["Engine Cylinders"].isna(), "Model"].isin(["RX-7", "RX-8"]).all()
                     and _correct("t7_cyl", silver["Engine Cylinders"].isna().sum())),
        step("6) Number of Doors filled from the same model",
             lambda: _correct("t7_doors", silver["Number of Doors"].isna().sum())),
        step("7) Engine HP complete, Engine_HP_missing exists, electric cars got an electric median",
             lambda: silver["Engine HP"].isna().sum() == 0
                     and _correct("t7_hp", silver["Engine_HP_missing"].astype(bool).sum())
                     and _correct("t7_hp_el", silver.loc[el & silver["Engine_HP_missing"].astype(bool), "Engine HP"].median())),
        step("8) Market Category has no gaps, the new value is 'None'",
             lambda: silver["Market Category"].notna().all()
                     and _correct("t7_market", (silver["Market Category"] == "None").sum())),
        step("   decision log: one row per step 1–8 with the number of rows changed",
             lambda: len(decision_log) == 8 and int(decision_log.loc[decision_log["step"] == 3, "rows changed"].iloc[0])
                     == int(silver["MSRP_unknown"].astype(bool).sum())),
        step("   validate: Bronze fails all 5 rules, Silver passes all",
             lambda: len(validate(cars)) == 5 and validate(silver) == []),
    ]
    print(f"\n{sum(results)}/{len(results)} steps correct")
