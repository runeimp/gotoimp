package clog

import (
	"fmt"
	"log"
	"runtime"
)

const (
	DebugLevelFatal uint8 = iota // Fatal errors and panics always output (default)
	DebugLevelError uint8 = iota // Code error
	DebugLevelWarn  uint8 = iota // Code warning
	DebugLevelInfo  uint8 = iota // Code useful info
	DebugLevelDebug uint8 = iota // Code debug info
)

const (
	InfoColor    = "\033[1;34m%s\033[0m"
	NoticeColor  = "\033[1;36m%s\033[0m"
	WarningColor = "\033[1;33m%s\033[0m"
	ErrorColor   = "\033[1;31m%s\033[0m"
	DebugColor   = "\033[0;36m%s\033[0m"
)

const (
	LabelColorDebug   = "\033[0;36mDEBUG\033[0m"
	LabelColorError   = "\033[1;31mERROR\033[0m"
	LabelColorFatal   = "\033[1;31mFATAL\033[0m"
	LabelColorInfo    = "\033[1;34mINFO\033[0m "
	LabelColorPanic   = "\033[1;31mPANIC\033[0m"
	LabelColorWarning = "\033[1;33mWARN\033[0m "
)

var DebugLevel uint8

func Debug(format string, msg ...interface{}) {
	if DebugLevel > DebugLevelInfo {
		if runtime.GOOS == "windows" {
			log.Println("DEBUG", fmt.Sprintf(format, msg...))
		} else {
			log.Println(LabelColorDebug, fmt.Sprintf(format, msg...))
		}
	}
}

func Info(format string, msg ...interface{}) {
	if DebugLevel > DebugLevelWarn {
		if runtime.GOOS == "windows" {
			log.Println("INFO ", fmt.Sprintf(format, msg...))
		} else {
			log.Println(LabelColorInfo, fmt.Sprintf(format, msg...))
		}
	}
}

func Warn(format string, msg ...interface{}) {
	if DebugLevel > DebugLevelError {
		if runtime.GOOS == "windows" {
			log.Println("WARN ", fmt.Sprintf(format, msg...))
		} else {
			log.Println(LabelColorWarning, fmt.Sprintf(format, msg...))
		}
	}
}

func Error(format string, msg ...interface{}) {
	if DebugLevel > DebugLevelFatal {
		if runtime.GOOS == "windows" {
			log.Println("ERROR", fmt.Sprintf(format, msg...))
		} else {
			log.Println(LabelColorError, fmt.Sprintf(format, msg...))
		}
	}
}

func Fatal(msg ...interface{}) {
	if runtime.GOOS == "windows" {
		log.Fatalln("FATAL", fmt.Sprint(msg...))
	} else {
		log.Fatalln(LabelColorFatal, fmt.Sprint(msg...))
	}
}

func Panic(msg ...interface{}) {
	if runtime.GOOS == "windows" {
		log.Panicln("PANIC", fmt.Sprint(msg...))
	} else {
		log.Panicln(LabelColorPanic, fmt.Sprint(msg...))
	}
}
