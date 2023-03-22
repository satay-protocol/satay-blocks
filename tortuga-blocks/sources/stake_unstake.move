module tortuga_blocks::stake_unstake {

    use std::signer;
    use std::option::{Self, Option};

    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;

    use tortuga_governance::staked_aptos_coin::StakedAptosCoin;

    use hippo_aggregator::aggregator;

    /// stake `AptosCoin` through Ditto and mint `StakedAptos` coins
    /// * `aptos_coins` - the `AptosCoin` coins to stake
    /// * `addr` - the address of the account staking the coins
    public fun stake<Y, Z, E2, E3>(
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
        aptos_coins: Coin<AptosCoin>
    ): Coin<StakedAptosCoin> {
        let (
            residual_apt,
            residual_y,
            residual_z,
            stapt_coins
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

        check_and_deposit_opt(sender, residual_apt);
        check_and_deposit_opt(sender, residual_y);
        check_and_deposit_opt(sender, residual_z);

        stapt_coins
    }

    /// unstake `StakedAptos` through Ditto to redeem `AptosCoin` coins
    /// * `staked_aptos` - the `StakedAptos` coins to unstake
    /// * `addr` - the address of the account unstaking the coins
    public fun unstake<Y, Z, E2, E3>(
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
        tapt_coins: Coin<StakedAptosCoin>
    ): Coin<AptosCoin> {
        let (
            residual_tapt,
            residual_y,
            residual_z,
            aptos_coins
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

        check_and_deposit_opt(sender, residual_tapt);
        check_and_deposit_opt(sender, residual_y);
        check_and_deposit_opt(sender, residual_z);

        aptos_coins
    }

    fun check_and_deposit_opt<X>(sender: &signer, coin_opt: Option<Coin<X>>) {
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

    fun check_and_deposit<X>(sender: &signer, coin: Coin<X>) {
        let sender_addr = signer::address_of(sender);
        if (!coin::is_account_registered<X>(sender_addr)) {
            coin::register<X>(sender);
        };
        coin::deposit(sender_addr, coin);
    }
}
