// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AIModelMarketplace {
    address public owner;

    // Struct to represent an AI model
    struct Model {
        string name;
        string description;
        uint256 price;
        address creator;
        uint256 totalRating;
        uint256 ratingCount;
    }

    // Array to store models
    Model[] public models;

    // Mapping to track purchases (modelId => list of buyers)
    mapping(uint256 => address[]) public modelPurchasers;

    // Event emitted when a new model is listed
    event ModelListed(uint256 indexed modelId, string name, string description, uint256 price, address indexed creator);

    // Event emitted when a model is purchased
    event ModelPurchased(uint256 indexed modelId, address indexed buyer);

    // Event emitted when a model is rated
    event ModelRated(uint256 indexed modelId, uint8 rating, address indexed rater);

    // Event emitted when funds are withdrawn
    event FundsWithdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Constructor to initialize the contract owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows a user to list a new AI model on the marketplace.
     * @param name The name of the AI model.
     * @param description A brief description of the AI model.
     * @param price The price of the AI model in wei.
     */
    function listModel(string memory name, string memory description, uint256 price) public {
        require(price > 0, "Price must be greater than zero");

        // Create a new model and add it to the array
        models.push(Model({
            name: name,
            description: description,
            price: price,
            creator: msg.sender,
            totalRating: 0,
            ratingCount: 0
        }));

        // Emit the ModelListed event
        uint256 modelId = models.length - 1;
        emit ModelListed(modelId, name, description, price, msg.sender);
    }

    /**
     * @dev Enables a user to purchase a specific AI model by its ID.
     * @param modelId The ID of the AI model to purchase.
     */
    function purchaseModel(uint256 modelId) public payable {
        require(modelId < models.length, "Invalid model ID");
        Model memory model = models[modelId];
        require(msg.value == model.price, "Incorrect payment amount");

        // Calculate platform fee and creator's payment
        uint256 platformFee = (msg.value * 1) / 1000; // 0.1% fee
        uint256 creatorPayment = msg.value - platformFee;
        // Fee will stay in the contract for OWNER to claim

        // Transfer the creator's payment
        payable(model.creator).transfer(creatorPayment);

        // Mark the model as purchased by adding the buyer to the list
        modelPurchasers[modelId].push(msg.sender);

        // Emit the ModelPurchased event
        emit ModelPurchased(modelId, msg.sender);
    }

    /**
     * @dev Allows a user to rate a purchased AI model.
     * @param modelId The ID of the AI model to rate.
     * @param rating The rating to give (1-5).
     */
    function rateModel(uint256 modelId, uint8 rating) public {
        require(modelId < models.length, "Invalid model ID");

        // Ensure the user has purchased the model
        bool hasPurchased = false;
        for (uint256 i = 0; i < modelPurchasers[modelId].length; i++) {
            if (modelPurchasers[modelId][i] == msg.sender) {
                hasPurchased = true;
                break;
            }
        }
        require(hasPurchased, "Only buyers can rate this model");

        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        // Update model's rating information
        models[modelId].totalRating += rating;
        models[modelId].ratingCount += 1;

        // Emit the ModelRated event
        emit ModelRated(modelId, rating, msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw all accumulated funds.
     */
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw");

        // Transfer the balance to the owner
        payable(owner).transfer(balance);

        // Emit the FundsWithdrawn event
        emit FundsWithdrawn(owner, balance);
    }

    /**
     * @dev Fetches the total number of models listed on the marketplace.
     * @return The total number of models.
     */
    function getModelCount() public view returns (uint256) {
        return models.length;
    }

    /**
     * @dev Retrieves the details of a specific AI model.
     * @param modelId The ID of the AI model.
     * @return name The name of the AI model.
     * @return description The description of the AI model.
     * @return price The price of the AI model in wei.
     * @return creator The address of the model's creator.
     * @return averageRating The average rating of the model.
     */
    function getModelDetails(uint256 modelId) public view returns (
        string memory name,
        string memory description,
        uint256 price,
        address creator,
        uint256 averageRating
    ) {
        require(modelId < models.length, "Invalid model ID");

        Model memory model = models[modelId];
        averageRating = model.ratingCount > 0 ? model.totalRating / model.ratingCount : 0;

        return (
            model.name,
            model.description,
            model.price,
            model.creator,
            averageRating
        );
    }
}
