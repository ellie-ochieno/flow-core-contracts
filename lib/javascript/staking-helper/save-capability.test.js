import "../utils/config";
import { createAccount } from "../utils/create-account";
import { deployContract } from "../utils/deploy-code";
import * as fcl from "@onflow/fcl";
import { getContractTemplate } from "./contract.test";
import { authorization } from "../utils/crypto";

describe("test save/copy of capability", () => {
  test("run transaction", async () => {
    const node = await createAccount();

    const admin = authorization();

    const code = `
      import FlowToken from 0x0ae53cb6e3f42a79
      import FungibleToken from 0xee82856bf20e2aa6
      
      transaction {
        prepare(payer: AuthAccount, node: AuthAccount) {
        
          let newAccount = AuthAccount(payer: payer)
          
          let emptyVault <- FlowToken.createEmptyVault()
          newAccount.save<@FungibleToken.Vault>(<- emptyVault, to: /storage/emptyVault)
          
          let capability = newAccount.link<&FungibleToken.Vault>(/private/VaultRef, target: /storage/emptyVault)
          node.save(capability, to: /storage/vaultCapability)
          
          log("Capability was successfully stored")
        }
      }  
    `;

    try {
      const response = await fcl.send([
        fcl.transaction(code),
        fcl.proposer(admin),
        fcl.payer(admin),
        fcl.limit(999),
        fcl.authorizations([admin, authorization(node)]),
      ]);
      const tx = await fcl.tx(response).onceExecuted();
      expect(tx.status).toBe(4);
    } catch (error) {
      console.log(error);
    }

    try {
      const code = `
        import FlowToken from 0x0ae53cb6e3f42a79
        import FungibleToken from 0xee82856bf20e2aa6
      
        transaction {
          prepare(node: AuthAccount) {
            let capability = node.copy()
          }
        }
      `;
      const response = await fcl.send([
        fcl.transaction(code),
        fcl.proposer(admin),
        fcl.payer(admin),
        fcl.limit(999),
        fcl.authorizations([authorization(node)]),
      ]);
      const tx = await fcl.tx(response).onceExecuted();
      expect(tx.status).toBe(4);
    } catch (error) {
      console.log(error);
    }
  });
});
