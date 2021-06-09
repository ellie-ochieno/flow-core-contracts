import FlowEpochClusterQC from 0xQCADDRESS

pub fun main(clusterIndex: UInt16): {String: UInt64} {

    let clusters = FlowEpochClusterQC.getClusters()

    return clusters[clusterIndex].nodeWeights

}