#! /usr/local/bin/gawk -f
# Parse result files into csv format.
#
# Sample command to parse one result file:
#   ./parse-result.awk azure/results/azure-blob-nfs-dbench-default-output.txt
#
# Sample command to parse all the result file:
#   ./parse-result.awk */results/*-output.txt > results.csv

# Print header line.
BEGIN { FS= "[: ,/=]+" ; print "file name,storage class,capacity (GiB),average random read latency (ms),average random write latency (ms),random read IOPS,random write IOPS,random read BW (MiB/s),random write BW (MiB/s),sequential read BW (MiB/s),sequential write BW(MiB/s),mixed random read IOPS,mixed random write IOPS" }

/storageClassName:/ { printf "%s,%s,",FILENAME,$3 }
/storage:.*Gi/ { printf "%d,",$3 }
/storage:.*Ti/ { printf "%d,",$3*1024 }

# Print read/write latency.
/ lat \(usec\):/ { printf "%s,",$9/1000}
/ lat \(msec\):/ { printf "%s,",$9}

/^Random Read\/Write IOPS:/ { printf "%s,%s,%d,%d,",$5,$6,$8,$10}
/^Sequential Read\/Write:/ { printf "%d,%d,",$4,$6}
/^Mixed Random Read\/Write IOPS:/ { printf "%s,%s\n",$6,$7}

ENDFILE { print "\n" }