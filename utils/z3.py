__author__ = 'Afsoon Afzal'

import subprocess
import os
from settings import Z3_COMMAND


def run_z3(query):
    ret = False
    values = []
    with open('z3_query.smt2', 'w') as f:
        f.write(query)
        f.flush()
        proc = subprocess.Popen(Z3_COMMAND + ' -smt2 z3_query.smt2', stdout=subprocess.PIPE, shell=True)
        (out, err) = proc.communicate()
        print "**** " + out
        if err:
            print "ERROR: z3"
        for l in out.splitlines():
            if l == 'sat':
                ret = True
            elif l == 'unsat':
                ret = False
            if l.startswith('(('):
                l_temp = l[2:-2]
                parts = l_temp.split(' ')
                if len(parts) != 2:
                    print "ERROR: Why?"
                values.append((parts[0][2:], int(parts[1])))
    os.system('rm z3_query.smt2')
    return ret, values


def twos_comp(val, bits):
    """compute the 2's compliment of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = -(-val - (1 << bits))        # compute negative value
    return val                         # return positive value as is
