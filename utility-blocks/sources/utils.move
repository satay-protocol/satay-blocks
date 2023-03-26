module satay::utils {

    use std::signer;
    use std::option::{Self, Option};

    use aptos_framework::coin::{Self, Coin};

    public fun check_and_deposit_opt<X>(sender: &signer, coin_opt: Option<Coin<X>>) {
        if (option::is_some(&coin_opt)) {
            let coin = option::extract(&mut coin_opt);
            let sender_addr = signer::address_of(sender);
            if (!coin::is_account_registered<X>(sender_addr)) {
                coin::register<X>(sender);
            };
            coin::deposit(sender_addr, coin);
        };
        option::destroy_none(coin_opt)
    }

    public fun check_and_deposit<X>(sender: &signer, coin: Coin<X>) {
        if(coin::value(&coin) == 0) {
            coin::destroy_zero(coin);
            return
        };
        let sender_addr = signer::address_of(sender);
        if (!coin::is_account_registered<X>(sender_addr)) {
            coin::register<X>(sender);
        };
        coin::deposit(sender_addr, coin);
    }

    public fun unwrap_coin_opt<CoinType>(coin_opt: Option<Coin<CoinType>>): Coin<CoinType> {
        let coin = if (option::is_some(&coin_opt)) {
            option::extract(&mut coin_opt)
        } else {
            coin::zero<CoinType>()
        };
        option::destroy_none(coin_opt);
        coin
    }

    public fun merge_coin_and_coin_opt<CoinType>(coin: Coin<CoinType>, coin_opt: Option<Coin<CoinType>>): Coin<CoinType> {
        let coin_opt_unwrap = unwrap_coin_opt(coin_opt);
        coin::merge(&mut coin, coin_opt_unwrap);
        coin
    }
}
