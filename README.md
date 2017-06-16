# About

Command-line utility for keeping track of expenses in multiple currencies.

Original currency is always saved alongside the EUR and USD equivalent _at the time_.

This way we can report in either EUR or USD without having to look for old conversion
rates and hence without the need for internet connection for doing reports.

## Options

- `expense add`, `a`, `+`: Interactively add a new expense.
- `expense report`, `r`:  Report on your spendings.
- `expense review`: Review long-term purchases.
- `expense console`, `c`: Launch Ruby console with expense data loaded.
- `expense edit`, `e`: Edit expense data in $EDITOR.

## Environment variables

`EXPENSE_DATA_FILE_PATH` defaults to `~/Dropbox/Data/Archive/Expenses/2017.json`.
