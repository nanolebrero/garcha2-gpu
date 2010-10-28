&INT0 
 TITLE = 'NO3', 
 NATOM = 66
 NOPT = 0, 
 NORM = T, 
 ANG = T, 
 EX = T, 
 COUL = F, 
 SCF1 = T, 
 PROP = F, 
 FIELD = F, 
 SOL = F, 
 RESP1 = F/
  8        36.570000       66.519997       45.970001
  1       35.950001       66.370003       45.209999
  1       36.049999       66.630005       46.820000
  8        36.209999       73.330002       48.779999
  1       36.820000       73.629997       48.049999
  1       35.829998       72.440002       48.559998
  8        37.230000       71.550003       45.750000
  1       36.520000       71.430000       45.050003
  1       37.239998       70.760002       46.350002
  8        35.669998       70.729996       48.279999
  1       34.739998       70.479996       48.010002
  1       35.930000       70.229996       49.099998
  8        42.930000       68.610001       48.889999
  1       42.000000       68.540001       48.520004
  1       43.040001       69.500000       49.330002
  8        40.590000       70.209999       47.849998
  1       39.809998       69.899994       47.320000
  1       41.170002       70.790001       47.280003
  8        39.540001       70.199997       42.620003
  1       39.279999       71.160004       42.620003
  1       38.829998       69.660004       43.070000
  8        39.639999       66.770004       46.100002
  1       39.779999       65.930000       46.620003
  1       39.090000       67.410004       46.650002
  8        43.369999       69.510002       44.500000
  1       42.880001       68.639999       44.590000
  1       43.139999       69.940002       43.629997
  8        39.209999       65.619995       49.879997
  1       40.100002       65.169998       49.739998
  1       38.480000       64.970001       49.689999
  8        40.750000       73.870003       45.770000
  1       41.250000       73.010002       45.830002
  1       41.399998       74.639999       45.739998
  8        39.730000       73.709999       49.650002
  1       40.300003       73.060005       50.149998
  1       39.570000       73.379997       48.720001
  8        41.830002       67.379997       44.650002
  1       41.119999       67.110001       45.300003
  1       41.570000       67.099998       43.720001
  8        37.880001       71.500000       50.549999
  1       37.420002       72.320000       50.209999
  1       38.860001       71.690002       50.639999
  8        40.779999       70.959999       50.529999
  1       40.570000       70.520004       49.660000
  1       41.750000       71.220001       50.560001
  8        37.610001       68.959999       50.060001
  1       38.139999       68.470001       50.739998
  1       37.830002       69.940002       50.110001
  8        38.119999       73.870003       46.510002
  1       37.700001       73.010002       46.240002
  1       39.059998       73.900002       46.170002
  8        42.280003       71.540001       46.339996
  1       42.940002       72.279999       46.430000
  1       42.719997       70.750000       45.919998
  8        38.070000       68.440002       47.459999
  1       38.020000       68.430000       48.460003
  1       37.239998       68.029999       47.080002
  8        40.960003       68.739998       52.140003
  1       40.830002       69.669998       51.799999
  1       40.120003       68.220001       52.010002
  8        38.029999       68.260002       43.769997
  1       38.020000       67.790001       44.650002
  1       38.849998       67.979996       43.260002
  8        43.419998       71.529999       50.079998
  1       43.369999       72.349998       50.650002
  1       44.310001       71.500000       49.629997

gaussian
 8  15   6
 6 2 1 4 1 1
 0 0 0 1 1 2
   5222.9022000   -0.001936
    782.5399400   -0.014851
    177.2674300   -0.073319
     49.5166880   -0.245116
     15.6664400   -0.480285
      5.1793599   -0.335943
     10.6014410    0.078806
      0.9423170   -0.567695
      0.2774746    1.000000
     33.4241260    0.017560
      7.6221714    0.107630
      2.2382093    0.323526
      0.6867300    0.483223
      0.1938135    1.000000
      0.8000000    1.000000
 8 10 10
 1 1 1 1 1 1 1 1 1 1
 0 0 0 0 0 0 0 1 1 2
    628.6475400    1.000000
    143.9976180    1.000000
     40.0859040    1.000000
     11.9849376    1.000000
      1.4560475    1.000000
      4.7140760    1.000000
      0.4059979    1.000000
      4.7140760    1.000000
      0.4059979    1.000000
      1.0000000    1.000000
gaussian
 1   6   3
 4 1 1
 0 0 0
     50.9991780    0.0096604761
      7.4832181    0.073728860
      1.7774676    0.29585808
      0.5193295    0.71590532
      0.1541100    1.000000
      0.7500000    1.000000
 1 4 4
 1 1 1 1  1 1 1
 0 0 0 0  1 1 1
     45.0000000    1.000000
      7.5000000    1.000000
      0.3000000    1.000000
      1.5000000    1.000000
endbasis
&SCFINP
 OPEN = F,
 NMAX=300
 NCO = 110
 NUNP = 0, 
 ATRHO = F, 
 VCINP = F, 
 DIRECT = T, 
 EXTR = F, 
 SHFT = F, 
 SHI =  1., 
 IDAMP = 0, 
 GOLD =  5.,
 TOLD =  1.E-06,
 WRITE = F, 
 MEMO = T/
&EXCH 
 IEXCH=9
 INTEG = T, 
 DENS = T, 
 IGRID = 2,
 IGRID2 = 1/


