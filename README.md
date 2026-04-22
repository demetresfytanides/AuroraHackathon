# Aurora Hackathon — ERF on ALCF Aurora

End-to-end, copy/paste workflow for downloading, building, and running
[ERF (Energy Research and Forecasting)](https://github.com/erf-model/ERF)
on the **Aurora** supercomputer at the
[Argonne Leadership Computing Facility (ALCF)](https://www.alcf.anl.gov/aurora).

This tutorial walks you through:

1. Creating an SSH key and connecting it to your GitHub account.
2. Cloning ERF on Aurora.
3. Building ERF with the provided `scripts/build_erf_aurora.sh` helper.
4. Copying an example case and launching it with `scripts/case_helper.sh`.
5. Submitting a batch job with `scripts/job.pbs` via PBS Pro.
6. Placeholders for enabling radiation + land model (SLM / NoahMP) and
   running a WPS-initialized case.

> Everything below is designed to be copy/paste friendly. Edit the paths
> that reference `/flare/gpu_hack/dfytanidis` and replace them with your
> own project / user directories.

---

## 0. Prerequisites

- An active ALCF account with access to Aurora.
- Membership in a project with Aurora allocation (e.g. `crocus`, `gpu_hack`, ...).
- A GitHub account.

Log in to Aurora:

```bash
ssh <your_alcf_username>@aurora.alcf.anl.gov
```

---

## 1. Create an SSH key for GitHub

You only need to do this **once per machine** (i.e. once on Aurora).

### 1.1 Generate the key pair

```bash
# On Aurora (login node)
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate an ed25519 key — recommended by GitHub
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_github
```

When prompted:
- Press **Enter** to accept the default file location (or use the `-f` path above).
- Optionally set a passphrase (leave blank for no passphrase).

### 1.2 Start the ssh-agent and add the key

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github
```

### 1.3 Tell SSH to use this key for github.com

```bash
cat >> ~/.ssh/config <<'EOF'

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
```

### 1.4 Copy the **public** key

```bash
cat ~/.ssh/id_ed25519_github.pub
```

Copy the entire output (starts with `ssh-ed25519 ...`).

### 1.5 Add the key to GitHub

1. Go to https://github.com/settings/keys
2. Click **New SSH key**.
3. Title: `Aurora login node` (or whatever you like).
4. Key type: **Authentication Key**.
5. Paste the public key into the **Key** field.
6. Click **Add SSH key**.

### 1.6 Verify the connection

```bash
ssh -T git@github.com
```

You should see:

```
Hi <your_github_username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 2. Clone ERF on Aurora

Choose a working directory on the **flare** (project) filesystem — the
home filesystem is small and slow for builds.

```bash
# Pick a project path that you have write access to
export BASE=/flare/gpu_hack/<your_username>
or BASE=~/

#optional
mkdir -p "$BASE"
cd "$BASE"

git clone git@github.com:erf-model/ERF.git
cd ERF
git submodule update --init --recursive
```

You should now have `$BASE/ERF` containing the full ERF source tree.

---

## 3. Grab the hackathon helper scripts

Clone this tutorial repo anywhere you like (e.g. in your home directory),
then copy the three helper scripts into `$BASE/ERF`:

```bash
cd ~
git clone git@github.com:demetresfytanides/AuroraHackathon.git
cp AuroraHackathon/scripts/build_erf_aurora.sh  $BASE/ERF/
cp AuroraHackathon/scripts/case_helper.sh       $BASE/ERF/
cp AuroraHackathon/scripts/job.pbs              $BASE/ERF/
chmod +x $BASE/ERF/build_erf_aurora.sh $BASE/ERF/case_helper.sh
```

---

## 4. Build ERF on Aurora

The build is driven entirely by `scripts/build_erf_aurora.sh`. It:

- Sources `Build/machines/aurora_erf.profile` (loads compilers + MPI + NetCDF + HDF5).
- Resolves `NETCDF_C_ROOT`, `NETCDF_FORTRAN_ROOT`, and `HDF5_ROOT` from the module system.
- Configures CMake with SYCL / Intel PVC support, NetCDF, HDF5, NoahMP, and RRTMGP enabled.
- Builds in `build_aurora/` and (optionally) installs to `install_aurora/`.

Run it from the ERF top-level directory on a **compute-capable login node**
or inside an interactive job:

```bash
cd $BASE/ERF
./build_erf_aurora.sh 2>&1 | tee build.log
```

The first full build takes a while (SYCL AOT compilation for PVC is
expensive). When it finishes you should see the executable at:

```
$BASE/ERF/build_aurora/Exec/<case>/erf_<case>
```

> **Tip:** To produce a clean `install_aurora/bin/erf_exec` (which the
> helper and job scripts expect), uncomment the last two `cmake --install`
> lines in `scripts/build_erf_aurora.sh` and rerun.

### 4.1 What the CMake flags mean

| Flag | Purpose |
| --- | --- |
| `-DERF_ENABLE_MPI=ON` | MPI parallelism |
| `-DERF_ENABLE_NETCDF=ON` | NetCDF I/O (needed for real cases / WPS) |
| `-DERF_ENABLE_HDF5=ON` | Parallel HDF5 I/O |
| `-DERF_ENABLE_NOAHMP=ON` | Enable Noah-MP land-surface model |
| `-DERF_ENABLE_RRTMGP=ON` | Enable RRTMGP radiation package |
| `-DERF_ENABLE_SYCL=ON` | GPU offload via SYCL |
| `-DAMReX_GPU_BACKEND=SYCL` | AMReX SYCL backend |
| `-DAMReX_INTEL_ARCH=pvc` | Target Intel Data Center GPU Max (PVC) |
| `-DAMReX_SYCL_AOT=ON` | Ahead-of-time compilation for PVC |
| `-DKokkos_ENABLE_SYCL=ON` | Kokkos SYCL backend (used by RRTMGP / Noah-MP) |
| `-DKokkos_ARCH_INTEL_PVC=ON` | Kokkos target arch |

---

## 5. Run an example case interactively

The `case_helper.sh` script copies a canonical ERF test case into a run
directory, loads the runtime environment, and launches a short single-rank
smoke test with `mpiexec -n 1`.

**Before** using it, open `scripts/case_helper.sh` and edit the `BASE`
variable to match **your** project directory:

```bash
BASE=/flare/gpu_hack/<your_username>
```

### 5.1 Usage

```bash
./case_helper.sh <CASE_NAME> <TEMPLATE_PATH> <INPUT_FILE>
```

Defaults:

- `CASE_NAME  = abl_test`
- `TEMPLATE   = Exec/CanonicalTests/ABL`
- `INPUT_FILE = inputs_most`

Example — run the ABL (Atmospheric Boundary Layer) canonical test:

```bash
cd $BASE/ERF
./case_helper.sh abl_test Exec/CanonicalTests/ABL inputs_most
```

This creates `$BASE/runs/abl_test/`, copies the template inputs into it,
cleans old `plt*` / `chk*` outputs, reloads the runtime modules, and
launches ERF interactively.

> This interactive run is meant as a quick sanity check. For real work,
> submit a job (section 6).

---

## 6. Submit a batch job with PBS Pro

Aurora uses **PBS Pro**. The provided `scripts/job.pbs` launches ERF on 1
Aurora node (12 MPI ranks) for 20 minutes in the `debug` queue.

### 6.1 Edit `job.pbs` for your environment

Update these at the top of the file:

```bash
#PBS -A <your_project>        # e.g. crocus, gpu_hack, ...
#PBS -q debug                 # or prod, etc.
#PBS -l select=1              # number of nodes
#PBS -l walltime=00:20:00
#PBS -N erf_abl_test
#PBS -l filesystems=home:flare
```

And these environment variables inside the script:

```bash
CASE_DIR=/flare/gpu_hack/<your_username>/runs/abl_test
ERF_DIR=/flare/gpu_hack/<your_username>/ERF
EXE=$ERF_DIR/install_aurora/bin/erf_exec   # or your build_aurora/... path
INPUTS=inputs_most
```

### 6.2 Submit

```bash
cd $CASE_DIR                              # same directory referenced inside job.pbs
qsub $ERF_DIR/job.pbs
```

### 6.3 Monitor

```bash
qstat -u $USER            # queue status
qstat -f <jobid>          # full detail
tail -f run.out           # inside the case directory, once the job starts
```

Output files:

- `run.out`              — merged stdout / stderr from the run
- `erf_abl_test.o<jobid>` — PBS log (from `#PBS -j oe`)
- `plt*` / `chk*`         — ERF plot / checkpoint dumps

---

## 7. Repository layout

```
AuroraHackathon/
├── README.md                        # <-- you are here
├── scripts/
│   ├── build_erf_aurora.sh          # CMake-based build driver for Aurora
│   ├── case_helper.sh               # Copy a test case + run interactively
│   └── job.pbs                      # PBS Pro batch job template
└── docs/
    ├── radiation_landmodel.md       # Placeholder: enabling SLM / NoahMP / RRTMGP
    └── wps_case.md                  # Placeholder: running a WPS-initialized case
```

---

## 8. Advanced topics (placeholders — TODO)

These sections are intentionally left as stubs so they can be filled in
during / after the hackathon.

- [docs/radiation_landmodel.md](docs/radiation_landmodel.md) — how to
  switch on the radiation package (**RRTMGP**) and the land-surface
  models (**SLM** and **Noah-MP**) at both build time and run time.
- [docs/wps_case.md](docs/wps_case.md) — how to initialize and run an
  ERF case from **WPS** (WRF Preprocessing System) output
  (`met_em.d0*.nc`).

---

## 9. Troubleshooting quick-reference

| Symptom | Likely fix |
| --- | --- |
| `NETCDF_C_ROOT is not set` | Re-source `Build/machines/aurora_erf.profile` or load `netcdf-c` module explicitly. |
| `Permission denied (publickey)` on `git clone` | Re-check section 1; ensure `~/.ssh/config` points at the correct key and the public key is registered on GitHub. |
| Build OOMs the login node | Launch the build from an interactive PBS job (`qsub -I -l select=1 -q debug ...`). |
| `qsub: Unauthorized Request` | Set `#PBS -A <valid_project>` to a project you belong to. |
| Job runs but produces no output | Ensure the job's working directory matches `CASE_DIR` and that `$INPUTS` exists there. |

---

## 10. Credits

Maintained for the ALCF Aurora Hackathon.
Build / run scripts adapted from the ERF project:
https://github.com/erf-model/ERF
