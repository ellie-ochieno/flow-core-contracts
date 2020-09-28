import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import FlowIDTableStaking from 0x01cf0e2f2f715450

// Use service account to mint tokens

pub contract FlowStakingHelper {

    /// Event that is emitted when tokens are deposited to the escrow vault
    pub event TokensDeposited(amount: UFix64)
    
    /// Event that is emitted when tokens are successfully staked
    pub event StakeAccepted(amount: UFix64)

    /// Event
    pub event CapabilityDeposited(by: Address, to: Address)

    /// Common paths to storage and capabilities
    pub let HelperStoragePath: Path
    pub let HelperLinkPath: Path
    pub let HelperNodeLinkPath: Path

    pub let HolderStoragePath: Path
    pub let HolderPublicPath: Path
    pub let HolderOwnerPath: Path

    /// CAPABILITY HOLDER
    /// Empty inteface to expose owner of the resource
    pub resource interface Owner {}

    /// Publicly available interfaces to allow deposit of capabilities
    pub resource interface CapabilityReceiver {
        pub fun depositCapability(_ capability: Capability, depositor: &{Owner})
    }

    pub resource CapabilityHolder: CapabilityReceiver {
        access(self) let capabilities: {Address: Capability}

        
        /// Allows to store capability into the dictionary by third party
        /// "depositor" argument allows only owners of said resource to write
        pub fun depositCapability(_ capability: Capability, depositor: &{Owner}) {
            let owner = self.owner!.address;
            let address = depositor.owner!.address
            self.capabilities[address] = capability
            
            /// Emit the event to notify owner
            emit CapabilityDeposited(by: address, to: owner)
        }

        /// Utility method to store capability by CapbilitHolder owner
        pub fun storeCapability(_ capability: Capability, key: Address){
            self.capabilities[key] = capability
        }

        // Get capability by address
        pub fun getCapabilityByAddress(_ address: Address): Capability? {
            return self.capabilities[address]
        }

        init(){
            /// Init empty dictionary for capabilities
            self.capabilities = {}
        }
    }

    pub fun createCapabilityHolder(): @CapabilityHolder {
        return  <- create CapabilityHolder()
    }

    pub resource interface NodeHelper {
        access(contract) var nodeStaker: @FlowIDTableStaking.NodeStaker?
        pub let escrowVault: @FungibleToken.Vault
        
        // Function to abort creation of node record and return tokens back
        pub fun abort()

        // Return tokens from escrow back to custody provider
        pub fun withdrawEscrow(amount: UFix64)

        // Complete initialization of StakingHelper with node info
        pub fun addNodeInfo(networkingKey: String, networkingAddress: String, nodeAwardVaultCapability: Capability, cutPercentage: UFix64)

        // Submit staking request to staking contract
        // Should be called ONCE to init the record in staking contract and get NodeRecord
        // TODO: Node should not be able to initiate staking process, since they will set cutPercentage
        /* 
        pub fun submit(id: String, role: UInt8 ) {   

        }
        */

        // Request to unstake portion of staked tokens
        pub fun unstake(amount: UFix64)

        // Return unlocked tokens from staking contract
        pub fun withdrawTokens(amount: UFix64) {
            pre{
                self.nodeStaker != nil: "NodeRecord was not initialized"    
            }
        }
            
    }

    pub resource StakingHelper: NodeHelper {
        // Staking parameters
        pub let stakingKey: String

        // Networking parameters
        pub var networkingKey: String
        pub var networkingAddress: String

        // FlowToken Vault to hold escrow tokens
        pub let escrowVault: @FungibleToken.Vault

        // Receiver Capability for account, where rewards are paid
        pub let stakerAwardVaultCapability: Capability
        pub var nodeAwardVaultCapability: Capability?

        // Portion of reward that goes to node operator
        pub var cutPercentage: UFix64

        // Flag that to ensure StakingHelper is initialized by both parties
        pub var initialized: Bool

        // Optional to store NodeStaker object from staking contract
        access(contract) var nodeStaker: @FlowIDTableStaking.NodeStaker?

        init(stakingKey: String, stakerAwardVaultCapability: Capability){
            self.stakingKey = stakingKey
            self.stakerAwardVaultCapability = stakerAwardVaultCapability

            self.networkingKey = ""
            self.networkingAddress = ""
            self.nodeAwardVaultCapability = nil
            self.cutPercentage = 0.0

            // init resource with empty node record
            self.nodeStaker <- nil

            // initiate empty FungibleToken Vault to store escrowed tokens
            self.escrowVault <- FlowToken.createEmptyVault()

            self.initialized = false        
        }

        destroy() {
            self.withdrawEscrow(amount: self.escrowVault.balance)
                        
            destroy self.escrowVault
            destroy self.nodeStaker
        }

        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    addNodeInfo
        // Access:  Custody Provider
        // Action:  Deposit tokens to escrow Vault   
        // TODO:    We shall exclude this method from Token Holder interface

        pub fun addNodeInfo(networkingKey: String, networkingAddress: String, nodeAwardVaultCapability: Capability, cutPercentage: UFix64) {
            self.networkingKey = networkingKey
            self.networkingAddress = networkingAddress
            self.nodeAwardVaultCapability = nodeAwardVaultCapability
            self.cutPercentage = cutPercentage

            self.initialized = true 
        }
        
        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    depositEscrow
        // Access:  Custody Provider
        // Action:  Deposit tokens to escrow Vault   
        //
        pub fun depositEscrow(vault: @FungibleToken.Vault) {
            let amount = vault.balance 
            self.escrowVault.deposit(from: <- vault)

            emit TokensDeposited(amount: amount)
        }

        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    withdawEscrow
        // Access:  Custody Provider
        // Action:  Returns tokens from escrow back to custody provider
        //
        pub fun withdrawEscrow(amount: UFix64) {
            pre {
                amount <= self.escrowVault.balance: "Amount is bigger than escrow"
            }
            // We will create temporary Vault in order to preserve one living in StakingHelper
            let tempVault <- self.escrowVault.withdraw(amount: amount)
            
            self.stakerAwardVaultCapability.borrow<&{FungibleToken.Receiver}>()!.deposit(from: <- tempVault)
        }
        
        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    submit
        // Access:  Node Operator
        // Action:  Submits staking request to staking contract
        //
        pub fun submit(id: String, role: UInt8 ) {
            pre{
                // TODO: add 
                // check that entry already exists? 
                self.nodeStaker == nil: "NodeRecord already initialized"
                id.length > 0: "id field can't be empty"
            }

            let stakingKey = self.stakingKey 
            let networkingKey = self.networkingKey 
            let networkingAddress = self.networkingAddress
            let cutPercentage = self.cutPercentage
            let tokensCommitted <- self.escrowVault.withdraw(amount: self.escrowVault.balance)
             
            self.nodeStaker <-! FlowIDTableStaking.addNodeRecord(id: id, role: role, networkingAddress: networkingAddress, networkingKey: networkingKey, stakingKey: stakingKey, tokensCommitted: <- tokensCommitted, cutPercentage: cutPercentage )            
        }

        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    abort
        // Access:  Custody Provider, Node Operator
        // Action:  Abort initialization and return tokens back to custody provider
        //
        pub fun abort() {
            pre {
                self.nodeStaker == nil: "NodeRecord was already initialized"
            }

            self.withdrawEscrow(amount: self.escrowVault.balance)
            
            // TODO: post condition throwing error here...
            /* 
            post {
                // Check that escrowVault is empty
                self.escrowVault.balance == 0: "Escrow Vault is not empty"
            }
            */            
        }

        
        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    abort
        // Access:  Custody Provider, Node Operator
        // Action:  Commit more tokens to stake
        //
        pub fun stakeNewTokens(amount: UFix64) {
            let tokens <- self.escrowVault.withdraw(amount: amount)

            if (self.nodeStaker != nil) {
                self.nodeStaker?.stakeNewTokens(<- tokens)
            } else {
                self.escrowVault.deposit(from: <- tokens)
            }
        }


        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    stake
        // Access:  Custody Provider, Node Operator
        // Action: Function to request to commit to stake a certain amount of unlocked tokens
        pub fun stakeUnlockedTokens(amount: UFix64) {
            pre{
                self.nodeStaker != nil: "NodeRecord was not initialized"    
            }

            self.nodeStaker?.stakeUnlockedTokens(amount: amount)    
        }

        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    unstake
        // Access:  Custody Provider, Node Operator
        // Action: Function to request to unstake portion of staked tokens
        // 
        pub fun unstake(amount: UFix64) {
            pre{
                self.nodeStaker != nil: "NodeRecord was not initialized"    
            }

            self.nodeStaker?.requestUnStaking(amount: amount)
        }

         
        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    withdrawTokens
        // Access:  Custody Provider
        //
        // Action: Return unlocked tokens from staking contract
        pub fun withdrawTokens(amount: UFix64){
            if let vault <- self.nodeStaker?.withdrawUnlockedTokens(amount: amount) {
                // TODO: send them backto the staker and not escrow vault
                self.escrowVault.deposit(from: <- vault)
            } else {
                // TODO: Emit event that withdraw failed 
            }
        }

        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    withdrawReward
        // Access:  Custody Provider, Node Operator
        //
        // Action: Withdraw rewards from staking contract
        pub fun withdrawReward(amount: UFix64){
            pre{
                self.initialized == true: "StakingHelper is not fully initialized"
                self.nodeStaker != nil: "NodeRecord was not initialized"    
            }

            let nodeVaultRef = self.nodeAwardVaultCapability!.borrow<&FungibleToken.Vault>()
            let stakerVaultRef = self.stakerAwardVaultCapability.borrow<&FungibleToken.Vault>()

            if let rewardVault <- self.nodeStaker?.withdrawRewardedTokens(amount: amount){
                let nodeAmount = rewardVault.balance * self.cutPercentage

                let nodePart <- rewardVault.withdraw(amount: nodeAmount)
                nodeVaultRef!.deposit(from: <- nodePart)
                stakerVaultRef!.deposit(from: <- rewardVault)
            }
        }

        // ---------------------------------------------------------------------------------
        // Type:    METHOD
        // Name:    stakeRewards
        // Access:  Custody Provider, Node Operator
        //
        // Action: Stake rewards stored inside of staking contract without returning them to involved parties
        pub fun stakeRewards(amount: UFix64){
            self.nodeStaker?.stakeRewardedTokens(amount: amount)
        }
    }

    // ---------------------------------------------------------------------------------
    // Type:    METHOD
    // Name:    createHelper
    // Access:  Public
    //
    // Action: create new StakingHelper object with specified parameters
    pub fun createHelper(stakingKey: String, stakerAwardVaultCapability: Capability): @StakingHelper {
        return <- create StakingHelper(stakingKey: stakingKey,  stakerAwardVaultCapability: stakerAwardVaultCapability)
    }

    init(){
        self.HelperStoragePath = /storage/flowStakingHelper
        self.HelperLinkPath = /private/flowStakingHelper
        self.HelperNodeLinkPath = /private/flowNodeHelper
        
        /// Init paths
        self.HolderStoragePath = /storage/capabilityHolder
        self.HolderPublicPath = /public/capabilityHolder
        self.HolderOwnerPath = /private/capabilityHolderOwner
    }
}
 
 