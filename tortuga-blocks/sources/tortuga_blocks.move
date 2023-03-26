module satay::tortuga_blocks {

    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;

    use tortuga_governance::staked_aptos_coin::StakedAptosCoin;

    use hippo_aggregator::aggregator;

    use satay::utils;

    public entry fun deposit<Y, Z, E2, E3>(
        sender: &signer,
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool, // first trade uses normal order
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool, // second trade uses normal order
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool, // second trade uses normal order
        amount: u64,
    ) {
        let aptos_coins = coin::withdraw<AptosCoin>(sender, amount);
        let (aptos_coins, y_coins, z_coins, tapt_coins) = stake<Y, Z, E2, E3>(
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
            aptos_coins
        );
        utils::check_and_deposit(sender, aptos_coins);
        utils::check_and_deposit(sender, y_coins);
        utils::check_and_deposit(sender, z_coins);
        utils::check_and_deposit(sender, tapt_coins);
    }

    /// stake `AptosCoin` through Ditto and mint `StakedAptos` coins
    /// * `aptos_coins` - the `AptosCoin` coins to stake
    /// * `addr` - the address of the account staking the coins
    public fun stake<Y, Z, E2, E3>(
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool, // first trade uses normal order
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool, // second trade uses normal order
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool, // second trade uses normal order
        aptos_coins: Coin<AptosCoin>
    ): (Coin<AptosCoin>, Coin<Y>, Coin<Z>, Coin<StakedAptosCoin>) {
        let (
            apt_opt,
            y_opt,
            z_opt,
            tapt_coins
        ) = aggregator::swap_direct<AptosCoin, Y, Z, StakedAptosCoin, u8, E2, E3>(
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
            aptos_coins
        );
        (utils::unwrap_coin_opt(apt_opt), utils::unwrap_coin_opt(y_opt), utils::unwrap_coin_opt(z_opt), tapt_coins)
    }

    public entry fun withdraw<Y, Z, E2, E3>(
        sender: &signer,
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool, // first trade uses normal order
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool, // second trade uses normal order
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool, // second trade uses normal order
        amount: u64,
    ) {
        let tapt_coins = coin::withdraw<StakedAptosCoin>(sender, amount);
        let (tapt_coins, y_coins, z_coins, aptos_coins) = unstake<Y, Z, E2, E3>(
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
            tapt_coins
        );
        utils::check_and_deposit(sender, aptos_coins);
        utils::check_and_deposit(sender, y_coins);
        utils::check_and_deposit(sender, z_coins);
        utils::check_and_deposit(sender, tapt_coins);
    }

    /// unstake `StakedAptos` through Ditto to redeem `AptosCoin` coins
    /// * `staked_aptos` - the `StakedAptos` coins to unstake
    /// * `addr` - the address of the account unstaking the coins
    public fun unstake<Y, Z, E2, E3>(
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool, // first trade uses normal order
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool, // second trade uses normal order
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool, // second trade uses normal order
        tapt_coins: Coin<StakedAptosCoin>
    ): (Coin<StakedAptosCoin>, Coin<Y>, Coin<Z>, Coin<AptosCoin>) {
        let (
            tapt_opt,
            y_opt,
            z_opt,
            apt_coins
        ) = aggregator::swap_direct<StakedAptosCoin, Y, Z, AptosCoin, u8, E2, E3>(
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
            tapt_coins
        );
        (utils::unwrap_coin_opt(tapt_opt), utils::unwrap_coin_opt(y_opt), utils::unwrap_coin_opt(z_opt), apt_coins)
    }

    public fun unstake_exact_out<Y, Z, E2, E3>(
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool,
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool,
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool,
        tapt_coins: Coin<StakedAptosCoin>,
        exact_out: u64
    ): (Coin<StakedAptosCoin>, Coin<Y>, Coin<Z>, Coin<AptosCoin>) {
        let (
            tapt_opt,
            y_opt,
            z_opt,
            apt_opt,
            tapt_coins,
            apt_coins
        ) = aggregator::swap_exact_out_with_change_direct<StakedAptosCoin, Y, Z, AptosCoin, u8, E2, E3>(
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
            tapt_coins,
            exact_out
        );
        let tapt = utils::merge_coin_and_coin_opt<StakedAptosCoin>(tapt_coins, tapt_opt);
        let apt = utils::merge_coin_and_coin_opt<AptosCoin>(apt_coins, apt_opt);
        (tapt, utils::unwrap_coin_opt(y_opt), utils::unwrap_coin_opt(z_opt), apt)
    }
}
