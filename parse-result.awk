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

# Random Read/Write IOPS: 888/27. BW: 123MiB/s / 7328KiB/s
/^Random Read\/Write IOPS:/ {
    match($0, /^Random Read\/Write IOPS: ([0-9.]+)(k?)\/([0-9.]+)(k?). BW: ([0-9.]+)(.+)\/s \/ ([0-9.]+)(.+)\/s$/, arr)
        if(arr[2] == "k")
            arr[1] *= 1000
        if(arr[4] == "k")
            arr[3] *= 1000
        if(arr[6] == "KiB")
            arr[5] /= 1024
        else if(arr[6] == "TiB")
            arr[6] *= 1024
        if(arr[8] == "KiB")
            arr[7] /= 1024
        else if(arr[8] == "TiB")
            arr[7] *= 1024
        # print arr[1], arr[3], arr[5], arr[7]
        random_read_iops=arr[1]
        randome_write_iops=arr[3]
        random_read_bw=arr[5]
        random_write_bw=arr[7]
}

# Sequential Read/Write: 228MiB/s / 27.3MiB/s
/^Sequential Read\/Write:/ {
    match($0, /^Sequential Read\/Write: ([0-9.]+)(.+)\/s \/ ([0-9.]+)(.+)\/s$/, arr)
        if(arr[2] == "KiB")
            arr[1] /= 1024
        else if(arr[2] == "TiB")
            arr[1] *= 1024
        if(arr[4] == "KiB")
            arr[3] /= 1024
        else if(arr[4] == "TiB")
            arr[3] *= 1024
        sequential_read_bw=arr[1]
        sequential_write_bw=arr[3]
}

/^Mixed Random Read\/Write IOPS:/ {
    match($0, /^Mixed Random Read\/Write IOPS: ([0-9.]+)(k?)\/([0-9.]+)(k?)$/, arr)
        if(arr[2] == "k")
            arr[1] *= 1000
        if(arr[4] == "k")
            arr[3] *= 1000
        mixed_random_read_iops=arr[1]
        mixed_random_write_iops=arr[3]
        printf "%s,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
            FILENAME,
            storage_class,
            capacity,
            read_latency,write_latency,
            random_read_iops,randome_write_iops,
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

#ENDFILE {}