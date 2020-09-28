import * as types from "@onflow/types";
import "../utils/config";
import { deployContract } from "../utils/deploy-code";
import { getTemplate } from "../utils/file";
import { getAccount, registerContract, getContractAddress } from "../rpc-calls";
import { sendTransaction } from "../utils/interaction";

const bpContract = "../../../contracts";
const bpTxTemplates = "../../../transactions";
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
const NODE_AWARD_CUT = 0.3;
const ACCT_NODE_OPERATOR = "node-operator";
const ACCT_TOKEN_HOLDER = "token-holder";

describe("deploy contracts", function () {
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

    const contractCode = getContractTemplate("FlowStakingHelper", {
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

describe("init capability holders", function () {
  test("init capability holders", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
    };
    const code = getTxTemplate(
      "stakingHelper/newFlow/init_capability_holder",
      addressMap
    );

    // Init CapabilityHolder for Token Holder account
    try {
      const tokenHolder = await getAccount(ACCT_TOKEN_HOLDER);
      const signers = [tokenHolder];
      const txStatus = await sendTransaction({ code, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }

    // Init CapabilityHolder for Node Operator Holder account
    try {
      const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);
      const signers = [nodeOperator];
      const txStatus = await sendTransaction({ code, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  test("create staking helper and store capability to it into node and token holder", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const IDTableStakingAddress = await getContractAddress(
      "Mock_FlowIDTableStaking"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
      FlowIDTableStaking: IDTableStakingAddress,
    };

    const tokenHolder = await getAccount(ACCT_TOKEN_HOLDER);
    const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);

    const code = getTxTemplate(
      "stakingHelper/newFlow/init_staking_helper",
      addressMap
    );
    const stakingKey = "---test---";
    const args = [
      [stakingKey, types.String],
      [tokenHolder, nodeOperator, types.Address],
    ];
    const signers = [tokenHolder];

    try {
      const txStatus = await sendTransaction({ code, args, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
  test("get capability by address", async () => {
    const flowStakingHelperAddress = await getContractAddress(
      "FlowStakingHelper"
    );
    const addressMap = {
      FlowStakingHelper: flowStakingHelperAddress,
    };
    const code = getTxTemplate(
      "stakingHelper/newFlow/get_capability_by_address",
      addressMap
    );

    const tokenHolder = await getAccount(ACCT_TOKEN_HOLDER);
    const nodeOperator = await getAccount(ACCT_NODE_OPERATOR);

    // Check Token Holder CapabilityHolder
    try {
      const args = [[nodeOperator, types.Address]];
      const signers = [tokenHolder];
      const txStatus = await sendTransaction({ code, args, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }

    // Check Node Operator CapabilityHolder
    try {
      const args = [[tokenHolder, types.Address]];
      const signers = [nodeOperator];
      const txStatus = await sendTransaction({ code, args, signers });
      console.log({ txStatus });
    } catch (e) {
      console.log(e);
      expect(error).toBe("");
    }
  });
});
