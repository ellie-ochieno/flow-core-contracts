import CapabilityTransfer from 0x1cf0e2f2f715450
transaction {
    let signer: AuthAccount
    let linkPath: Path
    let ownerPath: Path

    prepare(signer: AuthAccount){
        self.signer = signer

        let storagePath = CapabilityTransfer.storagePath
        let capabilityHolder <- CapabilityTransfer.createCapabilityHolder()

        /// clear old capability holder object in storage
        /// ONLY FOR TESTING. NOT FOR PRODUCTION ENVIRONMENT! 
        if let oldHolder <- self.signer.load<@CapabilityTransfer.CapabilityHolder>(from: storagePath) {
            destroy oldHolder
        }
        
        self.signer.save(<-capabilityHolder, to: storagePath)

        self.linkPath = CapabilityTransfer.publicPath        
        self.signer.link<&{CapabilityTransfer.CapabilityReceiver}>(self.linkPath, target: storagePath)
        
        self.ownerPath = CapabilityTransfer.ownerPath
        self.signer.link<&{CapabilityTransfer.Owner}>(self.ownerPath, target: storagePath)
    }

    post {
        self.signer
            .getCapability(self.linkPath)!
            .check<&{CapabilityTransfer.CapabilityReceiver}>():
            "CapabilityHolder reference was not created correctly"

        self.signer
            .getCapability(self.ownerPath)!
            .check<&{CapabilityTransfer.Owner}>():
            "CapabilityHolder Owner reference was not created correctly"
    }
}
