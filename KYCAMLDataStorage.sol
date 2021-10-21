// source code is the sole property of swissrealty.io
// do not reproduce for commercial or non-commercial purposes

pragma solidity ^0.5.3;


/* This contract is implemented in order to store the value of our KYC AML
 * Smart contract. Our goal here is to push for safety of our data and users
 * by allowing us to update the logic around certain data without erasing the data
 * itself.
 */

contract KYCAMLDataStorage {

    address public owner;

    mapping(address => bool) internal KYCAMLStatus;
    mapping(address => bool) internal accessAllowed;
    mapping(address => bool) internal isTrustedOperator;
    mapping(address => bool) internal authorizedKYCAMLLogic;

    constructor() public {

        owner = msg.sender;

        KYCAMLStatus[owner] = true;
        accessAllowed[owner] = true;
        isTrustedOperator[owner] = true;
        authorizedKYCAMLLogic[owner] = true;

    }

    /* Set of functions to handle which contract is controlling the storage contract
     * the functions are the following:
     *  1) authorizeAddress(address _authorizedAddress)
     *  2) revokeAddress(address _revokedAddress)
     *  3) authorizedContract modifier
     */

    modifier authorizedContract() {
        require(authorizedKYCAMLLogic[msg.sender] == true, "Account not authorizes. Run through KYC/AML procedure.");
        _;
    }

    function authorizeAddress(address _authorizedAddress) public authorizedContract returns (bool) {
        require(_authorizedAddress != address(0), "Invalid address. Change to another one");
        require(msg.sender != _authorizedAddress, "You can't authorize your own address.");

        authorizedKYCAMLLogic[_authorizedAddress] = true;

        return true;
    }

    function revokeAddress(address _revokedAddress) public authorizedContract returns (bool) {
        require(_revokedAddress != address(0), "Invalid address. Change to another one.");
        require(msg.sender != _revokedAddress, "You can't revoke your own address");

        authorizedKYCAMLLogic[_revokedAddress] = false;

        return true;
    }

    /* Set of functions to handle variable returns for the logic contract
     * the functions are the following:
     *  1) checkStatus(addressChecked, requestor) => returns the KYC/AML Status of the addressChecked
     *  2) checkOperatorStatus(addressChecked) => returns the Trusted Operator Status of the addressChecked
     *  3) checkViewerStatus(addressChecked) => returns the Viewer Status of the addressChecked
     *  4) owner() returns the owner of the contract
     */

    function checkStatus(address _addressChecked) public authorizedContract view returns (bool) {
        return KYCAMLStatus[_addressChecked];
    }

    function checkOperatorStatus(address _addressChecked) public authorizedContract view returns (bool) {
        return isTrustedOperator[_addressChecked];
    }

    function checkViewerStatus(address _addressChecked) public authorizedContract view returns (bool) {
        return accessAllowed[_addressChecked];
    }

    function Owner() public view returns (address) {
        return owner;
    }

    /* Set of functions to change the state of certain variables in the DataStorage Contract
     * the functions are the following:
     *  1) setStatus(account, status) --> sets the status of the account on KYC/AML
     *  2) setOperatorStatus(operator, status) --> sets the status of the operator on the right to operate the contract variables
     *  3) setAccessStatus(account, status) --> sets the status of the viewer authorization for the viewer
     */

    function setStatus(address _account, bool _status) public authorizedContract returns (bool) {
        // sets the _account to the desired status
        KYCAMLStatus[_account] = _status;

        return true;
    }

    function setOperatorStatus(address _operator, bool _status) public authorizedContract returns (bool) {
        // sets status of the operator, can revoke it or make it active
        isTrustedOperator[_operator] = _status;
        setAccessStatus(_operator, _status);

        return true;
    }

    function setAccessStatus(address _viewer, bool _status) public authorizedContract returns (bool) {
        // sets status of the viewer, can revoke it or make it active
        accessAllowed[_viewer] = _status;

        return true;
    }

}
