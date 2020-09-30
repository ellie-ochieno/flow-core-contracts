import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import FlowIDTableStaking from 0x01cf0e2f2f715450

pub contract FlowStakingHelper {
    /// EVENTS
    /// TODO: Implement necessary events
    pub event CapabilityDeposited(by: Address, to: Address)

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

        pub let nodeInfo: Info   

        access(contract) var nodeStaker: @FlowIDTableStaking.NodeStaker

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action:  Commit more tokens to stake
        pub fun stakeNewTokens(_ tokens: @FungibleToken.Vault){
            self.nodeStaker.stakeNewTokens(<- tokens)
        }

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action: Function to request to commit to stake a certain amount of unlocked tokens
        pub fun stakeUnlockedTokens(amount: UFix64) {
             self.nodeStaker.stakeUnlockedTokens(amount: amount)    
        }

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action: Stake rewards stored inside of staking contract without returning them to involved parties
        pub fun stakeRewardedTokens(amount: UFix64){
            self.nodeStaker.stakeRewardedTokens(amount: amount)
        }

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action: Function to request to unstake portion of staked tokens
        /// 
        pub fun requestUnStaking(amount: UFix64) {
            self.nodeStaker.requestUnStaking(amount: amount)
        }

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action: Function to request to unstake portion of staked tokens
        /// 
        /// TODO: Do we need this method?
        pub fun unstakeAll() {
            self.nodeStaker.unstakeAll()
        }

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action: Return unlocked tokens from staking contract
        pub fun withdrawUnlockedTokens(amount: UFix64){
            let unlockedTokens <- self.nodeStaker.withdrawUnlockedTokens(amount: amount)
            self.returnTokensToStaker(tokens: <- unlockedTokens)
        }

        /// ---------------------------------------------------------------------------------
        /// Access:  TODO: DEFINE ACCESS
        /// Action: Withdraw rewards from staking contract
        pub fun withdrawRewardedTokens(amount: UFix64){
            let rewardTokens <- self.nodeStaker.withdrawRewardedTokens(amount: amount)
            self.returnTokensToStaker(tokens: <- rewardTokens)
        }


        /// ---------------------------------------------------------------------------------
        /// Access: Token Holder
        /// Action: Method to update capability pointing to a Vault, which would accumulate rewards
        pub fun setRewardVaultCapability(_ newCapability: Capability){
            self.stakerRewardVaultCapability = newCapability
        }

        /// ---------------------------------------------------------------------------------
        /// Access: Internal
        /// Action: Method to pass tokens back to Token Holder via stored vault capability
        pub fun returnTokensToStaker(tokens: @FungibleToken.Vault) {
            let stakerVault = self.stakerRewardVaultCapability.borrow<&FungibleToken.Vault>()!
            stakerVault.deposit(from: <- tokens)
        }


        /// ---------------------------------------------------------------------------------
        /// Init and Destroy
        init(stakingKey: String, rewardVaultCapability: Capability, nodeInfo: Info, id: String, tokensCommitted: @FungibleToken.Vault) {
            self.stakingKey = stakingKey
            self.stakerRewardVaultCapability = rewardVaultCapability
            self.nodeInfo = nodeInfo

            let networkingKey = nodeInfo.networkingKey
            let networkingAddress = nodeInfo.networkingAddress
            let role = nodeInfo.role;

            // Init with empty nodeStaker
            self.nodeStaker <- FlowIDTableStaking.addNodeRecord(
                    id: id, 
                    role: role, 
                    networkingAddress: networkingAddress, 
                    networkingKey: networkingKey, 
                    stakingKey: stakingKey, 
                    tokensCommitted: <- tokensCommitted
                )
        }

        destroy() {
            destroy self.nodeStaker
        }
    }


    /// -----------------------------------------------------------------------------------------
    /// CONTRACT MAIN
    /// -----------------------------------------------------------------------------------------
   
    /// PATHS
    pub let storageNodeInfoPath: Path
    pub let publicNodeInfoPath: Path

    pub let storageCapabilityHolder: Path
    pub let privateCapabilityHolder: Path
    pub let privateHolderOwner: Path
    pub let publicCapabilityReceiver: Path

    pub let storageStakingHelper: Path
    pub let linkNodeHelper: Path
    pub let linkStakingHelper: Path

    /// METHODS

    pub fun createNewOperatorInfo(role: UInt8, networkingKey: String, networkingAddress: String ): @OperatorInfo {
        return <- create OperatorInfo(
                role: role, 
                networkingKey: networkingKey, 
                networkingAddress: networkingAddress
            )
    }

    pub fun createCapabilityHolder(): @CapabilityHolder {
        return <- create CapabilityHolder()
    }

    pub fun createStakingHelper(stakingKey: String, rewardVaultCapability: Capability, nodeInfo: Info, id:String, tokensCommitted: @FungibleToken.Vault): @StakingHelper {
        return <- create StakingHelper(
                stakingKey: stakingKey, 
                rewardVaultCapability: rewardVaultCapability, 
                nodeInfo: nodeInfo, 
                id: id, 
                tokensCommitted: <- tokensCommitted
            )
    }

    /// INIT
    init(){
        self.storageNodeInfoPath = /storage/flowNodeOperatorInfo
        self.publicNodeInfoPath = /public/flowNodeOperatorInfo

        self.storageCapabilityHolder = /storage/flowCapabilityHolder
        self.privateCapabilityHolder = /private/flowCapabilityHolder
        self.privateHolderOwner = /private/flowCapabilityHolderOwner
        self.publicCapabilityReceiver = /public/flowCapabilityReceiver

        self.storageStakingHelper = /storage/flowStakingHelper
        self.linkNodeHelper = /private/flowNodeHelper
        self.linkStakingHelper = /private/flowStakingHelper
    }
}