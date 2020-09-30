import FungibleToken from 0xee82856bf20e2aa6
import FlowStakingHelper from 0x179b6b1cb6755e31

transaction(stakingKey:String, nodeId: String, stakeAmount: UFix64, nodeOperatorAddress: Address) {
    let staker: AuthAccount
    let nodeOperator: PublicAccount

    prepare(staker: AuthAccount){
        self.staker = staker
        self.nodeOperator = getAccount(nodeOperatorAddress)

    /// -----------------------------------------------------------------------------------------------------------
    /// 1. Create CapabilityHolder for Token Holder account
    /// -----------------------------------------------------------------------------------------------------------
        let storagePath = FlowStakingHelper.storageCapabilityHolder
        let ownerLinkPath = FlowStakingHelper.privateHolderOwner

        /// Create new CapabilityHolder
        let capabilityHolder <- FlowStakingHelper.createCapabilityHolder()

        /// Clear previously stored object
        if let oldHolder <- self.staker.load<@FlowStakingHelper.CapabilityHolder>(from: storagePath){
            destroy oldHolder
        }
        self.staker.save(<-capabilityHolder, to: storagePath)
        self.staker.link<&{FlowStakingHelper.Owner}>(ownerLinkPath, target: storagePath)

    /// -----------------------------------------------------------------------------------------------------------
    /// 2. Create new StakingHelper
    /// -----------------------------------------------------------------------------------------------------------
        let tokenReceiverPath = /public/flowTokenReceiver
        let rewardVaultCapability = self.staker.getCapability(tokenReceiverPath)!

        /// Get node info from nodeOperator public capability
        let publicNodeInfoPath = FlowStakingHelper.publicNodeInfoPath
        let nodeInfo =  self.nodeOperator
                        .getCapability(publicNodeInfoPath)!
                        .borrow<&FlowStakingHelper.OperatorInfo>()!
                        .getNodeInfo()

        let tokenVaultReference = self.staker.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)!
        let tokensCommitted <- tokenVaultReference.withdraw(amount:stakeAmount) 
        
        // Create new StakingHelper
        let stakingHelper <- FlowStakingHelper.createStakingHelper(
                stakingKey: stakingKey, 
                rewardVaultCapability: rewardVaultCapability, 
                nodeInfo: nodeInfo,
                id: nodeId,
                tokensCommitted: <- tokensCommitted
            )

    /// -----------------------------------------------------------------------------------------------------------
    /// 3. Save capabilities to respected accounts
    /// -----------------------------------------------------------------------------------------------------------

        /// Prepare paths that will be used to store StakingHelper and create capabilities to it
        let storageStakingHelper = FlowStakingHelper.storageStakingHelper
        let linkStakingHelper = FlowStakingHelper.linkStakingHelper
        let linkNodeHelper = FlowStakingHelper.linkNodeHelper

        /// Save StakingHelper into newly created account and distribute capabilities to Token Holder and Node Operator
        let newAccount = AuthAccount(payer: self.staker)
        newAccount.save(<-stakingHelper, to: storageStakingHelper)
        newAccount.link<&FlowStakingHelper.StakingHelper>(linkStakingHelper, target: storageStakingHelper)
        newAccount.link<&{FlowStakingHelper.NodeHelper}>(linkNodeHelper, target: storageStakingHelper) 

        let stakerCapability = newAccount.getCapability(linkStakingHelper)!
        let nodeCapability = newAccount.getCapability(linkNodeHelper)!

        // Store capability inside CapabilityHolder owned by Token Holder
        let stakerCapabilityHolder = self.staker.borrow<&FlowStakingHelper.CapabilityHolder>(from: storagePath)!
        stakerCapabilityHolder.storeCapability(stakerCapability, key: nodeOperatorAddress)

         
        // Deposit capability into CapabilityHolder owned by Node Operator
        let stakerCapabilityOwner = self.staker
                                .getCapability(ownerLinkPath)!
                                .borrow<&{FlowStakingHelper.Owner}>()!
        log(stakerCapabilityOwner)
         
        let receiverPath = FlowStakingHelper.publicCapabilityReceiver
        let nodeCapabilityHolder = self.nodeOperator.getCapability(receiverPath)!
                                       .borrow<&{FlowStakingHelper.CapabilityReceiver}>()!
        
        nodeCapabilityHolder.depositCapability(nodeCapability, depositor: stakerCapabilityOwner)
    }
} 