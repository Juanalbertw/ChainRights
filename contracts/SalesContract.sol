// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GameRegistry.sol";
import "./CRI.sol";

contract SalesContract is GameRegistry {
    IERC20 public usdcToken;
    Token public criToken;

    // Mapping from game ID to license number to price
    mapping(uint256 => mapping(uint256 => uint256)) public sellingPool;

    constructor(address _usdcTokenAddress) {
        usdcToken = IERC20(_usdcTokenAddress);
    }

    function buy(uint256 gameId) external payable {
        uint256 price = games[gameId].price;
        
        require(msg.value == price, "Incorrect payment amount");
        require(usdcToken.transferFrom(msg.sender, address(this), price), "Payment failed");

        createGameLicense(gameId);

        uint256 developersShare = price * 975 / 1000;
        address developer = games[gameId].developer;
        require(usdcToken.transfer(developer, developersShare), "Transfer to developer failed");

	    // Mint and send CRI tokens to the game developer
        uint256 criAmount = calculateCRIAmount(price); 
        criToken.mintTo(developer, criAmount);
        criToken.mintTo(msg.sender, 5 * criAmount);
    }

    function sell(uint256 gameId, uint price) public {
        require(gameLicenses[gameId][msg.sender].isActive, "No active license to sell");
        require(!gameLicenses[gameId][msg.sender].isInSellingPool, "License already in selling pool");

        // Update status of license
        putInSellingPool(gameId, msg.sender);

        // Put in selling pool
        uint licenseNumber = gameLicenses[gameId][msg.sender].licenseNumber;
        sellingPool[gameId][licenseNumber] = price;
    }

    function revokeSell(uint gameId) public {
        require(gameLicenses[gameId][msg.sender].isInSellingPool, "You do not have a license in selling pool.");

        // Update status of license
        removeFromSellingPool(gameId, msg.sender);

        // Remove from selling pool
        uint licenseNumber = gameLicenses[gameId][msg.sender].licenseNumber;
        delete sellingPool[gameId][licenseNumber];
    }

    function buyFromSellingPool(uint256 gameId, address owner) external payable {
        require(gameLicenses[gameId][owner].licenseNumber > 0 && gameLicenses[gameId][owner].isInSellingPool, "License not available or not in selling pool");

        uint256 price = games[gameId].price;
        require(msg.value == price, "Incorrect payment amount");
        require(usdcToken.transferFrom(msg.sender, address(this), price), "Payment failed");

        transferOwnership(gameId, owner, msg.sender);

        uint256 developersShare = price * 75 / 1000; // 7.5% to the game developer
        uint256 ownersShare = price * 900 / 1000;    // 90% to the current owner

        address developer = games[gameId].developer;
        require(usdcToken.transfer(developer, developersShare), "Transfer to developer failed");
        require(usdcToken.transfer(owner, ownersShare), "Transfer to owner failed");
    }

    function calculateCRIAmount(uint256 price) private view returns (uint256) {
        uint256 totalSupply = criToken.getTotalSupply();
        uint256 currentSupply = criToken.getCurrentSupply();


        if (totalSupply == 0) {
            return 0;
        }

        uint256 criAmount = (price) * (currentSupply / totalSupply);
        return criAmount;
    }
}
