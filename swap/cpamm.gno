package swap

import (
	igrc20 "gno.land/p/grc/grc20"
)

// Pool for constant product market maker
type CPAMM struct {
	// share information
	name        string
	symbol      string
	totalSupply uint64

	// pair information
	pairA      igrc20.GRC20
	pairB      igrc20.GRC20
	liquidityA uint64
	liquidityB uint64
}

func NewCPAMM(pairA, pairB igrc20.GRC20) *CPAMM {
	return &CPAMM{
		pairA: pairA,
		pairB: pairB,

		name:   pairA.GetName() + "/" + pairB.GetName(),
		symbol: pairA.GetSymbol() + "/" + pairB.GetSymbol(),

		balances:   avl.NewMutTree(),
		allowances: avl.NewMutTree(),
	}
}

func TotalSupply(token igrc20.GRC20) uint64 {
	return TotalSupply(wgnot)
}
