import matplotlib.pyplot as plt

# on charge les données depuis le fichier
matrix_sizes = []
times = []
speedups = []

with open('../results/size_var.txt', 'r') as f:
    for line in f:
        data = line.split()
        matrix_sizes.append(int(data[0]))
        times.append(float(data[1]))
        speedups.append(float(data[2]))

#figure pour le temps 
plt.figure(figsize=(10, 6))
plt.plot(matrix_sizes, times, label='Time (s)', color='blue', marker='o')

plt.xlabel('Matrix size')
plt.ylabel('Value')
plt.title('Matrix Product Performance: Time')
plt.legend()

plt.show()

#figure pour le speedup
plt.figure(figsize=(10, 6))
plt.plot(matrix_sizes, speedups, label='Speedup', color='red', marker='x')

plt.xlabel('Matrix size')
plt.ylabel('Value')
plt.title('Matrix Product Performance: Speedup')
plt.legend()

plt.show()