import CapabilityTransfer from 0x1cf0e2f2f715450
transaction {
    let signer: AuthAccount
    let linkPath: Path
    prepare(signer: AuthAccount){
        self.signer = signer
        self.linkPath = CapabilityTransfer.publicPath    

        let ref = self.signer
            .getCapability(self.linkPath)!
            .borrow<&{CapabilityTransfer.CapabilityReceiver}>()!

        log(ref.resourceType)
    }

    post {
        self.signer
            .getCapability(self.linkPath)!
            .check<&{CapabilityTransfer.CapabilityReceiver}>():
            "CapabilityHolder reference was not created correctly"
    }
}
