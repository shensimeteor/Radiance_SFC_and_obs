import numpy as np
from sys import argv
from glob import glob
import csv
from collections import defaultdict
import os.path

narg=len(argv)
if(narg <=2 ):
    print("Error: should provide 2 parameter (dir of error files;  output_dir)")
    exit(-1)
dir_input=argv[1]
dir_output=argv[2]

error_files = glob(dir_input + "/*.txt")

nfile=len(error_files)
dct_content=defaultdict(list)

dlt=csv.excel
dlt.skipinitialspace = True
get_title=0
for ifile in range(nfile):
    filex=error_files[ifile]
    file_base = os.path.basename(filex)
    lst = file_base.split('_')
    file_date = lst[0]
    with open(filex, "r") as f:
        reader = csv.reader(f, dialect=dlt)
        icount=0
        for (icount,row) in enumerate(reader):
            if(get_title == 0):
                print(type(row))
                row.insert(0, "datetime")
                titlex=','.join(row)
                get_title = 1
            else:
                if(icount == 0):
                    continue
                sid = row[0]
                row.insert(0, file_date)
                linex=','.join(row)
                dct_content[sid].append(linex)

#output
for sid in sorted(dct_content.keys()):
    station_file = dir_output+"/station_" + sid + ".csv"
    with open(station_file, "a") as f:
        f.write(titlex+"\n");
        for line in dct_content[sid]:
            f.write(line+"\n");

