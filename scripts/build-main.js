#!/usr/bin/env node

;(() => {
  const fs = require('fs')

  const loadJson = (fp) => {
    return JSON.parse(fs.readFileSync(fp, { encoding: 'utf8', flag: 'r' }))
  }

  const targetContracts = ['IHex', 'IFeeRecipient', 'HexTransferable', 'HexMock']

  targetContracts.forEach((target) => {
    const { contractName, abi } = loadJson(`./build/contracts/${target}.json`)

    fs.writeFileSync(
      `./abis/${target}.json`,
      JSON.stringify({
        contractName,
        abi
      })
    )
  })
})()
