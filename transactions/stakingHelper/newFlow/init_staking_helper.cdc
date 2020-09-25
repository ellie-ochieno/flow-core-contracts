import FungibleToken from 0xee82856bf20e2aa6
import FlowIDTableStaking from 0xe03daebed8ca0615
import FlowStakingHelper from 0x045a1763c93006ca

transaction(stakingKey: String, awardReceiver: Address, nodeId: String) {

    let staker: AuthAccount
    let capabilityHolder: &{FlowStakingHelper.CapabilityReceiver}
    
    let holderPath: Path
    let flowReceiverPath: Path
    let linkStakingHelper: Path
    let storageStakingHelper: Path

    prepare(staker: AuthAccount) {
        self.staker = staker

        self.holderPath = FlowStakingHelper.HolderPublicPath
        self.storageStakingHelper = FlowStakingHelper.HelperStoragePath
        self.linkStakingHelper = FlowStakingHelper.HelperLinkPath
        self.flowReceiverPath = /public/flowTokenReceiver

        self.capabilityHolder = staker.getCapability(self.holderPath)!
                                      .borrow<&{FlowStakingHelper.CapabilityReceiver}>()!
        
        // TODO: allow storing multiple StakingHelpers based on address of the node
    }

    execute {
        let newAccount = AuthAccount(payer: self.staker)
        let stakerAwardVaultCapability = getAccount(awardReceiver).getCapability(self.flowReceiverPath)!

        // Create new StakingHelper object
        let helper <- FlowStakingHelper.createHelper(stakingKey: stakingKey, stakerAwardVaultCapability: stakerAwardVaultCapability)
        
        // Save newly created StakingHelper into newAccount storage
        newAccount.save<@FlowStakingHelper.StakingHelper>(<- helper, to: self.storageStakingHelper)

        // Create capability to stored StakingHelper
        newAccount.link<&FlowStakingHelper.StakingHelper>(self.linkStakingHelper, target: self.storageStakingHelper)    
        let capability = newAccount.getCapability(self.linkStakingHelper)

        // clear storages before saving anything, remove after tests
        self.staker.load<Capability>(from: self.storageStakingHelper)
        self.staker.save(capability!, to: self.storageStakingHelper)   
    }
}