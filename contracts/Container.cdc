pub contract Container{
    pub let message: String
    pub resource CapabilityContainer{
        pub let capability: Capability?

        init(_ capability: Capability?){
            self.capability = capability    
        }
    }

    pub fun createContainer(_ capability: Capability?):@CapabilityContainer {
        return <- create CapabilityContainer(capability)
    }

    init(){
        self.message = "contract deployed"
    }
}