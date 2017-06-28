import numpy as np
from sys import argv
from glob import glob
import csv
from collections import defaultdict
'''
function: get every station's error metrics (Bias, RMSE, MAE, etc.)
usage:  python error_stats_summary.py <dir of error files (e.g. output_stats/GECHRAR/)> <output_stats_file>
'''

narg=len(argv)
if(narg <=2 ):
    print("Error: should provide 2 parameter (dir of error files;  output_stats_file)")
    exit(-1)
dir_input=argv[1]
output_stats=argv[2]

error_files = glob(dir_input + "/*.txt")
print(error_files)

nfile=len(error_files)
dct_error=defaultdict(list)
dct_model=defaultdict(list)
dct_obs=defaultdict(list)
dct_lon=dict([])
dct_lat=dict([])

dlt=csv.excel
dlt.skipinitialspace = True
for ifile in range(nfile):
    filex=error_files[ifile]
    with open(filex, "r") as f:
        reader = csv.DictReader(f, dialect=dlt)
        for row in reader:
            err = float(row['error_rad'])
            sid = row['stnid']
            if ( err > 9999 ): 
                continue
            if sid in dct_lon:
                if( abs(float(row['lons']) - dct_lon[sid]) > 0.01 or abs(float(row['lats']) - dct_lat[sid]) > 0.01 ):
                    print("Warn: stn lon/lat changed! %s in %s: (%7.2f,%7.2f) -> (%7.2f,%7.2f)" %(sid, filex, dct_lon[sid], dct_lat[sid], float(row['lons']),float(row['lats'])))
            else:
                dct_lon[sid] = float(row['lons'])
                dct_lat[sid] = float(row['lats'])
            dct_error[sid].append(float(row['error_rad']))
            dct_model[sid].append(float(row['wrf_rad']))
            dct_obs[sid].append(float(row['obs_rad']))

#write out
with open(output_stats,"w") as f:
    f.write("stnid, lons, lats, ns, bias, rmse, rmse_dbias, mae, corr \n")
    for sid in dct_error.keys():
        array_error=np.array(dct_error[sid])
        ns=len(array_error)
        bias=np.mean(array_error)
        rmse=np.sqrt(np.sum(np.square(array_error))/ns)
        mae=np.mean(np.abs(array_error))
        db_array_error = array_error - bias
        rmse_dbias=np.sqrt(np.sum(np.square(db_array_error))/ns)
        xmtrx=np.zeros((2,ns))
        xmtrx[0,:] = np.array(dct_model[sid])
        xmtrx[1,:] = np.array(dct_obs[sid])
        corrmxtr=np.corrcoef(xmtrx)
        corr=corrmxtr[0,1]
        f.write("%s, %f, %f, %d, %f, %f, %f, %f, %f\n" %(sid, dct_lon[sid], dct_lat[sid], ns, bias, rmse, rmse_dbias, mae, corr))

