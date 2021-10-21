// source code is the sole property of swissrealty.io
// do not reproduce for commercial or non-commercial purposes

// solhint-disable-next-line compiler-fixed
pragma solidity ^0.5.3;

import { KYCAMLDataStorage } from "./KYCAMLDataStorage.sol";

/* This contract is designed to store the staus of a specific address
 * regarding its KYC/AML status on Swiss Realty's investment platform.
 * It can be operated by Trusted Addresses and viewed only by addresses
 * authorized to do so. All teh relevant documentation and rights will
 * be stored off-chain. This contract should act as a central repository for Swiss Realty.
 */
contract KYCAMLContract {

    // shows what addresses have been modified by who, the status is kept private
    event StatusModified(address indexed _addressChecked, address indexed _operator);
    // emits when a trusted operator is recorded in our contract --> message to record the name of the institution
    event TrustedOperatorStatus(address indexed _operatorAddress, bool _status, address indexed _modifierAddress, string _message);
    // same as before
    event AuthorizedViewerStatus(address indexed _addressAdded, bool _status, address indexed _modifierAddress, string _message);

    KYCAMLDataStorage DataStorage;

    constructor(address _KycAmlDataStorageContract) public {

        DataStorage = KYCAMLDataStorage(_KycAmlDataStorageContract);

    }

    /* Function to check the status of a certain account against our storage of KYC/AML status
     * This function will return a boolean to be interpreted as follows:
     *  1) true --> the account checked for has passed our KYC/AML
     *  2) false --> the account checked for has not passed our KYC/AML
     */

    function checkStatus(address _address) public view returns (bool) {
        checkViewerAuth(msg.sender, _address);
        bool status = DataStorage.checkStatus(_address);
        return status;
    }

    function checkOperator(address _addressChecked) public view returns (bool) {
        bool status = DataStorage.checkOperatorStatus(_addressChecked);
        return status;
    }

    function checkViewer(address _addressChecked) public view returns (bool) {
        bool status = DataStorage.checkViewerStatus(_addressChecked);
        return status;
    }

    function checkOwner() public view returns (address) {
        address owner = DataStorage.owner();
        return owner;
    }

    /* Allows Trusted Operators to change the status of a KYC/AML procedure for a certain account.
     * Only two status can be recorded: true (successful procedure) or false (procedure not started/ongoing).
     * In the front end, it is very easy to extend the status available to the user by doing the following:
     * 1) When a user starts submitting documents and information, we can check on the chain and see that his KYC
     * status is still on false so if(documentsSubmitted && false) --> Procedure started by the user
     * 2) When a user has successfully submitted all the documents but they were not reviewed yet, we can
     * mark the status as --> Being assessed / in evaluation
     */

    function modifyStatus(address _addressChecked, bool _status) public returns (bool) {

        preValidation(_addressChecked, _status);
        checkOperatorAuth(msg.sender);

        // Sets the status of the _addressChecked to the _status (can be true or false)
        DataStorage.setStatus(_addressChecked, _status);

        // emits an event on the chain for tracking purposes
        emit StatusModified(_addressChecked, msg.sender);

        // returns true because it was successful
        return true;
    }

    /* Adds or remove a Trusted Operator on the list of Trusted Operators. Trusted Operators can validate
     * KYC/AML for any Ethereum addresses, expect the Owner's and their's
     */

    function modifyOperator(address _addressAdded, bool _status, string memory _message) public returns (bool) {

        preValidation(_addressAdded, _status);
        checkIfOwner(msg.sender);

        bool transactionReceipt = DataStorage.setOperatorStatus(_addressAdded, _status);
        if (transactionReceipt == true) {
            emit TrustedOperatorStatus(_addressAdded, transactionReceipt, msg.sender, _message);
            return true;
        } else {
            return false;
        }

    }

    /* Adds or remove a viewer on the contract. Authorized Viewers are able to check the KYC/AML status
     * of any Ethereum addresses against our central registry
     */

    function modifyViewer(address _addressAdded, bool _status, string memory _message) public returns (bool) {

        preValidation(_addressAdded, _status);
        checkOperatorAuth(msg.sender);

        // sets the status of the address in question to the desired state (true or false) by the Truested Operator
        DataStorage.setAccessStatus(_addressAdded, _status);

        // emits an event to the chain to update
        emit AuthorizedViewerStatus(_addressAdded, _status, msg.sender, _message);

        return true;
    }

    /* Helper function validate accounts and check authorizations in order to see, modify and access
     * certain functions in our KYC/AML contracts
     */

    function preValidation(address _addressChecked, bool _status) internal view {
        require(_addressChecked != DataStorage.owner(), "Can't revoke the Operator status of the owner.");
        require(_addressChecked != msg.sender, "Can't modify your own status.");
        require(_status == true || _status == false, "Do not assign another value than true or false");
    }

    function checkOperatorAuth(address _addressChecked) internal view {
        require(DataStorage.checkOperatorStatus(_addressChecked) == true, "Your account is not an operator.");
    }

    function checkViewerAuth(address _sender, address _addressChecked) internal view {
        require(
            DataStorage.checkViewerStatus(_sender) == true ||
            _sender == _addressChecked,
            "Your account is not a viewer.");
    }

    function checkIfOwner(address _addressChecked) internal view {
        require(DataStorage.owner() == _addressChecked, "Your account is not the owner.");
    }
}
