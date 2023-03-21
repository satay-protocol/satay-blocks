module aries_blocks::borrow_lend {

    use aries::controller;

    /// deposit
    public entry fun deposit<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::deposit<CoinType>(
            account,
            profile_name,
            amount,
            false
        );
    }

    public entry fun repay<CoinType>() {

    }
}
