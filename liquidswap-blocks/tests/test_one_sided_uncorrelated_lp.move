#[test_only]
module satay_blocks::test_one_sided_uncorrelated_lp {

    use std::signer;

    use aptos_framework::coin;

    use test_helpers::test_pool;
    use test_coin_admin::test_coins::{Self, BTC, USDT};

    use liquidswap_lp::lp_coin::LP;

    use liquidswap::liquidity_pool;
    use liquidswap::math;
    use liquidswap::curves::Uncorrelated;

    use satay_blocks::one_sided_uncorrelated_lp;

    // constants

    const BTC_INITIAL_LIQUIDITY: u64 = 100000000;
    const USDT_INITIAL_LIQUIDITY: u64 = 500000000;

    const DEPOSIT_AMOUNT: u64 = 100000;

    const ACCEPTABLE_RESIDUAL_BPS: u64 = 500;
    const ACCEPTABLE_REMAINING_BPS: u64 = 9940;
    const MAX_BPS: u64 = 10000;

    // error codes

    const ERR_DEPOSIT: u64 = 1;
    const ERR_WITHDRAW: u64 = 2;

    fun setup_tests(): (signer, signer) {
        let (coin_admin, lp_owner) = test_pool::setup_coins_and_lp_owner();

        liquidity_pool::register<BTC, USDT, Uncorrelated>(&lp_owner);
        test_pool::mint_liquidity<BTC, USDT, Uncorrelated>(
            &lp_owner,
            test_coins::mint<BTC>(&coin_admin, BTC_INITIAL_LIQUIDITY),
            test_coins::mint<USDT>(&coin_admin, USDT_INITIAL_LIQUIDITY)
        );

        (coin_admin, lp_owner)
    }

    fun deposit_usdt(coin_admin: &signer, deposit_amount: u64) {
        coin::register<USDT>(coin_admin);
        coin::deposit(
            signer::address_of(coin_admin),
            test_coins::mint<USDT>(coin_admin, deposit_amount)
        );
        one_sided_uncorrelated_lp::deposit<USDT, BTC>(coin_admin, deposit_amount, 0);
    }

    fun deposit_btc(coin_admin: &signer, deposit_amount: u64) {
        coin::register<BTC>(coin_admin);
        coin::deposit(
            signer::address_of(coin_admin),
            test_coins::mint<BTC>(coin_admin, deposit_amount)
        );
        one_sided_uncorrelated_lp::deposit<BTC, USDT>(coin_admin, deposit_amount, 0);
    }


    #[test]
    fun test_deposit_usdt() {
        let (coin_admin, _) = setup_tests();

        deposit_usdt(&coin_admin, DEPOSIT_AMOUNT);

        let user_addr = signer::address_of(&coin_admin);
        assert!(coin::balance<LP<BTC, USDT, Uncorrelated>>(user_addr) > 0, ERR_DEPOSIT);
        let acceptable_residual = math::mul_div(DEPOSIT_AMOUNT, ACCEPTABLE_RESIDUAL_BPS, MAX_BPS);
        assert!(coin::balance<USDT>(user_addr) < acceptable_residual, 1);
    }

    #[test]
    fun test_deposit_btc() {
        let (coin_admin, _) = setup_tests();

        deposit_btc(&coin_admin, DEPOSIT_AMOUNT);

        let user_addr = signer::address_of(&coin_admin);
        assert!(coin::balance<LP<BTC, USDT, Uncorrelated>>(user_addr) > 0, ERR_DEPOSIT);
        let acceptable_residual = math::mul_div(DEPOSIT_AMOUNT, ACCEPTABLE_RESIDUAL_BPS, MAX_BPS);
        assert!(coin::balance<BTC>(user_addr) < acceptable_residual, 1);
    }

    fun withdraw_usdt(coin_admin: &signer){
        let lp_balance = coin::balance<LP<BTC, USDT, Uncorrelated>>(signer::address_of(coin_admin));
        one_sided_uncorrelated_lp::withdraw<USDT, BTC>(coin_admin, lp_balance, 0);
    }

    fun withdraw_btc(coin_admin: &signer){
        let lp_balance = coin::balance<LP<BTC, USDT, Uncorrelated>>(signer::address_of(coin_admin));
        one_sided_uncorrelated_lp::withdraw<BTC, USDT>(coin_admin, lp_balance, 0);
    }

    #[test]
    fun test_deposit_withdraw_usdt() {
        let (coin_admin, _) = setup_tests();

        deposit_usdt(&coin_admin, DEPOSIT_AMOUNT);
        withdraw_usdt(&coin_admin);

        let user_addr = signer::address_of(&coin_admin);
        let acceptable_balance = math::mul_div(DEPOSIT_AMOUNT, ACCEPTABLE_REMAINING_BPS, MAX_BPS);
        assert!(coin::balance<USDT>(user_addr) > acceptable_balance, 3);
    }

    #[test]
    fun test_deposit_withdraw_btc() {
        let (coin_admin, _) = setup_tests();

        deposit_btc(&coin_admin, DEPOSIT_AMOUNT);
        withdraw_btc(&coin_admin);

        let user_addr = signer::address_of(&coin_admin);
        let acceptable_balance = math::mul_div(DEPOSIT_AMOUNT, ACCEPTABLE_REMAINING_BPS, MAX_BPS);
        assert!(coin::balance<BTC>(user_addr) > acceptable_balance, 3);
    }

    #[test]
    fun test_deposit_usdt_withdraw_btc() {
        let (coin_admin, _) = setup_tests();

        deposit_usdt(&coin_admin, DEPOSIT_AMOUNT);
        withdraw_btc(&coin_admin);
        let user_addr = signer::address_of(&coin_admin);
        let feeless_return = math::mul_div(DEPOSIT_AMOUNT, BTC_INITIAL_LIQUIDITY, USDT_INITIAL_LIQUIDITY);
        let acceptable_balance = math::mul_div(feeless_return, ACCEPTABLE_REMAINING_BPS, MAX_BPS);
        assert!(coin::balance<BTC>(user_addr) > acceptable_balance, 3);
    }

    #[test]
    fun test_deposit_btc_withdraw_usdt() {
        let (coin_admin, _) = setup_tests();

        deposit_btc(&coin_admin, DEPOSIT_AMOUNT);
        withdraw_usdt(&coin_admin);
        let user_addr = signer::address_of(&coin_admin);
        let feeless_return = math::mul_div(DEPOSIT_AMOUNT, USDT_INITIAL_LIQUIDITY, BTC_INITIAL_LIQUIDITY);
        let acceptable_balance = math::mul_div(feeless_return, ACCEPTABLE_REMAINING_BPS, MAX_BPS);
        assert!(coin::balance<USDT>(user_addr) > acceptable_balance, 3);
    }
}
