package swap

import (
	igrc20 "gno.land/p/grc/grc20"
)

// Pool interface
type Pool interface {
	// implements the GRC20 interface for pool shares
	igrc20.GRC20

	// provide liquidity to the pool with tokens from both pairs
	ProvideLiquidity(amountA uint64, amountB uint64) uint64

	// remove liquidity from the pool
	RemoveLiquidity(shares uint64) (uint64, uint64)

	// swap tokens in the pool from pair A
	SwapA(amount uint64) uint64

	// swap tokens in the pool from pair B
	SwapB(amount uint64) uint64
}
