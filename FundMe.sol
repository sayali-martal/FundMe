// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

// Import from chainlink
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // For uint wrapping
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    // Get called the moment contract is deployed
    constructor() public {
        owner = msg.sender;
    }

    // Accept the payment
    function fund() public payable {
        // Set minimum value
        uint256 minimumUsd = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUsd, "Need minimum $50 ETH to complete the transaction");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Get version of AggregatorV3Interface
    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    // ETH -> USD conversion rate
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // Price in WEI
        return uint256(answer * 10000000000);
    }

    // Convert ETH -> USD 
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        // Both ethPrice and EthAmount has 10^18 taggedto it
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        // Runs function wherever underscore is present
        _;
    }

    // Send to only owner
    function withdraw() payable onlyOwner public {
        // Transfers the amount
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // Reset funder array
        funders = new address[](0);
    }
}
