package templates

import "github.com/onflow/flow-core-contracts/lib/go/templates/internal/assets"

const (
	stakingHelperCreateNew = "stakingHelper/create_staking_helper.cdc"
	stakingHelperAbort = "stakingHelper/abort_staking_request.cdc"
	stakingHelperTransferTokens = "stakingHelper/transfer_tokens.cdc"
	stakingHelperUnbondStake = "stakingHelper/unbond_stake.cdc"
	stakingHelperWithdrawRewards = "stakingHelper/withdraw_rewards.cdc"
)

func GenerateCreateNewStaker(ftAddr, stakingHelperAddr string) []byte {
	code := assets.MustAssetString(filePath + stakingHelperCreateNew)

	return []byte(ReplaceAddresses(code, ftAddr, "","", stakingHelperAddr))
}