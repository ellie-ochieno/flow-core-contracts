import FlowStakingHelper from 0x179b6b1cb6755e31

transaction(address: Address) {
    let signer: AuthAccount
    prepare(signer: AuthAccount){
        self.signer = signer

        let storagePath = FlowStakingHelper.storageCapabilityHolder
        let holder = self.signer.borrow<&FlowStakingHelper.CapabilityHolder>(from: storagePath)!

        let capability = holder.getCapabilityByAddress(address)!
        log("Capability for address ".concat(address.toString()))
        log(capability) 
    }
}