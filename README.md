# verse-native-bench

Hand-written Verse rewrites of Fortnite's native functions, benchmarked against the natives on three runtimes:

- **New VM**: Epic's new VerseVM (`VerseCmd`), local;
- **BPVM local**: the Blueprint VM backend that Fortnite runs (`VerseCLR`, Shipping build), local;
- **BPVM UEFN**: the same code on the server of a UEFN play session.

107 comparisons, every rewrite checked against its native on the same inputs. Full table with the code behind each row: [results page](https://claude.ai/artifact/QMYzfUfhG92REekDU8S97A) (also in [`results/bench-results.html`](results/bench-results.html), data in [`results/table.json`](results/table.json)).

## Findings

Speed-up = native time / rewrite time (above 1 means the rewrite is faster). Median of 4 rounds, 10,000 calls per block.

**On the BPVM, building a `/UnrealEngine.com/Temporary/SpatialMath` struct is what costs, not the math.** Every `vector3{...}` of Temporary creates 3 strings (`MakeLiteral("__verse_0x…_X")`…), a `TMap<string,bool>` of the given fields, and calls `SpatialMath_vector3$OverrideFactory` before setting the fields (seen in the BPVM disassembly). The `/Verse.org/SpatialMath` `vector3` (`@import_as FVVector3`) only sets its 3 fields. 10,000 constructions ([`experiments/struct_cost.verse`](experiments/struct_cost.verse)):

| | New VM | BPVM |
|---|---|---|
| Temporary `vector3{...}` | 14 ms | 190 ms |
| Verse.org `vector3{...}` | 18 ms | 6.8 ms |
| user struct | 7–8 ms | 133–222 ms |
| tuple `(X, Y, Z)` | 3.8 ms | 3.9 ms |

So anything that builds intermediate vectors gains a lot when rewritten:

| Rewrite | New VM | BPVM local | **BPVM UEFN** |
|---|---|---|---|
| `HomingStep` (7 intermediate vectors) with `(float, float, float)` tuples | 4.71× | 32.09× | **17.99×** |
| `HomingStep` with the Verse.org `vector3` | 0.97× | 19.29× | **8.29×** |
| `A + B` with tuples | 2.94× | 25.65× | **17.78×** |
| `DistanceSquared`, without `V2 - V1` | 3.08× | 22.97× | **14.56×** |
| `V.IsFinite[]`, returns `V` instead of rebuilding it | 2.86× | 15.18× | **13.37×** |
| `GetLocalForward`, constant axis | 2.15× | 18.54× | **11.76×** |
| `Concatenate`, one pass instead of recursive `Slice` | 0.61× | 6.32× | **11.04×** |
| `Distance`, without `V2 - V1` | 2.95× | 13.85× | **7.98×** |
| `ReflectVector`, without its 3 intermediate vectors | 2.42× | 3.68× | **3.93×** |
| `MakeUnitVector` | 1.67× | 2.22× | **2.37×** |

**C++ natives stay faster for scalar math.** No Verse rewrite comes close: `Sqrt` 0.08×, `Sin`/`Cos`/`Tan` ~0.1×, `Exp`/`Ln`/hyperbolics ~0.05×, `Floor`/`Round` 0.04×, `Abs` 0.27×, `Mod` 0.40×, generic `SortBy` 0.71× (all BPVM UEFN).

**UEFN confirms the local BPVM.** 103 of 107 comparisons get the same verdict; the other 4 are borderline (`Min`/`Max` float, `Insert`, `TransformVectorNoScale`). Large gains are a bit smaller in UEFN, losses are the same. The UEFN run's checksum matches the local one bit for bit.

**On the new VM the gaps mostly disappear.** Verse.org vectors are on par with Temporary ones and tuples gain 2.5–5×, so this is mostly a BPVM matter for now.

What it means for hot UEFN code:
1. Compute with tuples, or at least with `/Verse.org/SpatialMath`, rather than `/UnrealEngine.com/Temporary/SpatialMath`.
2. If an API needs a Temporary `vector3`, build it once, at the end.
3. In a long loop, suspend now and then (`Sleep(0.0)`): the BPVM transaction keeps every allocation until it commits.
4. Keep the natives for scalar math.
5. Effects (`<computes>`, `<reads>`, `<transacts>`) do not change speed. On the BPVM, `set Arr += array{X}` is expensive (~15 µs), `set Arr[I] = X` is almost free.

## How it was measured

1. **Real runtimes.** The new VerseVM and the BPVM were built from Unreal Engine source (pin `de57436d4d`), with `/Verse.org/SpatialMath` and `/UnrealEngine.com/Temporary/SpatialMath` and their original C++ natives, plus a `PROFILE <tag>: <ms> ms` line for every `profile` block. Absolute times differ from Fortnite's; only the native/rewrite ratio on one VM matters.
2. **Drop-in rewrites.** Every rewrite in [`bench/lib`](bench/lib) is plain Verse with the same signature and effects as its native, and compiles in UEFN as is.
3. **Same results.** Before timing, [`bench/harness`](bench/harness) compares each rewrite with its native on edge cases (NaN, ±Inf, -0.0, subnormals, failures of `<decides>` functions) and random inputs: 96 check groups, no divergence on the three runtimes. Gaps are 0 ulp, except `FastSqrt` (≤ 1 ulp), degree/radian conversions (≤ 1 ulp, up to 7 ulp on a rotated vector) and transcendentals (≤ 3 ulp).
4. **Timing.** Each block times 10,000 calls (arrays: 100 operations on 1,000 elements, 25 for `Concatenate` and `ReplaceAll`; sorting: 50 sorts of 200 floats), 4 rounds, median. Inputs are built once, outside the `profile` blocks.
5. **UEFN.** The same files run from a Verse device in a UEFN session, with `Sleep(0.0)` between blocks to stay under UEFN's ~10 s limit for code that runs without suspending.

## Layout

| Path | Contents | In UEFN |
|---|---|---|
| [`bench/lib`](bench/lib) | the rewrites: `FastMath`, `FastArray`, `FastSpatial`, `FastVerseSpatial`, `TupleMath`, `FastTranscendental`, `FastSort`, `FastEasing` | as is |
| [`bench/harness`](bench/harness) | `Check*` (correctness), `Bench*` (`profile` blocks), inputs, `RunCheck` / `RunBench` | in the same folder as `lib` |
| [`bench/cli`](bench/cli) | `Main` for the local runtimes | no |
| [`bench/uefn`](bench/uefn) | `bench_device`: the same calls from `OnBegin` | yes |
| [`experiments`](experiments) | struct construction cost, SpatialMath smoke test | no |
| [`tools`](tools) | launcher, UEFN sync, results table and page | — |
| [`results`](results) | `raw/` profile lines of each runtime, `table.json`, the results page | — |

Profile tags are `Native <Name>` and `<Variant> <Name>` with `Fast`, `Inline`, `Inlined`, `VerseOrg`, `Tuple` or `Scalar` as variant.

## Running

### Local runtimes

The runtimes live in WSL (Ubuntu 24.04) under `~/verse-bench/{new,bpvm,ship}`; they are built from Unreal Engine source, which needs access to Epic's GitHub. Then, from Windows:

```bat
verse.cmd --vm=all bench                         :: new, bpvm, ship, with a comparison table
verse.cmd --vm=new,ship experiments\struct_cost.verse
```

`--vm` takes `new`, `bpvm`, `ship`, `both` (new and bpvm) or `all`. A folder is concatenated in the order `lib`, `harness`, `cli`. A full `--vm=all` run takes a few GB of memory: never run two at once.

To rebuild the table and the page from raw outputs:

```sh
py tools/bench-table.py results/table.json new=results/raw/new.txt ship=results/raw/ship.txt uefn=results/raw/uefn.txt
py tools/bench-page.py results/table.json bench results/bench-results.html
```

### UEFN

1. `bash tools/uefn-sync.sh <uefn-project-dir>` copies `lib`, `harness` and `uefn` into `Content/NativeBench`, one folder so one module. The `lib` files get an `a_` prefix: UEFN compiles a folder in name order, and a type alias (`verse_vector3`, `vec3`) cannot be used before its file.
2. Place `bench_device` in the level and start a session. Correctness checks are off by default (`RunChecks`, ~100 s).
3. Profile lines land in the editor log (`%LOCALAPPDATA%\UnrealEditorFortnite\Saved\Logs\UnrealEditorFortnite.log`) as `LogVerse: VerseProfile: <tag> <ms> ms`; `bench-table.py` reads that file directly (`--uefn-since=<timestamp>` keeps one session).

### Adding a benchmark

Write the rewrite in `bench/lib`, add `bench/harness/bench_<name>.verse` with a `Check<Name>` and a `Bench<Name>`, and give each one an index in `RunCheck` and `RunBench` ([`bench/harness/all.verse`](bench/harness/all.verse)). Keep each `RunBench` item under ~2 s on the local Shipping BPVM so it stays under UEFN's limit.

## Verse notes picked up along the way

- `NaN = NaN` and `NaN <= NaN` succeed; `NaN < X`, `NaN > X` and `NaN <> NaN` fail.
- The BPVM keeps `-0.0` (literals, storage, natives) but `=` does not tell it from `0.0`; the new VM turns everything into `+0.0`. The checks compare zero signs through `ArcTan(X, -1.0)`. The natives `Sqrt`, `Abs` and `Tan` return `+0.0` for `-0.0`.
- `Clamp` (float) returns NaN as soon as an argument is NaN, despite its `@doc`. `FastClamp` reproduces the real behavior.
- `Floor`, `Ceil`, `Round` and `Int` on a float outside the 64-bit integer range raise a runtime error, not a failure.
- `ArcSin(NaN)` returns π/2 and `ArcCos(NaN)` returns 0: the native clamps its argument to [-1, 1].
- Rounding without a native call: `(X + 6755399441055744.0) - 6755399441055744.0` (to nearest, ties to even, |X| < 2^51).
- A local `var` is not allowed in `<computes>`, hence the recursion in `FastSqrt`. Instantiating a class makes a function at least `<transacts>`.
- Overloading a function on two option types (`?vector2` / `?vector3`) is rejected as ambiguous.
- Naming a variable like a `/Verse.org/Verse` function (`Round`, `Floor`, `Abs`, `Min`…) is an ambiguity error.
- In UEFN a `using` only applies to its own file; in a single concatenated file a top-level `using` also applies inside modules, hence the `verse_vector3`/`verse_rotation`/`verse_transform` aliases.
- `VerseCLR` cannot call a `<suspends>` target directly, so the launcher starts `Main` with `spawn{}`; on the new VM a file with `@editable` fields cannot run.
- On Windows, editing `.verse` files with PowerShell 5.1 `Get-Content`/`Set-Content` breaks UTF-8 and the compiler fails with V3100.
