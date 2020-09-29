import FlowStakingHelper from 0x045a1763c93006ca

transaction (role: UInt8, key: String, address: String) {
    let node: AuthAccount
    let linkPath: Path

    prepare(node: AuthAccount) {
        self.node = node;

        let storagePath = FlowStakingHelper.storageNodeInfoPath
        self.linkPath = FlowStakingHelper.publicNodeInfoPath

        let nodeInfo <- FlowStakingHelper.createNewOperatorInfo(role: role, networkingKey: key, networkingAddress: address)
        
        /// Clear previously stored object
        if let oldInfo <- node.load<@FlowStakingHelper.OperatorInfo>(from: storagePath){
            destroy oldInfo
        }
        node.save(<-nodeInfo, to: storagePath)
        node.link<&FlowStakingHelper.OperatorInfo>(self.linkPath, target: storagePath)
    }

    post {
        self.node
            .getCapability(self.linkPath)!
            .check<&FlowStakingHelper.OperatorInfo>():
            "Opeartor info capability was not created properly"
    }
}