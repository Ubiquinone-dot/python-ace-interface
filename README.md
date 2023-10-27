# python-ace-interface
A simple script for interfacing with the Julia code required to compute ACE (Atomic Cluster Expansion) descriptors (See ACEsuit for original Julia code [here](https://github.com/ACEsuit/ACEpotentials.jl))

## Usage
In `python_ace.py` there are two functions:
1. `exec_jl_script` performs atomsfile -> acefile calculations by interfacing with the julia script. Will take an ASE (atomic simulation environment) atoms file to a .npz file that can be loaded in numpy afterwards.
2. `atoms_to_ace` is a wrapper around the above function (will make a buffer) and will take as input an ase.Atoms object or list of ase.Atoms and directly return the ACE descriptor for the configuration. The buffer created can be reloaded by supplying `reload_buffer=True` (assumes the inputs are exactly the same so not realiable).


`ace_io_script.jl` uses two packages for loading as it's the simplest way to get out the elements from the file.

`usage.ipynb` takes you through a test example for the script.

## To run / Install
Make sure Julia's installed on your system.
Run `ace_io_script.jl` to install the dependencies and comment out the Pkg import past `Pkg.activate("...")`.


