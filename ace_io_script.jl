"""
Usage: julia julia_script.jl <input_file> <output_file> <rcut:float> <order:int> <totaldegree:int>

reads atoms from xyz <infile>
then calculates site descriptors using ACE1x
then writes ACE descriptor to <outfile> in an npz format (outfile specified must end with .npz)

Notes:
    - shape (B, N, C), where B is usually 1 for files with one structure.
        - B: number of structures, N: number of atoms, C: number of channels
    - takes parameters for ACE1x: rcut, order, totaldegree
    - uses NQCBase to get the symbols cos im lazy, may cause issues
    - Assumes you've built the package see commented lines below
    - When called from python, you are expected to handle the IO etc. (might not be the best way to do this)

author: @ubiquinone-dot (JB)
"""

using Pkg; 
Pkg.activate("./jl")
# Pkg.activate("./data/jl")

Pkg.Registry.add("General")  # only needed when installing Julia for the first time
Pkg.Registry.add(RegistrySpec(url="https://github.com/ACEsuit/ACEregistry"))
Pkg.Registry.add(RegistrySpec(url="https://github.com/NQCD/NQCRegistry"))
Pkg.add("NQCBase")
Pkg.add("ACEpotentials")
Pkg.add("JuLIP")
Pkg.add("IJulia")
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("ASE")
Pkg.add("NPZ")
Pkg.add("PyCall")


using JuLIP: read_extxyz
using NQCBase
using ACEpotentials
using NPZ

function load_aces(filename, rcut=5.5, order=3, totaldegree=8)
    
    # need NQCBase to get the symbols cos im lazy, may cause issues
    ats, _, _ = NQCBase.read_extxyz(filename)
    elements = unique(ats.types)

    # JuLIP.Atoms loading
    ats = read_extxyz(filename)
    println("Found elements: ", elements)
    println(ats)

    # calculate site descriptors
    aces=[]
    for at in ats
        basis = ACE1x.ace_basis(elements = elements, rcut = rcut, order = order, totaldegree = totaldegree);
        x = site_descriptors(basis, at)
        x = hcat(x...)'  # (N, C)
        push!(aces, x)
    end
    aces  # (B, N, C)
end

function main(infile::String, outfile::String, rcut::Float64, order::Int, totaldegree::Int)
    matrix = load_aces(infile, rcut, order, totaldegree)
    matrix = cat(matrix..., dims=3)  
    matrix = permutedims(matrix, (3, 1, 2)) # (B, N, C): usually B=1 for files with one structure.
    println("Size of matrix: ", size(matrix)) # (200, 54, 211)
    npzwrite(outfile, matrix)
end

# IO
if length(ARGS) == 5
    try
        rcut = parse(Float64, ARGS[3])
        order = parse(Int, ARGS[4])
        totaldegree = parse(Int, ARGS[5])
        
        main(ARGS[1], ARGS[2], rcut, order, totaldegree)
    catch e
        println("Error:", e)
        println("Usage: julia julia_script.jl <input_file> <output_file> <rcut:float> <order:int> <totaldegree:int>")
    end
else
    println("Usage: julia julia_script.jl <input_file> <output_file> <rcut:float> <order:int> <totaldegree:int>")
end

