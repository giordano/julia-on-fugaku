# Julia on Fugaku (2022-04-29)

_Note: many links refer to internal documentation which is accessible only to Fugaku users._

## Storage

Before doing anything on Fugaku, be aware that there are [tight
limits](https://www.fugaku.r-ccs.riken.jp/en/operation/20220408_01) on the size of (20 GiB)
and the number of inodes in (200k) your home directory.  If you use many Julia Pkg
artifacts, it's very likely you'll hit these limits.  You'll notice that you hit the limit
because any disk I/O operation will result in a `Disk quota exceeded` error like this:

```console
[user@fn01sv03 ~]$ touch foo
touch: cannot touch 'foo': Disk quota exceeded
```

You can check the quota of your home directory with `accountd` for the size, and `accountd
-i` for the number of inodes.

### Using the data directory

In order to avoid clogging up the home directory you may want to move the Julia depot to the
data directory:

```sh
DATADIR="/data/<YOUR GROUP>/${USER}"
export JULIA_DEPOT_PATH="${DATADIR}/julia-depot"
```

## Interactive usage

The login nodes you access via `login.fugaku.r-ccs.riken.jp` ([connection
instructions](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/use_latest/AccessToTheSystem/LoggingInToTheFugakuComputerWithLocalAccount.html))
have Cascade Lake CPUs, so they aren't much useful if you want to run an aarch64 Julia.

There is a Julia module built with Spack [available on the compute
nodes](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/UsingOSS/oss_e.html#packages-installed-on-the-compute-nodes),
but I still haven't understood how to access the volume where Spack is installed from a
compute node, please let me know if you do.  Anyway, as of this writing (2022-04-29) the
version of Julia provided is 1.6.3, so you may want to download a more recent version from
the [official website](https://julialang.org/downloads/).  Use the `aarch64` builds for
Glibc Linux, preferably [latest
stable](https://julialang.org/downloads/#current_stable_release) or even the [nightly
build](https://julialang.org/downloads/nightlies/) if you feel confident.

You can [submit jobs to the
queue](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/use_latest/JobExecution/Overview.html)
to run Julia code, but this is cumbersone, especially if you need quick feedback during
development or debugging.  Instead, a better workflow consists of getting an [interactive
node](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/use_latest/JobExecution/InteractiveJob.html),
for example with:

```
pjsub --interact -L "node=1" -L "rscgrp=int" -L "elapse=30:00" --sparam "wait-time=600" --mpi "max-proc-per-node=4"
```

To enable full vectorisation you may need to set the environment variable
`JULIA_LLVM_ARGS="-aarch64-sve-vector-bits-min=512"`.  Example:
https://github.com/JuliaLang/julia/issues/40308#issuecomment-901478623.  However, note that
are a couple of sever bugs when using 512-bit vectors:

* <https://github.com/JuliaLang/julia/issues/44401> (may be an upstream LLVM bug:
  <https://github.com/llvm/llvm-project/issues/53331>)
* <https://github.com/JuliaLang/julia/issues/44263> (only in Julia v1.8+)

## MPI.jl

[`MPI.jl`](https://github.com/JuliaParallel/MPI.jl) with default JLL-provided MPICH works
out of the box!  In order to
[configure](https://juliaparallel.github.io/MPI.jl/stable/configuration/) `MPI.jl` v0.19 to
use system-provided Fujitsu MPI (based on OpenMPI) you have to specify the [MPI C
compiler](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/lang_latest/FujitsuCompiler/CompileCommands.html)
for A64FX with

```
julia --project -e 'ENV["JULIA_MPI_BINARY"]="system"; ENV["JULIA_MPICC"]="mpifcc"; using Pkg; Pkg.build("MPI"; verbose=true)'
```

Note: `mpifcc` is available only on the compute nodes.  On the login nodes that would be
`mpifccpx`, but this is the cross compiler running on Intel architecture, it's unlikely
you'll run an `aarch64` Julia on there.  [Preliminary
tests](https://github.com/JuliaParallel/MPI.jl/issues/539) show that `MPI.jl` should work
mostly fine with Fujitsu MPI, but custom error handlers may not be available (read: trying
to use them causes segmentation faults).

***Note***: in `MPI.jl` v0.20 Fujitsu MPI is a known ABI (it's the same as OpenMPI) and
there is nothing special to do to configure it apart from [choosing the system
binaries](https://juliaparallel.org/MPI.jl/dev/configuration/#Configuration-2).

## Reverse engineering Fujitsu compiler using LLVM output

The Fujitsu compiler has [two operation
modes](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/lang_latest/FujitsuCompiler/C/modeTradAndClangC.html):
"trad" (for "traditional") and "clang" (enabled by the flag `-Nclang`).  In clang mode it's
based on LLVM (version 7 at the moment).  This means you can get it to emit LLVM IR with
`-emit-llvm`.  For example, with

```console
$ echo 'int main(){}' | fcc -Nclang -x c - -S -emit-llvm -o -
```

you get

```llvm
; ModuleID = '-'
source_filename = "-"
target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-gnu"

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @main() local_unnamed_addr #0 !dbg !8 {
  ret i32 0, !dbg !11
}

attributes #0 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="a64fx" "target-features"="+crc,+crypto,+fp-armv8,+lse,+neon,+ras,+rdm,+sve,+v8.2a" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5}
!llvm.ident = !{!6}
!llvm.compinfo = !{!7}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang: Fujitsu C/C++ Compiler 4.7.0 (Nov  4 2021 10:55:52) (based on LLVM 7.1.0)", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, enums: !2)
!1 = !DIFile(filename: "-", directory: "/home/ra000019/a04463")
!2 = !{}
!3 = !{i32 2, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{!"clang: Fujitsu C/C++ Compiler 4.7.0 (Nov  4 2021 10:55:52) (based on LLVM 7.1.0)"}
!7 = !{!"C::clang"}
!8 = distinct !DISubprogram(name: "main", scope: !9, file: !9, line: 1, type: !10, isLocal: false, isDefinition: true, scopeLine: 1, isOptimized: true, unit: !0, retainedNodes: !2)
!9 = !DIFile(filename: "<stdin>", directory: "/home/ra000019/a04463")
!10 = !DISubroutineType(types: !2)
!11 = !DILocation(line: 1, column: 12, scope: !8)
```

## SystemBenchmarks.jl

I ran [`SystemBenchmarks.jl`](https://github.com/IanButterworth/SystemBenchmark.jl) on a
compute node.  Here are the results:
<https://github.com/IanButterworth/SystemBenchmark.jl/issues/8#issuecomment-1039775968>.

## BLAS

OpenBLAS seems to have poor performance:

```julia
julia> using LinearAlgebra

julia> peakflops()
2.589865257047898e10
```

Up to v1.7, Julia uses OpenBLAS v0.3.17, which actually doesn't support A64FX at all, so
it's probably using the generic kernels.
[`v0.3.19`](https://github.com/xianyi/OpenBLAS/releases/tag/v0.3.19) and
[`v0.3.20`](https://github.com/xianyi/OpenBLAS/releases/tag/v0.3.20) improved support for
this chip, you can find a build of 0.3.20 at
https://github.com/JuliaBinaryWrappers/OpenBLAS_jll.jl/releases/download/OpenBLAS-v0.3.20%2B0/OpenBLAS.v0.3.20.aarch64-linux-gnu-libgfortran5.tar.gz,
but sadly there isn't a great performance improvement:

```julia
julia> BLAS.lbt_forward("lib/libopenblas64_.so")
4856

julia> peakflops()
2.6362952057793587e10
```

There is an [optimised
BLAS](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/lang_latest/Library/BLASLAPACKScaLAPACKLibrary.html#how-to-dynamically-load-and-use-blas-lapack-and-scalapack)
provided by Fujitsu, with support for SVE (with both LP64 and ILP64).  In order to use it,
install [`FujitsuBLAS.jl`](https://github.com/giordano/FujitsuBLAS.jl)

```julia
julia> using FujitsuBLAS, LinearAlgebra

julia> BLAS.get_config()
LinearAlgebra.BLAS.LBTConfig
Libraries: 
└ [ILP64] libfjlapackexsve_ilp64.so

julia> peakflops()
4.801227630694119e10
```

The package [`BLISBLAS.jl`](https://github.com/carstenbauer/BLISBLAS.jl) similarly forwards
BLAS calls to the [blis](https://github.com/flame/blis) library, which has optimised kernel
for A64FX.

### Benchmarks

_Suggested by Chris Elrod_

Pure Julia:

```julia
julia> using BenchmarkTools, LinearAlgebra, Statistics

julia> function axpy!(z,a,x,y)
           @simd for i in eachindex(z,x,y)
               @inbounds z[i] = muladd(a, x[i], y[i])
           end
       end
axpy! (generic function with 1 method)

julia> b = @benchmark axpy!(z, a, x, y) setup=(N=100; z=randn(N, N); a=randn(); x=randn(N,N); y=randn(N,N));

julia> mean(b.times)
3777.00815

julia> median(b.times)
3773.625

julia> extrema(b.times)
(3703.75, 4537.5)
```

vs vendor BLAS:

```julia
julia> BLAS.get_config()
LinearAlgebra.BLAS.LBTConfig
Libraries: 
└ [ILP64] libfjlapackexsve_ilp64.so

julia> b = @benchmark BLAS.axpy!(a, x, y) setup=(N=100; a=randn(); x=randn(N,N); y=randn(N,N));

julia> mean(b.times)
3354.0343875

julia> median(b.times)
3348.75

julia> extrema(b.times)
(3300.0, 4095.0)
```

Pure Julia implementation is within ~10-15% of the vendor BLAS.

## Building Julia from source

### with GCC

Building Julia from source with GCC (which is the default if you don't set `CC` and `CXX`)
works fine, it's just _slow_:

```
[...]
    JULIA usr/lib/julia/corecompiler.ji
Core.Compiler ──── 903.661 seconds
[...]
Base  ─────────────271.257337 seconds
ArgTools  ───────── 50.348227 seconds
Artifacts  ────────  1.193792 seconds
Base64  ───────────  1.057241 seconds
CRC32c  ───────────  0.097865 seconds
FileWatching  ─────  1.169747 seconds
Libdl  ────────────  0.026215 seconds
Logging  ──────────  0.411966 seconds
Mmap  ─────────────  0.972844 seconds
NetworkOptions  ───  1.159094 seconds
SHA  ──────────────  2.067851 seconds
Serialization  ────  2.942512 seconds
Sockets  ──────────  3.568797 seconds
Unicode  ──────────  0.814165 seconds
DelimitedFiles  ───  1.121546 seconds
LinearAlgebra  ────109.560774 seconds
Markdown  ─────────  7.977584 seconds
Printf  ───────────  1.635409 seconds
Random  ─────────── 13.843395 seconds
Tar  ──────────────  3.146368 seconds
Dates  ──────────── 16.694863 seconds
Distributed  ──────  8.163152 seconds
Future  ───────────  0.060472 seconds
InteractiveUtils  ─  5.245523 seconds
LibGit2  ────────── 15.469061 seconds
Profile  ──────────  5.399918 seconds
SparseArrays  ───── 42.660136 seconds
UUIDs  ────────────  0.165799 seconds
REPL  ───────────── 40.149298 seconds
SharedArrays  ─────  5.476926 seconds
Statistics  ───────  2.130843 seconds
SuiteSparse  ────── 16.849304 seconds
TOML  ─────────────  0.714203 seconds
Test  ─────────────  3.538098 seconds
LibCURL  ──────────  3.547585 seconds
Downloads  ────────  3.657012 seconds
Pkg  ────────────── 54.053634 seconds
LazyArtifacts  ────  0.019103 seconds
Stdlibs total  ────427.178257 seconds
Sysimage built. Summary:
Total ─────── 698.447219 seconds 
Base: ─────── 271.257337 seconds 38.8372%
Stdlibs: ──── 427.178257 seconds 61.1611%
[...]
Precompilation complete. Summary:
Total ─────── 1274.714700 seconds
Generation ── 886.445205 seconds 69.5407%
Execution ─── 388.269495 seconds 30.4593%
```

### With Fujitsu compiler

_For reference, the version used for the last build I attempted was
[`1ad2396f`](https://github.com/JuliaLang/julia/commit/1ad2396f05fa63a71e5842c814791cd7c7715100)_

Compiling Julia from source with the Fujitsu compiler is complicated.  In particular, it's
an absolute pain to use the Fujitsu compiler in trad mode.  You can have some more luck with
clang mode.

Preparation.  Create the `Make.user` file with this content (I'm not sure this file is
actually necessary when using Clang mode, but it definitely is with trad mode):

```makefile
override ARCH := aarch64
override BUILD_MACHINE := aarch64-unknown-linux-gnu
```

Then you can compile with (`-Nclang` is to select clang mode)

```
make -j50 CC="fcc -Nclang" CFLAGS="-Kopenmp" CXX="FCC -Nclang" CXXFLAGS="-Kopenmp"
```

The compiler in trad mode doesn't define the macro `__SIZEOF_POINTER__`, so compilation
would fail in
https://github.com/JuliaLang/julia/blob/1ad2396f05fa63a71e5842c814791cd7c7715100/src/support/platform.h#L114-L115.
The solution is to set the macro `-D__SIZEOF_POINTER__=8` in the `CFLAGS` (or just not use
trad mode).  Then, you may get errors like

```
/vol0003/ra000019/a04463/repo/julia/src/jltypes.c:2000:13: error: initializer element is not a compile-time constant
            jl_typename_type,
            ^~~~~~~~~~~~~~~~
./julia_internal.h:437:41: note: expanded from macro 'jl_svec'
                n == sizeof((void *[]){ __VA_ARGS__ })/sizeof(void *),        \
                                        ^~~~~~~~~~~
/usr/include/sys/cdefs.h:439:53: note: expanded from macro '_Static_assert'
      [!!sizeof (struct { int __error_if_negative: (expr) ? 2 : -1; })]
                                                    ^~~~
/vol0003/ra000019/a04463/repo/julia/src/jltypes.c:2025:43: error: initializer element is not a compile-time constant
    jl_typename_type->types = jl_svec(13, jl_symbol_type, jl_any_type /*jl_module_type*/,
                                          ^~~~~~~~~~~~~~
./julia_internal.h:437:41: note: expanded from macro 'jl_svec'
                n == sizeof((void *[]){ __VA_ARGS__ })/sizeof(void *),        \
                                        ^~~~~~~~~~~
/usr/include/sys/cdefs.h:439:53: note: expanded from macro '_Static_assert'
      [!!sizeof (struct { int __error_if_negative: (expr) ? 2 : -1; })]
                                                    ^~~~
```

This is the compiler's fault, which is supposed to be able to handle this, but you can just
delete the assertions at lines
https://github.com/JuliaLang/julia/blob/1ad2396f05fa63a71e5842c814791cd7c7715100/src/julia_internal.h#L427-L429,
https://github.com/JuliaLang/julia/blob/1ad2396f05fa63a71e5842c814791cd7c7715100/src/julia_internal.h#L436-L438,
https://github.com/JuliaLang/julia/blob/1ad2396f05fa63a71e5842c814791cd7c7715100/src/julia_internal.h#L444-L446.

If you're lucky enough, with all these changes, you may be able to build `usr/bin/julia`.
Unfortunately, last time I tried, run this executable causes a segmentation fault in
`dl_init`:

```
(gdb) run
Starting program: /vol0003/ra000019/a04463/repo/julia/julia 
Missing separate debuginfos, use: yum debuginfo-install glibc-2.28-151.el8.aarch64
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib64/libthread_db.so.1".

Program received signal SIGSEGV, Segmentation fault.
0x000040000000def4 in _dl_init () from /lib/ld-linux-aarch64.so.1
Missing separate debuginfos, use: yum debuginfo-install FJSVxoslibmpg-2.0.0-25.14.1.el8.aarch64 elfutils-libelf-0.182-3.el8.aarch64
(gdb) bt
#0  0x000040000000def4 in _dl_init () from /lib/ld-linux-aarch64.so.1
#1  0x000040000020adb0 in _dl_catch_exception () from /lib64/libc.so.6
#2  0x00004000000125e4 in dl_open_worker () from /lib/ld-linux-aarch64.so.1
#3  0x000040000020ad54 in _dl_catch_exception () from /lib64/libc.so.6
#4  0x0000400000011aa8 in _dl_open () from /lib/ld-linux-aarch64.so.1
#5  0x0000400000091094 in dlopen_doit () from /lib64/libdl.so.2
#6  0x000040000020ad54 in _dl_catch_exception () from /lib64/libc.so.6
#7  0x000040000020ae20 in _dl_catch_error () from /lib64/libc.so.6
#8  0x00004000000917f0 in _dlerror_run () from /lib64/libdl.so.2
#9  0x0000400000091134 in dlopen@@GLIBC_2.17 () from /lib64/libdl.so.2
#10 0x0000400000291f34 in load_library (rel_path=0x400001e900c6 <dep_libs+30> "libjulia-internal.so.1", src_dir=<optimized out>, err=1) at /vol0003/ra000019/a04463/repo/julia/cli/loader_lib.c:65
#11 0x0000400000291c78 in jl_load_libjulia_internal () at /vol0003/ra000019/a04463/repo/julia/cli/loader_lib.c:200
#12 0x000040000000de04 in call_init.part () from /lib/ld-linux-aarch64.so.1
#13 0x000040000000df08 in _dl_init () from /lib/ld-linux-aarch64.so.1
#14 0x0000400000001044 in _dl_start_user () from /lib/ld-linux-aarch64.so.1
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
```
