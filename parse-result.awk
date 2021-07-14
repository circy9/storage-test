#! /usr/local/bin/gawk -f
# Parse result files into csv format.
#
# Sample command to parse one result file:
#   ./parse-result.awk azure/results/azure-blob-nfs-dbench-default-output.txt
#
# Sample command to parse all the result file:
#   ./parse-result.awk */results/*-output.txt > results.csv

# Print header line.
BEGIN {
    FS= "[: ,/=]+" ;
    print "file name,\
storage class,\
capacity (GiB),\
average random read latency (ms),\
average random write latency (ms),\
random read IOPS,\
random write IOPS,\
random read BW (MiB/s),\
random write BW (MiB/s),\
sequential read BW (MiB/s),\
sequential write BW(MiB/s),\
mixed random read IOPS,\
mixed random write IOPS"
}

# Extract storage class name.
/storageClassName:/ {
    storage_class = $3
}

# Extract storage capacity.
/storage:.*Gi/ {
    capacity = $3
}
/storage:.*Ti/ {
    capacity = $3*1024
}

# Extract read/write latency.
/read_latency:/ { section = "read_latency" }
/write_latency:/ { section = "write_latency" }
/ lat \(usec\):/ {
    if(section == "read_latency")
        read_latency = $9/1000
    else if(section == "write_latency")
        write_latency = $9/1000
}
/ lat \(msec\):/ {
    if(section == "read_latency")
        read_latency = $9
    else if(section == "write_latency")
        write_latency = $9
}

/^Random Read\/Write IOPS:/ {
    random_read_iops=$5
    random_write_iops=$6
    random_read_bw=$8
    random_write_bw=$10
}

/^Sequential Read\/Write:/ {
    sequential_read_bw=$4
    sequential_write_bw=$6
}

/^Mixed Random Read\/Write IOPS:/ {
    mixed_random_read_iops=$6
    mixed_random_write_iops=$7
}

{
    if(mixed_random_write_iops != "") {
        printf "%s,%s,%d,%s,%s,%s,%s,%d,%d,%d,%d,%s,%s\n",
            FILENAME,
            storage_class,
            capacity,
            read_latency,write_latency,
            random_read_iops,random_write_iops,
            random_read_bw,random_write_bw,
            sequential_read_bw,sequential_write_bw,
            mixed_random_read_iops,mixed_random_write_iops
        storage_class = ""
        capacity = ""
        read_latency = 0
        write_latency = 0
        random_read_iops = ""
        random_write_iops = ""
        random_read_bw = 0
        random_write_bw = 0
        sequential_read_bw = 0
        sequential_write_bw = 0
        mixed_random_read_iops = ""
        mixed_random_write_iops = ""
    }
}

#ENDFILE {}