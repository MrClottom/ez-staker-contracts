const { expectRevert, expectEvent, BN } = require('@openzeppelin/test-helpers')
const { convertFloatToUQInt, convertUQIntToFloat, withinError } = require('safe-qmath/utils')
const { hexToHearts, ffBytes, ZERO_ADDRESS } = require('./utils')
const { expect } = require('chai')

const HexMock = artifacts.require('HexMock')
const HexTransferable = artifacts.require('HexTransferable')

contract('HexTransferable', ([main1, main2, user1, user2, user3]) => {
  beforeEach(async () => {
    this.hexToken = await HexMock.new({ from: main1 })
    this.crispyStaker = await HexTransferable.new(
      this.hexToken.address,
      convertFloatToUQInt(0.003),
      { from: main2 }
    )
  })

  it('can stake, transfer and unstake', async () => {
    this.hexToken.mint({ from: user1 })

    const stakeAmount = 3000
    const stakeDays = 377
    const currentFee = await this.crispyStaker.fee()

    await this.hexToken.approve(this.crispyStaker.address, ffBytes(32), { from: user1 })

    const tokenId = new BN('0')
    expectEvent(
      await this.crispyStaker.stake(hexToHearts(stakeAmount), stakeDays, currentFee, {
        from: user1
      }),
      'Transfer',
      {
        from: ZERO_ADDRESS,
        to: user1,
        tokenId: tokenId
      }
    )

    expect(await this.hexToken.balanceOf(user1)).to.be.bignumber.equal(
      hexToHearts(10000 - stakeAmount),
      'Amount to stake not removed'
    )

    const owner = await this.crispyStaker.ownerOf(tokenId)
    expect(owner).to.equal(user1, 'Stake token minted to wrong address')

    await this.crispyStaker.safeTransferFrom(user1, user2, tokenId, { from: user1 })

    expect(await this.crispyStaker.ownerOf(tokenId)).equal(
      user2,
      'Stake token minted to wrong address'
    )

    await expectRevert(
      this.crispyStaker.unstake(tokenId, { from: user1 }),
      'Must own stake to unstake'
    )

    await this.crispyStaker.unstake(tokenId, { from: user2 })

    const resultingBalance = await this.hexToken.balanceOf(user2)
    expect(
      withinError(
        resultingBalance,
        hexToHearts(stakeAmount * (1 + 0.02 * stakeDays) * (1 - convertUQIntToFloat(currentFee)))
      ),
      'user2 didn\'t receive correct amount'
    ).to.be.true
  })

  it('can stake and unstake multiple', async () => {
    const stakeAmount = 3000
    const stakeDays = 377
    const currentFee = await this.crispyStaker.fee()

    await this.hexToken.mint({ from: user1 })

    const stake = async (addr, amount, days) => {
      await this.crispyStaker.stake(amount, days, currentFee, { from: addr })
      return (await this.crispyStaker.totalSupply()).sub(new BN('1'))
    }

    await this.hexToken.approve(this.crispyStaker.address, ffBytes(32), { from: user1 })

    const tokenId1 = await stake(user1, hexToHearts(stakeAmount), stakeDays * 1)
    const { stakeId: stakeId1 } = await this.hexToken.stakeLists(this.crispyStaker.address, '0')
    const tokenId2 = await stake(user1, hexToHearts(stakeAmount), stakeDays * 2)
    const { stakeId: stakeId2 } = await this.hexToken.stakeLists(this.crispyStaker.address, '1')
    const tokenId3 = await stake(user1, hexToHearts(stakeAmount), stakeDays * 3)
    const { stakeId: stakeId3 } = await this.hexToken.stakeLists(this.crispyStaker.address, '2')

    await this.crispyStaker.safeTransferFrom(user1, user2, tokenId1, { from: user1 })
    await this.crispyStaker.safeTransferFrom(user1, user3, tokenId2, { from: user1 })

    await this.crispyStaker.unstake(tokenId1, { from: user2 })

    expect(
      (await this.hexToken.stakeLists(this.crispyStaker.address, '0')).stakeId
    ).to.be.bignumber.equal(stakeId3, 'Mock failed to reshuffle')
    expect(await this.crispyStaker.getStakeIndex(tokenId3)).to.be.bignumber.equal(
      new BN('0'),
      'Transferable staker failed to reshuffle stakeIndex'
    )
    expect(await this.crispyStaker.getTokenId('0')).to.be.bignumber.equal(
      tokenId3,
      'Transferable staker failed to reshuffle tokenId'
    )

    await this.crispyStaker.unstake(tokenId3, { from: user1 })

    expect(
      (await this.hexToken.stakeLists(this.crispyStaker.address, '0')).stakeId
    ).to.be.bignumber.equal(stakeId2, 'Mock failed to reshuffle')
    expect(await this.crispyStaker.getStakeIndex(tokenId3)).to.be.bignumber.equal(
      new BN('0'),
      'Transferable staker failed to reshuffle stakeIndex'
    )
    expect(await this.crispyStaker.getTokenId('0')).to.be.bignumber.equal(
      tokenId2,
      'Transferable staker failed to reshuffle tokenId'
    )
  })
})
