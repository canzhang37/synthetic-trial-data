"""Fit CTGAN once per replicate and write one synthetic copy per fit.

python python/ctgan_generate.py --data data/colon.csv --out data/synthetic/ctgan --reps 100 --workers 10
"""
import argparse
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np
import pandas as pd

CONTINUOUS = ["age", "nodes", "rec_time", "os_time"]
SEED0 = 2027


def one(args):
    data, out, rep, epochs = args
    import torch
    from ctgan import CTGAN
    from joblib import parallel_config

    torch.set_num_threads(1)  # workers run side by side
    seed = SEED0 + rep
    np.random.seed(seed)
    torch.manual_seed(seed)
    d = pd.read_csv(data)
    discrete = [c for c in d.columns if c not in CONTINUOUS]
    t = time.time()
    m = CTGAN(epochs=epochs)
    m.set_random_state(seed)
    # ctgan forks a joblib worker per core here
    with parallel_config(backend="sequential"):
        m.fit(d, discrete_columns=discrete)
        s = m.sample(len(d))
    for c in CONTINUOUS:
        s[c] = s[c].round().clip(d[c].min(), d[c].max()).astype(int)
    s.to_csv(Path(out) / f"rep_{rep:03d}.csv", index=False)
    return rep, time.time() - t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--reps", type=int, default=100)
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--workers", type=int, default=1)
    ap.add_argument("--epochs", type=int, default=300)
    a = ap.parse_args()
    Path(a.out).mkdir(parents=True, exist_ok=True)
    jobs = [(a.data, a.out, r, a.epochs) for r in range(a.first, a.first + a.reps)]
    with ProcessPoolExecutor(a.workers) as ex:
        for rep, sec in ex.map(one, jobs):
            print(f"rep {rep}: {sec:.0f}s", flush=True)


if __name__ == "__main__":
    main()
