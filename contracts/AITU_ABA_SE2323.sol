// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract AITU_ABA_SE2323 is ERC20, Ownable {
    struct AIModel {
        string name;
        string description;
        uint256 price;
        address seller;
        string accessLink;
        bool isSold;
        uint256 totalRating;
        uint256 numRatings;
    }

    AIModel[] public aiModels;
    mapping(uint256 => address) public modelToBuyer;
    mapping(uint256 => mapping(address => bool)) public hasRated;

    event ModelListed(
        uint256 indexed modelId,
        string name,
        uint256 price,
        address seller
    );

    event ModelPurchased(
        uint256 indexed modelId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );

    event ModelRated(
        uint256 indexed modelId,
        address indexed rater,
        uint256 rating
    );

    event TransferDetails(
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 timestamp
    );

    struct TransferRecord {
        address sender;
        address receiver;
        uint256 amount;
        uint256 timestamp;
    }

    TransferRecord public recentTransfer;

    constructor(address initialOwner) ERC20("AITU_ABA_SE2323", "ABA") Ownable(initialOwner) {
        _mint(initialOwner, 2000 * 10**decimals());
    }

    function listAIModel(
        string memory name,
        string memory description,
        uint256 price,
        string memory accessLink
    ) external returns (uint256) {
        AIModel memory newModel = AIModel({
            name: name,
            description: description,
            price: price,
            seller: msg.sender,
            accessLink: accessLink,
            isSold: false,
            totalRating: 0,
            numRatings: 0
        });
        
        aiModels.push(newModel);
        uint256 modelId = aiModels.length - 1;
        emit ModelListed(modelId, name, price, msg.sender);
        return modelId;
    }

    function purchaseAIModel(uint256 modelId) external {
        require(modelId < aiModels.length, "Model does not exist");
        AIModel storage model = aiModels[modelId];
        require(!model.isSold, "Model already sold");
        require(msg.sender != model.seller, "Cannot buy your own model");
        require(balanceOf(msg.sender) >= model.price, "Insufficient balance");

        _transfer(msg.sender, model.seller, model.price);
        model.isSold = true;
        modelToBuyer[modelId] = msg.sender;

        emit ModelPurchased(modelId, msg.sender, model.seller, model.price);
    }

    function rateModel(uint256 modelId, uint256 rating) external {
        require(modelId < aiModels.length, "Model does not exist");
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(modelToBuyer[modelId] == msg.sender, "Only buyer can rate");
        require(!hasRated[modelId][msg.sender], "Already rated");

        AIModel storage model = aiModels[modelId];
        model.totalRating += rating;
        model.numRatings += 1;
        hasRated[modelId][msg.sender] = true;

        emit ModelRated(modelId, msg.sender, rating);
    }

    function getModelRating(uint256 modelId) external view returns (uint256, uint256) {
        require(modelId < aiModels.length, "Model does not exist");
        AIModel storage model = aiModels[modelId];
        return (model.totalRating, model.numRatings);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        bool success = super.transfer(recipient, amount);
        if (success) {
            recentTransfer = TransferRecord(msg.sender, recipient, amount, block.timestamp);
            emit TransferDetails(msg.sender, recipient, amount, block.timestamp);
        }
        return success;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        bool success = super.transferFrom(sender, recipient, amount);
        if (success) {
            recentTransfer = TransferRecord(sender, recipient, amount, block.timestamp);
            emit TransferDetails(sender, recipient, amount, block.timestamp);
        }
        return success;
    }
function getRecentTransfer() public view returns (address, address, uint256, uint256) {
        return (
            recentTransfer.sender,
            recentTransfer.receiver,
            recentTransfer.amount,
            recentTransfer.timestamp
        );
    }

    function getTransferTimestamp() public view returns (uint256) {
        return recentTransfer.timestamp;
    }

    function getTransferSender() public view returns (address) {
        return recentTransfer.sender;
    }

    function getTransferReceiver() public view returns (address) {
        return recentTransfer.receiver;
    }

    function getFormattedTimestamp() public view returns (string memory) {
        return convertTimestampToString(recentTransfer.timestamp);
    }

    function convertTimestampToString(uint256 timestamp) internal pure returns (string memory) {
        uint256 SECONDS_IN_DAY = 86400;
        uint256 SECONDS_IN_HOUR = 3600;
        uint256 SECONDS_IN_MINUTE = 60;

        uint16 year = 1970;
        uint8 month;
        uint8 day;

        uint256 daysSinceEpoch = timestamp / SECONDS_IN_DAY;

        while (true) {
            uint256 daysInYear = isLeapYear(year) ? 366 : 365;
            if (daysSinceEpoch < daysInYear) {
                break;
            }
            daysSinceEpoch -= daysInYear;
            year++;
        }

        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (isLeapYear(year)) {
            daysInMonth[1] = 29;
        }

        for (month = 0; month < 12; month++) {
            if (daysSinceEpoch < daysInMonth[month]) {
                break;
            }
            daysSinceEpoch -= daysInMonth[month];
        }

        day = uint8(daysSinceEpoch + 1);
        month += 1;

        uint256 remainingSeconds = timestamp % SECONDS_IN_DAY;
        uint8 hour = uint8(remainingSeconds / SECONDS_IN_HOUR);
        uint8 minute = uint8((remainingSeconds % SECONDS_IN_HOUR) / SECONDS_IN_MINUTE);

        return string(
            abi.encodePacked(
                uintToString(day), "/", uintToString(month), "/", uintToString(year),
                " ", uintToString(hour), ":", uintToString(minute)
            )
        );
    }

    function isLeapYear(uint16 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 == 0 && year % 400 != 0) {
            return false;
        }
        return true;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 length;
        while (temp != 0) {
            length++;
            temp /= 10;
        }
        bytes memory result = new bytes(length);
        uint256 index = length - 1;
        while (value != 0) {
            result[index] = bytes1(uint8(48 + value % 10));
            value /= 10;
            if (index > 0) {
                index--;
            } else {
                break;
            }
        }
        return string(result);
    }
}