import pandas as pd
import matplotlib.pyplot as plt

#pandas va chercher les données
df = pd.read_csv("../results/perf_bloc_var.txt", sep=" ", header=None)
df.columns = [
    "BLOCK", "TIME", "SPEEDUP",
    "ATOM_CACHE_MISSES", "CORE_CACHE_MISSES",
    "ATOM_CACHE_REF", "CORE_CACHE_REF",
    "ATOM_LLC_MISSES", "CORE_LLC_MISSES",
    "CORE_L1_MISSES"
]

#permet d'extraire les bons labels de blocs
df["BLOCK_LABEL"] = df["BLOCK"].apply(lambda x: (f"{str(x)[:len(str(x))//3]}x{str(x)[len(str(x))//3:2*len(str(x))//3]}x{str(x)[2*len(str(x))//3:]}" if len(str(x)) >= 3 else f"{x}x{x}x{x}"))
x = df["BLOCK_LABEL"]

#graphique
plt.figure(figsize=(14, 8))

plt.plot(x, df["CORE_L1_MISSES"], 'o-', label="L1 Misses (Core)", color="red")
plt.plot(x, df["CORE_LLC_MISSES"], '*-', label="LLC Misses (Core)", color="orange")
plt.plot(x, df["CORE_CACHE_MISSES"], '+-', label="Cache Misses (Core)", color="purple")
#plt.plot(x, df["ATOM_CACHE_MISSES"], 'o--', label="Cache Misses (Atom)", color="pink")

plt.xticks(rotation=45)
plt.xlabel("Block size (i x j x k)")
plt.ylabel("Nombre de cache misses")
plt.title("Analyse des Cache Misses selon les tailles de blocs")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
#plt.yscale("log")

plt.savefig("../figures/cache_misses_by_block.png")
plt.show()
