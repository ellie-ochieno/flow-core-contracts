import FlowIDTableStaking from 0xIDENTITYTABLEADDRESS

// This script returns the balance of staked tokens of a delegator

pub fun main(nodeID: String, delegatorID: UInt32): UFix64 {
    return FlowIDTableStaking.getDelegatorStakedBalance(nodeID: nodeID, delegatorID: delegatorID)!
}