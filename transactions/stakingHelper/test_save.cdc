import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6

transaction {
    prepare(node: AuthAccount) {
        let newAccount = AuthAccount(payer: node)
        let emptyVault <- FlowToken.createEmptyVault()     
        newAccount.save<@FungibleToken.Vault>(<- emptyVault, to: /storage/emptyVault)
        newAccount.link<&FungibleToken.Vault>(/private/VaultRef, target: /storage/emptyVault)

        let capability = newAccount.getCapability(/private/VaultRef)

        // Clear storage, so we can reuse this transaction
        node.load<AnyStruct>(from: /storage/emptyVault)
        
        // Save capability to storage
        node.save<Capability>(capability!, to: /storage/emptyVault)
        
        let copy = node.copy<Capability>(from:/storage/emptyVault)!
        let ref = copy.borrow<&FungibleToken.Vault>()!
        
        log("Vault Balance:".concat(ref.balance.toString()))
    }
}
 