import FlowStakingHelper from 0x045a1763c93006ca

pub fun main(address: Address): FlowStakingHelper.Info {
    let account = getAccount(address);
    
    let linkPath = FlowStakingHelper.publicNodeInfoPath
    let infoCapability = account.getCapability(linkPath)!
    let operatorInfo = infoCapability.borrow<&FlowStakingHelper.OperatorInfo>()!

    return operatorInfo.getNodeInfo()
}