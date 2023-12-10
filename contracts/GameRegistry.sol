// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

contract GameRegistry {

    struct GameData {
        string name;
        string description;
        string developerName;
        address developer;
        uint256 price;
        uint256 nextGameLicense;
    }

    struct License {
        uint256 licenseNumber;
        bool isActive;
        bool isInSellingPool;
        uint256 purchaseDate;

        // If license !isActive and isInSellingPool, license is about to be sold
        // If license !isActive and !isInSellingPool, license is revoked
    }

    uint256 nextGameId = 1;

    // Mapping from game ID to its data
    mapping(uint256 => GameData) public games;

    // Mapping from game ID to a mapping of address to game license
    mapping(uint256 => mapping(address => License)) public gameLicenses;

    // Mapping from user address to list of game IDs they own
    mapping(address => uint256[]) public userGames;

    // Mapping from developer address to list game IDs they registered
    mapping(address => uint256[]) public developerGameRegistered;

    // Mapping from developer address to amount of stake they own (not developed yet)
    mapping(address => uint256) public stake;

    function sufficientStake(address _developer) private view returns (bool) {
        // Stake mechanism is based on number of games published.

        if (developerGameRegistered[_developer].length < 3) {
            // Small developer
            return stake[_developer] > 100;
        } else if (developerGameRegistered[_developer].length < 8) {
            // Medium developer
            return stake[_developer] > 200;
        } else {
            // Large developer
            return stake[_developer] > 500;
        }
    }

    function registerGame(string memory _name, string memory _description, string memory _developerName, uint256 _price) public {
        // Anyone is allowed to register a game, but they must provide sufficient stake.

        // Require that stake is sufficient.
        require(sufficientStake(msg.sender), "Insufficient stake.");

        // Add the new game to the mapping
        games[nextGameId] = GameData({
            name: _name,
            description: _description,
            developerName: _developerName,
            developer: msg.sender,
            price: _price,
            nextGameLicense: 1 // Game license number starts from 1 in this implementation
        });

        // Add the game to the developer's list of registered games
        developerGameRegistered[msg.sender].push(nextGameId);

        nextGameId++;
    }

    function createGameLicense(uint256 _gameId) internal {
        // Payment handling is handled by sales contract.

        // Assign the game license to the buyer
        gameLicenses[_gameId][msg.sender] = License({
            licenseNumber: games[_gameId].nextGameLicense,
            isActive: true,
            isInSellingPool: false,
            purchaseDate: block.timestamp
        });

        // Add the game to the user's list of owned games
        userGames[msg.sender].push(_gameId);
    }

    function checkLicense(uint256 _gameId, address _owner) public view returns (bool) {
        // Only game developer or user can check license
        require(msg.sender == _owner || msg.sender == games[_gameId].developer, "Only game developer or user is permitted to check license.");
               
        // Access the License struct for the given game and user address
        License memory userLicense = gameLicenses[_gameId][_owner];

        // Check if the license is active
        return userLicense.isActive;
    }
    
    function putInSellingPool(uint _gameId, address _owner) internal {
        // Sales contract should call this function when a user wants to sell license

        License memory userLicense = gameLicenses[_gameId][_owner];
        
        // Require that owner owns the game
        require(userLicense.licenseNumber > 0, "Owner doesn't own the game.");

        // Require that owner's license is active
        require(userLicense.isActive, "Owner license isn't active.");

        gameLicenses[_gameId][_owner].isActive = false;
        gameLicenses[_gameId][_owner].isInSellingPool = true;
    }

    function removeFromSellingPool(uint _gameId, address _owner) internal {
        // Sales contract should call this function when a user cancels to sell license

        License memory userLicense = gameLicenses[_gameId][_owner];
        
        // Require that owner owns the game
        require(userLicense.licenseNumber > 0, "Owner doesn't own the game.");

        // Require that owner's license is put in the selling pool
        require(userLicense.isInSellingPool, "Owner license isn't in selling pool.");

        gameLicenses[_gameId][_owner].isActive = true;
        gameLicenses[_gameId][_owner].isInSellingPool = false;
    }

    function transferOwnership(uint _gameId, address _owner, address _newOwner) internal  {
        // Sales contract should call this function upon resell

        License memory userLicense = gameLicenses[_gameId][_owner];
        
        // Require that owner owns the game
        require(userLicense.licenseNumber > 0, "Owner doesn't own the game.");

        // Require that owner's license is put in the selling pool
        require(userLicense.isInSellingPool, "Owner license isn't in selling pool.");

        // Require that newOwner doesn't own the game (in this implementation, one user can only own one license of a game)
        require(gameLicenses[_gameId][_newOwner].licenseNumber == 0, "New user already own a license for the game.");

        // Transfer ownership
        gameLicenses[_gameId][_newOwner] = License({
            licenseNumber: userLicense.licenseNumber,
            isActive: true,
            isInSellingPool: false,
            purchaseDate: block.timestamp // we use resell timestamp
        });

        delete gameLicenses[_gameId][_owner];
    }
}