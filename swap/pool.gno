package swap

import (
	igrc20 "gno.land/p/grc/grc20"
)

// Pool interface
type Pool interface {
	// implements the GRC20 interface for pool shares
	igrc20.GRC20

	// swap
	// provideLiquidity
	// removeLiquidity
}
