// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import './IHex.sol';
import './lib/fee/FeeTaker.sol';
import './lib/fee/FeeMath.sol';

contract HexTransferable is ERC721, FeeTaker {
    using FeeMath for uint256;
    using SafeMath for uint256;

    IHex public hexToken;
    uint256 public stakesOpen;

    constructor(IHex hexToken_, uint192 startFee)
        FeeTaker(startFee, hexToken_)
        ERC721('crispy.finance tokenized Hex stakes', 'HXS')
    {
        hexToken = hexToken_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    function stake(uint256 totalAmount, uint256 stakeDays, uint192 expectedFee)
        external feeMatch(expectedFee)
    {
        hexToken.transferFrom(msg.sender, address(this), totalAmount);
        (uint256 stakeAmount, uint256 collectedFee) = totalAmount.splitToFee(expectedFee);

        _accountFee(collectedFee);
        _stake(stakeAmount, stakeDays);
    }

    function unstake(uint256 stakeId, uint256 stakeIndex) external {
        require(
            ownerOf(stakeId) == msg.sender,
            'Must own stake to unstake'
        );
        _burn(stakeId);

        uint256 unstakeReward = _unstake(stakeId, stakeIndex);
        hexToken.transfer(msg.sender, unstakeReward);
    }

    function _unstake(uint256 stakeId, uint256 stakeIndex) internal {
        uint256 balanceBefore = hexToken.balanceOf(address(this));

        hexToken.stakeEnd(stakeIndex, stakeId);

        uint256 balanceAfter = hexToken.balanceOf(address(this));

        return balanceAfter.sub(balanceBefore);
        hexToken.transfer(msg.sender, balanceAfter.sub(balanceBefore));
    }

    function _stake(uint256 stakeAmount, uint256 stakeDays) internal {
        require(stakeAmount > 0, 'Insufficient stake amount');
        require(stakeDays > 0, 'Insufficient stake days');

        hexToken.stakeStart(stakeAmount, stakeDays);
        (uint40 internalStakeId,,,,,,) = hexToken.stakeLists(
            address(this),
            stakesOpen++
        );
        _mint(msg.sender, internalStakeId);
    }
}
