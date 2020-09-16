          import FlowToken from 0x0ae53cb6e3f42a79
          import FungibleToken from 0xee82856bf20e2aa6
          import Container from 0x01cf0e2f2f715450
          
          pub fun main(): UFix64 {
            let node = getAccount(0x02)
            
            let containerRef = node.getCapability(/public/container)!.borrow<&Container.CapabilityContainer>()!
              //?? panic("Could not borrow reference to container")
            
            
            let vaultRef = containerRef.capability!.borrow<&FungibleToken.Vault>()
            
            return 0.0 //vaultRef.balance
          }