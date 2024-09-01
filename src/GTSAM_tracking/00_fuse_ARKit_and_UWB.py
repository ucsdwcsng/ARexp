import gtsam
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd

def match_indices_and_values_3D(arr1, arr2, arr1_1, arr2_1):
   def closest_point(point, points):
      return np.linalg.norm(points - point, axis=1).argmin()

   if arr1.shape[0] <= arr2.shape[0]:
      smaller_array = arr1
      larger_array = arr2

      smaller_array1 = arr1_1
      larger_array1 = arr2_1
      switched = False
   else:
      smaller_array = arr2
      larger_array = arr1

      smaller_array1 = arr2_1
      larger_array1 = arr1_1
      switched = True

   matched_values = []
   matched_values1 = []
   for point in smaller_array:
      closest_index = closest_point(point, larger_array)
      matched_values.append(larger_array[closest_index])
      matched_values1.append(larger_array1[closest_index])

   matched_values = np.array(matched_values)
   matched_values1 = np.array(matched_values1)

   return switched, smaller_array, matched_values, smaller_array1, matched_values1

def bot(key):
   key = int(key)
   try:
      return gtsam.symbol(ord('x'), key)
   except:
      return gtsam.symbol('x', key)

def vector3(x, y, z):
   return np.array([x, y, z], dtype=float)

# Load the data from files
case_num = int(input('Input the index of the case number: '))
cases_df = pd.read_csv("input/cases.csv")

if not os.path.exists('output'):
   os.makedirs('output')
dir_case = f'output/case{case_num}'
if not os.path.exists(dir_case):
   os.makedirs(dir_case)

case_data = cases_df.iloc[case_num]
brightness = case_data['Brightness']
data_dir = f"input/case{case_num}"
envs = [el for el in os.listdir(data_dir) if el != "uwb"]

gnd_locs = {}
arkit_locs = {}

# Load ground truth and arkit location data for the specified case
gnd_locs = np.genfromtxt(os.path.join(data_dir, "resampled_truth.csv"), delimiter=",", skip_header=1)[:, 1:]
arkit_locs = np.genfromtxt(os.path.join(data_dir, "resampled_arkit.csv"), delimiter=",", skip_header=1)[:, 4:]

# Load UWB data from the same case-specific directory
gnd_uwb_locs = np.genfromtxt(os.path.join(data_dir, "resampled_uwb_truth.csv"), delimiter=",", skip_header=1)[:, 1:]
uwb_locs = np.genfromtxt(os.path.join(data_dir, "resampled_uwb.csv"), delimiter=",", skip_header=1)

# for each env match the uwb and arkit data based on the ground truth values
matched_arkit_locs = {}
matched_uwb_locs = {}
matched_gnd_uwb_locs = {}
matched_gnd_arkit_locs = {}
for env in envs:
   switched, arr1, arr2, arr3, arr4 = match_indices_and_values_3D(gnd_locs, gnd_uwb_locs, arkit_locs, uwb_locs)
   if switched:
      matched_arkit_locs[env] = arr4
      matched_uwb_locs[env] = arr3

      matched_gnd_arkit_locs[env] = arr2
      matched_gnd_uwb_locs[env] = arr1
   else:
      matched_arkit_locs[env] = arr3
      matched_uwb_locs[env] = arr4

      matched_gnd_arkit_locs[env] = arr1
      matched_gnd_uwb_locs[env] = arr2
   print(switched)

# Setup and optimize the graph
plt.close('all')
use_gnd = False # only for sanity check
robust = False # use robust cost function
noise_dict = {
   200: {'sigma_vio': 0.05, 'sigma_uwb': 0.2},
   7: {'sigma_vio': 0.1, 'sigma_uwb': 0.05},
   0: {'sigma_vio': 0.1, 'sigma_uwb': 0.05},
   'blink': {'sigma_vio': 0.1, 'sigma_uwb': 0.05}
}

# Print brightness value for debugging
print(f"Brightness value: {brightness}")

# Convert brightness to int if necessary
try:
   brightness = int(brightness)
except ValueError:
   pass

# Determine the noise parameters based on the brightness level
if brightness in noise_dict:
   noise = noise_dict[brightness]
else:
   # Set default noise parameters if brightness level is unsupported
   noise = {'sigma_vio': 0.1, 'sigma_uwb': 0.1}
   print(f"Unsupported brightness level {brightness}. Using default noise parameters.")

print(f"Noise parameters: {noise}")

NOISE_VIO = gtsam.noiseModel.Diagonal.Sigmas(vector3(noise['sigma_vio'], # translation in X
                                                     noise['sigma_vio'], # translation in Y
                                                     noise['sigma_vio'])) # translation in Z
NOISE_UWB = gtsam.noiseModel.Diagonal.Sigmas(vector3(noise['sigma_uwb'],
                                                     noise['sigma_uwb'],
                                                     noise['sigma_uwb']))

if robust:
   base = gtsam.noiseModel.mEstimator.Huber(1.345)
   NOISE_VIO = gtsam.noiseModel.Robust(base, NOISE_VIO)
   NOISE_UWB = gtsam.noiseModel.Robust(base, NOISE_UWB)

# Create a factor graph
graph = gtsam.NonlinearFactorGraph()

# Add unary factors for VIO measurements
for i in range(len(matched_gnd_arkit_locs[env])):
   if use_gnd:
      graph.add(gtsam.PriorFactorPoint3(bot(i), gtsam.Point3(matched_gnd_arkit_locs[env][i]), NOISE_VIO))
   else:
      graph.add(gtsam.PriorFactorPoint3(bot(i), gtsam.Point3(matched_arkit_locs[env][i]), NOISE_VIO))

# Add unary factors for UWB measurements
for i in range(len(matched_gnd_uwb_locs[env])):
   if use_gnd:
      graph.add(gtsam.PriorFactorPoint3(bot(i), gtsam.Point3(matched_gnd_uwb_locs[env][i]), NOISE_UWB))
   else:
      graph.add(gtsam.PriorFactorPoint3(bot(i), gtsam.Point3(matched_uwb_locs[env][i]), NOISE_UWB))

# Create initial estimates
initial_estimate = gtsam.Values()
for i in range(len(matched_gnd_arkit_locs[env])):
   if use_gnd:
      initial_estimate.insert(bot(i), gtsam.Point3(matched_gnd_arkit_locs[env][i]))
   else:
      initial_estimate.insert(bot(i), gtsam.Point3(matched_arkit_locs[env][i]))

# Create the optimizer
params = gtsam.LevenbergMarquardtParams()
params.setVerbosityLM('trylambda')
optimizer = gtsam.LevenbergMarquardtOptimizer(graph, initial_estimate, params)
result = optimizer.optimize()

optimized_estimate = []

for i in range(len(matched_gnd_arkit_locs[env])):
   optimized_estimate.append(result.atPoint3(bot(i)))

optimized_estimate = np.array(optimized_estimate)

# Plot the CDF of errors of arkit, uwb, optimized, and gnd arkit locs
plt.figure()
plt.hist(np.linalg.norm(matched_gnd_arkit_locs[env] - matched_arkit_locs[env], axis=1),
         bins=100, density=True, cumulative=True, histtype='step', label='arkit')
plt.hist(np.linalg.norm(matched_gnd_arkit_locs[env] - optimized_estimate, axis=1),
         bins=100, density=True, cumulative=True, histtype='step', label='optimized')
plt.hist(np.linalg.norm(matched_gnd_arkit_locs[env] - matched_uwb_locs[env], axis=1),
         bins=100, density=True, cumulative=True, histtype='step', label='uwb')
plt.legend()
plt.title(env)
plt.xlabel('Error (m)')
plt.ylabel('CDF')
plt.grid()
plt.savefig(f'output/case{case_num}/error_cdf.png')

# Save the errors from the CDF Plots to a csv file
df = pd.DataFrame({'arkit': np.linalg.norm(matched_gnd_arkit_locs[env] - matched_arkit_locs[env], axis=1),
                   'optimized': np.linalg.norm(matched_gnd_arkit_locs[env] - optimized_estimate, axis=1),
                   'uwb': np.linalg.norm(matched_gnd_arkit_locs[env] - matched_uwb_locs[env], axis=1)})

df.to_csv(f'output/case{case_num}/error_timeline.csv', index=False)

# Plot the original, optimized and gnd arkit locs as time series in subplots
if True:
   # plt.close('all')
   plt.figure()
   plt.suptitle(env)
   plt.subplot(311)
   plt.plot(matched_gnd_arkit_locs[env][:, 0], label="gnd_arkit_x")
   plt.plot(optimized_estimate[:, 0], label="optimized_arkit_x")
   plt.plot(matched_arkit_locs[env][:, 0], label="pred_arkit_x")
   plt.plot(matched_uwb_locs[env][:, 0], label="pred_uwb_x")
   plt.legend()

   plt.subplot(312)
   plt.plot(matched_gnd_arkit_locs[env][:, 1], label="gnd_arkit_y")
   plt.plot(optimized_estimate[:, 1], label="optimized_arkit_y")
   plt.plot(matched_arkit_locs[env][:, 1], label="pred_arkit_y")
   plt.plot(matched_uwb_locs[env][:, 1], label="pred_uwb_y")
   plt.legend()

   plt.subplot(313)
   plt.plot(matched_gnd_arkit_locs[env][:, 2], label="gnd_arkit_z")
   plt.plot(optimized_estimate[:, 2], label="optimized_arkit_z")
   plt.plot(matched_arkit_locs[env][:, 2], label="pred_arkit_z")
   plt.plot(matched_uwb_locs[env][:, 2], label="pred_uwb_z")
   plt.legend()
   
   plt.savefig(f'output/case{case_num}/error_timeline.png')
   plt.show()
