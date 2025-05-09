import math
import numpy as np

def C(x):
    return 1 / math.sqrt(2) if x==0 else 1

# X = matrix = np.tile(np.arange(8), (8, 1))
# X *= 10
X = np.array([
    [212, 250, 245, 242, 240, 238, 235, 231],
    [214, 250, 246, 244, 243, 243, 239, 237],
    [213, 252, 251, 249, 249, 248, 236, 246],
    [215, 255, 254, 254, 253, 251, 251, 250],
    [215, 256, 254, 254, 253, 253, 252, 251],
    [215, 256, 254, 254, 254, 254, 252, 251],
    [216, 257, 256, 253, 254, 254, 251, 250],
    [216, 257, 256, 253, 254, 253, 251, 250]
])
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

QT = np.array([
    [16, 11, 10, 16, 24, 40, 51, 61,],
    [12, 12, 14, 19, 26, 58, 60, 55,],
    [14, 13, 16, 24, 40, 57, 69, 56,],
    [14, 17, 22, 29, 51, 87, 80, 62,],
    [18, 22, 37, 56, 68, 109, 103, 77,],
    [24, 35, 55, 64, 81, 104, 113, 92,],
    [49, 64, 78, 87, 103, 121, 120, 101,],
    [72, 92, 95, 98, 112, 100, 103, 99]
])
np.set_printoptions(suppress=True, precision=2)
# Y1Rounded = np.round(Y1, 2)
print("Input matrix X:")
print(X)
print("\X^T:")
print(X.T)
print("CX^T:")
print(np.round(np.dot(C, X.T), 2))
print("(CX^T)^T:")
print(np.round(np.dot(C, X.T).T, 2))
print("C((CX^T)^T)")
print(np.round(np.dot(C, np.dot(C, X.T).T), 2))
print("quant")
print(np.round(np.dot(C, np.dot(C, X.T).T), 2)/QT)
# print("Ture is:")
# print(Y0Rounded)
