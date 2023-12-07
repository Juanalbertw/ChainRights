// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title GameRegistry
 * @dev Store game data and manage developer staking requirements
 */
contract GameRegistry {

// mapping(address => list(game_id))

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
        uint256 purchaseDate;
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

    function sufficientStake(address _developer) private returns (bool) {
        // Specific mechanism should be based on sales.
        // Here, stake is based on number of games published.

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

    /**
     * @dev Register a new game.
     * @param _name The name of the game.
     * @param _description The description of the game.
     * @param _developerName The developer of the game.
     * @param _price The price of the game.
     */
    function registerGame(string memory _name, string memory _description, string memory _developerName, uint256 _price) public {
        // Anyone is allowed to register a game, but they must provide sufficient stake.

        // Require that stake is sufficient.
        require(sufficientStake(msg.sender), "Insufficient stake.");

        // Require that the game isn't already registered (do we need this?)
        // require(games[_gameId].developer == address(0), "Game already registered.");

        // Add the new game to the mapping
        games[nextGameId] = GameData({
            name: _name,
            description: _description,
            developerName: _developerName,
            developer: msg.sender,
            price: _price,
            nextGameLicense: 1
        });

        // Add the game to the developer's list of registered games
        developerGameRegistered[msg.sender].push(nextGameId);

        nextGameId++;
        
        // Note: Consider adding more logic here, such as initializing the license mapping for the game,
        // or setting up events to emit when a game is registered.
    }

    /**
     * @dev Buy a license for a game. This function would handle the transfer of funds and the assignment of the game license to the buyer.
     * @param _gameId The ID of the game for which to buy a license.
     */
    function buyGameLicense(uint256 _gameId) public payable {
        // This is a placeholder function. You'll need to add actual payment handling,
        // check that the game exists, ensure the msg.value is enough for the game's price, etc.

        // Assign the game license to the buyer
        gameLicenses[_gameId][msg.sender] = License({
            licenseNumber: games[_gameId].nextGameLicense,
            isActive: true,
            purchaseDate: block.timestamp
        });

        // Add the game to the user's list of owned games
        userGames[msg.sender].push(_gameId);

        // Note: This function should emit an event after a successful purchase.
    }

    /**
     * @dev Check if an address owns a license for a particular game.
     * @param _gameId The ID of the game to check.
     * @param _owner The address to check.
     * @return bool indicating whether the address owns a license for the game.
     */
    function checkLicense(uint256 _gameId, address _owner) public view returns (bool) {
        // Access the License struct for the given game and user address
        License memory userLicense = gameLicenses[_gameId][_owner];

        // Check if the license is active
        return userLicense.isActive;
    }

    // Additional functions for license verification, transferring ownership, and so on, would be added here.

    // Note: You would also typically include admin functions to manage the game listings,
    // handle payments, and interact with other contracts (e.g., the token contract).
}