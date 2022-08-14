package pool

import (
	"std"

	"gno.land/p/grc/grc20"
)

// Pool interface
type Pool interface {
	// implements the GRC20 interface for pool shares
	grc20.IGRC20

	// provide liquidity to the pool with tokens from both pairs
	ProvideLiquidity(from, pkgaddr std.Address, amountA uint64, amountB uint64) uint64

	// remove liquidity from the pool
	RemoveLiquidity(pkgaddr, to std.Address, shares uint64) (uint64, uint64)

	// swap tokens in the pool from pair A
	SwapA(from, pkgaddr std.Address, amount uint64) uint64

	// swap tokens in the pool from pair B
	SwapB(from, pkgaddr std.Address, amount uint64) uint64
}
