import FlowStakingHelper from 0x179b6b1cb6755e31

transaction (address: Address) {
    prepare(signer: AuthAccount) {

        log("Check capability for address:")
        log(address);

        let holderStoragePath = FlowStakingHelper.HolderStoragePath
        let capbilityHolder = signer.borrow<&FlowStakingHelper.CapabilityHolder>(from: holderStoragePath)!
        let storedCapability = capbilityHolder.getCapabilityByAddress(address)
        
        log("Stored Capability")
        log(storedCapability);
    }
}