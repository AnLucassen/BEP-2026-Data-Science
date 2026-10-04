# subgroupsem 0.1-0.9017.9001 (BEP fork, An-Mei Lucassen)

* Added algorithms 'Apriori' and 'BestFirst' (from pysubgroup 0.7.8).
* SEM_QF is now a BoundedInterestingnessMeasure with optimistic estimate +Inf,
  so no candidate is ever pruned because of its quality.
* Unknown algorithm names now stop with an error (previously only a warning
  followed by an obscure error).
* Added slots 'algorithm', 'counters' (descriptions evaluated, rejected by size,
  model fits) and 'log' (optional per-candidate log, keep_log = TRUE).
* The 'subgroup' column of summary_statistics is now a character string.

# subgroupsem 0.1.0-9000

* Adapted subgroupsem to pysubgroup version 0.7.2
* Added new arguments to subgroupsem function, which are partly not implemented yet
* Arguments "weighted_attr" and "generalization_aware" are deprecated and removed
* Updated and extended some documentation
* Added a `NEWS.md` file to track changes to the package.
