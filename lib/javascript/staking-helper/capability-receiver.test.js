import * as types from "@onflow/types";
import "../utils/config";
import { getTemplate } from "../utils/file";
import { mintFlow, getFlowBalance } from "../templates/";
import { getAccount, getContractAddress, registerContract } from "../rpc-calls";
import { executeScript, sendTransaction } from "../utils/interaction";
import { deployContract } from "../utils/deploy-code";

const bpContract = "../../../contracts";
const bpTxTemplates = "../../../transactions";

const getContractTemplate = (name, addressMap, byName = true) => {
  return getTemplate(`${bpContract}/${name}.cdc`, addressMap, byName);
};

const getTxTemplate = (name, addressMap, byName = true) => {
  return getTemplate(
    `${bpTxTemplates}/capabilityTransfer/${name}.cdc`,
    addressMap,
    byName
  );
};

describe("CapabilityHolder init", () => {
  test("desploy contract", async () => {
    const capabilityTransferAccount = await getAccount("capability-transfer");
    const contract = getContractTemplate("CapabilityTransfer");
    try {
      const deployResult = await deployContract(
        capabilityTransferAccount,
        contract
      );
      expect(deployResult.status).toBe(4);
      await registerContract("CapabilityTransfer", capabilityTransferAccount);
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  test("init capability on token-holder", async () => {
    const contractAddress = await getContractAddress("CapabilityTransfer");
    const tokenHolder = await getAccount("token-holder");
    const nodeOperator = await getAccount("node-operator");
    const addressMap = {
      CapabilityTransfer: contractAddress,
    };
    const code = getTxTemplate("init-receiver", addressMap);

    // Init Token Holder
    try {
      const signers = [tokenHolder];
      const txStatus = await sendTransaction({ code, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }

    // Init node operator
    try {
      const signers = [nodeOperator];
      const txStatus = await sendTransaction({ code, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  test("store token holder capability in node operator", async () => {
    const contractAddress = await getContractAddress("CapabilityTransfer");
    const tokenHolder = await getAccount("token-holder");
    const nodeOperator = await getAccount("node-operator");
    const addressMap = {
      CapabilityTransfer: contractAddress,
    };
    const code = getTxTemplate("store-capability", addressMap);
    const args = [[nodeOperator, types.Address]];
    const signers = [tokenHolder];

    try {
      const txStatus = await sendTransaction({
        code,
        args,
        signers,
      });
      console.log({ txStatus });
    } catch (error) {
      console.log("⚠ ERROR:", error);
      expect(error).toBe("");
    }
  });
});

describe("CapabilityHolder access test", () => {
  test("node operator can access Vault on token holder", async () => {
    const contractAddress = await getContractAddress("CapabilityTransfer");
    const nodeOperator = await getAccount("node-operator");
    const tokenHolder = await getAccount("token-holder");
    const addressMap = {
      CapabilityTransfer: contractAddress,
    };
    const code = getTxTemplate("access-capability", addressMap);
    const signers = [nodeOperator];
    const args = [[tokenHolder, types.Address]];
    try {
      const txStatus = await sendTransaction({
        code,
        args,
        signers,
      });
      console.log({ txStatus });
    } catch (error) {
      console.log("⚠ ERROR:", error);
      expect(error).toBe("");
    }
  });
});
