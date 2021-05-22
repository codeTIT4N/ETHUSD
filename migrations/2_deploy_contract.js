const ETHUSD = artifacts.require("ETHUSD");

module.exports = function (deployer) {
    deployer.deploy(ETHUSD);
};
