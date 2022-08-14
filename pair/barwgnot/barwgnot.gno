package pair

import (
	"std"
	"strings"

	"gno.land/p/pool"
	"gno.land/p/ufmt"
	"gno.land/r/bar20"
	"gno.land/r/users"
	"gno.land/r/wgnot"
)

var (
	pair *pool.CPAMM
)

func init() {
	pair = pool.NewCPAMM(
		"bar/wgnot",
		"BARWGNOT",
		wgnot.GetGRC20(),
		bar20.GetGRC20(),
		10,
	)
}

// Pool operations

func ProvideLiquidity(amountA uint64, amountB uint64) uint64 {
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()

	return pair.ProvideLiquidity(caller, pkgaddr, amountA, amountB)
}

func RemoveLiquidity(shares uint64) (uint64, uint64) {
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()

	pair.RemoveLiquidity(pkgaddr, caller, shares)
}

func SwapA(amount uint64) uint64 {
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()

	return pair.SwapA(caller, pkgaddr, amount)
}

func SwapB(amount uint64) uint64 {
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()

	return pair.SwapB(caller, pkgaddr, amount)
}

// GRC20 Implementation

func TotalSupply() uint64 {
	return pair.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	return pair.BalanceOf(owner.Resolve())
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	return pair.Allowance(owner.Resolve(), spender.Resolve())
}

func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	pair.Transfer(caller, to.Resolve(), amount)
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	pair.Approve(caller, spender.Resolve(), amount)
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	pair.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

// Render

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return bar.RenderHome()
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance := bar.BalanceOf(owner.Resolve())
		return ufmt.Sprintf("%d\n", balance)
	default:
		return "404\n"
	}
}
