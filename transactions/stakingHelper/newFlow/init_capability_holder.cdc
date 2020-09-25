import FlowStakingHelper from 0x045a1763c93006ca

transaction {
    let signer: AuthAccount
    let linkPath: Path
    let ownerPath: Path

    prepare(signer: AuthAccount){
        self.signer = signer
        
        self.linkPath = FlowStakingHelper.HolderPublicPath
        self.ownerPath = FlowStakingHelper.HolderOwnerPath      
        let storagePath = FlowStakingHelper.HolderStoragePath

        let capabilityHolder <- FlowStakingHelper.createCapabilityHolder()

        /// clear old capability holder object in storage
        /// ONLY FOR TESTING. NOT FOR PRODUCTION ENVIRONMENT! 
        if let oldHolder <- self.signer.load<@FlowStakingHelper.CapabilityHolder>(from: storagePath) {
            destroy oldHolder
        }
        
        self.signer.save(<-capabilityHolder, to: storagePath)

        /// Create public capability to CapabilityHolder restricted by CapabilityReceiver interface
        self.signer.link<&{FlowStakingHelper.CapabilityReceiver}>(self.linkPath, target: storagePath)        
        /// Create private capability to CapabilityHolder restricted by Owner interface
        self.signer.link<&{FlowStakingHelper.Owner}>(self.ownerPath, target: storagePath)
    }

    post {
        self.signer
            .getCapability(self.linkPath)!
            .check<&{FlowStakingHelper.CapabilityReceiver}>():
            "Public CapabilityHolder reference was not created correctly"

        self.signer
            .getCapability(self.ownerPath)!
            .check<&{FlowStakingHelper.Owner}>():
            "Private CapabilityHolder reference was not created correctly"
    }
}