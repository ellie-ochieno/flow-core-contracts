import FlowIDTableStaking from 0xIDENTITYTABLEADDRESS

// This script returns the balance of staked tokens of a node

pub fun main(nodeID: String): UFix64 {
<<<<<<< HEAD
    return FlowIDTableStaking.getNodeCommittedBalance(nodeID)!
=======
    let nodeInfo = FlowIDTableStaking.NodeInfo(nodeID: nodeID)
    return nodeInfo.tokensCommitted
>>>>>>> struct
}