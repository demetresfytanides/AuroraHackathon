# Enabling Radiation and Land-Surface Models in ERF

> **Status: PLACEHOLDER.**
> This page will be filled in during / after the Aurora Hackathon.
> Below is a skeleton of the sections we intend to cover — add notes as we go.

This document describes how to enable and configure:

1. The **RRTMGP** radiation package.
2. The **Simple Land Model (SLM)**.
3. The **Noah-MP** land-surface model.

For each component we will document:

- Build-time CMake flags.
- Runtime input-file (`inputs`) parameters.
- Required ancillary data (lookup tables, initial / boundary data).
- A minimal worked example on Aurora.

---

## 1. Radiation — RRTMGP

### 1.1 Build-time

The `scripts/build_erf_aurora.sh` build already includes:

```cmake
-DERF_ENABLE_RRTMGP=ON
-DKokkos_ENABLE_SYCL=ON
-DKokkos_ARCH_INTEL_PVC=ON
```

> TODO: explain any additional submodules / data that need to be in
> place (e.g. `Submodules/RRTMGP`, k-distribution files under
> `Data/rrtmgp/`).

### 1.2 Runtime inputs

> TODO: list the relevant `erf.*` / `radiation.*` keys, e.g.:
>
> ```
> erf.radiation_model   = rrtmgp
> radiation.sw_lookup   = <path-to-sw-k-distribution.nc>
> radiation.lw_lookup   = <path-to-lw-k-distribution.nc>
> radiation.dt_rad      = <seconds>
> ```

### 1.3 Minimal example

> TODO: point at or include a canonical test input under
> `Exec/DevTests/.../inputs_rrtmgp`.

---

## 2. Simple Land Model (SLM)

### 2.1 Build-time

> TODO: confirm which CMake flags toggle SLM (e.g. `-DERF_ENABLE_SLM=ON`
> if separate from Noah-MP) and update `scripts/build_erf_aurora.sh`
> accordingly.

### 2.2 Runtime inputs

> TODO: document the `erf.land_model = slm` key and SLM-specific
> parameters (soil levels, initial temperatures, moisture, ...).

### 2.3 Minimal example

> TODO.

---

## 3. Noah-MP

### 3.1 Build-time

`scripts/build_erf_aurora.sh` already enables Noah-MP:

```cmake
-DERF_ENABLE_NOAHMP=ON
```

> TODO: document any required table files (e.g. `MPTABLE.TBL`,
> `SOILPARM.TBL`, `GENPARM.TBL`, `VEGPARM.TBL`) and where they should
> live in the run directory.

### 3.2 Runtime inputs

> TODO: list the relevant keys, e.g.:
>
> ```
> erf.land_model       = noahmp
> noahmp.table_dir     = ./noahmp_tables
> noahmp.dt_lsm        = <seconds>
> ```

### 3.3 Minimal example

> TODO: a copyable set of `inputs` snippets + pointer to an example test
> case in the ERF repo.

---

## 4. Running a combined radiation + land example on Aurora

> TODO: full end-to-end recipe:
>
> 1. Build ERF with the flags above.
> 2. Use `scripts/case_helper.sh` to copy a suitable template.
> 3. Edit `inputs` to enable `rrtmgp` + `noahmp` (or `slm`).
> 4. Copy lookup / parameter tables into the run directory.
> 5. Submit with a modified `scripts/job.pbs`.
