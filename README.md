# Where does the cost of SubgroupSEM come from?

Bachelor end project, An-Mei Lucassen, TU/e, 2026–2027.
Measures and reduces the runtime and memory of subgroup discovery in structural
equation models (SubgroupSEM, Kiefer et al., 2024) for four search algorithms:
depth-first search, Apriori, best-first search and beam search.

## Repository layout

| Path | What |
|---|---|
| `pkg/subgroupsem/` | copy of [langenberg/subgroupsem](https://github.com/langenberg/subgroupsem) at commit `5e02c6c`, with my changes (see `NEWS.md` there and `docs/subgroupsem-bep-changes.diff`) |
| `R/config.R` | all settings and seeds of the experiments |
| `R/helpers.R` | shared functions (loading a package version, run metadata, tie-aware comparison) |
| `R/00_install.R` | one-time setup of R packages (renv) and both subgroupsem versions |
| `R/install_bep.R` | reinstall my version after every change in `pkg/subgroupsem` |
| `R/run_one.R` | one experiment run in one fresh R process |
| `R/01_hs_reproduce.R` | does the original code reproduce the reference results? |
| `R/02_hs_algorithms.R` | all four algorithms on Holzinger–Swineford |
| `R/03_check_hs.R` | automatic correctness checks |
| `python/make_figures.py` | all figures |
| `reference/` | published / reference values |
| `results/` | summaries (committed); `results/raw/` is not committed |
| `figures/` | figures (PNG + PDF) |

## Requirements (tested setup: Windows 11, Anaconda, VS Code)

* R >= 4.3, Python 3.12 (Anaconda environment `bep`), Git for Windows
* Keep the project outside OneDrive and in a path without spaces

## Setup (once per machine)

In the **Anaconda Prompt**:
```
conda create -n bep python=3.12 -y
conda activate bep
cd C:\Users\<you>\code\BEP-2026-Data-Science
python -m pip install -r requirements.txt
python -c "import sys; print(sys.executable)"
```
Copy `.Renviron.example` to `.Renviron` and paste that Python path in it (forward slashes).

In a terminal in the project folder (VS Code: Terminal > New Terminal):
```
Rscript R/00_install.R
```

## Reproduce the Holzinger–Swineford stage

```bash
Rscript R/01_hs_reproduce.R     # must end with "REPRODUCTION OK"
Rscript R/02_hs_algorithms.R    # ~3 minutes
Rscript R/03_check_hs.R         # must end with "ALL CHECKS PASSED"
python python/make_figures.py   # in the Anaconda Prompt, with `conda activate bep`
```

Python prints harmless `pkg_resources` deprecation and pandas `FutureWarning`
messages; they come from pysubgroup 0.7.8 and do not affect the results.

## Licence

GPL-3.0 (see `LICENSE`). The code in `pkg/subgroupsem/` is derived from
subgroupsem (GPL ≥ 2, © Langenberg, Lemmerich, Kiefer); pysubgroup is Apache-2.0.
