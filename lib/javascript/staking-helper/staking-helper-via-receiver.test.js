import * as types from "@onflow/types";
import "../utils/config";
import { deployContract } from "../utils/deploy-code";
import { getTemplate } from "../utils/file";
import { getAccount, registerContract, getContractAddress } from "../rpc-calls";
import { executeScript, sendTransaction } from "../utils/interaction";

const bpContract = "../../../contracts";
const bpTxTemplates = "../../../transactions/stakingHelper/single-tx-flow";
const bpMockContract = "../../../mocks";

const getMockContractTemplate = (name, addressmap, byName = true) => {
  return getTemplate(`${bpMockContract}/${name}.cdc`, addressmap, byName);
};

const getContractTemplate = (name, addressMap, byName = true) => {
  return getTemplate(`${bpContract}/${name}.cdc`, addressMap, byName);
};
const getTxTemplate = (name, addressMap, byName = true) => {
  return getTemplate(`${bpTxTemplates}/${name}.cdc`, addressMap, byName);
};

// ------------------------------------- CONSTANTS -----------------------------
const ACCT_NODE_OPERATOR = "node-operator";
const ACCT_TOKEN_HOLDER = "token-holder";

const NODE_TYPE_COLLECTION = 1

const NODE_AWARD_CUT = 0.3;
const NODE_KEY = "---PUBLIC-KEY---";
const NODE_ADDRESS = "1.3.3.7";

describe("deploy contracts", () => {
  test("deploy mock FlowIDTableStaking", async () => {
    const mockIDTableContract = getMockContractTemplate(
      "Mock_FlowIDTableStaking",
      {}
    );
    const mockOwner = await getAccount("mock-table-owner");
    try {
      const deployStatus = await deployContract(mockOwner, mockIDTableContract);
      expect(deployStatus.status).toBe(4);
      console.log(`Mock contract was deployed to ${mockOwner}`);
      await registerContract("Mock_FlowIDTableStaking", mockOwner);
    } catch (error) {
      console.log("⚠ ERROR:", error);
      expect(error).toBe("");
    }
  });
  test("deploy StakingHelper", async () => {
    const IDTableStakingAddress = await getContractAddress(
      "Mock_FlowIDTableStaking"
    );
    const stakingHelperAddress = await getAccount("staking-helper-owner");

    const contractCode = getContractTemplate("FlowStakingHelperMk2", {
      FlowIDTableStaking: IDTableStakingAddress,
    });

    try {
      const txStatus = await deployContract(stakingHelperAddress, contractCode);
      expect(txStatus.status).toBe(4);
      expect(txStatus.errorMessage).toBe("");

      await registerContract("FlowStakingHelper", stakingHelperAddress);
      console.log(
        `StakingHelper contract deployed successfully to ${stakingHelperAddress}`
      );
    } catch (error) {
      console.log("⚠ ERROR:", error);
      expect(error).toBe("");
    }
  });
});

describe("init step", () => {
  test("init node operator info", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
    };
    const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);

    // Prepare transaction details
    const code = getTxTemplate("init-node-operator-info", addressMap);
    const args = [
      [NODE_TYPE_COLLECTION, types.UInt8],
      [NODE_KEY, NODE_ADDRESS, types.String],
    ];
    const signers = [nodeOperator];

    try {
      const txStatus = await sendTransaction({ code, args, signers });
      console.log("Transaction executed succesfully");
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  test("read node operator info", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
    };

    const code = getTxTemplate("scripts/get-node-operator-info", addressMap);
    const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);
    const args = [[nodeOperator, types.Address]];

    try {
      const result = await executeScript({ code, args });
      expect(result.role).toBe(NODE_TYPE_COLLECTION);
      expect(result.networkingKey).toBe(NODE_KEY);
      expect(result.networkingAddress).toBe(NODE_ADDRESS);
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  test("init node operator capability holder", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
    };
    const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);

    // Prepare transaction details
    const code = getTxTemplate(
      "init-node-operator-capability-holder",
      addressMap
    );
    const signers = [nodeOperator];

    try {
      const txStatus = await sendTransaction({ code, signers });
      expect(txStatus.status).toBe(4);
      console.log("Transaction executed succesfully");
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  // TEST ABOUT PASS

  test("create new staking helper", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
    };
    const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);
    const tokenHolder = await getAccount(ACCT_TOKEN_HOLDER);

    // Prepare transaction details
    const code = getTxTemplate("init-staking-helper", addressMap);
    const args = [[nodeOperator, types.Address]];
    const signers = [tokenHolder];

    try {
      const txStatus = await sendTransaction({ code, args, signers });
      expect(txStatus.status).toBe(4);
      console.log("Transaction executed succesfully");
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
});
