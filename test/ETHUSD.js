const ETHUSD = artifacts.require("ETHUSD");
contract('ETHUSD', function () {
    let ethInstance;
    it('should deploy smart contract properly', async () => {
        const ethContract = await ETHUSD.deployed();
        assert(ethContract.address != '', 'the smart contract is not deployed properly');
    })


    it('should get a response from the oracle (called the createPrice() from constructor which featches current price from oracle)', function () {
        return ETHUSD.deployed().then(function (instance) {
            ethInstance = instance;
            //checks the number of stored prices if it is 1 this means the querry sucessfully returned a result
            return ethInstance.ctr();
        }).then(function (ctr) {
            assert.equal(ctr, 1, 'no response from the oracle')
        })
    })


    it('should be able to update the stored price', function () {
        return ETHUSD.deployed().then(function (instance) {
            ethInstance = instance;
            return ethInstance.updatePrice(1, "2800.52");
        }).then(function (result) {
            assert(result.receipt.status, true, "updation failed")
        })
    })


    it('should be able to read the stored price (which should be equal to the price updated earlier)', function () {
        return ETHUSD.deployed().then(function (instance) {
            ethInstance = instance;
            return ethInstance.readPrice(1);
        }).then(function (readPrice) {
            assert.equal(readPrice, "2800.52", "not able to read")
        })
    })


    it('should be able to delete the stored price', function () {
        return ETHUSD.deployed().then(function (instance) {
            ethInstance = instance;
            return ethInstance.deletePrice(1);
        }).then(function (success) {
            assert(success, true, 'transaction failed');
            return ethInstance.ctr();
        }).then(function (ctr) {
            assert.equal(ctr, 0, 'not deleted')
        })
    })
})
