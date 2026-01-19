#!/usr/bin/env python3
# run_fxpmath_ref_v3.py
# Fix: err sign convention matches Octave: err = x - vfxp

import csv
import sys
from pathlib import Path
import numpy as np

try:
    from fxpmath import Fxp
except Exception as e:
    raise SystemExit("fxpmath import failed. Install with: pip install fxpmath") from e

ROUND_MAP = {
    "round": "around",
    "around": "around",
    "nearest": "around",
    "rnd": "around",
    "floor": "floor",
    "ceil": "ceil",
    "fix": "fix",
    "trunc": "trunc",
}

OVF_MAP = {
    "sat": "saturate",
    "saturate": "saturate",
    "wrap": "wrap",
    "wraparound": "wrap",
}

def norm_rounding(r):
    r = (r or "").strip().lower()
    return ROUND_MAP.get(r, "trunc")

def norm_overflow(o):
    o = (o or "").strip().lower()
    return OVF_MAP.get(o, "saturate")

def read_vector_csv(path):
    data = np.loadtxt(str(path), delimiter=",", ndmin=1)
    return np.atleast_1d(np.asarray(data, dtype=float))

def write_vector_csv(path, arr):
    arr = np.atleast_1d(np.asarray(arr))
    with Path(path).open("w", newline="") as f:
        for v in arr.reshape(-1):
            f.write("{:.17g}\n".format(float(v)))

def quantize(x, signed, n_word, n_frac, overflow, rounding):
    x_arr = np.atleast_1d(np.asarray(x, dtype=float))
    fx = Fxp(
        x_arr,
        signed=bool(int(signed)),
        n_word=int(n_word),
        n_frac=int(n_frac),
        overflow=norm_overflow(overflow),
        rounding=norm_rounding(rounding),
    )
    v = np.asarray(fx(), dtype=float)
    e = x_arr - v   # <-- Octave convention
    return v, e

def read_meta(meta_path):
    rows = []
    with meta_path.open("r", newline="") as f:
        r = csv.DictReader(f)
        required = ["tc_id", "op", "signed", "n_word", "n_frac", "overflow", "rounding"]
        for k in required:
            if k not in (r.fieldnames or []):
                raise SystemExit("meta.csv missing column '{}' (found: {})".format(k, r.fieldnames))
        for row in r:
            rows.append({
                "tc_id": int(row["tc_id"]),
                "op": row["op"].strip().lower(),
                "signed": int(row["signed"]),
                "n_word": int(row["n_word"]),
                "n_frac": int(row["n_frac"]),
                "overflow": row["overflow"].strip(),
                "rounding": row["rounding"].strip(),
            })
    return rows

def run_fir(outdir):
    fmeta = outdir / "filter_meta.csv"
    if not fmeta.exists():
        raise SystemExit("Missing filter_meta.csv for FIR testcase")

    cfg = {}
    with fmeta.open("r", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            name = row["name"].strip().lower()
            cfg[name] = {
                "signed": int(row["signed"]),
                "n_word": int(row["n_word"]),
                "n_frac": int(row["n_frac"]),
                "overflow": row["overflow"].strip(),
                "rounding": row["rounding"].strip(),
            }

    b = read_vector_csv(outdir / "tc_10_b.csv")
    x = read_vector_csv(outdir / "tc_10_x.csv")

    bq, _ = quantize(b, **cfg["b"])
    xq, _ = quantize(x, **cfg["x"])

    y = np.convolve(xq, bq, mode="full")[: xq.shape[0]]
    write_vector_csv(outdir / "tc_10_y_py.csv", y)

def main():
    if len(sys.argv) != 2:
        print("Usage: run_fxpmath_ref_v3.py <interop_dir>", file=sys.stderr)
        return 2

    outdir = Path(sys.argv[1]).expanduser().resolve()
    meta_path = outdir / "meta.csv"
    if not meta_path.exists():
        print("Missing meta.csv at {}".format(meta_path), file=sys.stderr)
        return 2

    meta = read_meta(meta_path)

    for row in meta:
        tc_id = row["tc_id"]
        op = row["op"]

        if op == "quantize":
            x_path = outdir / "tc_{}_x.csv".format(tc_id)
            if not x_path.exists():
                raise SystemExit("Missing stimulus {}".format(x_path))
            x = read_vector_csv(x_path)
            v, e = quantize(
                x,
                signed=row["signed"],
                n_word=row["n_word"],
                n_frac=row["n_frac"],
                overflow=row["overflow"],
                rounding=row["rounding"],
            )
            write_vector_csv(outdir / "tc_{}_py_vfxp.csv".format(tc_id), v)
            write_vector_csv(outdir / "tc_{}_py_err.csv".format(tc_id), e)

        elif op == "fir":
            run_fir(outdir)

    return 0

if __name__ == "__main__":
    raise SystemExit(main())