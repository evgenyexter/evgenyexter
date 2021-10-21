// source code is the sole property of swissrealty.io
// do not reproduce for commercial or non-commercial purposes

pragma solidity ^0.5.3;


import { ERC20Token } from "./ERC20Token.sol";
import { ERC777BaseToken } from "./ERC777BaseToken.sol";
import { DataStorage } from "./DataStorage.sol";
import { KYCAMLContract } from "./KYCAMLContract.sol";


contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {

    // setting up contract dependencies
    DataStorage DS;
    KYCAMLContract KAM;

    bool internal erc20compatible;

    constructor(
        address _dataStorageAddress,
        address _KYCAMLContractAddress
    ) public ERC777BaseToken(_dataStorageAddress) {

            // Define the contracts external dependencies
            DS = DataStorage(_dataStorageAddress);
            KAM = KYCAMLContract(_KYCAMLContractAddress);

            // Shift to false if we do not want backwards compatibility with ERC20
            erc20compatible = true;

            // steInterfaceImplementation would technically register the token in ERC820
            // in order to comply with the cenral repo aproach
            // setInterfaceImplementation("ERC20Token", address(this));
    }

    /// @notice This modifier is applied to erc20 obsolete methods that are
    /// implemented only to maintain backwards compatibility. When the erc20
    /// compatibility is disabled, this methods will fail.
    modifier erc20 () {
        require(
            erc20compatible,
            "This contract is not compatible with erc20."
        );
        _;
    }

    /// @notice this modifier is applied in function that need to have
    /// users having passed KYC/AML procedures
    modifier authorizedAccounts() {
        // check status of the msg.sender
        bool status = KAM.checkStatus(msg.sender);
        require(
            status == true,
            "This account is not authorized. Run through KYC/AML procedures."
        );
        _;
    }

    /// @notice modifier checking if issuer of the message is the owner of the asset
    /// bwing sold
    modifier onlyOwner() {
        address owner = DS.getOwner();
        require(
            owner == msg.sender,
            "Function reserved to the owner of the asset being sold."
        );
        _;
    }

    /// set the rate at which eth are giving tokens
    function setRate(uint256 _rate) public returns (bool _success) {
        return DS.setRate(_rate);
    }

    // RETURN FUNCTIONS
    /// @notice For Backwards compatibility
    /// @return The decimals of the token. Forced to 18 in ERC777.
    function decimals() public erc20 view returns (uint8) { return uint8(18); }

    /// @notice requests the name from the storage contract
    /// @return The name of the token as suggested in the name of the interface :)
    function name() public view returns (string memory) { return DS.name(); }

    /// @notice requests the symbol from the storage contract
    /// @return The symbol of the token as suggested in the name of the interface :)
    function symbol() public view returns (string memory) { return DS.symbol(); }

    /// @notice requests the totalSupply from the storage contract
    /// @return The total supply of the token as suggested in the name of the interface :)
    function totalSupply() public view returns (uint256) { return DS.totalSupply(); }

    /// @notice requests the token rate from the storage contract
    /// @return The rate of the token
    function getRate() public view returns (uint256) { return DS.getRate(); }

    /// @notice requests the token rate from the storage contract
    /// @return The rate of the token
    function getOwner() public view returns (address) { return DS.getOwner(); }

    /// @notice requests the balance of a certain address
    /// @param _tokenHolder the address of the actual token holder from which we request the balance
    /// @return the balance of the specified address
    function balanceOf(address _tokenHolder) public view returns (uint256) {
        return DS.balanceOf(_tokenHolder);
    }


    // SETTER FUNCTIONS
    /// @notice ERC20 backwards compatible transfer.
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transfer(address _to, uint256 _amount) public erc20 authorizedAccounts returns (bool success) {
        require (
            KAM.checkStatus(_to) == true,
            "The account is not authorized to run the transaction."
        );
        doSend(
            msg.sender,
            msg.sender,
            _to,
            _amount,
            "",
            "",
            false
        );
        return true;
    }

    /// @notice ERC20 backwards compatible transferFrom.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 authorizedAccounts returns (bool success) {
        require(_amount <= DS.checkAllowance(_from, msg.sender), "Not allowed to transfer this amount. Needs to be lower.");

        // Cannot be after doSend because of tokensReceived re-entry
        DS.setAllowance(_from, msg.sender, _amount);
        doSend(
            msg.sender,
            _from,
            _to,
            _amount,
            "",
            "",
            false
        );
        return true;
    }

    /// @notice ERC20 backwards compatible approve.
    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    /// @return `true`, if the approve can't be done, it should fail.
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        DS.setAllowance(msg.sender, _spender, _amount);
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice ERC20 backwards compatible allowance.
    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        remaining = DS.checkAllowance(_owner, _spender);
        return remaining;
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _userData,
        bytes memory _operatorData,
        bool _preventLocking
    ) internal {
        super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
        if (erc20compatible) {emit Transfer(_from, _to, _amount);}
    }

    function doBurn(
        /* address _operator,*/
        address _tokenHolder,
        uint256 _amount
        // bytes memory _holderData,
        // bytes memory _operatorData
    ) internal {
        // super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
        if (erc20compatible) {emit Transfer(_tokenHolder, address(0), _amount);}
    }
}
