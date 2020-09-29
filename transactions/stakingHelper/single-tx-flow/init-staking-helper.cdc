import FlowStakingHelper from 0x045a1763c93006ca

transaction(nodeOperator: Address) {
    let staker: AuthAccount
    let privatePath: Path

    prepare(staker: AuthAccount){
        self.staker = staker

        /// Create CapabilityHolder for Token Holder account
        let storagePath = FlowStakingHelper.storageCapabilityHolder
        let privatePath = FlowStakingHelper.privateCapabilityHolder

        let capabilityHolder <- FlowStakingHelper.createCapabilityHolder()

        /// Clear previously stored object
        if let oldHolder <- self.staker.load<@FlowStakingHelper.CapabilityHolder>(from: storagePath){
            destroy oldHolder
        }
        self.staker.save(<-capabilityHolder, to: storagePath)

        // Token Holder only needs Owner
        self.staker.link<&{FlowStakingHelper.Owner}>(privatePath, target: storagePath)

        /// store privatePath value to be accessible in post block
        self.privatePath = privatePath

        /// TODO: Implement creation of staking helper
    }

    post {
        self.staker
            .getCapability(self.privatePath)!
            .check<&{FlowStakingHelper.Owner}>():
            "CapabilityReceiver capability was not created properly"
    }
}