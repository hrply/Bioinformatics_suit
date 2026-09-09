#!/usr/bin/env python3
import subprocess
import json
import sys

packages = [
    "scipy", "pandas", "numpy", "matplotlib", "seaborn", "h5py", "pyarrow",
    "scrublet", "python-igraph", "leidenalg", "phate", "bokeh", "holoviews",
    "shapely", "scikit-image", "scanpy", "scvelo", "squidpy", "gseapy",
    "decoupler", "torch-geometric", "umap-learn", "pynndescent", "scikit-network",
    "scikit-learn", "scikit-misc", "scikit-survival", "statsmodels", "pydeseq2",
    "cellbender", "harmonypy", "flowio", "bbknn", "scirpy", "pertpy", "cellrank",
    "liana", "FlowKit", "PhenoGraph", "muon", "snapatac2", "pybiomart",
    "statannotations", "pingouin", "PyCytoData"
]

print(f"{'Package':<20} {'conda-forge':<12} {'PyPI':<12} {'更新源'}")
print("-" * 60)

for pkg in packages:
    # conda-forge version
    try:
        result = subprocess.run(
            ["mamba", "search", "-c", "conda-forge", pkg, "--json"],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        pkgs = data.get("result", {}).get("pkgs", [])
        conda_ver = pkgs[-1]["version"] if pkgs else "N/A"
    except:
        conda_ver = "N/A"

    # PyPI version
    try:
        result = subprocess.run(
            ["pip", "index", "versions", pkg],
            capture_output=True, text=True, timeout=10
        )
        output = result.stdout
        if "Available versions:" in output:
            lines = output.split("Available versions:")[1].strip().split("\n")
            pip_ver = lines[0].strip().split(",")[0].strip()
        else:
            pip_ver = "N/A"
    except:
        pip_ver = "N/A"

    # Compare
    if conda_ver != "N/A" and pip_ver != "N/A":
        try:
            c_parts = [int(x) for x in conda_ver.split(".")]
            p_parts = [int(x) for x in pip_ver.split(".")]
            if p_parts > c_parts:
                source = "PyPI ↑"
            elif c_parts > p_parts:
                source = "conda-forge ↑"
            else:
                source = "相同"
        except:
            source = "?"
    else:
        source = "?"

    print(f"{pkg:<20} {conda_ver:<12} {pip_ver:<12} {source}")