module liquidswap_bricks::one_sided_uncorrelated_lp {

    use std::signer;

    use aptos_framework::coin::{Self, Coin};

    use liquidswap_lp::lp_coin::LP;

    use liquidswap::curves::Uncorrelated;
    use liquidswap::router_v2;
    use liquidswap::math;
    use liquidswap::coin_helper;

    // error codes

    /// when apply does not return enough LP tokens
    const ERR_INSUFFICIENT_LP_OUT: u64 = 1;
    /// when liquidate does not return enough X tokens
    const ERR_INSUFFICIENT_X_OUT: u64 = 2;

    public entry fun deposit<X, Y>(user: &signer, amount: u64, min_lp_out: u64) {
        let input_coins = coin::withdraw<X>(user, amount);
        if(coin_helper::is_sorted<X, Y>()){
            let (residual_x_coins, lp_coins) = apply_input_x<X, Y>(input_coins, min_lp_out);
            coin::deposit(signer::address_of(user), residual_x_coins);
            if(!coin::is_account_registered<LP<X, Y, Uncorrelated>>(signer::address_of(user))) {
                coin::register<LP<X, Y, Uncorrelated>>(user);
            };
            coin::deposit<LP<X, Y, Uncorrelated>>(signer::address_of(user), lp_coins);
        } else {
            let (residual_y_coins, lp_coins) = apply_input_y<Y, X>(input_coins, min_lp_out);
            coin::deposit(signer::address_of(user), residual_y_coins);
            if(!coin::is_account_registered<LP<Y, X, Uncorrelated>>(signer::address_of(user))) {
                coin::register<LP<Y, X, Uncorrelated>>(user);
            };
            coin::deposit<LP<Y, X, Uncorrelated>>(signer::address_of(user), lp_coins);
        }
    }

    public entry fun withdraw<X, Y>(user: &signer, amount: u64, min_x_out: u64) {
        let x_coins: Coin<X>;
        if(coin_helper::is_sorted<X, Y>()){
            let lp_coins = coin::withdraw<LP<X, Y, Uncorrelated>>(user, amount);
            x_coins = liquidate_output_x<X, Y>(lp_coins, min_x_out);

        } else {
            let lp_coins = coin::withdraw<LP<Y, X, Uncorrelated>>(user, amount);
            x_coins = liquidate_output_y<Y, X>(lp_coins, min_x_out);
        };
        if(!coin::is_account_registered<X>(signer::address_of(user))) {
            coin::register<X>(user);
        };
        coin::deposit(signer::address_of(user), x_coins);
    }

    public fun apply_input_x<X, Y>(
        input_coins: Coin<X>,
        min_lp_out: u64
    ): (Coin<X>, Coin<LP<X, Y, Uncorrelated>>) {
        let swap_amount = calculate_swap_amount<X, Y>(coin::value(&input_coins));
        let other_coins = router_v2::swap_exact_coin_for_coin<X, Y, Uncorrelated>(
            coin::extract(&mut input_coins, swap_amount),
            0
        );
        let (
            res_x,
            res_y,
            lp
        ) = router_v2::add_liquidity<X, Y, Uncorrelated>(input_coins, 0, other_coins, 0);
        assert!(coin::value(&lp) >= min_lp_out, ERR_INSUFFICIENT_LP_OUT);
        if(coin::value(&res_y) == 0){
            coin::destroy_zero(res_y);
        } else {
            coin::merge(
                &mut res_x,
                router_v2::swap_exact_coin_for_coin<Y, X, Uncorrelated>(res_y, 0)
            );
        };
        (res_x, lp)
    }

    public fun apply_input_y<X, Y>(input_coins: Coin<Y>, min_lp_out: u64): (Coin<Y>, Coin<LP<X, Y, Uncorrelated>>) {
        let swap_amount = calculate_swap_amount<Y, X>(coin::value(&input_coins));
        let other_coins = router_v2::swap_exact_coin_for_coin<Y, X, Uncorrelated>(
            coin::extract(&mut input_coins, swap_amount),
            0
        );
        let (
            res_x,
            res_y,
            lp
        ) = router_v2::add_liquidity<X, Y, Uncorrelated>(other_coins, 0, input_coins, 0);
        assert!(coin::value(&lp) >= min_lp_out, ERR_INSUFFICIENT_LP_OUT);
        if(coin::value(&res_x) == 0){
            coin::destroy_zero(res_x);
        } else {
            coin::merge(
                &mut res_y,
                router_v2::swap_exact_coin_for_coin<X, Y, Uncorrelated>(res_x, 0)
            );
        };
        (res_y, lp)
    }

    public fun liquidate_output_x<X, Y>(
        lp_coins: Coin<LP<X, Y, Uncorrelated>>,
        min_x_out: u64
    ): Coin<X> {
        let (x, y) = router_v2::remove_liquidity(lp_coins, min_x_out, 0);
        coin::merge(&mut x, router_v2::swap_exact_coin_for_coin<Y, X, Uncorrelated>(y, 0));
        assert!(coin::value(&x) >= min_x_out, ERR_INSUFFICIENT_X_OUT);
        x
    }

    public fun liquidate_output_y<X, Y>(
        lp_coins: Coin<LP<X, Y, Uncorrelated>>,
        min_x_out: u64
    ): Coin<Y> {
        let (x, y) = router_v2::remove_liquidity(lp_coins, min_x_out, 0);
        coin::merge(&mut y, router_v2::swap_exact_coin_for_coin<X, Y, Uncorrelated>(x, 0));
        assert!(coin::value(&y) >= min_x_out, ERR_INSUFFICIENT_X_OUT);
        y
    }

    // https://blog.alphaventuredao.io/onesideduniswap/
    public fun calculate_swap_amount<X, Y>(amt_x: u64): u64 {
        let (res_x, _) = router_v2::get_reserves_size<X, Y, Uncorrelated>();
        let (fee_numer, fee_denom) = router_v2::get_fees_config<X, Y, Uncorrelated>();
        // (2 - f) * res_x
        let inter_a = math::mul_div(2 * fee_denom - fee_numer, res_x, fee_denom);
        // 2 * (1 - f)
        let inter_b = math::mul_div(2, (fee_denom - fee_numer), fee_denom);
        (
            (math::sqrt(math::mul_to_u128(inter_a, inter_a) + math::mul_to_u128(2 * inter_b * amt_x, res_x)) - inter_a)
            / inter_b
        )
    }
}
