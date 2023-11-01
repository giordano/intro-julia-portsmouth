### A Pluto.jl notebook ###
# v0.19.29

using Markdown
using InteractiveUtils

# ╔═╡ 83fd4129-f9bf-47af-a9ea-505511909ebe
using PlutoUI

# ╔═╡ 8d0daf94-b37f-4d58-9d64-4891f4f4ad14
using BenchmarkTools

# ╔═╡ 6e315b20-a943-4d23-9fa1-18913fb73263
using ShortCodes

# ╔═╡ dbfb9383-1671-4810-b638-a9512af39f9d
using Markdown

# ╔═╡ 8b29a745-ddf7-4a16-8cfe-13603cbfc9ef
using QRCoders

# ╔═╡ cfe07ec9-8470-48ef-82bb-f224812d0663
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ a45d80d7-6160-4194-8112-5630767629db
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ 63ba95f0-0a04-11ee-30b5-65d2b018e857
md"""
## Julia: fresh approach to scientific computing

_by Mosè Giordano, RSE @ UCL_

This notebook in running Julia v$(string(VERSION)).  You can obtain the notebook at <https://github.com/giordano/intro-julia-portsmouth>, which you can also run yourself locally after installing Julia.  With material from the Julia community particularly Valentin Churavy (PhD Student in Computer Science @ MIT).

## Who am I?

* backgroun in Physics
* Research Software Developer at University College London since 2019
* user of the Julia programming language since 2016

## What's Julia?

Julia is a modern, dynamic, general-purpose, compiled programming language.
It's interactive ("like Python"), can be used in a REPL or notebooks, like Jupyter (it's the "Ju") or Pluto (this one🎈).
Julia has a runtime which includes a just-in-time (JIT) compiler and a garbage collector (GC), for automatic memory management.

Julia is mainly used for numerical computing, diffential equations solvers suite is quite popular.

Main paradigm of Julia is multiple dispatch, what functions do depend on type and number of _all_ arguments.

## Why Julia?

* Explorable & Understandable
* Composability thanks to multiple dispatch
* User-defined types are as fast and compact as built-ins
* Code that is close to the mathematics
* Built-in package manager, with focus on reproducibility
* No need to switch languages for performance...
* ...but you can still call C-like shared libraries with simple Foreign Function Interface (FFI) if you want to
* MIT licensed: free and open source

#### Two-language problem

You start out proto-typing in one language (high-level, dynamic), but performance forces you to switch to a different one (low-level, static).

* For convinience use a scripting language (Python, R, Matlab, ...)
* but do all the hard stuff in a systems language (C, C++, Fortran)

Pragmatic for many applications, but has drawbacks

* aren't the hard parts exactly where you need an easier language
* creates a social barrier – a wall between users and developers
* "sandwich problem" – layering of system & user code is expensive
* prohibits full stack optimisations

### ...or two-culture problem?

From "[My Target Audience](https://scientificcoder.com/my-target-audience)" by Matthijs Cox:

$(Resource("https://cdn.hashnode.com/res/hashnode/image/upload/v1681735971356/91b6e886-7ce1-41a3-9d9f-29b7b096e7f2.png"))
$(Resource("https://cdn.hashnode.com/res/hashnode/image/upload/v1681735992315/62fdd58f-4630-4120-8eb4-5238740543e8.png"))

**Tearing down barriers of collaboration**

* Fostering collaboration
* Low-barrier from package user to package developer
* One codebase to rule them all
* Understandable and explorable performance

### Productivity

$(Resource("https://i.imgur.com/Ym5H0Pz.jpeg"))
$(Resource("https://i.imgur.com/KZMZSru.jpeg"))
from <https://twitter.com/ChapelLanguage/status/1623389242822111232>
"""

# ╔═╡ badfa3aa-e4f5-4dbe-aa15-30efd3beb00a
md"""
## Crash course on multiple dispatch 🪨📜✂️

From "[SIAM CSE19: Solving the Two Language Problem in Scientific Computing and Machine Learning with Julia](https://www.youtube.com/watch?v=OfMP5PTFQk0)" (acceptance speech for J. H. Wilkinson Prize 2019 for Numerical Software)

$(Resource("https://i.imgur.com/QqUPohw.png"))

_Based on my blogpost "[Rock–paper–scissors game in less than 10 lines of code](https://giordano.github.io/blog/2017-11-03-rock-paper-scissors)"._
"""

# ╔═╡ 3add1691-4781-4791-bed0-921a860f0e48
begin
	abstract type Shape end
	struct Rock     <: Shape end
	struct Paper    <: Shape end
	struct Scissors <: Shape end
	play(::Type{Paper}, ::Type{Rock})     = "Paper wins"
	play(::Type{Paper}, ::Type{Scissors}) = "Scissors wins"
	play(::Type{Rock},  ::Type{Scissors}) = "Rock wins"
	play(::Type{T},     ::Type{T}) where {T<: Shape} = "Tie, try again"
	play(a::Type{<:Shape}, b::Type{<:Shape}) = play(b, a) # Commutativity
end

# ╔═╡ 7b5317aa-9feb-4185-bc7b-2ef10c9038a4
play(Paper, Scissors)

# ╔═╡ c38c7664-35f0-4109-9872-f3e2065b7db9
play(Rock, Rock)

# ╔═╡ d647ba60-0a37-47f1-ac7f-9f8020cb2c6e
play(Rock, Paper)

# ╔═╡ 727fd979-35f6-473d-8348-adf3270e600d
@which play(Rock, Paper)

# ╔═╡ 7dcbdada-8fb7-4e2e-8aea-76db704cb5f9
md"""
## Compiler pipeline and performance optimisation

$(Resource("https://i.imgur.com/fyipOmk.png"))
(_Diagram of Julia compiler pipeline, from "[Julia for High Performance Computing Course @ HLRS - Code Specialization](https://github.com/carstenbauer/JuliaHLRS22)" by Carsten Bauer_)

The only existing implementation of Julia is based on the LLVM compiler, a popular modular compilation framework.

With Julia we can easily inspect each stage of the compilation pipeline.
"""

# ╔═╡ 4b370eb0-0b58-4d13-9673-2b9efe87ee36
c_sum_code = """
#include <stddef.h>
double c_sum(size_t n, double *x) {
    double s = 0.0;
    for (size_t i = 0; i < n; ++i) {
        s += x[i];
    }
    return s;
}
""";

# ╔═╡ b8a95293-a737-43c9-a95f-7d30a3cd1e75
Markdown.parse(
	"""
	Source code in C for computing the sum of the elements of an array in C:
	```c
	$(c_sum_code)
	```
	Let's compile it:
	"""
)

# ╔═╡ d0f6d679-4047-4d42-bdbf-0d72fab8b02e
begin
	c_lib = tempname()
	flags = `-O3` # -fno-trapping-math -fno-signed-zeros -fassociative-math
	native_flag = `-m$(Sys.ARCH === :aarch64 || startswith(string(Sys.ARCH), "arm") ? "tune" : "arch")=native` # on ARM we need to use `-mtune` instead of `-march`
	run(pipeline(`gcc $(flags) -fPIC $(native_flag) -x c -shared - -o $(c_lib)`; stdin=IOBuffer(c_sum_code)))
end;

# ╔═╡ 659b59e2-40bd-40cf-86f9-db209dc9c58f
c_sum(x::Array{Float64}) = @ccall c_lib.c_sum(length(x)::Csize_t, x::Ptr{Float64})::Float64

# ╔═╡ f328fa71-41e9-4a4c-aeef-412b1ba7dc59
c_sum([1.0, 2, 3])

# ╔═╡ 3100d9fb-58a1-4169-80e7-e188124b6096
function jl_sum(x::AbstractVector)
	sum = zero(eltype(x))
	for el in x
		sum += el
	end
	return sum
end

# ╔═╡ 1aa917ad-e420-4572-891b-00ec33fde528
@code_typed jl_sum([1.0])

# ╔═╡ 26d979c8-b1dc-4b60-b108-6152cd348493
@code_llvm debuginfo=:none jl_sum([1.0])

# ╔═╡ 25f40b2c-c918-4f83-823b-dd8a842d66a0
@code_native debuginfo=:none jl_sum([1.0])

# ╔═╡ 698b0981-b9fa-416b-b6bf-e2aa2a98e152
md"Make sure we're getting the same results:"

# ╔═╡ 014ce3e4-d653-403c-b01a-85db87ea8b40
let
	v = randn(1_000_000)
	c_sum(v) ≈ jl_sum(v) ≈ sum(v)
end

# ╔═╡ aab90cf3-2951-484f-a3da-9bcdd121abe5
@benchmark c_sum(v) setup=(v=randn(10_000)) evals=1

# ╔═╡ ada6193f-4bbd-4ba7-9b5c-3477cc15ad58
@benchmark jl_sum(v) setup=(v=randn(10_000)) evals=1

# ╔═╡ 58780c7d-1e7e-464e-a4c9-3f3a93504ceb
@benchmark sum(v) setup=(v=randn(10_000)) evals=1

# ╔═╡ 170b786e-0490-4601-b626-ed48bd5097d8
md"""
## Accelerators

$(Twitter(1207302719490478080))

Excellent native GPU computing support

* [NVIDIA](https://github.com/JuliaGPU/CUDA.jl)
* [AMD](https://github.com/JuliaGPU/AMDGPU.jl)
* [Intel](https://github.com/JuliaGPU/oneAPI.jl)
* [Apple](https://github.com/JuliaGPU/Metal.jl)

Experimental support for accelerators like [Graphcore IPU](https://github.com/JuliaIPU/IPUToolkit.jl) and [NEC SX-Aurora](https://github.com/sx-aurora-dev/VectorEngine.jl).

## Big projects

For an overview of other projects in the Julia community, especially in the scientific machine learning domain, you cat watch the JuliaCon 2023 keynote talk "[Scientific Machine Learning through Symbolic Numerics](https://www.youtube.com/watch?v=tynmTkpdAME)" by Chris Rackauckas:

$(YouTube("tynmTkpdAME"))

## Compilation caching

If you tried Julia before, you have probably been aware of the fact that loading certain packages and/or running some functions for the first time in a fresh session (time-to-first-X) used to take a long time.

Julia had for a long time the ability to perform native caching, to reduce startup latency, but it was limited to:

* system image
* application deployment through PackageCompiler.jl

Since Julia v1.9 we now create per package native caches in the form of package images, drastically lowering the latency of Julia.

$(Resource("https://julialang.org/assets/blog/2023-1.9-highlights/benchmarks.png"))

Read more in the [Julia 1.9 Highlights](https://julialang.org/blog/2023/04/julia-1.9-highlights/).

For a recent overview of other recent advancements in the Julia language, you can watch the talk "[State of Julia](https://www.youtube.com/watch?v=jFhL8EVrz7s)" at JuliaCon

$(YouTube("jFhL8EVrz7s"))
"""

# ╔═╡ 073093e0-2e8e-4416-aa8d-892ac5000c5d
md"""
## Want to get started with Julia?

### Installing Julia

You have a few options:

* Official binaries from [Julia website](https://julialang.org/downloads/)
* [Juliaup installer](https://github.com/JuliaLang/juliaup) (it lets you manage multiple versions at the same time)
* build it from [source](https://github.com/JuliaLang/julia/), if you are into this kind of experience

Avoid Julia packages in Linux distributions, they often package it with incompatible LLVM or other dependencies.

### Coding environments

* [Julia for Visual Studio Code](https://www.julia-vscode.org/) (IDE):

  $(Resource("https://i.imgur.com/OFUQdQm.png"))

* Jupyter with [IJUlia](https://github.com/JuliaLang/IJulia.jl) kernel (interactive notebook):

  $(Resource("https://i.imgur.com/y7DhrQd.png"))

* Pluto (*reactive* notebook): this one

### Learning resources

* [Official documentation](https://docs.julialang.org/)
* [Other learning resources](https://julialang.org/learning/)
* [doggo dot jl YouTube channel](https://www.youtube.com/@doggodotjl)

### Got any questions?

* Engage the [community](https://julialang.org/community/)
* [Discourse web forum](https://discourse.julialang.org/)

### Download the notebook

$(mktempdir() do dir
	file = joinpath(dir, "qrcode.png")
	exportqrcode("https://github.com/giordano/intro-julia-portsmouth", file; targetsize=12)
	LocalResource(file)
end)

"""

# ╔═╡ bfaa1f3a-11c7-4b7e-95a2-4da860477d29
md"""
## Appendix

### Metaprogramming: code generating code

Let's try to define a function which computes the time to evaluate its argument:
"""

# ╔═╡ 8eaf3230-a6fc-401a-8e65-e986dba28397
function mytime(ex)
	t_start = time_ns()
	output = ex
	t_end = time_ns()
	println("Time: ", round((t_end - t_start) / 1e9; sigdigits=4), " seconds")
	output
end

# ╔═╡ f70fbb7b-5045-45d6-9fa2-627f32fbe54a
mytime(sleep(0.5))

# ╔═╡ 2e69a6fe-b3fc-4de3-a973-e5c9e136ebde
md"""
This doesn't work as hoped, because arguments are evaluated eagerly before entering the function body.
An alternative would be to pass as argument to the function `mytime` another function, but then the syntax can become more complicated then desired.

Julia has LISP-like metaprogramming capabilities: macros are advanced functions which turn _unevaluated_ expressions into some other manipulated expressions and evaluate the resulting expressions.
Macros can be used to create Domain-Specific Languages (DSLs), a popular example in Julia is [`Turing.jl`](https://turing.ml/), a library for probabilistic programming.

!!! note

    Developers shouldn't abuse macros as they make code harder to read (a macro could do anything with the input expression, even completely ignoring it!), but they can be be extremely useful for reducing boilerplate or repetitive code, when functions are not an option due to eager evaluation of arguments.
"""

# ╔═╡ 748f68a4-a3e4-459b-b0d0-bff3f4177c6a
macro mytime(ex::Expr)
	return quote
		local t_start = time_ns()
		local output = $(esc(ex))
		local t_end = time_ns()
		println("Time: ", round((t_end - t_start) / 1e9; sigdigits=4), " seconds")
		output
	end
end

# ╔═╡ bf6148eb-dab3-4011-aed1-4c777a1c4c89
@mytime sleep(0.5)

# ╔═╡ e180affc-d77c-41fe-a6ec-e7a379c7adea
@macroexpand @mytime sleep(0.5)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
QRCoders = "f42e9828-16f3-11ed-2883-9126170b272d"
ShortCodes = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"

[compat]
BenchmarkTools = "~1.3.2"
PlutoUI = "~0.7.51"
QRCoders = "~1.0.1"
ShortCodes = "~0.3.6"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.3"
manifest_format = "2.0"
project_hash = "3a73aa266fa927b82efdb43225de309fb909fc02"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

    [deps.AbstractFFTs.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "91bd53c39b9cbfb5ef4b015e8b582d344532bd0a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.0"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "76289dc51920fdc6e0013c872ba9551d54961c24"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.6.2"

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

    [deps.Adapt.weakdeps]
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "d9a9701b899b30332bbcb3e1679c41cce81fb0e8"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.2"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "8a62af3e248a8c4bad6b32cbbe663ae02275e32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "299dc33549f68299137e51e6d49a13b5b1da9673"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "2e4520d67b0cef90865b3ef727594d2a58e0e1f8"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.11"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "bca20b2f5d00c4fbc192c3212da8fa79f4688009"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.7"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "355e2b974f2e3212a75dfb60519de21361ad3cb7"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.9"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3d09a9f60edf77f8a4d99f9e015e8fbf9989605d"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.7+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "ea8031dea4aff6bd41f1df8f2fdfb25b33626381"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.4"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IntervalSets]]
deps = ["Dates", "Random"]
git-tree-sha1 = "8e59ea773deee525c99a8018409f64f19fb719e6"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.7"
weakdeps = ["Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsStatisticsExt = "Statistics"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "4ced6667f9974fc5c5943fa5e2ef1ca43ea9e450"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.8.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "95220473901735a0f4df9d1ca5b171b568b2daa3"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.13.2"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "d65930fa2bc96b07d7691c652d701dcbe7d9cf0b"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "9ee1618cbf5240e6d4e0371d6f24065083f60c48"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.11"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Memoize]]
deps = ["MacroTools"]
git-tree-sha1 = "2b1dfcba103de714d31c033b5dacc2e4a12c7caa"
uuid = "c03570c3-d221-55d1-a50c-7939bbd78826"
version = "0.4.4"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "2ac17d29c523ce1cd38e27785a7d23024853a4bb"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.10"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "a4ca623df1ae99d09bc9868b008262d0c0ac1e4f"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.4+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "9b02b27ac477cad98114584ff964e3052f656a0f"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.0"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e47cd150dbe0443c3a3651bc5b9cbd5576ab75b7"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.52"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "00099623ffee15972c16111bcf84c58a0051257c"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.9.0"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.QRCoders]]
deps = ["FileIO", "ImageCore", "ImageIO"]
git-tree-sha1 = "a7a56a2550dbea3b603b357adf81710385d1d3c7"
uuid = "f42e9828-16f3-11ed-2883-9126170b272d"
version = "1.0.1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.ShortCodes]]
deps = ["Base64", "CodecZlib", "Downloads", "JSON3", "Memoize", "URIs", "UUIDs"]
git-tree-sha1 = "5844ee60d9fd30a891d48bab77ac9e16791a0a57"
uuid = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
version = "0.3.6"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "2da10356e31327c7096832eb9cd86307a50b1eb6"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "ca4bccb03acf9faaf4137a9abc1881ed1841aa70"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.10.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "34cc045dd0aaa59b8bbe86c644679bc57f1d5bd0"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.8"

[[deps.TranscodingStreams]]
git-tree-sha1 = "7c9196c8c83802d7b8ca7a6551a0236edd3bf731"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.0"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─cfe07ec9-8470-48ef-82bb-f224812d0663
# ╟─83fd4129-f9bf-47af-a9ea-505511909ebe
# ╟─a45d80d7-6160-4194-8112-5630767629db
# ╟─63ba95f0-0a04-11ee-30b5-65d2b018e857
# ╟─badfa3aa-e4f5-4dbe-aa15-30efd3beb00a
# ╠═3add1691-4781-4791-bed0-921a860f0e48
# ╠═7b5317aa-9feb-4185-bc7b-2ef10c9038a4
# ╠═c38c7664-35f0-4109-9872-f3e2065b7db9
# ╠═d647ba60-0a37-47f1-ac7f-9f8020cb2c6e
# ╠═727fd979-35f6-473d-8348-adf3270e600d
# ╟─7dcbdada-8fb7-4e2e-8aea-76db704cb5f9
# ╟─4b370eb0-0b58-4d13-9673-2b9efe87ee36
# ╟─b8a95293-a737-43c9-a95f-7d30a3cd1e75
# ╠═d0f6d679-4047-4d42-bdbf-0d72fab8b02e
# ╠═659b59e2-40bd-40cf-86f9-db209dc9c58f
# ╠═f328fa71-41e9-4a4c-aeef-412b1ba7dc59
# ╠═3100d9fb-58a1-4169-80e7-e188124b6096
# ╠═1aa917ad-e420-4572-891b-00ec33fde528
# ╠═26d979c8-b1dc-4b60-b108-6152cd348493
# ╠═25f40b2c-c918-4f83-823b-dd8a842d66a0
# ╟─698b0981-b9fa-416b-b6bf-e2aa2a98e152
# ╠═014ce3e4-d653-403c-b01a-85db87ea8b40
# ╠═8d0daf94-b37f-4d58-9d64-4891f4f4ad14
# ╠═aab90cf3-2951-484f-a3da-9bcdd121abe5
# ╠═ada6193f-4bbd-4ba7-9b5c-3477cc15ad58
# ╠═58780c7d-1e7e-464e-a4c9-3f3a93504ceb
# ╟─170b786e-0490-4601-b626-ed48bd5097d8
# ╟─073093e0-2e8e-4416-aa8d-892ac5000c5d
# ╟─bfaa1f3a-11c7-4b7e-95a2-4da860477d29
# ╠═8eaf3230-a6fc-401a-8e65-e986dba28397
# ╠═f70fbb7b-5045-45d6-9fa2-627f32fbe54a
# ╟─2e69a6fe-b3fc-4de3-a973-e5c9e136ebde
# ╠═748f68a4-a3e4-459b-b0d0-bff3f4177c6a
# ╠═bf6148eb-dab3-4011-aed1-4c777a1c4c89
# ╠═e180affc-d77c-41fe-a6ec-e7a379c7adea
# ╟─6e315b20-a943-4d23-9fa1-18913fb73263
# ╟─dbfb9383-1671-4810-b638-a9512af39f9d
# ╟─8b29a745-ddf7-4a16-8cfe-13603cbfc9ef
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
