import FlowStakingHelper from 0x179b6b1cb6755e31

transaction {
    let node: AuthAccount
    let linkPath: Path

    prepare(node: AuthAccount){
        self.node = node

        let storagePath = FlowStakingHelper.storageCapabilityHolder
        let publicPath = FlowStakingHelper.publicCapabilityReceiver
        let privatePath = FlowStakingHelper.privateHolderOwner

        let capabilityHolder <- FlowStakingHelper.createCapabilityHolder()

        if let oldHolder <- self.node.load<@FlowStakingHelper.CapabilityHolder>(from: storagePath) {
            destroy oldHolder
        }

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