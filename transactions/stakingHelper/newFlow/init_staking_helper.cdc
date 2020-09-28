import FungibleToken from 0xee82856bf20e2aa6
import FlowIDTableStaking from 0x01cf0e2f2f715450
import FlowStakingHelper from 0x179b6b1cb6755e31

transaction(stakingKey: String, awardReceiver: Address, nodeOperator: Address) {

    let staker: AuthAccount
    let node: PublicAccount

    let capabilityHolder: &FlowStakingHelper.CapabilityHolder
    let nodeCapabilityHolder: &{FlowStakingHelper.CapabilityReceiver}
    
    let holderPath: Path
    let holderStoragePath: Path

    let flowReceiverPath: Path
    let linkStakingHelper: Path
    let linkNodeHelper: Path
    let storageStakingHelper: Path

    prepare(staker: AuthAccount) {
        self.staker = staker
        self.node = getAccount(nodeOperator)

        self.holderPath = FlowStakingHelper.HolderPublicPath
        self.holderStoragePath = FlowStakingHelper.HolderStoragePath

        self.storageStakingHelper = FlowStakingHelper.HelperStoragePath
        self.linkStakingHelper = FlowStakingHelper.HelperLinkPath
        self.linkNodeHelper = FlowStakingHelper.HelperNodeLinkPath
        self.flowReceiverPath = /public/flowTokenReceiver


        self.capabilityHolder = staker.borrow<&FlowStakingHelper.CapabilityHolder>(from: self.holderStoragePath)!
        self.nodeCapabilityHolder = self.node.getCapability(self.holderPath)!
                                        .borrow<&{FlowStakingHelper.CapabilityReceiver}>()!
    }

    execute {
         
        let newAccount = AuthAccount(payer: self.staker)
        let stakerAwardVaultCapability = getAccount(awardReceiver).getCapability(self.flowReceiverPath)!

        // Create new StakingHelper object
        let helper <- FlowStakingHelper.createHelper(stakingKey: stakingKey, stakerAwardVaultCapability: stakerAwardVaultCapability)
         
        // Save newly created StakingHelper into newAccount storage
        newAccount.save<@FlowStakingHelper.StakingHelper>(<- helper, to: self.storageStakingHelper)
        newAccount.link<&FlowStakingHelper.StakingHelper>(self.linkStakingHelper, target: self.storageStakingHelper)
        newAccount.link<&{FlowStakingHelper.NodeHelper}>(self.linkNodeHelper, target: self.storageStakingHelper)    
        
        let stakerCapability = newAccount.getCapability(self.linkStakingHelper)!
        let nodeCapability = newAccount.getCapability(self.linkNodeHelper)!
        
        self.capabilityHolder.storeCapability(stakerCapability, key: nodeOperator)
        
         
        /// Create new restricted capability and store it into Node Operator CapabilityHolder 
        let ownerRef = self.staker
                            .getCapability(FlowStakingHelper.HolderOwnerPath)!
                            .borrow<&{FlowStakingHelper.Owner}>()!
        self.nodeCapabilityHolder.depositCapability(nodeCapability, depositor: ownerRef)
        
    }
}