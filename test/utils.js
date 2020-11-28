const { BN } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')

const expectEqualBN = (x, y, errorMsg) => assert.equal(x.toString(), y.toString(), errorMsg)

const weiBN = (ethVal) => web3.utils.toWei(new BN(ethVal))

const asBN = (x) => new BN(x.toString())

const expectTransfer = async (from, to, amount, transfer, getBalance) => {
  const beforeFromBalance = await getBalance(from)
  const beforeToBalance = await getBalance(to)

  await transfer()

  const afterFromBalance = await getBalance(from)
  const afterToBalance = await getBalance(to)

  expectEqualBN(beforeToBalance.add(amount), afterToBalance, 'amount not credited to recipient')
  expectEqualBN(
    beforeFromBalance.sub(amount),
    afterFromBalance,
    'amount not substracted from sender'
  )
}

const expectERC20Transfer = async (from, to, amount, tokenInstance) => {
  await expectTransfer(
    from,
    to,
    amount,
    async () => tokenInstance.transfer(to, amount, { from }),
    tokenInstance.balanceOf
  )
}

const repByte = (byte, n) => '0x'.concat(byte.repeat(n))

const zeroBytes = (n) => repByte('00', n)
const ffBytes = (n) => repByte('ff', n)

const ZERO_ADDRESS = zeroBytes(20)

module.exports = {
  asBN,
  ffBytes,
  repByte,
  zeroBytes,
  weiBN,
  expectEqualBN,
  expectTransfer,
  expectERC20Transfer,
  ZERO_ADDRESS
}
