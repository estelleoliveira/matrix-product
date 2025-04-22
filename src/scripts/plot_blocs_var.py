import matplotlib.pyplot as plt

# on charge les données depuis le fichier
blocsize = []
times = []
speedups = []

with open('../results/blocs_var.txt', 'r') as f:
    for line in f:
        data = line.split()
        blocsize.append(data[0])
        times.append(float(data[1]))
        speedups.append(float(data[2]))

#etiquette
block_labels = []
for b in blocsize:
    block_labels.append(f"{b[:2]}×{b[2:]}")

#figure pour le temps 
plt.figure(figsize=(10, 6))
plt.plot(blocsize, times, label='Time (s)', color='blue', marker='o')

plt.xticks(range(len(times)), block_labels, rotation=90) 
plt.xlabel('Blocsize')
plt.ylabel('Value')
plt.title('Matrix Product Performance: Time')
plt.legend()

plt.show()

#figure pour le speedup
plt.figure(figsize=(10, 6))
plt.plot(blocsize, speedups, label='Speedup', color='red', marker='x')

plt.xticks(range(len(times)), block_labels, rotation=90) 
plt.xlabel('Block size')
plt.ylabel('Value')
plt.title('Matrix Product Performance: Speedup')
plt.legend()

plt.show()