
pub contract CapabilityTransfer {

    pub let storagePath: Path
    pub let publicPath: Path
    pub let ownerPath: Path

    pub resource interface Owner {
        // Empty interface, just to provide a ref to account
        pub let resourceType: String
    }

    pub resource interface CapabilityReceiver {
        pub fun depositCapability(_ capability: Capability, sender: &{Owner})
    } 

    pub resource CapabilityHolder: CapabilityReceiver, Owner {
        access(self) let capabilities: {Address: Capability}
        pub let resourceType: String

        pub fun getAddressList(): [Address] {
            return self.capabilities.keys
        }

        pub fun depositCapability(_ capability: Capability, sender: &{Owner}){
            log("I live inside storage of account ".concat(self.owner!.address.toString()))
             
            if let senderRef = sender as? &{Owner} {
                log(senderRef.owner!.address)
            }
            
            // log("Capability Sender: ".concat(senderAddress)
            /* 
            if let ref = capability.borrow<&{CapabilityReceiver}>() {
                let address = ref.owner!.address
                self.capabilities[address] = capability
                log("Capability deposited by ".concat(address.toString()))
            }
            */
        }

        pub fun getCapabilityByAddress(_ address: Address): Capability? {
            return self.capabilities[address]
        }

        init(){
            self.resourceType = "CapabilityHolder"
            self.capabilities = {}
        }
    }

    pub fun createCapabilityHolder(): @CapabilityHolder {
        return <- create CapabilityHolder()
    }

    init(){
        self.storagePath = /storage/capabilityHolder
        self.publicPath = /public/capabilityHolder
        self.ownerPath = /private/capabilityHolderOwner
    }
}
