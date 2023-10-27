"""
Script for executing julia from python

Notes:
- With testing I found the PyJulia package to be too slow. Use subprocess
- Bottleneck is usually initializing the Julia env
"""

import subprocess
import numpy as np

import os, sys, glob
from ase.io import read, write
from ase import Atoms

from typing import Union, List
import time

# interface for julia script to calculate aces
def exec_jl_script(input_file, output_file, rcut=5.5, order=3, totaldegree=8, verbose=True):
    def call():
        script_file_dir = os.path.dirname(os.path.realpath(__file__))  # script file should be in same directory as this script
        script = os.path.join(script_file_dir, "ace_io_script.jl")
        assert os.path.isfile(script), f"Script {script} does not exist, check dir {script_file_dir}"

        cmd = ["julia", script, input_file, output_file, rcut, order, totaldegree]
        cmd = [str(i) for i in cmd]

        if verbose: print('Executing command:', cmd)
        result = subprocess.run(cmd, capture_output=True, text=True)
        if verbose: print(result.stdout)

        if result.returncode != 0:
            raise RuntimeError(f"Command \n{cmd}\n failed with error code:\n{result.returncode}\n and output :\n{result.stdout}\n")

        return result
    return call()

def atoms_to_ace(atoms: Union[Atoms, List], rcut=5.5, order=3, totaldegree=8, outname="ace.npz", reload_buffer=False):
    
    script_file_path = os.path.dirname(os.path.realpath(__file__))

    # Buffer directory
    buffer_dir = os.path.join(script_file_path, "buffer")
    if not os.path.isdir(buffer_dir):
        os.mkdir(buffer_dir)
    if not reload_buffer:
        for f in glob.glob(os.path.join(buffer_dir, "*")):
            os.remove(f)  # remove all files in buffer directory
    
    input_file = os.path.join(buffer_dir, "atoms_buffer.xyz")

    if reload_buffer:
        try:
            aces = np.load(os.path.join(buffer_dir, outname))
            return aces
        except FileNotFoundError:
            print("Could not find file")

    # Write atoms to buffer
    if isinstance(atoms, Atoms):
        atoms.write(input_file)
    elif isinstance(atoms, list):
        for at in atoms:
            write(input_file, at, append=True)
        time.sleep(0.1)  # io
    else:
        raise TypeError(f"atoms must be an ASE Atoms object or a list of ASE Atoms objects, not {type(atoms)}")

    output_file = os.path.join(buffer_dir, outname)
    exec_jl_script(input_file, output_file, rcut, order, totaldegree)
    aces = np.load(output_file)

    return aces
    

if __name__=='__main__':
    # Test the function
    infile = "data/density-1.0-T-2000.extxyz"
    outfile = "data/test.npz"
    aces = jl_atoms_to_ace(infile, outfile)
