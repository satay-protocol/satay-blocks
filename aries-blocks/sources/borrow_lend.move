module aries_blocks::borrow_lend {

    use std::string::String;

    use aptos_framework::coin::Coin;

    use aries::controller;
    use aries::profile::CheckEquity;

    /// deposit `amount` of `CoinType` to Aries Markets
    public entry fun deposit<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::deposit<CoinType>(account, profile_name, amount, false);
    }

    /// repay 'amount' of 'CoinType' to Aries Markets
    public entry fun repay<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::deposit<CoinType>(account, profile_name, amount, false);
    }

    /// withdraw `amount` of `CoinType` from Aries Markets
    public entry fun withdraw<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::withdraw<CoinType>(account, profile_name, amount, false);
    }

    /// borrow `amount` of `CoinType` from Aries Markets
    public entry fun borrow<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::withdraw<CoinType>(account, profile_name, amount, false);
    }

    public fun begin_flash_loan<CoinType>(account: &signer, profile_name: String, amount: u64): (CheckEquity, Coin<CoinType>) {
        controller::begin_flash_loan<CoinType>(account, profile_name, amount)
    }

    public fun end_flash_loan<CoinType>(receipt: CheckEquity, coin: Coin<CoinType>) {
        controller::end_flash_loan<CoinType>(receipt, coin);
    }
}
