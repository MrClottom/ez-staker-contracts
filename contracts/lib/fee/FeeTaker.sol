// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './IFeeRecipient.sol';
import 'safe-qmath/contracts/SafeQMath.sol';


abstract contract FeeTaker is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IERC20 public mainToken;
    uint192 public fee;
    uint256 public collectedFees = 0;
    bool public sendFeeToOwner;

    event FeeSet(uint192 newFee);

    constructor(uint192 startFee, IERC20 mainToken_) {
        _setFee(startFee);
        mainToken = mainToken_;
    }

    modifier feeMatch(uint192 expectedFee) {
        require(expectedFee == fee, 'Fee has changed');
        _;
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        require(amount <= collectedFees, 'Insufficient funds available');

        collectedFees = collectedFees.sub(amount);
        mainToken.transfer(owner(), amount);
    }

    function setFee(uint192 newFee) external onlyOwner {
        _setFee(newFee);
    }

    function setSendFeeToOwner(bool sendFeeToOwner_) external onlyOwner {
        sendFeeToOwner = sendFeeToOwner_;
    }

    function _accountFee(uint256 collectedFee) internal {
        if (sendFeeToOwner) {
            mainToken.transfer(owner(), collectedFee);
            if (owner().isContract()) {
                IFeeRecipient(owner()).onFeeReceived(collectedFee);
            }
        } else {
            collectedFees = collectedFees.add(collectedFee);
        }
    }

    function _setFee(uint192 newFee) internal {
        require(newFee <= SafeQMath.ONE, 'Fee may not be higher than 100%');
        fee = newFee;
        emit FeeSet(newFee);
    }
}
