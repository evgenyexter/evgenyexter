# Evgeny PhD based on the Steiner AG - Swiss Realty Project (Developer: Mikael Gross)

The Project is based on the Swiss Realty Token Repository

https://github.com/swissrealty/erc777-implementation/blob/master/README.md

# Real estate tokens
This repository will hold the set of smart contract for both the demo and the final product.
This repository is largely based on source code from https://github.com/0xjac/ERC777.

This repository will act as a storage for the smart contract that should be developed and tested on our local machine using:

http://truffleframework.com/

Needed:
* geth
* truffle
* ganache

## Dev

This set of smart contract is developed using an open source library of audited and safe smart contracts (openZeppelin).
The modifications and add-ins are managed by Mikael Gross @mGrossSRT

## Structure

The following structure represents our full set of smart contract in order to run the backend of our asset management solution:
@@ -30,7 +25,7 @@ The following structure represents our full set of smart contract in order to ru
* AssetSaleContract
* dataStorage

### General Structure
### Underlying infrastructure
* KYCAMLDataStorage
* KYCAMLContract

@@ -39,127 +34,4 @@ The following structure represents our full set of smart contract in order to ru

## Testing

In order to effectively test our set of smart contract, we should use the local blockchain generator from http://truffleframework.com/.
However, for earlier testing and devlopment it is adviced to use https://remix.ethereum.org/

In order to deploy and test our set of smart contract, we have put together the following:

### 1) Setup Ganache
* download from http://truffleframework.com/
* fire the app
* Open `truffle.js` file
* update the `localGanache` struct as required using information available in the Ganache main screen

### 2) Compile your smart contracts (if changes were applied in the code)
* in your folder root `sc-realty` run the command `truffle compile` in order to generate the ABIs
* if compilation is successful you will get the following message: `Writing artifacts to .\build\contracts`
* this is the location of your smart contracts ABIs and other relevant information for the migration

### 3) Setup the KYC/AML migration scripts
* using your terminal, go to the root folder `sc-realty`
* deploy the KYCAML storage using the following command: `truffle migrate --network localGanache -f 5 --to 5`
* save the KYC/AML storage contract number for later use
* in `6_KYCAMLContract_migration.js` replace the contract number by the one just generated
* deploy the KYCAML logic using the following command: `truffle migrate --network localGanache -f 6 --to 6`
* current cost in dev environment is approximately **0.18ETH**

### 4) Setup your Asset Storage migration scripts
* open `2_AssetStorage_migration.js` and change the variables that will define your Asset Token:

	````JavaScript
	// Setup the variables of the contract
	var AssetStorage = artifacts.require("../contracts/dataStorage.sol"); // do not touch
	var name = "NameofAsset"; // replace with the full name of the asset
	var symbol = "SymbolofToken"; // replace with the symbol of the token, usually a two to three letter long string 
	var granularity = 1; // default granularity to 1 meaning that 1 of the smallest value of ETH currency can buy it's equivalent in the token
	var totalSupply = 1000; // total supply of tokens
	var defaultOperators = ["0x3470Be6a62415F9081E1005A6C3c716fD7896EAc"]; // put here the account owning the token 
	````
* using your terminal, go to the root folder `sc-realty`
* deploy the asset storage using the following command: `truffle migrate --network localGanache -f 1 --to 2`. thid command will use the local development environment to deploy the Asset Storage contract
* you should get the following message in your terminal command line tool:
	````
	Running migration: 1_initial_migration.js
	  Deploying Migrations...
	  ... 0x6685990dbde06e85d2b93dcdf235a7e635377e43ec07428b45dd6ac9e0ff7fdc
	  Migrations: 0x42da1ea9fd548a4f404a7ad29e1d5bfdf6081cc7
	Saving artifacts...
	Running migration: 2_AssetStorage_migration.js
	  Replacing DataStorage...
	  ... 0x42a22f52f7597245cb4d8eb69677783ad9c5b11260c927e5b87f623a6bdacae2
	  DataStorage: 0x89f1d5bafe87da6dfcae760579604adaa59746e2
	Saving artifacts...
	````
* note that this data will also be available in the Ganache environment with the label contract creation
* current cost in dev environment is approximately **0.2ETH**

### 5) Setup your Asset logic migration script
* open `3_tokenSCs_migration.js` and change the variables that will link the token logic to the storage and kyc/aml logic
	````JavaScript
	// setup a few varible
	var Assetlogic = artifacts.require("../contracts/ERC777ERC20BaseToken.sol");
	var AssetStorageAddr = "0xf1675a86818bcb0ce929598e6fabafef69968f84";
	var KYCAMLLogicAddr = "0xf34132a8fc42b5fdee2b7ef6448027d43f390466";
	module.exports = function(deployer) {
	  deployer.deploy(Assetlogic, AssetStorageAddr, KYCAMLLogicAddr);
	};
	````
* migrate the contract using the command `truffle migrate --network localGanache -f 3 --to 3`
* cost in dev environment is approximately **0.4ETH**

### 6) Setup your Asset Sale migration script
* open `4_CrowdSale_migration.js` and change the variables where needed:
	````JavaScript
	// change variables for each deployment
	var AssetlogicX = artifacts.require("../contracts/CrowdsaleAsset.sol");
	var Wallet = "0x6404c1CECa2e3f02b6fead2D9c618faE05eb4F13";
	var AddressLogicContract = '0x2f6905aa4eb74836d8af69b0826bf5304c619800'
	module.exports = function(deployer) {
		deployer.deploy(AssetlogicX, Wallet, AddressLogicContract);
	};
	````
* migrate the contract using the command `truffle migrate --network localGanache -f 4 --to 4`
* cost in dev environment is approximately **0.11ETH**

#### Total deployment cost (25/02/2019)
* KYC/AML: 0.18ETH at current rate 24.7CHF
* Individual Token: 0.71ETH at current rate 97.3CHF
* Total cost of operation 122CHF (0.89ETH)

### 7) Authorize contracts
In order for the contracts to be operational, a few things need to happen on the blockchain.
1) KYC/AML logic has to be authorized on the KYC/AML storage contract by the deployer of the KYC/AML storage contract
2) Asset Logic contract needs to be authorized on the Asset Storage contract by the deployer of the Asset Storage contract
3) Asset Sale contract needs to be authorized on the Asset Logic contract by the deployer of the Asset Storage contract
4) All tokens have to be manageable by the Asset Sale contract that wil perform the transfers from the owner of the Asset Storage contract to the beneficiary (people that buy tokens)
5) Asset Logic has to be authorized as a viewer on the KYC/AML Logic contract running the function `modifyViewer(address _addressAdded, bool _status, string _message)` from the deployer of the KYC/AML Storage contract

To do that, we have to do the following:

#### 1) Connect to the JavaScript command line of your local blockchain
* check the geth version on your computer with `geth version`
* if geth is unavailable install it, google is a good source of knowledge on how to install geth
* in your command line terminal run: `geth attach http://127.0.0.1:7545` where `127.0.0.1` should be replaced by your host name and `7545` by your port number, this will start an instance of the geth javascript command line linked to our local test blockchain

#### 2) Unlock your "Owner" or "Deployer" account
* type `eth.accounts` to get an overview of all the accounts available
* type `personal.unlockAccount(eth.accounts[0],"",300000)`
	* change `eth.accounts[0]` to any number in order to match the desired account from the `eth.accounts` list
	* the `""` is the password, for the Ganache development framework all password are empty strings in order to facilitate development
	* change `300000` to your desired number of seconds to unlock the account. `300000` will give youa good 84 hours to go :)

#### 3) Build your contracts variables
In order to interract with any contract on your blockchain (local or decentralized), you will need to establish a connection to a specific contract. You do that by typing something similar to this `eth.contract(abi).at("contractNumber")`. after this you can easily trigger any functions/variables on this contract to perform state changes and/or see variables.
* build your contract variable: type `var KYCAMLStorage = eth.contract("abi").at("ContractNumber")`. replace abi by the contract abi and contract number by the contract number. It is recommended to save the abi in a file in order to easy access it.
* Do the same for `KYCAMLLogic`, `AssetStorage`, `AssetLogic` and `AssetSale`
* you are now ready to perform the contracts authorization

#### 4) Run your authorizations on the chain from the owner account
The goal of this step is to authorize contracts to operate on each other and calling functions accross them.
Our smart contracts relations are the following:
* `AssetStorage.allowAccess("assetLogicContractNumber")`: Authorizes token logic to work on the token storage
* `AssetLogic.approve("assetSaleContractNumber", totalSupply)`: Authorizes token sales to transfer from the owner account tokens
* `KYCAMLStorage.authorizeAddress("KYCAMLLogicContractNumber")`: Authorizes the KYC/AML Logic to interract with the storage
* `KYCAMLLogic.modifyViewer("assetSaleContractNumber", true, "Custom message")`: Authorizes the asset sale contract to check on teh KYC/AML contract for account KYC/AML Status

#### 5) Run you test scripts
In addition to the tests built in the original ERC777 repository, we have implemented new cases available in the test directory.
