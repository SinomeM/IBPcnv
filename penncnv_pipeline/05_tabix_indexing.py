#!/usr/bin/python

import sys
import time
from joblib import Parallel, delayed
import re
import os
import glob

print ('File to process:', str(sys.argv))

path_files=sys.argv[1]
path_out=sys.argv[2]

print(sys.argv[0])
print(sys.argv[1])
print(sys.argv[2])
print(sys.argv[3])
os.chdir(path_out)
def dataFilter(file):
    
    #os.chdir('/path/to/singhularity') # where the singularity image is
    file2= re.sub('.gz','', file)
    os.system('cp '+ path_files + file + ' '+path_out+ file) 
    os.system ('gzip -d '+path_out+ file)
    os.system('dos2unix '+path_out+ file2)
    os.system('tail -n +12 '+ path_out + file2+ " | awk '{ print $2,$9,$10 }'  OFS='\t' > "+path_out+"temp1GC_"+ file2)
    os.system('{ echo -e "Name\tSample.Log R Ratio\tSample.B Allele Freq";} >' + path_out+'temp_names')
    os.system(' cat '+path_out+'temp_names '+path_out+'temp1GC_'+file2+'  > '+path_out +'temp2GC_'+file2)
    os.system('singularity exec penncnv.simg genomic_wave.pl -adjust --gcmodelfile GSA.gcmodel '+path_out+'temp2GC_'+file2)
    os.system('tail -n +2 '+path_out+'temp2GC_'+file2+'.adjusted | cut -f2 > '+ path_out+'temp3GC_'+file2)
    os.system('tail -n +12 '+ path_out + file2+ " | awk '{ print $3,$4,$4,$9,$10,$2 }'  OFS='\t' > "+path_out+"temp1b_"+ file2)
    os.system('paste '+path_out+"temp1b_"+ file2+ ' ' +path_out+'temp3GC_'+file2+' >'+path_out+'temp1c_'+ file2)
    os.system("awk '{ print $1,$2,$3,$4,$7,$5,$6 }'  OFS='\t' "+path_out+'temp1c_'+ file2+"> "+path_out+"temp1_"+ file2)
    os.system("awk -F ' ' '{ $1 = ($1 =="+'"X"'+ " ? 23 : $1) } 1' OFS='\t' "+ path_out+"temp1_"+file2 + "| awk -F '\t' '{ $1 = ($1 == "+ '"Y" '+ "? 24 : $1) } 1' OFS='\t' | awk -F '\t' '{ $1 = ($1 == "+'"XY" '+"? 25 : $1) } 1' OFS='\t'  |awk -F '\t' '{ $1 = ($1 =="+'"MT"'+ " ? 26 : $1) } 1' OFS='\t' > "+ path_out+"temp2_"+file2 )
    os.system('sort -nk1 -nk2 '+ path_out+'temp2_'+file2+ ' > '+path_out+'temp3_'+ file2)
    os.system('cp '+path_out+'temp3_'+file2+ ' '+ path_out + file2)
    os.system('bgzip '+path_out+file2)
    os.system('tabix -f -p bed '+path_out + file2 + '.gz' )
    os.system('rm -R '+path_out+'temp1GC_'+file2)
    os.system('rm -R '+path_out+'temp_names'+file2)
    os.system('rm -R '+path_out+'temp2GC_'+file2)
    os.system('rm -R '+path_out+'temp2GC_'+file2+ '.adjusted')
    os.system('rm -R '+path_out+'temp3GC_'+file2)
    os.system('rm -R '+path_out+'temp1b_'+file2)
    os.system('rm -R '+path_out+'temp1c_'+file2)
    os.system('rm -R '+path_out+'temp1_'+file2)
    os.system('rm -R '+path_out+'temp2_'+file2)
    os.system('rm -R '+path_out+'temp3_'+file2)
    print(" Saving file at " + path_out  + file2)
    print(time.time() - t)  



t = time.time()
dataFilter(sys.argv[3])

print(time.time() - t)  

#### trash

