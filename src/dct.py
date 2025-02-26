import math
import numpy as np

def C(x):
    return 1 / math.sqrt(2) if x==0 else 1

X = np.array([[0, 2, 4, 6, 7, 5, 3, 1] for _ in range(8)])

def compute_Y(u, v):
    sum_result = 0
    for i in range(8):
        for j in range(8):
            sum_result += X[i, j] * math.cos((2 * i + 1) * u * math.pi / 16) * math.cos((2 * j + 1) * v * math.pi / 16)
    return (1 / 4) * C(u) * C(v) * sum_result

Y0 = np.zeros((8, 8))
for u in range(8):
    for v in range(8):
        Y0[u, v] = compute_Y(u, v)
Y0Rounded = np.round(Y0, 2)

pi = np.pi

a = 0.5 * np.cos(4 * pi / 16)
b = 0.5 * np.cos(1 * pi / 16)
c = 0.5 * np.cos(2 * pi / 16)
d = 0.5 * np.cos(3 * pi / 16)
e = 0.5 * np.cos(4 * pi / 16)
f = 0.5 * np.cos(5 * pi / 16)
g = 0.5 * np.cos(6 * pi / 16)

C = np.array([
    [a, a, a, a, a, a, a, a],
    [b, d, e, g, -g, -e, -d, -b],
    [c, f, -f, -c, -c, -f, f, c],
    [d, -g, -b, -e, e, b, g, -d],
    [a, -a, -a, a, a, -a, -a, a],
    [e, -b, g, d, -d, -g, b, -e],
    [f, -c, c, -f, -f, c, -c, f],
    [g, -e, d, -b, b, -d, e, -g]
])

Y1 =np.dot(C, X.T).T
Y1Rounded = np.round(Y1, 2)
print("Input matrix X:")
print(X)
print("\noutput matrix Y:")
print(Y0Rounded)
print(Y1Rounded)