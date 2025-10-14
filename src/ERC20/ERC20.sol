// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { LibERC20 } from "./libraries/LibERC20.sol";

contract ERC20 {

    // ERC-6093: Custom errors for ERC-20
    error ERC20InsufficientBalance(address _sender, uint256 _balance, uint256 _needed);
    error ERC20InvalidSender(address _sender);
    error ERC20InvalidReceiver(address _receiver);
    error ERC20InsufficientAllowance(address _spender, uint256 _allowance, uint256 _needed);
    error ERC20InvalidApprover(address _approver);
    error ERC20InvalidSpender(address _spender);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    function name() external view returns (string memory) {
        return LibERC20.getStorage().name;
    }

    function symbol() external view returns (string memory) {
        return LibERC20.getStorage().symbol;
    }

    function decimals() external view returns (uint8) {
        return LibERC20.getStorage().decimals;
    }

    function totalSupply() external view returns (uint256) {
        return LibERC20.getStorage().totalSupply;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return LibERC20.getStorage().balanceOf[_account];
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return LibERC20.getStorage().allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) external {
        LibERC20.ERC20Storage storage s = LibERC20.getStorage();
        if (_spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        s.allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);    
    }

    function transfer(address _to, uint256 _value) external {
        LibERC20.ERC20Storage storage s = LibERC20.getStorage();
        if (_to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        uint256 fromBalance = s.balanceOf[msg.sender];
        if (fromBalance < _value) {
            revert ERC20InsufficientBalance(msg.sender, fromBalance, _value);
        }
        unchecked {
            s.balanceOf[msg.sender] = fromBalance - _value;
            s.balanceOf[_to] += _value;
        }
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external {
        LibERC20.ERC20Storage storage s = LibERC20.getStorage();
        if (_from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (_to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        uint256 currentAllowance = s.allowances[_from][msg.sender];
        if (currentAllowance < _value) {
            revert ERC20InsufficientAllowance(msg.sender, currentAllowance, _value);
        }
        uint256 fromBalance = s.balanceOf[_from];
        if (fromBalance < _value) {
            revert ERC20InsufficientBalance(msg.sender, fromBalance, _value);
        }
        unchecked {
            s.allowances[_from][msg.sender] = currentAllowance - _value;
            s.balanceOf[_from] = fromBalance - _value;
            s.balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
    }    
    
    function burn(uint256 _value) external {
        LibERC20.ERC20Storage storage s = LibERC20.getStorage();
        uint256 balance = s.balanceOf[msg.sender];
        if (balance < _value) {
            revert ERC20InsufficientBalance(msg.sender, balance, _value);
        }
        unchecked {
            s.balanceOf[msg.sender] = balance - _value;
        }
        emit Transfer(msg.sender, address(0), _value);
    }

    function burnFrom(address _account, uint256 _value) external {
        LibERC20.ERC20Storage storage s = LibERC20.getStorage();
        uint256 currentAllowance = s.allowances[_account][msg.sender];
        if (currentAllowance < _value) {
            revert ERC20InsufficientAllowance(msg.sender, currentAllowance, _value);
        }
        uint256 balance = s.balanceOf[_account];
        if (balance < _value) {
            revert ERC20InsufficientBalance(_account, balance, _value);
        }
        unchecked {
            s.allowances[_account][msg.sender] = currentAllowance - _value;
            s.balanceOf[_account] = balance - _value;
        }        
        emit Transfer(msg.sender, address(0), _value);
    }


}
