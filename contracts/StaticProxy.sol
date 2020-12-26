// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.1;

contract StaticProxy {
  /*
  keccak256 hash of "eip1967.proxy.implementation" - 1

  python code to generate:

  import sha3 
  print((int.from_bytes(sha3.keccak_256('eip1967.proxy.implementation'.encode()).digest(), 'big') - 1).to_bytes(32, 'big').hex())
  */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


  constructor(address implementation, bytes memory data) {
    assembly { sstore(IMPLEMENTATION_SLOT, implementation) }
    (bool success,) = implementation.delegatecall(data);
    require(success);
  }

  function getImplementation() public view returns (address implementation) {
    assembly { implementation := sload(IMPLEMENTATION_SLOT) }
  }

  fallback () payable external {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let implementation := sload(IMPLEMENTATION_SLOT)
      let res := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // check that delegatecall has not changed the address stored in the implementation slot
      let implAfterCall := sload(IMPLEMENTATION_SLOT)
      if iszero(eq(implementation, implAfterCall)) {
        invalid()
      }

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())


      switch res
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}
