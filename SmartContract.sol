// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AIModelMarketplace {
    struct Model {
        string name;
        string description;
        uint256 price;
        address payable creator;
        uint8 ratingCount;
        uint256 totalRating;
    }

    uint256 public modelCount;
    mapping(uint256 => Model) public models;
    mapping(address => mapping(uint256 => bool)) public purchasedModels;

    event ModelListed(uint256 modelId, string name, address creator, uint256 price);
    event ModelPurchased(uint256 modelId, address buyer);
    event ModelRated(uint256 modelId, uint8 rating, address rater);

    modifier onlyCreator(uint256 modelId) {
        require(msg.sender == models[modelId].creator, "Not the creator of this model");
        _;
    }

    function listModel(string memory name, string memory description, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        modelCount++;
        models[modelCount] = Model(name, description, price, payable(msg.sender), 0, 0);
        emit ModelListed(modelCount, name, msg.sender, price);
    }

    function purchaseModel(uint256 modelId) external payable {
        Model storage model = models[modelId];
        require(model.price > 0, "Model does not exist");
        require(msg.value == model.price, "Incorrect value sent");
        require(!purchasedModels[msg.sender][modelId], "Already purchased this model");

        model.creator.transfer(msg.value);
        purchasedModels[msg.sender][modelId] = true;
        emit ModelPurchased(modelId, msg.sender);
    }

    function rateModel(uint256 modelId, uint8 rating) external {
        require(purchasedModels[msg.sender][modelId], "You must purchase this model first");
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        Model storage model = models[modelId];
        model.totalRating += rating;
        model.ratingCount++;
        emit ModelRated(modelId, rating, msg.sender);
    }

    function withdrawFunds() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(msg.sender).transfer(balance);
    }

    function getModelDetails(uint256 modelId) external view returns (
        string memory name,
        string memory description,
        uint256 price,
        address creator,
        uint256 averageRating
    ) {
        Model storage model = models[modelId];
        require(model.price > 0, "Model does not exist");

        uint256 avgRating = model.ratingCount > 0 ? model.totalRating / model.ratingCount : 0;

        return (
            model.name,
            model.description,
            model.price,
            model.creator,
            avgRating
        );
    }
}
