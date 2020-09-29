import FlowStakingHelper from 0x045a1763c93006ca

transaction {
    let node: AuthAccount
    let linkPath: Path

    prepare(node: AuthAccount){
        self.node = node

        let publicPath = FlowStakingHelper.publicCapabilityHolder
        let storagePath = FlowStakingHelper.storageCapabilityHolder
        let privatePath = FlowStakingHelper.privateCapabilityHolder

        let capabilityHolder <- FlowStakingHelper.createCapabilityHolder()
        self.node.save(<-capabilityHolder, to: storagePath)

        self.node.link<&{FlowStakingHelper.Owner}>(privatePath, target: storagePath)
        self.node.link<&{FlowStakingHelper.CapabilityReceiver}>(publicPath, target: storagePath)

        // store publicPath value to be accessible in post block
        self.linkPath = publicPath
    }

    post {
        self.node
            .getCapability(self.linkPath)!
            .check<&{FlowStakingHelper.CapabilityReceiver}>():
            "CapabilityReceiver capability was not created properly"
    }
}