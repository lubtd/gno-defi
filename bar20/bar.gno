package foo20

import (
	"std"
	"strings"

	grc20 "gno.land/p/grc/grc20/impl"
	"gno.land/p/ufmt"
	"gno.land/r/users"
)

var (
	foo   *grc20.Token
	admin std.Address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5" // test1
)

func init() {
	foo = grc20.NewToken("Bar", "BAR", 4)
	foo.Mint(admin, 1000000*10000)
}

// method proxies as public functions.
//

// getters.

func TotalSupply() uint64 {
	return foo.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	return foo.BalanceOf(owner.Resolve())
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	return foo.Allowance(owner.Resolve(), spender.Resolve())
}

// setters.

func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	foo.Transfer(caller, to.Resolve(), amount)
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	foo.Approve(caller, spender.Resolve(), amount)
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	foo.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

// administration.

func Mint(address users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	assertIsAdmin(caller)
	foo.Mint(address.Resolve(), amount)
}

func Burn(address users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	assertIsAdmin(caller)
	foo.Burn(address.Resolve(), amount)
}

// render.
//

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return foo.RenderHome()
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance := foo.BalanceOf(owner.Resolve())
		return ufmt.Sprintf("%d\n", balance)
	default:
		return "404\n"
	}
}

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}
