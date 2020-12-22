// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import './IHex.sol';
import './lib/fee/FeeTaker.sol';
import './lib/fee/FeeMath.sol';
import './IHexTransferable.sol';

contract HexTransferable is IHexTransferable, ERC721, FeeTaker {
    using FeeMath for uint256;
    using SafeMath for uint256;

    IHex public hexToken;

    uint256 public override totalIssuedTokens;

    // two-way mapping of hex stake indices to tokenId
    mapping(uint256 => uint256) internal _tokenIdToStakeIndex;
    mapping(uint256 => uint256) internal _stakeIndexToTokenId;

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
        external
        override
        feeMatch(expectedFee)
        returns (uint256)
    {
        hexToken.transferFrom(msg.sender, address(this), totalAmount);
        (uint256 stakeAmount, uint256 collectedFee) = totalAmount.splitToFee(expectedFee);

        _accountFee(collectedFee);
        return _stake(stakeAmount, stakeDays);
    }

    function unstake(uint256 tokenId) external override {
        require(
            ownerOf(tokenId) == msg.sender,
            'Must own stake to unstake'
        );

        uint256 stakeIndex = getStakeIndex(tokenId);
        (uint40 stakeId,,,,,,) = hexToken.stakeLists(address(this), stakeIndex);

        _burn(tokenId);
        _unstake(stakeIndex, stakeId);
    }

    function getStakeIndex(uint256 tokenId) public override view returns (uint256) {
        return _tokenIdToStakeIndex[tokenId];
    }

    function getTokenId(uint256 stakeIndex) public override view returns (uint256) {
        return _stakeIndexToTokenId[stakeIndex];
    }

    function _stake(uint256 stakeAmount, uint256 stakeDays)
        internal
        returns (uint256)
    {
        uint256 newTokenId = totalIssuedTokens++;
        _tokenIdToStakeIndex[newTokenId] = totalSupply();
        _stakeIndexToTokenId[totalSupply()] = newTokenId;

        _mint(msg.sender, newTokenId);
        hexToken.stakeStart(stakeAmount, stakeDays);

        return newTokenId;
    }

    function _unstake(uint256 stakeIndex, uint40 stakeId) internal {
        uint256 balanceBefore = hexToken.balanceOf(address(this));
        hexToken.stakeEnd(stakeIndex, stakeId);
        uint256 balanceAfter = hexToken.balanceOf(address(this));

        uint256 unstakeReward = balanceAfter - balanceBefore;
        hexToken.transfer(msg.sender, unstakeReward);

        if (stakeIndex != totalSupply()) {
            uint256 topTokenId = getTokenId(totalSupply());
            _tokenIdToStakeIndex[topTokenId] = stakeIndex;
            _stakeIndexToTokenId[stakeIndex] = topTokenId;
        }
    }
}
