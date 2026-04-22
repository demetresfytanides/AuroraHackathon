# Running a WPS-initialized Case in ERF

> **Status: PLACEHOLDER.**
> This page will be filled in during / after the Aurora Hackathon.

This document will describe how to take output from the **WRF
Preprocessing System (WPS)** (`geo_em.*`, `met_em.*` files) and use it
to drive a **real-data** case in ERF on Aurora.

---

## 1. What you need from WPS

Typical WPS output that ERF can ingest:

- `geo_em.d0<N>.nc` — static geographic fields from `geogrid.exe`.
- `met_em.d0<N>.<YYYY-MM-DD_HH>:00:00.nc` — time-dependent
  meteorological fields from `metgrid.exe`.

> TODO: confirm whether ERF consumes `met_em` directly or whether a
> `real.exe`-equivalent step (e.g. an ERF init program) is required.

---

## 2. Build requirements

NetCDF must be enabled in the build. This is already the case in
`scripts/build_erf_aurora.sh`:

```cmake
-DERF_ENABLE_NETCDF=ON
-DERF_ENABLE_HDF5=ON
```

> TODO: note any additional flag (e.g. `-DERF_ENABLE_WRF_INPUTS=ON`)
> required once confirmed.

---

## 3. Directory layout for a WPS-driven run

Suggested layout under `$BASE/runs/<case>`:

```
<case>/
├── inputs                          # ERF input file
├── wps/
│   ├── geo_em.d01.nc
│   ├── met_em.d01.2022-07-14_00:00:00.nc
│   ├── met_em.d01.2022-07-14_06:00:00.nc
│   └── ...
└── noahmp_tables/                  # only if using Noah-MP
```

---

## 4. Relevant `inputs` keys

> TODO: fill in the actual key names once verified in the ERF source.
> Expected pattern:
>
> ```
> erf.init_type          = real
> erf.nc_init_file       = wps/met_em.d01.2022-07-14_00:00:00.nc
> erf.nc_bdy_file        = wps/met_em.d01.2022-07-14_*:00:00.nc
> erf.geo_em_file        = wps/geo_em.d01.nc
> geometry.prob_lo       = ...
> geometry.prob_hi       = ...
> amr.n_cell             = ...
> ```

---

## 5. Recommended workflow on Aurora

1. Run **WPS** on a host of your choice (often a laptop / workstation or
   another ALCF system) to produce `geo_em.*` and `met_em.*`.
2. Transfer those NetCDF files to Aurora (`scp`, Globus, ...) into
   `$BASE/runs/<case>/wps/`.
3. Copy an ERF real-data template:

   ```bash
   cd $BASE/ERF
   ./case_helper.sh real_wps_case Exec/DevTests/<real_case_template> inputs_real
   ```

4. Edit `$BASE/runs/real_wps_case/inputs` to point at the WPS files.
5. Submit using an edited copy of `scripts/job.pbs`.

---

## 6. Open questions / TODO

- [ ] Verify the exact `Exec/...` subdirectory that ERF ships for
      WPS/real-data cases.
- [ ] Document grid / projection constraints (lat-lon vs Lambert vs
      Mercator) that ERF currently supports.
- [ ] Add a minimal CONUS or LES-style example with shareable
      `met_em.*` files on Aurora `/flare`.
- [ ] Document how to couple this with Noah-MP and RRTMGP
      (see [radiation_landmodel.md](radiation_landmodel.md)).
