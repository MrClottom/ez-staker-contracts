const { expectRevert, expectEvent, BN } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')
const { expectEqualBN, expectTransfer, weiBN, ffBytes, ZERO_ADDRESS, asBN } = require('./utils')

const HexTransferable = artifacts.require('HexTransferable')
const HexMock = artifacts.require('HexMock')

const roundAccurately = (x, dec) => {
  return Number(Math.round(x + 'e' + dec) + 'e-' + dec)
}

contract('HexTransferable', ([main1, main2, user1, user2]) => {
  it('can open and transfer stake', async () => {
    // setup
    const FEE_FACTOR = 2 ** 64
    let fee = 0.001
    const hexToken = await HexMock.new({ from: main1 })
    const hexTransferable = await HexTransferable.new(hexToken.address, asBN(fee * FEE_FACTOR), {
      from: main2
    })
    await hexToken.transfer(user1, weiBN(100), { from: main1 })
    await hexToken.approve(hexTransferable.address, ffBytes(32), { from: user1 })

    const stakeAmount = 80
    expectEvent(
      await hexTransferable.stake(weiBN(stakeAmount), 10, asBN(fee * FEE_FACTOR), { from: user1 }),
      'Transfer',
      {
        from: ZERO_ADDRESS,
        to: user1,
        tokenId: '0'
      }
    )
    expectEvent(
      await hexTransferable.safeTransferFrom(user1, user2, '0', { from: user1 }),
      'Transfer',
      {
        from: user1,
        to: user2,
        tokenId: '0'
      }
    )
    await expectRevert(
      hexTransferable.unstake('0', { from: user1 }),
      'Must own tokenized stake to unstake'
    )
    await hexTransferable.unstake('0', { from: user2 })

    const expectedFee = stakeAmount * fee
    const collectedFees = web3.utils.fromWei(await hexTransferable.collectedFees())
    assert.equal(
      roundAccurately(expectedFee, 7),
      roundAccurately(collectedFees, 7),
      'wrong fee collected'
    )

    expectTransfer(
      hexTransferable.address,
      main2,
      expectedFee,
      () => hexTransferable.withdrawFee(expectedFee),
      hexToken.balanceOf
    )
  })
})
