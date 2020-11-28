// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract HexMock is ERC20 {
    using SafeMath for uint256;

    struct StakeStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    mapping(address => StakeStore[]) public stakeLists;

    constructor() ERC20('Hex token', 'HEX') {
        _mint(msg.sender, 50000 ether);
    }

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)
        external
    {
        require(
            balanceOf(msg.sender) >= newStakedHearts,
            'Insufficient balance'
        );
        _burn(msg.sender, newStakedHearts);

        StakeStore memory newStake;

        newStake.stakeId = uint40(stakeLists[msg.sender].length);
        uint256 toStakeHearts = newStakedHearts.mul(newStakedDays.mul(2).add(100)).div(100);
        require(toStakeHearts <= type(uint72).max, 'Overflow');
        newStake.stakedHearts = uint72(toStakeHearts);

        stakeLists[msg.sender].push(newStake);
    }

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external {
        require(
            stakeLists[msg.sender][stakeIndex].stakeId == stakeIdParam,
            'Invalid stake parameters'
        );

        _mint(msg.sender, stakeLists[msg.sender][stakeIndex].stakedHearts);
        stakeLists[msg.sender][stakeIndex].stakedHearts = 0;
    }
}
