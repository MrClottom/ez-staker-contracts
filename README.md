# Ez Staker Contracts
Ez-Staker permits hex holders to tokenize their stakes upon staking.
Stakes are tokenized as ERC-721 tokens so they can be transfered and
used in other contracts/protocols. To unstake one must only own the minted
ERC-721 token. Once unstaked the token is burnt.

## Docs
These docs are for anyone wanting to integrate their DApp with the Ez-Staker
contracts. Ez-Staker is a smart contract building on top of the Hex contract so
some Hex utilities are included in this repo / package as well.


### 1 Installation
```
npm i ez-staker-contracts
```
This will install a node package containing abis, addresses and specific
javascript utility functions.

### 2 Contract Specs
#### 2.1 `HexTransferable.sol`
This is the main contract that does the staking and collects the fee. This
contract implements the standard `IERC721Enumerable` interface as documented
[here](https://docs.openzeppelin.com/contracts/3.x/api/token/erc721#IERC721Enumerable).
The address for this contract can be found in `utils` under the attribute
`addresses[network].ezStaker`
* `function stake(uint256 totalAmount, uint256 stakeDays, uint192 expectedFee)`

  This function stakes hex tokens for the `msg.sender` and mints an ERC-721
  token for the `msg.sender`. The token ID is equal to `stakesOpened` before calling
  `stake()`.

  In order for this function to complete successfully the following conditions
  must be met:
  * the `msg.sender` must have a hex balance equal to or greater than
  `totalAmount`
  * the `msg.sender`
  must have approved the contract address to spend an amount of hex greater than
  or equal to `totalAmount`
  * `expectedFee` must match the current `fee` of the contract.

  The expected fee is also passed as a parameter to avoid a race condition where
  the owner changes the fee before a `msg.sender` stakes. This would potentially
  mean taking a different cut then the `msg.sender` expected upon sending his
  transaction. The creation of new stakes may be prevented by the owner by
  setting the fee to a 100%.

  The fee is deducted from the `totalAmount`. If the fee is 1% for example and the
  `stakeAmount` is `800 HEX` the contract will only stake `792 HEX`. The
  `totalAmount` (minus the fee) and the `stakeDays` are then passed to the Hex
  contracts `stakeStart` function.

* `function unstake(uint stakeId)`

  This function ends the stake and sends the resulting hex to the unstaker.

  In order for this function to complete successfully the following condition
  must be met:

  * The `msg.sender` must be the owner of the ERC-721 with a token ID matching
  `stakeId`

  The unstake function can be called at anytime by the owner of the token, even
  to perform an emergency unstake. **All** the staking rewards are returned to
  the caller. No fee is deducted upon unstaking.

* `function fee() returns (uint192)`

  This function returns the current fee. The fee is a UQInt128.64 to convert the
  fee to a float simply divide the fee by `2^64`.

* `event FeeSet(uint192 newFee)`

  This event is emitted when the fee is changed. When the fee is set `newFee`
  will represent the new fee.

#### 2.2 `HexMock.sol`
This contract is deployed to testnets as it is only for testing purposes.
The address for this contract can be found in `utils` in the attribute
`addresses[network].hexMock`. This mock only provides the basic ERC20
functions as well as the minimum necessary methods to simulate the mainnet Hex
contract. Note this contract has `18` decimals instead of the `8` of mainnet
Hex.

* `function mint()` 

  mints `100 HEX` for the `msg.sender`. Anyone can call this function an unlimited
  amount of times.

* `function stake(uint256 newStakedHearts, uint256 newStakedDays)`

  creates a dummy stake which can instantly be unstaked. The unstake value is
  `2% / day` of the principal (non-compounding).
  `stakeReward = stakeAmount * (1 + 0.2 * stakeDays)`
