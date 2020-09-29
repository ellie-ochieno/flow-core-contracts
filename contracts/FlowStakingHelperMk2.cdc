import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import FlowIDTableStaking from 0xe03daebed8ca0615

pub contract FlowStakingHelper {
    /// EVENTS
    pub event CapabilityDeposited(by: Address, to: Address)
    /// TODO: Implement necessary events

    /// -----------------------------------------------------------------------------------------
    /// RESOURCES AND STRUCTS
    /// -----------------------------------------------------------------------------------------

    // Structure to hold node operator information, necessary to initialize StakingHelper
    pub struct Info {
        pub let role: UInt8
        pub let networkingKey: String
        pub let networkingAddress: String
    
        init(role: UInt8, networkingKey: String, networkingAddress: String) {
            self.role = role
            self.networkingKey = networkingKey
            self.networkingAddress = networkingAddress
        }
    }

    pub resource OperatorInfo {
        pub let info: Info

        pub fun getNodeInfo(): Info {
            return self.info
        }

        init(role: UInt8, networkingKey: String, networkingAddress: String){
            self.info = Info(role: role, networkingKey: networkingKey, networkingAddress: networkingAddress)
        }
    }

    pub fun createNewOperatorInfo(role: UInt8, networkingKey: String, networkingAddress: String ): @OperatorInfo {
        return <- create OperatorInfo(role: role, networkingKey: networkingKey, networkingAddress: networkingAddress)
    }

    /// CapabilityHolder is a resource that will be living in the Node Operator storage
    /// and expose public capability with single method "depositCapability". Token holders will
    /// use it to store restricted capability to StakingHelper for Node Operator 
    
    /// "Owner" interface will be used to uniquely identify depositor and restrict write access for
    /// any imposters. Interface don't have any fields specified, cause we only need access to "owner.address"
    /// field
    pub resource interface Owner {}
    
    /// "CapabilitReceiver" will be used to expose restricted capability for public use
    /// Arguments:
    ///     "capability" - capability that need to be stored inside CapabilityHolder
    ///     "depositor" - a reference to restricted capability, which will allow to identify the owner 
    pub resource interface CapabilityReceiver {
        pub fun depositCapability(_ capability: Capability, depositor: &{Owner})
    }

    pub resource CapabilityHolder: CapabilityReceiver {
        access(self) let capabilities: {Address: Capability}

        pub fun depositCapability(_ capability: Capability, depositor: &{Owner}){
            /// We can identify Node operator by checking who is the owner of the resource
            /// where "depositCapability" was called
            let holderOwner = self.owner!
            
            /// Depositor address can be inferred from reference to "Owner" capability
            let depositorAddress = depositor.owner!.address
            
            /// Store capability into storage
            self.capabilities[depositorAddress] = capability

            /// Emit event to notify parties that capability was succesfully stored0
            emit CapabilityDeposited(by: depositorAddress, to: holderOwner.address)
        }

        /// Utility method to store capability by CapabilytHolder owner
        pub fun storeCapability(_ capability: Capability, key: Address){
            self.capabilities[key] = capability
        }

        // Get capability by address
        pub fun getCapabilityByAddress(_ address: Address): Capability? {
            return self.capabilities[address]
        }

        init(){           
            self.capabilities = {}
        }
    }

    pub fun createCapabilityHolder(): @CapabilityHolder {
        return <- create CapabilityHolder()
    }


    /// NodeHelper interface will be used to provide NodeOperator restricted capability to 
    /// control Token Holders tokens. We want to provide all the necessary control, but restrict
    /// everything that only Token Holder should be able to do
    pub resource interface NodeHelper {
        /// TODO: provide restricted control over tokens to Node Operator
    }

    /// StakingHelper is a resource, which will allow Node Operator to use Token Holder tokens, when
    /// he doesn't have enough 
    pub resource StakingHelper: NodeHelper {

        pub let stakingKey: String
        pub var stakerRewardVaultCapability: Capability

        pub let networkingKey: String
        pub let networkingAddress: String        

        access(contract) var nodeStaker: @FlowIDTableStaking.NodeStaker?

        /// Method to update capability pointing to a Vault, which would accumulate rewards
        pub fun setRewardVaultCapability(_ newCapability: Capability){
            self.stakerRewardVaultCapability = newCapability
        }

        init(stakingKey: String, rewardVaultCapability: Capability, nodeInfo: Info) {
            self.stakingKey = stakingKey
            self.stakerRewardVaultCapability = rewardVaultCapability

            self.networkingKey = nodeInfo.networkingKey
            self.networkingAddress = nodeInfo.networkingAddress

            self.nodeStaker <- nil
        }

        destroy() {
            destroy self.nodeStaker
        }
    }

    pub fun createStakingHelper(stakingKey: String, rewardVaultCapability: Capability, nodeInfo: Info): @StakingHelper {
        return <- create StakingHelper(stakingKey: stakingKey, rewardVaultCapability: rewardVaultCapability, nodeInfo: nodeInfo)
    }


    /// -----------------------------------------------------------------------------------------
    /// CONTRACT
    /// -----------------------------------------------------------------------------------------

   
    /// PATHS
    pub let storageNodeInfoPath: Path
    pub let publicNodeInfoPath: Path

    pub let storageCapabilityHolder: Path
    pub let privateCapabilityHolder: Path
    pub let publicCapabilityHolder: Path

    /// METHODS

    /// INIT
    init(){
        self.storageNodeInfoPath = /storage/nodeOperatorInfo
        self.publicNodeInfoPath = /public/nodeOperatorInfo

        self.storageCapabilityHolder = /storage/capabilityHolder
        self.privateCapabilityHolder = /private/capabilityHolder
        self.publicCapabilityHolder = /public/capabilityHolder
    }
}