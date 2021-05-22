// SPDX-License-Identifier: MIT
pragma solidity >0.6.1 <0.9.0;

//To run tests on your system get some ether on your metamask wallet in ropsten test network from the faucet and then run: truffle test --network ropsten
import "./lib/UsingOraclize.sol";

//To interact with contract using remix uncomment the line below and comment the line abobe and set compiler version to 0.6.2
// import "https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol";

//Note: You have to provide some ether to contract to do more than one oracle querry (createPrice()) since first querry is free
//To do that just put some amount in value field in remix

contract ETHUSD is usingProvable {
    //----------------------------------------------------------------------------------------------------------------------------//
    //Structure for storing current price from the oracle
    //----------------------------------------------------------------------------------------------------------------------------//
    struct ethprice {
        //this will be unique for every entry
        uint256 id;
        //since solidity do not support decimals. I propose this workaround:-
        //decimal numbers like 2345.67 will be stored as 234567 and as we know
        //there will be 2 values after decimal so we will sore it without decimal and after
        //doing the calculations give the output by converting to decimal form and
        //storing that decimal form in a string
        uint256 price;
    }

    //events for oracle querries (we can see these logs on etherscan)
    event LogConstructorInitiated(string _nextStep);
    event LogPriceUpdated(string _price);
    event LogNewProvableQuery(string _description);

    //no. of prices stored
    uint256 public ctr;
    //id of the last oracle querry this is done just to make sure that every id is unique
    uint256 lastID;

    constructor() public payable {
        emit LogConstructorInitiated(
            "Constructor was initiated. Call 'createPrice()' to send the Provable Query."
        );
        ctr = 0;
        lastID = 0;
        //now we will call the createPrice() to get the current ether price at the time of deployment
        createPrice();
    }

    //to store all the prices from oracle querries
    mapping(uint256 => ethprice) Data;

    //----------------------------------------------------------------------------------------------------------------------------//
    //For finding the mean of all the stored prices
    //----------------------------------------------------------------------------------------------------------------------------//

    function findMean() public view returns (string memory) {
        require(ctr > 0);
        uint256 total = 0;
        uint256 mean;
        for (uint256 i = 1; i <= lastID; i++) {
            total += Data[i].price;
        }
        //setting precision as 2 because from oracle we will give the price in 2 decimal places
        mean = calcul(total, ctr, 2);
        return (
            strConcat(uint2str(mean / 10000), ".", getDecimalPart(mean, 8, 4))
        );
    }

    //----------------------------------------------------------------------------------------------------------------------------//
    //CRUD functions for the structure
    //----------------------------------------------------------------------------------------------------------------------------//

    //CREATE part of CRUD (to get the current price from the oracle)
    function createPrice() public payable {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery(
                "Provable query was NOT sent, please add some ETH to cover for the query fee"
            );
        } else {
            emit LogNewProvableQuery(
                "Provable query was sent, standing by for the answer.."
            );
            provable_query(
                "URL",
                "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price"
            );
        }
    }

    //this will return the current ether price from the oracle
    function __callback(bytes32 _myid, string memory _result) public override {
        if (msg.sender != provable_cbAddress()) revert();
        ctr++;
        lastID++;
        Data[lastID] = ethprice(lastID, parseInt(_result, 2));
    }

    //READ part of CRUD
    function readPrice(uint256 _id) public view returns (string memory) {
        require(_id > 0 && _id <= lastID);
        require(ctr > 0);
        uint256 index = getIndex(_id);
        require(index > 0);
        uint256 _price = Data[index].price;
        return
            strConcat(
                uint2str(Data[index].price / 100),
                ".",
                getDecimalPart(_price, 6, 4)
            );
    }

    //UPDATE part of CRUD (using this we can change the price stored using its id)
    function updatePrice(uint256 _id, string memory _price)
        public
        returns (bool)
    {
        require(_id > 0 && _id <= lastID);
        require(ctr > 0);
        uint256 index = getIndex(_id);
        require(index > 0);
        //note here we are taking the new price in string to not loose the decimal part
        //converting string into uint and keeping the decimal part
        Data[index].price = parseInt(_price, 2);
        return true;
    }

    //DELETE part of CRUD (using this we can delete an entry from stored prices)
    function deletePrice(uint256 _id) public returns (bool) {
        require(_id > 0 && _id <= lastID);
        require(ctr > 0);
        uint256 index = getIndex(_id);
        require(index > 0);
        for (uint256 i = 1; i <= lastID; i++) {
            if (i == index) {
                delete Data[index];
                ctr--;
                if (ctr == 0) lastID = 0;
                return true;
            }
        }
        return false;
    }

    //----------------------------------------------------------------------------------------------------------------------------//
    //Other helper functions for calculations
    //----------------------------------------------------------------------------------------------------------------------------//

    //to divide and save the decimal part
    function calcul(
        uint256 a,
        uint256 b,
        uint256 precision
    ) private pure returns (uint256) {
        return (a * (10**precision)) / b;
    }

    //to search if a particular id exists in the storred data and return its index
    function getIndex(uint256 _id) private view returns (uint256) {
        for (uint256 index = 1; index <= lastID; index++) {
            if (Data[index].id == _id) {
                return index;
            }
        }
        return 0;
    }

    //to get the decimal part
    function getDecimalPart(
        uint256 _i,
        uint8 len,
        uint8 pos
    ) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        bytes memory str1 = new bytes(len);
        bytes memory str2 = new bytes(len - pos);
        uint256 k = len - 1;
        while (_i != 0) {
            str1[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        uint8 j = 0;
        for (uint8 i = pos; i < len; i++) {
            str2[j] = str1[i];
            j++;
        }
        return string(str2);
    }
}
