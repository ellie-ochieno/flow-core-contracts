import "../utils/config";
import { createAccount } from "../utils/create-account";
import { deployContract } from "../utils/deploy-code";
import * as fcl from "@onflow/fcl";
import { getContractTemplate } from "./contract.test";
import { authorization } from "../utils/crypto";

describe("test container", () => {
  test("deploy, call, send transaction", async () => {
    const code = getContractTemplate("Container", {});
    const containerAccount = await createAccount();
    console.log({containerAccount});
    try {
      const response = await deployContract(containerAccount, code);
      const status = await fcl.tx(response).onceExecuted();
      expect(status.status).toBe(4);
    } catch (error) {
      console.log("error during deployment");
      console.log(error);
      expect(error).toBe("");
    }

    // Get message field on deployed contract
    try {
      const scriptResponse = await fcl.send([
        fcl.script`
          import Container from ${containerAccount}
          
          pub fun main():String {
            return Container.message
          }
        `,
      ]);
      const scriptResult = await fcl.decode(scriptResponse);
      expect(scriptResult).toBe("contract deployed");
    } catch (error) {
      console.log("Error during script call");
      console.log(error);
    }

    const helper = await createAccount();
    const nodeOperator = await createAccount();
    const custodyProvider = await createAccount();

    // send transaction to store capability
    try {
      const txResponse = await fcl.send([
        fcl.transaction`
          import FlowToken from 0x0ae53cb6e3f42a79
          import FungibleToken from 0xee82856bf20e2aa6
          import Container from ${containerAccount}
          
          transaction{
            let node: AuthAccount
            let provider: AuthAccount
            
            prepare(helper: AuthAccount, node: AuthAccount, provider: AuthAccount){
              self.node = node
              self.provider = provider
              log("Helper:".concat(helper.address.toString()))
              log("Node:".concat(node.address.toString()))
              log("Provider:".concat(provider.address.toString()))
              
              let emptyVault <- FlowToken.createEmptyVault()
              helper.save<@FungibleToken.Vault>(<- emptyVault, to: /storage/emptyVault)
      
              let capability = helper.link<&FungibleToken.Vault>(/private/MainReceiver, target: /storage/emptyVault)
              log(capability)
              let firstContainer <- Container.createContainer(capability)
              let secondContainer <- Container.createContainer(capability)
            
              node.save<@Container.CapabilityContainer>(<- firstContainer, to: /storage/container)
              provider.save<@Container.CapabilityContainer>(<- secondContainer, to: /storage/container)
            
              node.link<&Container.CapabilityContainer>(/public/container, target: /storage/container)
              provider.link<&Container.CapabilityContainer>(/public/container, target: /storage/container)
            
              log("Resources are saved. Links created")
            }
            post{
              self.node.getCapability(/public/container)!
                .check<&Container.CapabilityContainer>():
                "Node: Capability Container was not created properly..."
                
              self.provider.getCapability(/public/container)!
                .check<&Container.CapabilityContainer>():
                "Provider: Link to Capability Container was not created properly..."
            }
          }
        `,
        fcl.limit(999),
        fcl.proposer(authorization(helper)),
        fcl.payer(authorization(helper)),
        fcl.authorizations([
          authorization(helper),
          authorization(nodeOperator),
          authorization(custodyProvider),
        ]),
      ]);
      const txStatus = await fcl.tx(txResponse).onceExecuted();
      expect(txStatus.status).toBe(4);
    } catch (error) {
      console.log(error);
    }

    try {
      const vaultScriptResponse = await fcl.send([
        fcl.script`
          import FlowToken from 0x0ae53cb6e3f42a79
          import FungibleToken from 0xee82856bf20e2aa6
          import Container from ${containerAccount}
          
          pub fun main(): UFix64 {
            let node = getAccount(${nodeOperator})
            
            let containerRef = node.getCapability(/public/container)!
              .borrow<&Container.CapabilityContainer>()
              ?? panic("Could not borrow reference to container")
            
            
            let vaultRef = containerRef.capability!
              .borrow<&FungibleToken.Vault>()
              ?? panic("Could not borrow reference to Vault from stored capability")
               
            log("Vault Balance:")
            log(vaultRef.balance)

            return vaultRef.balance
          }
        `,
      ]);

      const vaultScriptResult = await fcl.decode(vaultScriptResponse);
      console.log({ vaultScriptResult });
    } catch (e) {
      console.log(e);
    }

    console.log("Done!");
  });
});
