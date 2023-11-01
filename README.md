# Julia: A Fresh Approach to Numerical Computing

This repository contains the Pluto notebook used for the presentation given on 2023-11-01 at the Faculty of Technology of the University of Portsmouth.

You can look at the [static HTML export](https://giordano.github.io/talks/2023-11-01-intro-julia/) of the [Pluto notebook](https://plutojl.org/), or run it yourself locally, following the instructions below.

## Running the Pluto notebook locally

After having [installed Julia](https://julialang.org/downloads/) (v1.9 or later version), in a terminal clone this repository using [Git](https://git-scm.com/) with the command
```sh
git clone https://github.com/giordano/intro-julia-portsmouth
```
move to the directory where you cloned the repository to (e.g. `cd intro-julia-portsmouth`) and then start julia with:
```sh
julia --project=.
```
This will open the Julia REPL, where you can run the following commands:
```julia
import Pkg
Pkg.instantiate()
import Pluto
Pluto.run()
```
