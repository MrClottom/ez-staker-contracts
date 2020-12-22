const { BN } = require('@openzeppelin/test-helpers')
const { expect } = require('chai')
const { hexToHearts } = require('./utils')

const HexMock = artifacts.require('HexMock')

contract('HexMock', ([main, user1]) => {
  beforeEach(async () => {
    this.hexToken = await HexMock.new({ from: main })
  })

  it('can stake and unstake', async () => {
    const amount = hexToHearts(1000)
    await this.hexToken.transfer(user1, amount, { from: main })

    await this.hexToken.stakeStart(hexToHearts(700), 177, { from: user1 })

    expect(await this.hexToken.stakeCount(user1)).to.be.bignumber.equal(
      new BN('1'),
      'expected user1 to have exactly 1 stake'
    )

    const { stakeId } = await this.hexToken.stakeLists(user1, 0)
    const balanceBeforeUnstake = await this.hexToken.balanceOf(user1)
    await this.hexToken.stakeEnd(0, stakeId, { from: user1 })
    const balanceAfterUnstake = await this.hexToken.balanceOf(user1)
    expect(balanceAfterUnstake.sub(balanceBeforeUnstake)).to.be.bignumber.above(
      new BN('0'),
      'no tokens received after unstake'
    )
  })

  it('can simulate multiple stakes', async () => {
    await this.hexToken.mint({ from: user1 })

    const stake = async (amount) => {
      await this.hexToken.stakeStart(amount, 300, { from: user1 })
      const stakeCount = await this.hexToken.stakeCount(user1)
      const stakeIndex = stakeCount.sub(new BN('1'))
      const { stakeId } = await this.hexToken.stakeLists(user1, stakeIndex)

      return stakeId
    }

    const checkUnstake = async (unstake) => {
      const balanceBeforeUnstake = await this.hexToken.balanceOf(user1)
      await unstake()
      const balanceAfterUnstake = await this.hexToken.balanceOf(user1)
      expect(balanceAfterUnstake.sub(balanceBeforeUnstake)).to.be.bignumber.above(
        new BN('0'),
        'no tokens received after unstake'
      )
    }

    const stake1 = await stake(hexToHearts(1000))
    const stake2 = await stake(hexToHearts(3000))
    const stake3 = await stake(hexToHearts(6000))

    await checkUnstake(() => this.hexToken.stakeEnd(new BN('0'), stake1, { from: user1 }))

    let { stakeId } = await this.hexToken.stakeLists(user1, 0)
    expect(stakeId).to.be.bignumber.equal(stake3, 'invalid reshuffeling')

    await checkUnstake(() => this.hexToken.stakeEnd(0, stake3, { from: user1 }))

    stakeId = (await this.hexToken.stakeLists(user1, 0)).stakeId
    expect(stakeId).to.be.bignumber.equal(stake2, 'invalid reshuffeling')
  })
})
