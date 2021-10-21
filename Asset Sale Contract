// source code is the sole property of swissrealty.io
// do not reproduce for commercial or non-commercial purposes

pragma solidity ^0.5.0;


// import the relevant contracts used in the Asset Sale Contract
import { ERC777ERC20BaseToken } from "./ERC777ERC20BaseToken.sol";
import { safeMath } from "./safeMath.sol";
import { KYCAMLContract } from "./KYCAMLContract.sol";


contract AssetSaleContract {

    using safeMath for uint256;

    ERC777ERC20BaseToken Asset; // The token being sold
    KYCAMLContract KYCAML; // Swiss Realty's KYC/AML contract

    address payable public wallet; // Address where funds are collected
    uint256 public rate; // How many token units a buyer gets per wei
    uint256 public weiRaised; // Amount of wei raised

    event AssetPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount); // log a token purchase
    event AssetSaleStarted(address _by, uint256 _time); // event of the Asset Sale launch

    constructor(
        address payable _wallet,
        address _tokenContract,
        address _kycamlContract
    ) public payable {
        require(_wallet != address(0), "The wallet is invalid, please enter a new account");
        require(_tokenContract != address(0), "The token contract is invalid, please change the address");

        Asset = ERC777ERC20BaseToken(_tokenContract);
        KYCAML = KYCAMLContract(_kycamlContract);
        wallet = _wallet;


        require(msg.sender == Asset.getOwner(), "You try to deploy an asset with a different account than the owner of it. Please switch.");

        emit AssetSaleStarted(wallet, block.timestamp);

    }

    modifier modify() {
        require(msg.sender == Asset.getOwner(), "To modify a value you need to be the asset owner.");
        _;
    }

    function newRate(uint256 _rate) public modify returns (bool) {
        require(Asset.getRate() > 0, "New rate is invalid, pleas specify a value greater than 0");
        Asset.setRate(_rate);

        return true;

    }

    function getRate() public view returns (uint256 _rate) {
        _rate = Asset.getRate();
        return _rate;
    }

    function () external payable {

        buyTokens(msg.sender);

    }

    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;

        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        rate = getRate();
        uint256 tokens = _getTokenAmount(weiAmount, rate);

        _processPurchase(_beneficiary, tokens);

        emit AssetPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _forwardFunds();

        // update state
        weiRaised = weiRaised.add(weiAmount);

    }

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(getRate() > 0, "The rate is 0 or less. Change the rate to a value superior than 0.");
        require(_beneficiary != address(0), "The address specified as the beneficiary is invalid, please restart using a valid address.");
        require(_weiAmount != 0, "The transaction amount is of 0. Change to superior than 0 amount.");
        if (_beneficiary == msg.sender) {
            require(KYCAML.checkStatus(_beneficiary) == true, "The beneficiary account is not verified. Run through KYC/AML.");
        } else {
            require(KYCAML.checkStatus(_beneficiary) == true, "The beneficiary account is not verified. Run it through KYC/AML.");
            require(KYCAML.checkStatus(msg.sender) == true, "The message sender account is not verified. Run through KYC/AML.");
        }
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        Asset.transferFrom(returnOwner(), _beneficiary, _tokenAmount);
    }


    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */

    function _getTokenAmount(uint256 _weiAmount, uint256 _rate) internal pure returns (uint256) {
        return _weiAmount.div(_rate);
    }


    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /**
    *  @dev Returns Account managing the crowdsale, the storage and the tokens
    */

    function returnOwner() public view returns (address) {
        return Asset.getOwner();
    }

    /**
    *  @dev Returns totalSupply managing the crowdsale, the storage and the tokens
    */

    function _totalSupply() public view returns (uint256) {
        return Asset.totalSupply();
    }

    /**
    *  @dev Returns available supply
    */

    function availableSupply() public view returns (uint256) {
        // get the balance of the owner of the contract as all the tokens were wired to this account in the first place
        return Asset.balanceOf(returnOwner());
    }

}
