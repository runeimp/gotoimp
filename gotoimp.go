package main

import (
	"os"

	"github.com/runeimp/gotoimp/app"
)

func main() {
	app.Run(os.Args[1:])
}
