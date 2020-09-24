import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import CapabilityTransfer from 0x1cf0e2f2f715450

transaction(receiver: Address) {
    let signer: AuthAccount
    let linkPath: Path
    let ownerPath: Path

    prepare(signer: AuthAccount){
        self.signer = signer
        self.linkPath = CapabilityTransfer.publicPath    
        self.ownerPath = CapabilityTransfer.ownerPath

           
        if let oldVault <- self.signer.load<@FungibleToken.Vault>(from: /storage/emptyVault) {
            destroy oldVault
        }
        
        // Create empty vault
        let emptyVault <- FlowToken.createEmptyVault()
         
        // Save empty vault into new account storage     
        self.signer.save<@FungibleToken.Vault>(<- emptyVault, to: /storage/emptyVault)
        self.signer.link<&FungibleToken.Vault>(/private/emptyVault, target: /storage/emptyVault)    
        let capability = self.signer.getCapability(/private/emptyVault)!
        
        //let holderReference = self.signer
        let holderReference = getAccount(receiver)
            .getCapability(self.linkPath)!
            .borrow<&{CapabilityTransfer.CapabilityReceiver}>()!
        
        let senderRef = self.signer
                    .getCapability(self.ownerPath)!
                    .borrow<&{CapabilityTransfer.Owner}>()!

        
        holderReference.depositCapability(capability, sender: senderRef)
    }
}