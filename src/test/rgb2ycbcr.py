import math
import numpy as np

matrix = np.array([
    [0.299, 0.587, 0.144],
    [0.5, -0.419, -0.081],
    [-0.169, -0.331, 0.500]
]);

rgb = np.array([
    250,
    221,
    184
])

print(np.dot(matrix, rgb)+np.array([0, 128, 128]))
