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

    uint256 private nonce;
    uint8 constant private DECIMALS = 8;

    mapping(address => StakeStore[]) public stakeLists;

    event StakeStart(
        uint256 data,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );

    constructor() ERC20('Mock tokens', 'HEX') {
        _mint(msg.sender, 50000 * 10**DECIMALS);
        _setupDecimals(DECIMALS);
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

        uint40 stakeId = uint40(bytes5(keccak256(
            abi.encodePacked(
                msg.sender,
                newStakedHearts,
                newStakedDays,
                nonce++
            )
        )));

        newStake.stakeId = stakeId;
        uint256 toStakeHearts = newStakedHearts.mul(newStakedDays.mul(2).add(100)).div(100);
        require(toStakeHearts <= type(uint72).max, 'Overflow');
        newStake.stakedHearts = uint72(toStakeHearts);

        stakeLists[msg.sender].push(newStake);

        emit StakeStart(
            uint256(uint40(block.timestamp))
                | (uint256(uint72(newStakedHearts)) << 40)
                | (uint256(uint72(toStakeHearts)) << 112)
                | (uint256(uint16(newStakedDays)) << 184),
            msg.sender,
            stakeId
        );
    }

    function _stakeRemove(StakeStore[] storage stakeList, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeList.length - 1;

        if (stakeIndex < lastIndex) stakeList[stakeIndex] = stakeList[lastIndex];
        require(stakeIndex <= lastIndex, 'something failed');

        stakeList.pop();
    }

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external {
        require(
            stakeLists[msg.sender].length > stakeIndex,
            'stakeIndex out of bounds'
        );
        require(
            stakeLists[msg.sender][stakeIndex].stakeId == stakeIdParam,
            'Invalid stake parameters'
        );

        _mint(msg.sender, stakeLists[msg.sender][stakeIndex].stakedHearts);

        _stakeRemove(stakeLists[msg.sender], stakeIndex);
    }

    function mint() external {
        _mint(msg.sender, 10000 * 10**DECIMALS);
    }

    function stakeCount(address owner) external view returns (uint256) {
        return stakeLists[owner].length;
    }
}
