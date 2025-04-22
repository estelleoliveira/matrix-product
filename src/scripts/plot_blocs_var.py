import matplotlib.pyplot as plt

#on charge les données
block_sizes = []
times = []
speedups = []

with open('../results/blocs_var.txt', 'r') as f:
    for line in f:
        data = line.strip().split()
        if len(data) != 5:
            continue
        i, j, k, time, speedup = data
        block_sizes.append((i, j, k))
        times.append(float(time))
        speedups.append(float(speedup))

#création des étiquettes avec les 3 premières colonnes du fichier
block_labels = [f"{i}x{j}x{k}" for (i, j, k) in block_sizes]

# figure pour les temps
plt.figure(figsize=(12, 6))
plt.plot(block_labels, times, label='Time (s)', color='blue', marker='o')
plt.xticks(rotation=90)
plt.xlabel('Block size (ixjxk)')
plt.ylabel('Execution time (s)')
plt.title('Matrix Product Performance: Time')
plt.tight_layout()
plt.legend()
plt.grid(True)
plt.savefig("../figures/time_blocs_var.png")
plt.show()

# figure pour le speedup
plt.figure(figsize=(12, 6))
plt.plot(block_labels, speedups, label='Speedup', color='red', marker='x')
plt.xticks(rotation=90)
plt.xlabel('Block size (ixjxk)')
plt.ylabel('Speedup (x)')
plt.title('Matrix Product Performance: Speedup')
plt.tight_layout()
plt.legend()
plt.grid(True)
plt.savefig("../figures/speedup_blocs_var.png")
plt.show()