// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AIModelMarketplace {
    struct AIModel {
        string name;
        string description;
        uint256 price;
        address payable creator;
        uint8 ratingCount;
        uint256 totalRating;
    }

    mapping(uint256 => AIModel) public models;
    uint256 public modelCount;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier validModel(uint256 modelId) {
        require(modelId < modelCount, "Model does not exist");
        _;
    }

    // List a new AI model
    function listModel(string memory name, string memory description, uint256 price) public {
        require(price > 0, "Price must be greater than zero");
        models[modelCount] = AIModel(name, description, price, payable(msg.sender), 0, 0);
        modelCount++;
    }

    // Purchase an AI model
    function purchaseModel(uint256 modelId) public payable validModel(modelId) {
        AIModel storage model = models[modelId];
        require(msg.value == model.price, "Incorrect payment amount");

        model.creator.transfer(msg.value);
    }

    // Rate an AI model
    function rateModel(uint256 modelId, uint8 rating) public validModel(modelId) {
        require(rating > 0 && rating <= 5, "Rating must be between 1 and 5");

        AIModel storage model = models[modelId];
        model.totalRating += rating;
        model.ratingCount++;
    }

    // Withdraw funds (only owner)
    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Get model details
    function getModelDetails(uint256 modelId) public view validModel(modelId) returns (
        string memory name,
        string memory description,
        uint256 price,
        address creator,
        uint256 averageRating
    ) {
        AIModel storage model = models[modelId];
        uint256 avgRating = model.ratingCount > 0 ? model.totalRating / model.ratingCount : 0;
        return (model.name, model.description, model.price, model.creator, avgRating);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
