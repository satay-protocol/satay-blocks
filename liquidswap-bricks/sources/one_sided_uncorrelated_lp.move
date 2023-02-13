module liquidswap_bricks::one_sided_uncorrelated_lp {

    use std::signer;

    use aptos_framework::coin::{Self, Coin};

    use liquidswap_lp::lp_coin::LP;

    use liquidswap::curves::Uncorrelated;
    use liquidswap::router_v2;
    use liquidswap::math;

    public entry fun deposit<X, Y>(user: &signer, amount: u64) {
        let input_coins = coin::withdraw<X>(user, amount);
        let (residual_x_coins, lp_coins) = apply<X, Y>(input_coins);
        coin::deposit(signer::address_of(user), residual_x_coins);
        if(!coin::is_account_registered<LP<X, Y, Uncorrelated>>(signer::address_of(user))) {
            coin::register<LP<X, Y, Uncorrelated>>(user);
        };
        coin::deposit<LP<X, Y, Uncorrelated>>(signer::address_of(user), lp_coins);
    }

    public entry fun withdraw<X, Y>(user: &signer, amount: u64) {
        let lp_coins = coin::withdraw<LP<X, Y, Uncorrelated>>(user, amount);
        let x_coins = liquidate<X, Y>(lp_coins);
        coin::deposit(signer::address_of(user), x_coins);
    }

    public fun apply<X, Y>(
        input_coins: Coin<X>
    ): (Coin<X>, Coin<LP<X, Y, Uncorrelated>>) {
        let swap_amount = calculate_swap_amount<X, Y>(&input_coins);
        let other_coins = router_v2::swap_exact_coin_for_coin<X, Y, Uncorrelated>(
            coin::extract(&mut input_coins, swap_amount),
            0
        );
        let (
            res_x,
            res_y,
            lp
        ) = router_v2::add_liquidity<X, Y, Uncorrelated>(input_coins, 0, other_coins, 0);
        coin::merge(
            &mut res_x,
            router_v2::swap_exact_coin_for_coin<Y, X, Uncorrelated>(res_y, 0)
        );
        (res_x, lp)
    }

    public fun liquidate<X, Y>(
        lp_coins: Coin<LP<X, Y, Uncorrelated>>
    ): Coin<X> {
        let (x, y) = router_v2::remove_liquidity(lp_coins, 0, 0);
        coin::merge(&mut x, router_v2::swap_exact_coin_for_coin<Y, X, Uncorrelated>(y, 0));
        x
    }

    // https://blog.alphaventuredao.io/onesideduniswap/
    fun calculate_swap_amount<X, Y>(
        input_coins: &Coin<X>
    ): u64 {
        let amt_x = coin::value(input_coins);
        let (res_x, _) = router_v2::get_reserves_size<X, Y, Uncorrelated>();
        let (fee_numer, fee_denom) = router_v2::get_fees_config<X, Y, Uncorrelated>();
        let fee = fee_numer / fee_denom;
        let inter = (2 - fee) * res_x;
        (math::sqrt(math::mul_to_u128(inter, inter) + 4 * math::mul_to_u128((1 - fee) * amt_x, res_x)) - (inter)) / (2 * (1 - fee))
    }
}
