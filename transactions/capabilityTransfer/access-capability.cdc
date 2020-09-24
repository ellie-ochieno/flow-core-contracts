import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import CapabilityTransfer from 0x1cf0e2f2f715450

transaction(sender: Address) {
    let signer: AuthAccount
    let storagePath: Path

    prepare(signer: AuthAccount){
        self.signer = signer
        self.storagePath = CapabilityTransfer.storagePath

        let ref = self.signer
            .borrow<&CapabilityTransfer.CapabilityHolder>(from: self.storagePath)!

        if let vaultCapability = ref.capabilities[sender] {  
            let vaultRef = vaultCapability.borrow<&FungibleToken.Vault>()!
            log(vaultRef.balance)
        }
    }
}