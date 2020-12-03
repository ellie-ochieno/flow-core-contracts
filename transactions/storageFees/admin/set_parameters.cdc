import StorageFees from 0xSTORAGEFEES

// This transaction changes the flow storage fees parameters
transaction(refundingEnabled: Bool?, minimumAccountStorage: UInt64?, flowPerByte: UFix64?, flowPerAccountCreation: UFix64) {
    let adminRef: &StorageFees.Administrator

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
        self.adminRef = acct.borrow<&StorageFees.Administrator>(from: /storage/storageFeesAdmin)
            ?? panic("Could not borrow reference to storage fees admin")
    }

    execute {
        if refundingEnabled != nil {
            self.adminRef.setRefundingEnabled(refundingEnabled)
        }
        if minimumAccountStorage != nil {
            self.adminRef.setMinimumAccountStorage(minimumAccountStorage)
        }
        if flowPerByte != nil {
            self.adminRef.setFlowPerByte(flowPerByte)
        }
        if flowPerAccountCreation != nil {
            self.adminRef.setFlowPerAccountCreation(flowPerAccountCreation)
        }
    }
}