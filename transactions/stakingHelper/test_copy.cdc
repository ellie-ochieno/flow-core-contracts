import FungibleToken from 0xee82856bf20e2aa6

transaction {
    prepare(node: AuthAccount) {

        let copy = node.copy<Capability>(from:/storage/emptyVault)!
        let ref = copy.borrow<&FungibleToken.Vault>()!
        
        log("Vault Balance:".concat(ref.balance.toString()))
    }
}