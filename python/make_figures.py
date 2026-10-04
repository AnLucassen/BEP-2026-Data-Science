"""Figures for the Holzinger-Swineford stage (weeks 40-41).

Run from the project root, after R/01, R/02 and R/03:
    .venv/bin/python python/make_figures.py        (macOS / Linux)
    .venv\\Scripts\\python python\\make_figures.py   (Windows)
Every figure is saved as PNG (for slides) and PDF (for the LaTeX thesis).
"""
from itertools import combinations
from math import comb, prod
from pathlib import Path
import json

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "results" / "raw" / "hs" / "algorithms"
FIG = ROOT / "figures"
FIG.mkdir(exist_ok=True)

# Okabe-Ito colours: readable for colour-blind readers and in grey print
C = {"DFS": "#0072B2", "Apriori": "#E69F00", "BestFirst": "#009E73",
     "Beam": "#CC79A7", "original": "#555555", "ref": "#D55E00"}
ALGS = ["DFS", "Apriori", "BestFirst", "Beam"]
plt.rcParams.update({"font.size": 9, "axes.spines.top": False,
                     "axes.spines.right": False, "figure.dpi": 120})


def save(fig, name):
    fig.tight_layout()
    for ext in ("png", "pdf"):
        fig.savefig(FIG / f"{name}.{ext}", dpi=300, bbox_inches="tight")
    plt.close(fig)
    print("saved", name)


def run_dir(variant, alg, measure="lrt", min_size=50, log=0, rep=1):
    return RAW / f"{variant}_{alg}_{measure}_min{min_size}_log{log}_rep{rep}"


def topk(variant, alg, **kw):
    return pd.read_csv(run_dir(variant, alg, **kw) / "topk.csv")


def log(alg, **kw):
    return pd.read_csv(run_dir("bep", alg, log=1, **kw) / "log.csv")


runs = pd.read_csv(ROOT / "results" / "hs_runs.csv")

# ---------------------------------------------------------------------------
# Figure 1 - reproduction: reproduced top-10 vs reference values
# ---------------------------------------------------------------------------
ref = pd.read_csv(ROOT / "reference" / "hs_reference.csv")
fig, axes = plt.subplots(1, 2, figsize=(9, 3.6))
for ax, measure, title in zip(axes, ["lrt", "wald"], ["Likelihood ratio", "Wald"]):
    rep = pd.read_csv(ROOT / "results" / f"hs_reproduced_{measure}.csv")
    r = ref[ref.measure == measure]
    ax.plot(r["rank"], r["quality"], "o", ms=10, mfc="none", color=C["ref"],
            label="reference (subgroupsem tests)")
    ax.plot(rep["rank"], rep["quality"], "x", ms=7, color=C["original"],
            label="reproduced (original code)")
    for _, row in rep.iterrows():
        ax.annotate(row["subgroup"].replace(" AND ", " ∧ "), (row["rank"], row["quality"]),
                    xytext=(4, 2), textcoords="offset points", fontsize=6, rotation=20)
    ax.set_xticks(range(1, 11))
    ax.set_xlabel("rank")
    ax.set_ylabel("quality")
    ax.set_title(title)
axes[0].legend(loc="lower left", fontsize=7)
save(fig, "fig1_hs_reproduction")

# ---------------------------------------------------------------------------
# Figure 2 - do the algorithms find the same top-10? (rank of each subgroup)
# ---------------------------------------------------------------------------
cols = {"original DFS": topk("original", "DFS")}
cols.update({a: topk("bep", a) for a in ALGS})
subgroups = list(dict.fromkeys(s for t in cols.values() for s in t["subgroup"]))
M = np.full((len(subgroups), len(cols)), np.nan)
for j, t in enumerate(cols.values()):
    for _, row in t.iterrows():
        M[subgroups.index(row["subgroup"]), j] = row["rank"]
fig, ax = plt.subplots(figsize=(6, 0.32 * len(subgroups) + 1.2))
im = ax.imshow(M, cmap="viridis_r", aspect="auto", vmin=1, vmax=10)
for i in range(M.shape[0]):
    for j in range(M.shape[1]):
        txt = "–" if np.isnan(M[i, j]) else str(int(M[i, j]))
        ax.text(j, i, txt, ha="center", va="center", fontsize=7,
                color="white" if (not np.isnan(M[i, j]) and M[i, j] > 5) else "black")
ax.set_xticks(range(len(cols)), list(cols), rotation=20)
ax.set_yticks(range(len(subgroups)), [s.replace(" AND ", " ∧ ") for s in subgroups], fontsize=7)
ax.set_title("Rank of each subgroup in the top-10 (– = not in top-10)")
fig.colorbar(im, ax=ax, label="rank", shrink=0.7)
save(fig, "fig2_hs_topk_agreement")

# ---------------------------------------------------------------------------
# Figure 3 - how much work does each algorithm do?
# ---------------------------------------------------------------------------
# number of descriptions predicted by formula (2): product over chosen covariates
d1 = log("DFS")
d1 = d1[d1["depth"] == 1]
attr = d1["description"].str.extract(r"^([^=<>:\s]+)")[0]
s_j = attr.value_counts().to_list()          # selectors per covariate
m = sum(s_j)
N3_formula = sum(prod(c) for k in range(1, 4) for c in combinations(s_j, k))
N3_all = sum(comb(m, k) for k in range(1, 4))  # every combination of m selectors

lr = runs[(runs.variant == "bep") & (runs.measure == "lrt") & (runs.min_size == 50) & (runs.log)]
lr = lr.set_index("algorithm").loc[ALGS]
fig, ax = plt.subplots(figsize=(6.5, 3.6))
x = np.arange(len(ALGS))
w = 0.26
ax.bar(x - w, lr["n_evaluated"], w, label="descriptions scored", color="#BBBBBB")
ax.bar(x, lr["n_below_30"] + lr["n_below_min_size"], w, label="rejected: too small", color="#888888")
ax.bar(x + w, lr["n_fit"], w, label="lavaan fits", color=[C[a] for a in ALGS])
for a_i, a in enumerate(ALGS):
    L = log(a)
    fitted = L[L["t_r_fit_s"].notna() & (L["depth"] > 0)]
    dup = len(fitted) - fitted["description"].nunique()
    ax.text(x[a_i] + w, lr.loc[a, "n_fit"] + 1, f"{int(lr.loc[a, 'n_fit'])}"
            + (f"\n({dup} repeated)" if dup else ""), ha="center", fontsize=7)
ax.axhline(N3_formula, ls="--", color="black", lw=0.8)
ax.text(-0.45, N3_formula + 1, f"formula (2): N3 = {N3_formula}", ha="left", fontsize=7)
ax.axhline(N3_all, ls=":", color="black", lw=0.8)
ax.text(1.55, N3_all + 1, f"all selector combinations = {N3_all}", ha="left", fontsize=7)
ax.set_xticks(x, ALGS)
ax.set_ylabel("count")
ax.set_title(f"Work per algorithm (HS, depth 3, min. size 50, {m} selectors: {s_j})")
ax.set_ylim(0, max(lr["n_evaluated"].max(), N3_all) * 1.25)
ax.legend(fontsize=7, loc="upper left", ncol=3)
save(fig, "fig3_hs_work")

# ---------------------------------------------------------------------------
# Figure 4 - runtime per algorithm (repetitions as dots, median as bar)
# ---------------------------------------------------------------------------
t = runs[(~runs.log) & (runs.min_size == 50)].copy()
t["label"] = np.where(t.variant == "original", "original DFS",
                      np.where(t.measure == "wald", "DFS (Wald)", t.algorithm))
order = ["original DFS"] + ALGS + ["DFS (Wald)"]
colour = {**C, "original DFS": C["original"], "DFS (Wald)": C["DFS"]}
fig, ax = plt.subplots(figsize=(6.5, 3.2))
for i, lab in enumerate(order):
    v = t.loc[t.label == lab, "time_search_s"].to_numpy()
    ax.bar(i, np.median(v), 0.6, color=colour[lab], alpha=0.35)
    ax.plot(np.full(len(v), i) + np.linspace(-0.12, 0.12, len(v)), v, "o", color=colour[lab], ms=4)
ax.set_xticks(range(len(order)), order, rotation=15)
ax.set_ylabel("search time (s)")
ax.set_title("Runtime on HS (bar = median, dots = repetitions) - pilot only")
save(fig, "fig4_hs_runtime")

# ---------------------------------------------------------------------------
# Figure 5 - cost of one fit vs subgroup size (min. size 30 run)
# ---------------------------------------------------------------------------
L = log("DFS", min_size=30)
L = L[L["t_r_fit_s"].notna() & (L["depth"] > 0)]
ok = L["quality"] >= 0
fig, ax = plt.subplots(figsize=(5.5, 3.4))
ax.scatter(L.loc[ok, "cover_size"], L.loc[ok, "t_r_fit_s"], s=18, color=C["DFS"], label="fit OK")
ax.scatter(L.loc[~ok, "cover_size"], L.loc[~ok, "t_r_fit_s"], s=30, marker="x",
           color=C["ref"], label="fit failed (quality -1)")
ax.set_yscale("log")
ax.set_xlabel("subgroup size (rows)")
ax.set_ylabel("time of one fit (s, log scale)")
share = L.loc[~ok, "t_r_fit_s"].sum() / L["t_r_fit_s"].sum()
ax.set_title(f"Failed fits take {share:.0%} of all fit time (HS, min. size 30)")
ax.legend(fontsize=7)
save(fig, "fig5_hs_fit_time_vs_size")

# ---------------------------------------------------------------------------
# Figure 6 - where does the time of a run go? (preview of RQ1)
# ---------------------------------------------------------------------------
parts = []
for a in ALGS:
    L = log(a)
    fit = L["t_r_fit_s"].fillna(0).sum()
    bridge = (L["t_eval_s"] - L["t_r_fit_s"].fillna(0)).sum()   # Python<->R + size check
    gen = L["t_between_s"].fillna(0).sum()                         # candidate generation etc.
    parts.append((a, gen, bridge, fit))
P = pd.DataFrame(parts, columns=["alg", "generation", "Python-R call", "lavaan fit"]).set_index("alg")
fig, ax = plt.subplots(figsize=(5.5, 3.2))
bottom = np.zeros(len(P))
for col, colr in zip(P.columns, ["#E69F00", "#999999", "#0072B2"]):
    ax.bar(P.index, P[col], bottom=bottom, color=colr, label=col)
    bottom += P[col].to_numpy()
for i, a in enumerate(P.index):
    ax.text(i, bottom[i], f"fit = {P.loc[a, 'lavaan fit'] / bottom[i]:.1%}", ha="center",
            va="bottom", fontsize=7)
ax.set_ylabel("seconds (sum over candidates)")
ax.set_title("Time per part of the work (logged runs)")
ax.legend(fontsize=7)
save(fig, "fig6_hs_time_breakdown")
