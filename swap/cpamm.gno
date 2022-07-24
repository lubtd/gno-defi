package swap

import (
	igrc20 "gno.land/p/grc/grc20"
	grc20 "gno.land/p/grc/grc20/impl"
)

// Pool for constant product market maker
type CPAMM struct {
	// share information
	name        string
	symbol      string
	decimals    uint
	totalSupply uint64

	// pair information
	pairA   *igrc20.GRC20
	pairB   *igrc20.GRC20
	liquidityA = 0
	liquidityB = 0
}

func TotalSupply(token igrc20.GRC20) uint64 {
	return toto(wgnot)
}

func toto(token igrc20.GRC20) uint64 {
	totalSupply := token.TotalSupply()
	panic(totalSupply)
	return totalSupply
}
