import pandas as pd
import matplotlib.pyplot as plt

#pandas va chercher les données
df = pd.read_csv("../results/perf_layout_var.txt", sep=" ", header=None)
df.columns = [
    "LAYOUT_A", "LAYOUT_B", "LAYOUT_C", "TIME", "SPEEDUP",
    "ATOM_CACHE_MISSES", "CORE_CACHE_MISSES",
    "ATOM_CACHE_REF", "CORE_CACHE_REF",
    "ATOM_LLC_MISSES", "CORE_LLC_MISSES",
    "CORE_L1_MISSES"
]

#permet d'extraire les bons labels de blocs
df["LAYOUT_LABEL"] = df.apply(lambda row: f"{row['LAYOUT_A'][-5:]}_{row['LAYOUT_B'][-5:]}_{row['LAYOUT_C'][-5:]}", axis=1)
x = df["LAYOUT_LABEL"]

#graphique
plt.figure(figsize=(14, 8))

plt.plot(x, df["CORE_L1_MISSES"], marker='o', linestyle='-', label="Core L1 Misses", color="red")
plt.plot(x, df["CORE_LLC_MISSES"], marker='*', linestyle='-', label="Core LLC Misses", color="orange")
plt.plot(x, df["CORE_CACHE_MISSES"], marker='+', linestyle='-', label="Core Cache Misses", color="purple")
plt.plot(x, df["ATOM_CACHE_MISSES"], marker='o', linestyle='--', label="Atom Cache Misses", color="pink")

plt.plot(x, df["ATOM_LLC_MISSES"], marker='s', linestyle='--', label="Atom LLC Misses", color="magenta")
plt.plot(x, df["ATOM_CACHE_REF"], marker='d', linestyle=':', label="Atom Cache Refs", color="blue")
plt.plot(x, df["CORE_CACHE_REF"], marker='x', linestyle=':', label="Core Cache Refs", color="green")

plt.xticks(rotation=45)
plt.xlabel("Layout (AxBxC)")
plt.ylabel("Nombre de cache misses")
plt.title("Analyse des Cache Misses selon les layouts")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
plt.yscale('log', subs=[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1,1.2, 1.3])

plt.savefig("../figures/cache_misses_layout.png")
plt.show()

#graphique time
plt.figure(figsize=(14, 8))

plt.plot(x, df["TIME"], marker='+', linestyle='--', label="Time", color="blue")
plt.xticks(rotation=45)
plt.xlabel("Layout (AxBxC)")
plt.ylabel("Nombre de cache misses")
plt.title("Analyse du temps selon les layouts")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
plt.savefig("../figures/time_layout.png")
plt.show()