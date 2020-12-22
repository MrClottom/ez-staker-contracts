// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

interface IHexTransferable is IERC721Enumerable {
    function totalIssuedTokens() external view returns (uint256);
    function stake(uint256 totalAmount, uint256 stakeDays, uint192 expectedFee)
        external returns (uint256);
    function unstake(uint256 tokenId) external;
    function getStakeIndex(uint256 tokenId) external view returns (uint256);
    function getTokenId(uint256 stakeIndex) external view returns (uint256);
}
