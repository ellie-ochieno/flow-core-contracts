import FlowIDTableStaking from 0xIDENTITYTABLEADDRESS

// This transaction pays rewards to all the staked nodes

transaction {

    // Local variable for a reference to the ID Table Admin object
    let adminRef: &FlowIDTableStaking.Admin

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
<<<<<<< HEAD
        self.adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: /storage/flowStakingAdmin)
=======
        self.adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: FlowIDTableStaking.StakingAdminStoragePath)
>>>>>>> struct
            ?? panic("Could not borrow reference to staking admin")
    }

    execute {
        self.adminRef.payRewards()
    }
}