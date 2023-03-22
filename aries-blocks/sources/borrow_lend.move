module aries_blocks::borrow_lend {

    use std::string::String;

    use aptos_framework::coin::Coin;

    use aries::controller;
    use aries::profile::CheckEquity;
    use aries::profile;
    use std::string;
    use aptos_std::type_info;

    /// register a new user with `profile_name`
    public entry fun register_user(account: &signer, profile_name: vector<u8>) {
        controller::register_user(account, profile_name);
    }

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

    public entry fun leveraged_swap<InCoin, Y, Z, OutCoin, E1, E2, E3>(
        account: &signer,
        profile_name: vector<u8>,
        allow_borrow: bool,
        amount: u64,
        minimum_out: u64,
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool,
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool,
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool
    ) {
        controller::hippo_swap<InCoin, Y, Z, OutCoin, E1, E2, E3>(
            account,
            profile_name,
            allow_borrow,
            amount,
            minimum_out,
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y
        );
    }

    public fun begin_flash_loan<CoinType>(account: &signer, profile_name: String, amount: u64): (CheckEquity, Coin<CoinType>) {
        controller::begin_flash_loan<CoinType>(account, profile_name, amount)
    }

    public fun end_flash_loan<CoinType>(receipt: CheckEquity, coin: Coin<CoinType>) {
        controller::end_flash_loan<CoinType>(receipt, coin);
    }

    public fun get_deposit_amount<CoinType>(account_addr: address, profile_name: vector<u8>): u64 {
        profile::get_deposited_amount(
            account_addr,
            &string::utf8(profile_name),
            type_info::type_of<CoinType>()
        )
    }
}
