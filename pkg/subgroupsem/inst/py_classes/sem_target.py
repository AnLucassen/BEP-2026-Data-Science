from pysubgroup.measures import AbstractInterestingnessMeasure, \
    BoundedInterestingnessMeasure

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


class SEM_QF(AbstractInterestingnessMeasure):
    def __init__(self):
    	pass

    # musste ich einfuegen. ist das neu?
    def calculate_constant_statistics(self, data, target):
        pass

    def calculate_statistics(self, subgroup, target, data):
        pass

    # Changed from "evaluate_from_data" to "calculate_statistics"
    def evaluate(self, subgroup, target, data, statistics):
        #if len(subgroup.covers) == 0:
        #    return -1
        instances = subgroup.covers(data)

        variables = [str(selector.attribute_name) for selector in subgroup.selectors]
        
        if (instances.sum() < 30):
            return -1

        rval = f_fit(instances, variables)

        return rval

    def is_applicable(self, subgroup):
        return isinstance(subgroup.target, SEMTarget)

    def supports_weights(self):
        return False

