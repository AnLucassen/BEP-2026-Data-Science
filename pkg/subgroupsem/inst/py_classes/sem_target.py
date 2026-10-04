from pysubgroup.measures import AbstractInterestingnessMeasure, \
    BoundedInterestingnessMeasure

import time
import numpy as np


class SEMTarget(object):
    statistic_types = ['size_sg']

    def __init__(self):
        pass

    def __repr__(self):
        return "T: Structural Equation Model"

    def __eq__(self, other):
        return self.__dict__ == other.__dict__

    def __lt__(self, other):
        return str(self) < str(other)

    def get_attributes(self):
        return []

    def calculate_statistics(self, subgroup, data, stats):
        sg_instances = subgroup.covers(data)

        statistics = dict()
        statistics['size_sg'] = np.sum(sg_instances)
        return statistics


# BEP change 1: SEM_QF now derives from BoundedInterestingnessMeasure.
# pysubgroup's Apriori refuses quality functions that are not "bounded".
# The optimistic estimate below is +inf for every candidate, so no branch
# can ever be pruned because of its quality: DFS, Apriori and best-first
# search stay exhaustive (up to depth and minimum size), as in the proposal.
class SEM_QF(BoundedInterestingnessMeasure):
    def __init__(self, keep_log=False):
        # BEP change 2: counters (always on, negligible cost) and an optional
        # per-candidate log (off by default, so the timed code path equals
        # the original one unless logging is requested).
        self.keep_log = keep_log
        self.n_evaluated = 0          # every description the algorithm scores
        self.n_below_30 = 0           # rejected by the hard minimum of 30 rows
        self.log = []
        self._last_exit = None

    def calculate_constant_statistics(self, data, target):
        pass

    def calculate_statistics(self, subgroup, target, data, statistics=None):
        pass

    def optimistic_estimate(self, subgroup, target, data, statistics):
        return float("inf")

    def evaluate(self, subgroup, target, data, statistics):
        t_enter = time.perf_counter()
        self.n_evaluated += 1
        instances = subgroup.covers(data)

        variables = [str(selector.attribute_name) for selector in subgroup.selectors]

        if (instances.sum() < 30):
            self.n_below_30 += 1
            rval = -1
        else:
            rval = f_fit(instances, variables, self.n_evaluated)

        if self.keep_log:
            t_exit = time.perf_counter()
            self.log.append({
                "order": self.n_evaluated,
                "description": str(subgroup),
                "depth": len(subgroup.selectors),
                "cover_size": int(instances.sum()),
                "quality": float(rval),
                # time spent in Python between two evaluations
                # (candidate generation + bookkeeping of the algorithm)
                "t_between_s": (t_enter - self._last_exit) if self._last_exit else float("nan"),
                # time of this evaluation as seen from Python (includes Python->R call)
                "t_eval_s": t_exit - t_enter,
            })
            self._last_exit = time.perf_counter()
        return rval

    def is_applicable(self, subgroup):
        return isinstance(subgroup.target, SEMTarget)

    def supports_weights(self):
        return False
