package splitters :: .versioner=disk .path="/exp/rwicks/ersatz/exp/inference" {}

global {
    grid="sge"
    location="coe"
    cpuActionFlags=""
    cpuResourceFlags="-l 'h_rt=100:0:0'"

    gpuActionFlags="-q gpu.q@@v100 -M rwicks@jhu.edu -m base"
    gpuResourceFlags="-l 'gpu=1,h_rt=500:0:0'"

    gpuLowActionFlags="-q gpu.q -M rwicks@jhu.edu -m base"
    gpuLowResourceFlags="-l 'gpu=1,h_rt=128:0:0'"

}

